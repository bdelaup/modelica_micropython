/* Script Python d'un peripherique externe : chargement dans un espace de noms
   propre, appel des gestionnaires, conversion des valeurs echangees.

   PARTAGE par les peripheriques serie (uartdevice/uartdevice_script.c) et les
   peripheriques I2C (i2cdevice/i2cdevice_script.c). Ce qui differe entre eux -
   le nom et la signature des gestionnaires, le moment ou ils sont appeles - reste
   dans leurs fichiers ; ici ne vit que la mecanique commune.

   Le script est charge UNE FOIS, a la construction de l'External Object, et
   execute dans un DICTIONNAIRE DE GLOBALES QUI LUI EST PROPRE - surtout pas
   PyRun_SimpleString, qui execute dans __main__ : deux peripheriques s'y
   ecraseraient mutuellement leurs variables, et pietineraient celles du script
   du microcontroleur. Les variables de module persistent donc d'un appel a
   l'autre sans mecanisme particulier (une machine d'etat s'ecrit naturellement),
   et deux instances du meme fichier ont deux etats independants.

   Aucune variable "peripherique courant" n'est necessaire : une fonction Python
   transporte ses globales (__globals__), donc appeler un gestionnaire ecrit dans
   LE dictionnaire de ce peripherique. C'est le sens de l'appel (C -> Python) qui
   rend la chose gratuite, a l'inverse du shim du microcontroleur (Python -> C,
   d'ou g_current).

   Les gestionnaires s'executent sur le thread Modelica : ils vont au bout, sans
   sleep() et sans acces a machine (cf. worker_context_ok cote microcontroleur).

   Inclus TEXTUELLEMENT par un chapeau (UartDeviceImpl.c, I2cDeviceImpl.c),
   apres pyhost.c dont il se sert, jamais compile seul. Garde d'inclusion
   obligatoire : les deux chapeaux peuvent atterrir dans la meme unite de
   compilation. */

#ifndef DEVSCRIPT_C_INCLUDED
#define DEVSCRIPT_C_INCLUDED

/* Prefixe les print() du script par le nom du composant : avec plusieurs
   appareils sur le meme bus, un journal non prefixe est illisible. Execute dans
   les globales du peripherique, AVANT le script ; un script qui redefinit
   print() garde evidemment la sienne. */
static const char* DEVSCRIPT_PRELUDE =
    "def print(*args, **kwargs):\n"
    "    __print__('[' + __device__ + ']', *args, **kwargs)\n";

/* Signale l'erreur Python en cours (trace dans le journal), rend le GIL, puis
   arrete la simulation. Ne revient pas. Le GIL est rendu AVANT
   ModelicaFormatError, qui ne revient pas : un GIL garde bloquerait tout.
   component : "UartDevice", "I2cDevice"... pour situer le message. */
static void devscript_fail(const char* component, const char* path, PyGILState_STATE gstate, const char* what) {
    if (PyErr_Occurred()) {
        PyErr_Print();
    }
    relay_emit_pending();
    PyGILState_Release(gstate);
    ModelicaFormatError("%s (%s) : %s - trace ci-dessus", component, path, what);
}

/* Reference forte sur une fonction du script, ou NULL si absente. GIL tenu. */
static PyObject* devscript_handler(PyObject* globals, const char* name) {
    PyObject* f = PyDict_GetItemString(globals, name);   /* empruntee */
    if (f && PyCallable_Check(f)) {
        Py_INCREF(f);
        return f;
    }
    return NULL;
}

/* Appelle outputs() (si le script la definit) et recopie le resultat dans
   out[0..n-1] : un nombre alimente out[0], une sequence est recopiee terme a
   terme. Les termes non fournis gardent leur valeur. GIL tenu. 0 ou -1. */
static int devscript_read_outputs(PyObject* outputs_fn, double* out, int n) {
    PyObject* r;
    int k;
    if (!outputs_fn) {
        return 0;
    }
    r = PyObject_CallNoArgs(outputs_fn);
    if (!r) {
        return -1;
    }
    if (PyFloat_Check(r) || PyLong_Check(r)) {
        out[0] = PyFloat_AsDouble(r);
    } else if (PySequence_Check(r) && !PyUnicode_Check(r) && !PyBytes_Check(r)) {
        Py_ssize_t len = PySequence_Size(r);
        for (k = 0; k < n && k < len; k++) {
            PyObject* item = PySequence_GetItem(r, k);
            double v = item ? PyFloat_AsDouble(item) : 0.0;
            Py_XDECREF(item);
            if (PyErr_Occurred()) {
                Py_DECREF(r);
                return -1;
            }
            out[k] = v;
        }
    } else {
        Py_DECREF(r);
        PyErr_SetString(PyExc_TypeError, "outputs() doit retourner un nombre ou une sequence de nombres");
        return -1;
    }
    Py_DECREF(r);
    return PyErr_Occurred() ? -1 : 0;
}

/* Tuple des n grandeurs venues du modele (argument v des gestionnaires). GIL tenu. */
static PyObject* devscript_values(const double* v, int n) {
    PyObject* t = PyTuple_New(n);
    int k;
    if (!t) {
        return NULL;
    }
    for (k = 0; k < n; k++) {
        PyTuple_SET_ITEM(t, k, PyFloat_FromDouble(v[k]));
    }
    return t;
}

