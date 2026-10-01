/* Hote CPython partage : demarrage unique de l'interpreteur, relais stdout/stderr
   vers le journal de simulation, lecture de fichier source.

   Partage par les DEUX chapeaux : PyRuntimeImpl.c (le microcontroleur) et
   UartDeviceImpl.c (les peripheriques serie dont le comportement est decrit par
   un script). CPython n'est demarre qu'une fois par process, quel que soit le
   nombre de composants qui s'en servent : c'est le premier construit qui le
   demarre, les suivants le trouvent deja la (Py_IsInitialized). L'ordre de
   construction des External Objects n'etant pas garanti par Modelica, aucun
   composant ne peut supposer etre le premier. L'interpreteur PRINCIPAL ainsi
   demarre sert aux scripts de peripherique ; chaque microcontroleur cree en plus
   son propre sous-interpreteur, sur son thread worker (cf. pyruntime_module.c).

   INVARIANT etabli ici et respecte partout : une fois pyhost_ensure() revenu, le
   thread Modelica NE TIENT PAS le GIL. Tout code qui appelle Python depuis ce
   thread l'encadre de PyGILState_Ensure/PyGILState_Release ; le thread worker
   du microcontroleur le relache chaque fois qu'il se gare (cf. yield_to_modelica).

   SECOND INVARIANT : aucun appel a l'API Python avant pyhost_load_dll(), que
   pyhost_ensure() fait en premier. Le modele n'est PAS lie a python312 : la DLL
   est chargee ici par son chemin absolu dans la distribution embarquee, jamais
   cherchee par Windows (qui prendrait celle d'un Python installe sur le poste
   s'il la trouve dans le PATH) - cf. requirements.md, decision "Distribution
   Python embarquee".

   Inclus TEXTUELLEMENT par un chapeau, jamais compile seul. Garde d'inclusion
   obligatoire : omc dedoublonne les annotations Include par leur texte, donc les
   deux chapeaux peuvent se retrouver dans la meme unite de compilation - et si
   ce n'est pas le cas, chacun a sa copie static, sans consequence puisque la
   garde a l'execution (Py_IsInitialized) est, elle, globale au process. */
#ifndef PYHOST_C_INCLUDED
#define PYHOST_C_INCLUDED

#include <windows.h>

/* --- Table d'import de python312.dll ---
   L'API Python est declaree dllimport (pyconfig.h Windows : Py_ENABLE_SHARED) :
   le code compile n'appelle pas Py_Foo directement, il lit le pointeur
   __imp_Py_Foo - fonctions comme donnees (Py_None, PyExc_*, Py*_Type). Au lieu
   de laisser l'import lib et le chargeur de Windows fournir ces pointeurs, on
   les definit ici et on les remplit par GetProcAddress. Liste generee par
   make_pyimports.sh (qui compile avec PYHOST_NO_IMPORT_TABLE pour relever les
   references non resolues) ; un symbole manquant se traduit par
   "undefined reference to `__imp_...'" a l'edition de liens.
   selectany : si les chapeaux tombent dans des unites de compilation
   distinctes, chacune porte la table et l'editeur de liens n'en garde qu'une. */
#ifdef PYHOST_NO_IMPORT_TABLE
#define PYHOST_IMPORTS(X)
#else
#include "pyimports.h"
#endif

#define PYHOST_IMP_DEFINE(n) __declspec(selectany) void* __imp_##n = NULL;
PYHOST_IMPORTS(PYHOST_IMP_DEFINE)

static const struct { const char* name; void** slot; } pyhost_import_table[] = {
#define PYHOST_IMP_ENTRY(n) { #n, &__imp_##n },
    PYHOST_IMPORTS(PYHOST_IMP_ENTRY)
    { NULL, NULL }
};

