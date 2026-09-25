/* Comportement d'un peripherique serie decrit par un script Python.

   Le script est charge UNE FOIS, a la construction de l'External Object, et
   execute dans un DICTIONNAIRE DE GLOBALES QUI LUI EST PROPRE - surtout pas
   PyRun_SimpleString, qui execute dans __main__ : deux peripheriques s'y
   ecraseraient mutuellement leurs variables, et pietineraient celles du script
   du microcontroleur. Les variables de module persistent donc d'un appel a
   l'autre sans mecanisme particulier (une machine d'etat s'ecrit naturellement),
   et deux instances du meme fichier ont deux etats independants.

   Aucune variable "peripherique courant" n'est necessaire : une fonction Python
   transporte ses globales (__globals__), donc appeler dev->py_on_receive ecrit
   dans LE dictionnaire de ce peripherique. C'est le sens de l'appel (C -> Python)
   qui rend la chose gratuite, a l'inverse du shim du microcontroleur (Python -> C,
   d'ou g_current).

   Contrat du script - trois fonctions, toutes facultatives :
     on_receive(ligne, t, v) -> bytes | str | None   une fois par ligne complete
     on_tick(t, v)           -> bytes | str | None   une fois par periode (si definie)
     outputs()               -> nombre | sequence    relue apres chaque gestionnaire
   ligne : bytes, sans le terminateur. t : temps simule (s). v : tuple des
   UARTDEV_MAX_VALUES grandeurs de valueIn.

   Ces fonctions s'executent sur le thread Modelica : elles vont au bout, sans
   sleep() et sans acces a machine (cf. worker_context_ok cote microcontroleur).

   Inclus TEXTUELLEMENT par UartDeviceImpl.c, jamais compile seul. */

#ifndef UARTDEVICE_SCRIPT_C_INCLUDED
#define UARTDEVICE_SCRIPT_C_INCLUDED

/* Prefixe les print() du script par le nom du composant : avec plusieurs
   appareils sur le meme bus, un journal non prefixe est illisible. Execute dans
   les globales du peripherique, AVANT le script ; un script qui redefinit
   print() garde evidemment la sienne. */
static const char* UARTDEV_PRELUDE =
    "def print(*args, **kwargs):\n"
    "    __print__('[' + __device__ + ']', *args, **kwargs)\n";

/* Signale l'erreur Python en cours (trace dans le journal), rend le GIL, puis
   arrete la simulation. Ne revient pas. Le GIL est rendu AVANT
   ModelicaFormatError, qui ne revient pas : un GIL garde bloquerait tout. */
static void uartdev_script_fail(struct UartDevice* dev, PyGILState_STATE gstate, const char* what) {
    if (PyErr_Occurred()) {
        PyErr_Print();
    }
    relay_emit_pending();
    PyGILState_Release(gstate);
    ModelicaFormatError("UartDevice (%s) : %s - trace ci-dessus", dev->script_path, what);
}

/* Reference forte sur une fonction du script, ou NULL si absente. */
static PyObject* uartdev_script_handler(PyObject* globals, const char* name) {
    PyObject* f = PyDict_GetItemString(globals, name);   /* empruntee */
    if (f && PyCallable_Check(f)) {
        Py_INCREF(f);
        return f;
    }
    return NULL;
}

/* Relit outputs() et recopie le resultat dans value_out. GIL tenu. 0 ou -1. */
static int uartdev_script_refresh_outputs(struct UartDevice* dev) {
    PyObject* r;
    int k;
    if (!dev->py_outputs) {
        return 0;
    }
    r = PyObject_CallNoArgs(dev->py_outputs);
    if (!r) {
        return -1;
    }
    if (PyFloat_Check(r) || PyLong_Check(r)) {
        dev->value_out[0] = PyFloat_AsDouble(r);
    } else if (PySequence_Check(r) && !PyUnicode_Check(r) && !PyBytes_Check(r)) {
        Py_ssize_t n = PySequence_Size(r);
        for (k = 0; k < UARTDEV_MAX_VALUES && k < n; k++) {
            PyObject* item = PySequence_GetItem(r, k);
            double v = item ? PyFloat_AsDouble(item) : 0.0;
            Py_XDECREF(item);
            if (PyErr_Occurred()) {
                Py_DECREF(r);
                return -1;
            }
            dev->value_out[k] = v;
        }
    } else {
        Py_DECREF(r);
        PyErr_SetString(PyExc_TypeError, "outputs() doit retourner un nombre ou une sequence de nombres");
        return -1;
    }
    Py_DECREF(r);
    return PyErr_Occurred() ? -1 : 0;
}