/* Convertit la valeur de retour d'un gestionnaire en octets : bytes, bytearray,
   str (UTF-8) ou None. Tronque a outmax (comme une file qui deborde), termine
   par '\0'. GIL tenu. Retourne la longueur (0 pour None), ou -1 avec PyErr. */
static int devscript_payload(PyObject* r, char* out, int outmax) {
    const char* data = NULL;
    Py_ssize_t len = 0;
    if (r == Py_None) {
        out[0] = '\0';
        return 0;
    }
    if (PyBytes_Check(r)) {
        data = PyBytes_AS_STRING(r);
        len = PyBytes_GET_SIZE(r);
    } else if (PyByteArray_Check(r)) {
        data = PyByteArray_AS_STRING(r);
        len = PyByteArray_GET_SIZE(r);
    } else if (PyUnicode_Check(r)) {
        data = PyUnicode_AsUTF8AndSize(r, &len);
        if (!data) {
            return -1;
        }
    } else {
        PyErr_SetString(PyExc_TypeError, "un gestionnaire doit retourner bytes, str ou None");
        return -1;
    }
    if (len > outmax) {
        len = outmax;
    }
    memcpy(out, data, (size_t) len);
    out[len] = '\0';
    return (int) len;
}

/* Charge le script d'un peripherique : demarre CPython si besoin (pyhost), cree
   un espace de noms propre, y execute le prelude puis le script. Retourne ce
   dictionnaire (reference forte, jamais relachee - le process se termine avec la
   simulation, meme choix que PyRuntime_destroy). Le GIL n'est PAS tenu au
   retour : l'appelant le reprend pour recuperer ses gestionnaires. En cas
   d'echec, arrete la simulation (ne revient pas). */
static PyObject* devscript_load(const char* component, const char* path,
                                const char* pythonHome, const char* instanceName) {
    char err[512];
    char* src;
    PyGILState_STATE gstate;
    PyObject* globals;
    PyObject* code;
    PyObject* r;
    const char* base;

    if (!path || path[0] == '\0') {
        ModelicaFormatError("%s : scriptPath est vide - indiquer le script .py qui decrit le peripherique", component);
        return NULL;
    }
    src = read_text_file(path);
    if (!src) {
        ModelicaFormatError("%s : impossible de lire le script du peripherique ('%s')", component, path);
        return NULL;
    }
    if (pyhost_ensure(pythonHome, err, sizeof(err)) != 0) {
        free(src);
        ModelicaFormatError("%s (%s) : %s", component, path, err);
        return NULL;
    }

    gstate = PyGILState_Ensure();

    globals = PyDict_New();
    if (!globals) {
        free(src);
        devscript_fail(component, path, gstate, "echec de creation de l'espace de noms");
        return NULL;   /* jamais atteint : ModelicaFormatError ne revient pas */
    }

    /* __name__ : nom de fichier sans extension, comme pour un module importe -
       surtout pas "__main__", qui executerait un eventuel bloc de test. */
    base = strrchr(path, '/');
    if (!base || strrchr(path, '\\') > base) {
        base = strrchr(path, '\\');
    }
    base = base ? base + 1 : path;
    {
        char modname[128];
        size_t i;
        PyObject* name;
        for (i = 0; i < sizeof(modname) - 1 && base[i] && base[i] != '.'; i++) {
            modname[i] = base[i];
        }
        modname[i] = '\0';
        name = PyUnicode_FromString(modname);
        PyDict_SetItemString(globals, "__name__", name);
        Py_XDECREF(name);
    }
    {
        PyObject* file = PyUnicode_DecodeFSDefault(path);
        PyObject* devname = PyUnicode_FromString(instanceName && instanceName[0] ? instanceName : component);
        PyObject* builtin_print = PyDict_GetItemString(PyEval_GetBuiltins(), "print");   /* empruntee */
        PyDict_SetItemString(globals, "__builtins__", PyEval_GetBuiltins());
        PyDict_SetItemString(globals, "__file__", file);
        PyDict_SetItemString(globals, "__device__", devname);
        if (builtin_print) {
            PyDict_SetItemString(globals, "__print__", builtin_print);
        }
        Py_XDECREF(file);
        Py_XDECREF(devname);
    }

    r = PyRun_String(DEVSCRIPT_PRELUDE, Py_file_input, globals, globals);
    if (!r) {
        free(src);
        devscript_fail(component, path, gstate, "echec du prelude");
        return NULL;
    }
    Py_DECREF(r);

    /* Le chemin du script est passe au compilateur : les traces d'exception
       nomment ainsi le bon fichier, ce qui compte avec plusieurs peripheriques. */
    code = Py_CompileString(src, path, Py_file_input);
    free(src);
    if (!code) {
        devscript_fail(component, path, gstate, "erreur de syntaxe dans le script");
        return NULL;
    }
    r = PyEval_EvalCode(code, globals, globals);
    Py_DECREF(code);
    if (!r) {
        devscript_fail(component, path, gstate, "le script a leve une exception au chargement");
        return NULL;
    }
    Py_DECREF(r);

    relay_emit_pending();
    PyGILState_Release(gstate);
    return globals;
}

#endif /* DEVSCRIPT_C_INCLUDED */