/* Chemin (UTF-8 le plus souvent, sinon page de code ANSI) -> UTF-16 alloue. */
static wchar_t* pyhost_widen(const char* s, size_t extra) {
    UINT cp = CP_UTF8;
    DWORD flags = MB_ERR_INVALID_CHARS;
    int n = MultiByteToWideChar(cp, flags, s, -1, NULL, 0);
    if (n <= 0) {
        cp = CP_ACP;
        flags = 0;
        n = MultiByteToWideChar(cp, flags, s, -1, NULL, 0);
    }
    if (n <= 0) {
        return NULL;
    }
    wchar_t* w = (wchar_t*) malloc(((size_t) n + extra) * sizeof(wchar_t));
    MultiByteToWideChar(cp, flags, s, -1, w, n);
    return w;
}

/* Charge <pythonHome>\python312.dll et remplit la table d'import. Idempotent.
   Retourne 0, ou -1 avec un message dans err. LOAD_LIBRARY_SEARCH_DLL_LOAD_DIR :
   les dependances de la DLL (vcruntime140.dll...) sont cherchees d'abord a cote
   d'elle. Les modules d'extension .pyd importent ensuite python312.dll par son
   nom : Windows leur donne celle-ci, deja chargee. */
static int pyhost_load_dll(const char* pythonHome, char* err, size_t errlen) {
    static HMODULE dll = NULL;
    if (dll) {
        return 0;
    }

    static const wchar_t dll_name[] = L"\\python312.dll";
    wchar_t* path = pyhost_widen(pythonHome, sizeof(dll_name) / sizeof(wchar_t));
    if (!path) {
        snprintf(err, errlen, "unreadable path of the Python distribution ('%s')", pythonHome);
        return -1;
    }
    size_t len = wcslen(path);
    for (size_t i = 0; i < len; ++i) {
        if (path[i] == L'/') {
            path[i] = L'\\';       /* LoadLibraryExW refuse les '/' avec les drapeaux LOAD_LIBRARY_SEARCH_* */
        }
    }
    while (len > 0 && path[len - 1] == L'\\') {
        path[--len] = L'\0';
    }
    wcscat(path, dll_name);

    HMODULE h = LoadLibraryExW(path, NULL, LOAD_LIBRARY_SEARCH_DLL_LOAD_DIR | LOAD_LIBRARY_SEARCH_DEFAULT_DIRS);
    free(path);
    if (!h) {
        snprintf(err, errlen, "cannot load %s\\python312.dll (Windows error %lu)",
                 pythonHome, (unsigned long) GetLastError());
        return -1;
    }
    for (int i = 0; pyhost_import_table[i].name; ++i) {
        void* p = (void*) GetProcAddress(h, pyhost_import_table[i].name);
        if (!p) {
            snprintf(err, errlen, "symbol %s missing from %s\\python312.dll (unexpected version?)",
                     pyhost_import_table[i].name, pythonHome);
            return -1;
        }
        *pyhost_import_table[i].slot = p;
    }
    dll = h;
    return 0;
}

/* --- Lecture de fichier source (shim, script du microcontroleur, script de
   peripherique) --- Retourne le contenu entier dans un tampon alloue, termine
   par '\0', ou NULL si le fichier ne peut pas etre ouvert. A liberer (free). */
static char* read_text_file(const char* path) {
    FILE* f = fopen(path, "rb");
    if (!f) {
        return NULL;
    }
    fseek(f, 0, SEEK_END);
    long size = ftell(f);
    fseek(f, 0, SEEK_SET);
    char* buf = (char*) malloc((size_t) size + 1);
    size_t got = fread(buf, 1, (size_t) size, f);
    buf[got] = '\0';
    fclose(f);
    return buf;
}

