/* Relais stdout/stderr du script Python vers le journal de simulation.

   Partie de l'implementation du runtime Python, incluse TEXTUELLEMENT par
   PyRuntimeImpl.c (fichier chapeau) : une seule unite de compilation, donc
   pas de #include croise ici et aucune etape de build supplementaire - cf.
   requirements.md, decision "Structure du package et interface C du runtime
   Python". Ce fichier n'est jamais compile seul. */

/* --- Relais stdout/stderr -> ModelicaFormatMessage ---
   print() avec plusieurs arguments declenche plusieurs write() distincts (un par
   argument/separateur) ; comme chaque appel a ModelicaFormatMessage produit sa
   propre ligne dans le journal OMEdit, il faut bufferiser jusqu'a un vrai saut de
   ligne plutot que relayer chaque write() individuellement (sinon un print("a", b)
   se retrouve fragmente sur plusieurs lignes). */

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
    {"flush", relay_flush, METH_VARARGS, "No-op"},
    {NULL, NULL, 0, NULL}
};

static struct PyModuleDef relay_module_def = {
    PyModuleDef_HEAD_INIT, "pyruntime_stdio", NULL, -1, relay_methods,
    NULL, NULL, NULL, NULL
};

static PyObject* PyInit_pyruntime_stdio(void) {
    return PyModule_Create(&relay_module_def);
}
