/* Hote CPython partage : demarrage unique de l'interpreteur, relais stdout/stderr
   vers le journal de simulation, lecture de fichier source.

   Partage par les DEUX chapeaux : PyRuntimeImpl.c (le microcontroleur) et
   UartDeviceImpl.c (les peripheriques serie dont le comportement est decrit par
   un script). Un seul interpreteur CPython existe dans le process, quel que soit
   le nombre de composants qui s'en servent : c'est le premier construit qui le
   demarre, les suivants le trouvent deja la (Py_IsInitialized). L'ordre de
   construction des External Objects n'etant pas garanti par Modelica, aucun
   composant ne peut supposer etre le premier.

   INVARIANT etabli ici et respecte partout : une fois pyhost_ensure() revenu, le
   thread Modelica NE TIENT PAS le GIL. Tout code qui appelle Python depuis ce
   thread l'encadre de PyGILState_Ensure/PyGILState_Release ; le thread worker
   du microcontroleur le relache chaque fois qu'il se gare (cf. yield_to_modelica).

   Inclus TEXTUELLEMENT par un chapeau, jamais compile seul. Garde d'inclusion
   obligatoire : omc dedoublonne les annotations Include par leur texte, donc les
   deux chapeaux peuvent se retrouver dans la meme unite de compilation - et si
   ce n'est pas le cas, chacun a sa copie static, sans consequence puisque la
   garde a l'execution (Py_IsInitialized) est, elle, globale au process. */
#ifndef PYHOST_C_INCLUDED
#define PYHOST_C_INCLUDED

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
   worker et celles des scripts de peripherique : pas de verrou supplementaire. */

static char g_stdout_buf[4096];
static size_t g_stdout_len = 0;

static void relay_emit_pending(void) {
    if (g_stdout_len > 0) {
        g_stdout_buf[g_stdout_len] = '\0';
        ModelicaFormatMessage("%s", g_stdout_buf);
        g_stdout_len = 0;
    }
}

static PyObject* relay_write(PyObject* self, PyObject* args) {
    const char* text;
    if (!PyArg_ParseTuple(args, "s", &text)) {
        return NULL;
    }
    for (const char* p = text; *p != '\0'; ++p) {
        if (*p == '\n') {
            relay_emit_pending();
        } else {
            g_stdout_buf[g_stdout_len++] = *p;
            if (g_stdout_len >= sizeof(g_stdout_buf) - 1) {
                relay_emit_pending();
            }
        }
    }
    Py_RETURN_NONE;
}

static PyObject* relay_flush(PyObject* self, PyObject* args) {
    relay_emit_pending();
    Py_RETURN_NONE;
}

static PyMethodDef relay_methods[] = {
    {"write", relay_write, METH_VARARGS, "Relaie l'ecriture vers ModelicaFormatMessage"},
    {"flush", relay_flush, METH_VARARGS, "Vide la ligne en cours"},
    {NULL, NULL, 0, NULL}
};

static struct PyModuleDef relay_module_def = {
    PyModuleDef_HEAD_INIT, "pyruntime_stdio", NULL, -1, relay_methods,
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

/* Demarre CPython s'il ne l'est pas deja. Retourne 0 si l'interpreteur est
   pret (demarre ici ou avant), -1 sinon avec un message dans err.
   Au retour, le thread appelant NE TIENT PAS le GIL (cf. invariant en tete). */
static int pyhost_ensure(const char* pythonHome, char* err, size_t errlen) {
    PyStatus status;
    PyConfig config;

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
            snprintf(err, errlen, "echec d'ajout de python312.zip au sys.path");
            return -1;
        }
        status = PyWideStringList_Append(&config.module_search_paths, Py_DecodeLocale(pythonHome, NULL));
        if (PyStatus_Exception(status)) {
            PyConfig_Clear(&config);
            snprintf(err, errlen, "echec d'ajout de %s au sys.path", pythonHome);
            return -1;
        }
    }
    status = PyConfig_SetBytesString(&config, &config.home, pythonHome);
    if (PyStatus_Exception(status)) {
        PyConfig_Clear(&config);
        snprintf(err, errlen, "echec de configuration de PYTHONHOME ('%s')", pythonHome);
        return -1;
    }

    status = Py_InitializeFromConfig(&config);
    PyConfig_Clear(&config);
    if (PyStatus_Exception(status)) {
        snprintf(err, errlen, "echec d'initialisation de CPython (home='%s')", pythonHome);
        return -1;
    }

    /* Relais stdout/stderr : installe une fois pour tout le process. */
    {
        PyObject* relay = PyModule_Create(&relay_module_def);
        if (relay) {
            PySys_SetObject("stdout", relay);
            PySys_SetObject("stderr", relay);
            pyhost_register_module("pyruntime_stdio", relay);   /* consomme la reference */
        }
    }

    /* Rend le GIL : le thread Modelica ne le tient plus, conformement a
       l'invariant. Chaque composant le reprendra au besoin par PyGILState_Ensure. */
    PyEval_SaveThread();
    return 0;
}

#endif /* PYHOST_C_INCLUDED */