/* --- Relais stdout/stderr -> ModelicaFormatMessage ---
   print() avec plusieurs arguments declenche plusieurs write() distincts (un par
   argument/separateur) ; comme chaque appel a ModelicaFormatMessage produit sa
   propre ligne dans le journal OMEdit, il faut bufferiser jusqu'a un vrai saut de
   ligne plutot que relayer chaque write() individuellement (sinon un print("a", b)
   se retrouve fragmente sur plusieurs lignes). Le GIL serialise les ecritures du
   worker et celles des scripts de peripherique : pas de verrou supplementaire.

   UN TAMPON PAR INTERPRETEUR : chaque microcontroleur a son sous-interpreteur et
   son relais (tampon dans son handle, cf. pyruntime_module.c), l'interpreteur
   principal - celui des scripts de peripherique - garde g_relay_main. Sans cela,
   la ligne commencee par un microcontroleur serait terminee par le texte d'un
   autre. Le tampon est retrouve par l'etat du module relais (PyModule_GetState),
   donc sans variable "relais courant". prefix : nom d'instance mis en tete de
   chaque ligne quand *prefix_on est vrai (plusieurs microcontroleurs), NULL pour
   l'interpreteur principal - les peripheriques prefixent deja eux-memes. */

struct RelayBuf {
    char buf[4096];
    size_t len;
    const char* prefix;
    const int* prefix_on;
};

static struct RelayBuf g_relay_main;

static void relay_flush_buf(struct RelayBuf* r) {
    if (r->len > 0) {
        r->buf[r->len] = '\0';
        if (r->prefix && r->prefix_on && *r->prefix_on) {
            ModelicaFormatMessage("[%s] %s", r->prefix, r->buf);
        } else {
            ModelicaFormatMessage("%s", r->buf);
        }
        r->len = 0;
    }
}

/* Vide le tampon de l'interpreteur principal (scripts de peripherique). */
static void relay_emit_pending(void) {
    relay_flush_buf(&g_relay_main);
}

static struct RelayBuf* relay_of(PyObject* module) {
    struct RelayBuf** state = (struct RelayBuf**) PyModule_GetState(module);
    return (state && *state) ? *state : &g_relay_main;
}

static PyObject* relay_write(PyObject* self, PyObject* args) {
    const char* text;
    if (!PyArg_ParseTuple(args, "s", &text)) {
        return NULL;
    }
    struct RelayBuf* r = relay_of(self);
    for (const char* p = text; *p != '\0'; ++p) {
        if (*p == '\n') {
            relay_flush_buf(r);
        } else {
            r->buf[r->len++] = *p;
            if (r->len >= sizeof(r->buf) - 1) {
                relay_flush_buf(r);
            }
        }
    }
    Py_RETURN_NONE;
}

static PyObject* relay_flush(PyObject* self, PyObject* args) {
    relay_flush_buf(relay_of(self));
    Py_RETURN_NONE;
}

static PyMethodDef relay_methods[] = {
    {"write", relay_write, METH_VARARGS, "Relays the write to ModelicaFormatMessage"},
    {"flush", relay_flush, METH_VARARGS, "Flushes the current line"},
    {NULL, NULL, 0, NULL}
};

/* Etat du module : un pointeur vers son tampon. */
static struct PyModuleDef relay_module_def = {
    PyModuleDef_HEAD_INIT, "pyruntime_stdio", NULL, sizeof(struct RelayBuf*), relay_methods,
    NULL, NULL, NULL, NULL
};

/* Enregistre un module cree en C dans sys.modules, APRES l'initialisation.
   Remplace PyImport_AppendInittab, qui n'est utilisable qu'avant Py_Initialize :
   or le premier composant construit n'est pas forcement celui qui a besoin du
   module. Le GIL doit etre tenu. Retourne 0 ou -1 (PyErr positionne). */
static int pyhost_register_module(const char* name, PyObject* module) {
    if (!module) {
        return -1;
    }
    int rc = PyDict_SetItemString(PyImport_GetModuleDict(), name, module);
    Py_DECREF(module);
    return rc;
}