/* Tuple des grandeurs venues du modele. */
static PyObject* uartdev_script_values(struct UartDevice* dev) {
    PyObject* t = PyTuple_New(UARTDEV_MAX_VALUES);
    int k;
    if (!t) {
        return NULL;
    }
    for (k = 0; k < UARTDEV_MAX_VALUES; k++) {
        PyTuple_SET_ITEM(t, k, PyFloat_FromDouble(dev->value_in[k]));
    }
    return t;
}

/* Convertit la valeur de retour d'un gestionnaire en charge utile. GIL tenu.
   Retourne la longueur (0 pour None), ou -1 avec PyErr positionne. */
static int uartdev_script_payload(PyObject* r, char* out, int outmax) {
    const char* data = NULL;
    Py_ssize_t len = 0;
    if (r == Py_None) {
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
        len = outmax;      /* tronque, comme une file d'emission qui deborde */
    }
    memcpy(out, data, (size_t) len);
    out[len] = '\0';
    return (int) len;
}

/* Appelle un gestionnaire deja muni de ses arguments (reference volee), puis
   relit outputs(). Retourne la longueur de la charge utile a emettre. En cas
   d'exception dans le script, arrete la simulation (ne revient pas). */
static int uartdev_script_call(struct UartDevice* dev, PyObject* func, const char* name,
                                PyObject* args, char* out, int outmax) {
    PyGILState_STATE gstate = PyGILState_Ensure();
    PyObject* r;
    int n;
    char what[96];

    if (!args) {
        uartdev_script_fail(dev, gstate, "echec de construction des arguments");
        return 0;   /* jamais atteint : ModelicaFormatError ne revient pas */
    }
    r = PyObject_CallObject(func, args);
    Py_DECREF(args);
    if (!r) {
        snprintf(what, sizeof(what), "%s() a leve une exception", name);
        uartdev_script_fail(dev, gstate, what);
        return 0;   /* jamais atteint : ModelicaFormatError ne revient pas */
    }
    n = uartdev_script_payload(r, out, outmax);
    Py_DECREF(r);
    if (n < 0) {
        snprintf(what, sizeof(what), "valeur de retour de %s() invalide", name);
        uartdev_script_fail(dev, gstate, what);
        return 0;   /* jamais atteint : ModelicaFormatError ne revient pas */
    }
    if (uartdev_script_refresh_outputs(dev) != 0) {
        uartdev_script_fail(dev, gstate, "outputs() a echoue");
        return 0;   /* jamais atteint : ModelicaFormatError ne revient pas */
    }
    relay_emit_pending();
    PyGILState_Release(gstate);
    return n;
}

static int uartdev_script_on_line(struct UartDevice* dev, const char* line, int len, char* out, int outmax) {
    PyObject* args;
    PyObject* values;
    if (!dev->py_on_receive) {
        return 0;
    }
    {
        PyGILState_STATE gstate = PyGILState_Ensure();
        values = uartdev_script_values(dev);
        args = values ? Py_BuildValue("(y#dN)", line, (Py_ssize_t) len, dev->now, values) : NULL;
        PyGILState_Release(gstate);
    }
    return uartdev_script_call(dev, dev->py_on_receive, "on_receive", args, out, outmax);
}

static int uartdev_script_on_tick(struct UartDevice* dev, char* out, int outmax) {
    PyObject* args;
    PyObject* values;
    if (!dev->py_on_tick) {
        return 0;
    }
    {
        PyGILState_STATE gstate = PyGILState_Ensure();
        values = uartdev_script_values(dev);
        args = values ? Py_BuildValue("(dN)", dev->now, values) : NULL;
        PyGILState_Release(gstate);
    }
    return uartdev_script_call(dev, dev->py_on_tick, "on_tick", args, out, outmax);
}

