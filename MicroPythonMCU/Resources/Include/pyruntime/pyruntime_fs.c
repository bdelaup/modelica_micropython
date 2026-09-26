/* Systeme de fichiers (flash simulee) : les trois natives qui relient le shim au handle.

   Toute la mecanique (copie horodatee de l'image, cloisonnement de open() et du
   module os facon MicroPython, racine "/" = la copie) vit dans le shim Python,
   ou shutil/les chaines rendent le code court : le C ne fait que transmettre la
   configuration venue de Modelica, recuperer la racine obtenue (le thread worker
   y cherche boot.py/main.py) et dire au shim sur quel thread il s'execute.
   Aucune de ces natives n'est un point de synchro : une ecriture en flash est
   instantanee en temps simule (meme choix que machine.Display) - cf.
   requirements.md, decision "Systeme de fichiers".

   Partie de l'implementation du runtime Python, incluse TEXTUELLEMENT par
   PyRuntimeImpl.c (fichier chapeau) : une seule unite de compilation, donc
   pas de #include croise ici et aucune etape de build supplementaire - cf.
   requirements.md, decision "Structure du package et interface C du runtime
   Python". Ce fichier n'est jamais compile seul. */

/* Appelees par le shim pendant PyRuntime_new, donc sur le thread Modelica (pas
   de REQUIRE_WORKER) : g_current y designe le handle en construction. */
static PyObject* native_fs_config(PyObject* self, PyObject* args) {
    if (!g_current) {
        PyErr_SetString(PyExc_RuntimeError, "fs_config n'est appelable que pendant l'initialisation du shim");
        return NULL;
    }
    return Py_BuildValue("(Nssss)", PyBool_FromLong(g_current->fsEnabled), g_current->fsSource,
                         g_current->fsWorkspace, g_current->instanceName, g_current->pythonHome);
}

static PyObject* native_fs_set_root(PyObject* self, PyObject* args) {
    const char* root;
    if (!PyArg_ParseTuple(args, "s", &root)) return NULL;
    if (!g_current) {
        PyErr_SetString(PyExc_RuntimeError, "fs_set_root n'est appelable que pendant l'initialisation du shim");
        return NULL;
    }
    free(g_current->fs_root);
    g_current->fs_root = strdup(root);
    Py_RETURN_NONE;
}

/* Vrai si l'appelant est le thread worker du microcontroleur. Le shim ne
   cloisonne que ce thread : un script de peripherique (thread Modelica) partage
   le meme interpreteur, donc les memes builtins, mais n'a pas de flash. Meme
   test que worker_context_ok, sans lever d'exception. */
static PyObject* native_on_worker(PyObject* self, PyObject* args) {
    return PyBool_FromLong(g_current && GetCurrentThreadId() == g_current->worker_thread_id);
}

/* Fin de simulation (appele par PyRuntime_destroy) : redit ou est la copie -
   le message de debut de simulation est souvent loin en haut du journal - et,
   si fsOpenExplorer, ouvre l'Explorateur Windows dessus. explorer.exe lance par
   CreateProcess plutot que ShellExecute : pas de bibliotheque shell32 a lier.
   Sans attente : la simulation se termine sans dependre de la fenetre. */
static void fs_at_exit(struct PyRuntimeHandle* h) {
    if (!h->fs_root) {
        return;
    }
    ModelicaFormatMessage("Systeme de fichiers : fin de simulation, fichiers dans %s\n", h->fs_root);
    if (!h->fsOpenExplorer) {
        return;
    }
    size_t len = strlen(h->fs_root) + 32;
    char* cmd = (char*) malloc(len);
    snprintf(cmd, len, "explorer.exe \"%s\"", h->fs_root);
    STARTUPINFOA si;
    PROCESS_INFORMATION pi;
    memset(&si, 0, sizeof(si));
    si.cb = sizeof(si);
    if (CreateProcessA(NULL, cmd, NULL, NULL, FALSE, 0, NULL, NULL, &si, &pi)) {
        CloseHandle(pi.hThread);
        CloseHandle(pi.hProcess);
    }
    free(cmd);
}