/* Ajoute un dossier a sys.path (en fin de liste). Le GIL doit etre tenu. */
static int pyhost_append_path(const char* dir) {
    PyObject* path = PySys_GetObject("path");   /* reference empruntee */
    PyObject* entry = PyUnicode_DecodeFSDefault(dir);
    if (!path || !entry) {
        Py_XDECREF(entry);
        return -1;
    }
    int rc = PyList_Append(path, entry);
    Py_DECREF(entry);
    return rc;
}

/* Installe le relais stdout/stderr dans l'interpreteur COURANT, sur le tampon
   r (cf. struct RelayBuf). Le GIL doit etre tenu. Retourne 0 ou -1. */
static int pyhost_install_relay(struct RelayBuf* r) {
    PyObject* relay = PyModule_Create(&relay_module_def);
    if (!relay) {
        return -1;
    }
    *(struct RelayBuf**) PyModule_GetState(relay) = r;
    if (PySys_SetObject("stdout", relay) != 0 || PySys_SetObject("stderr", relay) != 0) {
        Py_DECREF(relay);
        return -1;
    }
    return pyhost_register_module("pyruntime_stdio", relay);   /* consomme la reference */
}

/* Demarre CPython s'il ne l'est pas deja. Retourne 0 si l'interpreteur est
   pret (demarre ici ou avant), -1 sinon avec un message dans err.
   Au retour, le thread appelant NE TIENT PAS le GIL (cf. invariant en tete). */
static int pyhost_ensure(const char* pythonHome, char* err, size_t errlen) {
    PyStatus status;
    PyConfig config;

    if (pyhost_load_dll(pythonHome, err, errlen) != 0) {
        return -1;
    }
    if (Py_IsInitialized()) {
        return 0;
    }

    PyConfig_InitPythonConfig(&config);
    config.site_import = 0;
    config.use_environment = 0;
    config.module_search_paths_set = 1;

    /* Distribution "embeddable" : le stdlib est dans <home>\python312.zip, les
       modules d'extension .pyd sont directement dans <home>. Chemins construits
       explicitement : laisser CPython les deviner s'est revele peu fiable (le
       calcul se faisait polluer par une installation Python systeme via le
       registre Windows, cf. docs/integration-python.md). */
    {
        size_t home_len = strlen(pythonHome);
        char* zip_path = (char*) malloc(home_len + 32);
        sprintf(zip_path, "%s\\python312.zip", pythonHome);
        status = PyWideStringList_Append(&config.module_search_paths, Py_DecodeLocale(zip_path, NULL));
        free(zip_path);
        if (PyStatus_Exception(status)) {
            PyConfig_Clear(&config);
            snprintf(err, errlen, "failed to add python312.zip to sys.path");
            return -1;
        }
        status = PyWideStringList_Append(&config.module_search_paths, Py_DecodeLocale(pythonHome, NULL));
        if (PyStatus_Exception(status)) {
            PyConfig_Clear(&config);
            snprintf(err, errlen, "failed to add %s to sys.path", pythonHome);
            return -1;
        }
    }
    status = PyConfig_SetBytesString(&config, &config.home, pythonHome);
    if (PyStatus_Exception(status)) {
        PyConfig_Clear(&config);
        snprintf(err, errlen, "failed to set PYTHONHOME ('%s')", pythonHome);
        return -1;
    }

    status = Py_InitializeFromConfig(&config);
    PyConfig_Clear(&config);
    if (PyStatus_Exception(status)) {
        snprintf(err, errlen, "failed to initialise CPython (home='%s')", pythonHome);
        return -1;
    }

    /* Relais stdout/stderr de l'interpreteur principal (scripts de peripherique) ;
       chaque microcontroleur installe le sien dans son sous-interpreteur. */
    pyhost_install_relay(&g_relay_main);

    /* Rend le GIL : le thread Modelica ne le tient plus, conformement a
       l'invariant. Chaque composant le reprendra au besoin par PyGILState_Ensure. */
    PyEval_SaveThread();
    return 0;
}

#endif /* PYHOST_C_INCLUDED */