/* Charge le script du peripherique : demarre CPython si besoin (pyhost), cree
   un espace de noms propre, y execute le prelude puis le script, et retient les
   trois gestionnaires. En cas d'echec, arrete la simulation (ne revient pas). */
static void uartdev_script_load(struct UartDevice* dev, const char* pythonHome, const char* instanceName) {
    char err[512];
    char* src;
    PyGILState_STATE gstate;
    PyObject* globals;
    PyObject* code;
    PyObject* r;
    const char* base;

    if (dev->script_path[0] == '\0') {
        ModelicaFormatError("UartDevice : comportement 'Script' choisi mais scriptPath est vide");
        return;
    }
    src = read_text_file(dev->script_path);
    if (!src) {
        ModelicaFormatError("UartDevice : impossible de lire le script du peripherique ('%s')", dev->script_path);
        return;
    }
    if (pyhost_ensure(pythonHome, err, sizeof(err)) != 0) {
        free(src);
        ModelicaFormatError("UartDevice (%s) : %s", dev->script_path, err);
        return;
    }

    gstate = PyGILState_Ensure();

    globals = PyDict_New();
    dev->py_globals = globals;
    if (!globals) {
        free(src);
        uartdev_script_fail(dev, gstate, "echec de creation de l'espace de noms");
        return;   /* jamais atteint : ModelicaFormatError ne revient pas */
    }

    /* __name__ : nom de fichier sans extension, comme pour un module importe -
       surtout pas "__main__", qui executerait un eventuel bloc de test. */
    base = strrchr(dev->script_path, '/');
    if (!base || strrchr(dev->script_path, '\\') > base) {
        base = strrchr(dev->script_path, '\\');
    }
    base = base ? base + 1 : dev->script_path;
    {
        char modname[128];
        size_t i;
        for (i = 0; i < sizeof(modname) - 1 && base[i] && base[i] != '.'; i++) {
            modname[i] = base[i];
        }
        modname[i] = '\0';
        PyObject* name = PyUnicode_FromString(modname);
        PyDict_SetItemString(globals, "__name__", name);
        Py_XDECREF(name);
    }
    {
        PyObject* file = PyUnicode_DecodeFSDefault(dev->script_path);
        PyObject* devname = PyUnicode_FromString(instanceName && instanceName[0] ? instanceName : "UartDevice");
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

    r = PyRun_String(UARTDEV_PRELUDE, Py_file_input, globals, globals);
    if (!r) {
        free(src);
        uartdev_script_fail(dev, gstate, "echec du prelude");
        return;   /* jamais atteint : ModelicaFormatError ne revient pas */
    }
    Py_DECREF(r);

    /* Le chemin du script est passe au compilateur : les traces d'exception
       nomment ainsi le bon fichier, ce qui compte avec plusieurs peripheriques. */
    code = Py_CompileString(src, dev->script_path, Py_file_input);
    free(src);
    if (!code) {
        uartdev_script_fail(dev, gstate, "erreur de syntaxe dans le script");
        return;   /* jamais atteint : ModelicaFormatError ne revient pas */
    }
    r = PyEval_EvalCode(code, globals, globals);
    Py_DECREF(code);
    if (!r) {
        uartdev_script_fail(dev, gstate, "le script a leve une exception au chargement");
        return;   /* jamais atteint : ModelicaFormatError ne revient pas */
    }
    Py_DECREF(r);

    dev->py_on_receive = uartdev_script_handler(globals, "on_receive");
    dev->py_on_tick = uartdev_script_handler(globals, "on_tick");
    dev->py_outputs = uartdev_script_handler(globals, "outputs");

    /* Valeurs initiales des sorties : celles que le script declare, s'il le fait. */
    if (uartdev_script_refresh_outputs(dev) != 0) {
        uartdev_script_fail(dev, gstate, "outputs() a echoue au chargement");
        return;   /* jamais atteint : ModelicaFormatError ne revient pas */
    }
    relay_emit_pending();
    PyGILState_Release(gstate);
}

#endif /* UARTDEVICE_SCRIPT_C_INCLUDED */
