/* Module natif expose au shim, thread worker et API exportee vers Modelica (PyRuntime_new/_destroy/_sync).

   Partie de l'implementation du runtime Python, incluse TEXTUELLEMENT par
   PyRuntimeImpl.c (fichier chapeau) : une seule unite de compilation, donc
   pas de #include croise ici et aucune etape de build supplementaire - cf.
   requirements.md, decision "Structure du package et interface C du runtime
   Python". Ce fichier n'est jamais compile seul. */

/* Profil de carte ("generic" pour MCU, "pico" pour Boards.RaspberryPiPico) :
   le shim en deduit la numerotation de l'ADC, les broches par defaut et le
   multiplexage UART/I2C. */
static PyObject* native_board(PyObject* self, PyObject* args) {
    REQUIRE_WORKER();
    return PyUnicode_FromString(g_current->board_profile);
}

static PyMethodDef native_methods[] = {
    {"pin_init", native_pin_init, METH_VARARGS, "Sets the direction of a pin"},
    {"pin_write", native_pin_write, METH_VARARGS, "Drives a pin (if it is an output)"},
    {"pin_read", native_pin_read, METH_VARARGS, "Reads the resolved state of a pin"},
    {"pin_irq_set", native_pin_irq_set, METH_VARARGS, "Registers/clears the IRQ callback of a pin"},
    {"adc_init", native_adc_init, METH_VARARGS, "Switches a pin to analog input (disconnects its digital input: no IRQ nor wake-up)"},
    {"adc_read",native_adc_read, METH_VARARGS, "Reads the voltage measured on an ADC pin, as a fraction of the ADC reference voltage"},
    {"pwm_set_freq", native_pwm_set_freq, METH_VARARGS, "Sets the PWM frequency (Hz) of a pin, making it an output"},
    {"pwm_set_duty", native_pwm_set_duty, METH_VARARGS, "Sets the PWM duty cycle (0-1) of a pin"},
    {"pwm_deinit", native_pwm_deinit, METH_VARARGS, "Stops the PWM on a pin (back to a plain digital output)"},
    {"display_write", native_display_write, METH_VARARGS, "Sends a text to the connected educational display peripheral (instant delivery)"},
    {"uart_init", native_uart_init, METH_VARARGS, "Configures the UART (TX/RX pins, baud rate) and takes the pins"},
    {"uart_write", native_uart_write, METH_VARARGS, "Puts bytes in the transmit queue (non-blocking), returns the number accepted"},
    {"uart_any", native_uart_any, METH_VARARGS, "Number of received bytes waiting to be read"},
    {"uart_read", native_uart_read, METH_VARARGS, "Reads up to n received bytes (n < 0 = all), None if nothing"},
    {"uart_deinit", native_uart_deinit, METH_VARARGS, "Releases the UART and its pins"},
    {"i2c_init", native_i2c_init, METH_VARARGS, "Configures the I2C bus (SCL/SDA pins, frequency) and takes the pins"},
    {"i2c_xfer", native_i2c_xfer, METH_VARARGS, "Complete I2C transaction (write, read after repeated START), blocking"},
    {"i2c_deinit", native_i2c_deinit, METH_VARARGS, "Releases the I2C bus and its pins"},
    {"i2ct_init", native_i2ct_init, METH_VARARGS, "Configures the I2C target (address, SCL/SDA pins, optional memory) and takes the pins"},
    {"i2ct_deinit", native_i2ct_deinit, METH_VARARGS, "Releases the I2C target and its pins"},
    {"i2ct_irq", native_i2ct_irq, METH_VARARGS, "Registers/clears the IRQ handler of the I2C target"},
    {"i2ct_flags", native_i2ct_flags, METH_VARARGS, "Events handed to the last call of the I2C target handler"},
    {"i2ct_memaddr", native_i2ct_memaddr, METH_VARARGS, "Current memory address of the I2C target"},
    {"i2ct_readinto", native_i2ct_readinto, METH_VARARGS, "Copies the bytes received from the controller into a buffer, returns their number"},
    {"i2ct_write", native_i2ct_write, METH_VARARGS, "Queues bytes for the next reads of the controller, returns the number accepted"},
    {"timer_new", native_timer_new, METH_VARARGS, "Allocates a Timer() slot in the fixed pool"},
    {"timer_init", native_timer_init, METH_VARARGS, "Arms a Timer (period, mode, callback)"},
    {"timer_deinit", native_timer_deinit, METH_VARARGS, "Stops and releases a Timer"},
    {"sleep", native_sleep, METH_VARARGS, "Waits N seconds of simulated time"},
    {"idle", native_idle, METH_VARARGS, "Waits for the next whole millisecond (or an input transition)"},
    {"disable_irq", native_disable_irq, METH_VARARGS, "Masks the IRQ/Timer callbacks, returns the previous state"},
    {"enable_irq", native_enable_irq, METH_VARARGS, "Restores the masking state returned by disable_irq"},
    {"ticks_ms", native_ticks_ms, METH_VARARGS, "Simulated clock, in milliseconds"},
    {"ticks_us", native_ticks_us, METH_VARARGS, "Simulated clock, in microseconds"},
    {"fs_config", native_fs_config, METH_VARARGS, "File system configuration (source, workspace, instance, pythonHome)"},
    {"fs_set_root", native_fs_set_root, METH_VARARGS, "Records the root of the timestamped copy (host folder)"},
    {"on_worker", native_on_worker, METH_VARARGS, "True if the caller is the microcontroller thread"},
    {"board", native_board, METH_VARARGS, "Board profile: 'generic' (MCU) or 'pico' (Raspberry Pi Pico)"},
    {NULL, NULL, 0, NULL}
};

/* Enregistre dans sys.modules du sous-interpreteur du microcontroleur
   (pyhost_register_module), une instance par MCU, et non par
   PyImport_AppendInittab : ce dernier n'est utilisable qu'avant Py_Initialize,
   or l'interpreteur peut avoir ete demarre par un peripherique construit avant
   le microcontroleur (cf. pyhost.c). Pas d'etat de module : les natives
   retrouvent leur MCU par g_current, local au thread worker. */
static struct PyModuleDef native_module_def = {
    PyModuleDef_HEAD_INIT, "_pyruntime_native", NULL, -1, native_methods,
    NULL, NULL, NULL, NULL
};

/* read_text_file, le relais stdout et le demarrage de CPython vivent dans
   pyhost.c, partage avec les peripheriques serie. */

/* --- Module machine de l'interpreteur PRINCIPAL ---
   Le shim ne vit que dans les sous-interpreteurs des microcontroleurs. Un script
   de peripherique (interpreteur principal, thread Modelica) qui ferait "import
   machine" obtiendrait sinon un ModuleNotFoundError obscur : ce module-ci
   l'importe sans erreur, et tout acces a l'un de ses attributs leve le message
   de worker_context_ok (__getattr__ de module, PEP 562). time reste le vrai
   module de la stdlib, dont la bibliotheque standard a besoin. */
static PyObject* main_machine_getattr(PyObject* self, PyObject* name) {
    PyErr_SetString(PyExc_RuntimeError,
        "machine and time can only be used from the microcontroller script "
        "- a peripheral script runs outside its thread");
    return NULL;
}

static PyMethodDef main_machine_methods[] = {
    {"__getattr__", main_machine_getattr, METH_O, "machine is reserved to the microcontroller script"},
    {NULL, NULL, 0, NULL}
};

static struct PyModuleDef main_machine_def = {
    PyModuleDef_HEAD_INIT, "machine", NULL, -1, main_machine_methods,
    NULL, NULL, NULL, NULL
};

/* --- Thread worker --- */

/* Configuration du sous-interpreteur d'un microcontroleur : GIL PARTAGE avec
   l'interpreteur principal (Modelica n'execute de toute facon qu'un composant a
   la fois), allocateur commun, et extensions monophases autorisees - plusieurs
   modules .pyd de la stdlib 3.12 le sont encore. Seuls sys.modules, __main__,
   sys.path et builtins sont propres au MCU : c'est l'isolation recherchee. Cf.
   requirements.md, decision "Multi-instances". */
static const PyInterpreterConfig MCU_INTERP_CONFIG = {
    .use_main_obmalloc = 1,
    .allow_fork = 0,
    .allow_exec = 0,
    .allow_threads = 1,
    .allow_daemon_threads = 0,
    .check_multi_interp_extensions = 0,
    .gil = PyInterpreterConfig_SHARED_GIL,
};

/* Meme configuration, threads demons permis : pydevd (debugpy) en cree pour
   dialoguer avec VS Code. Seulement quand MCU.debugEnabled est vrai. */
static const PyInterpreterConfig MCU_INTERP_CONFIG_DEBUG = {
    .use_main_obmalloc = 1,
    .allow_fork = 0,
    .allow_exec = 0,
    .allow_threads = 1,
    .allow_daemon_threads = 1,
    .check_multi_interp_extensions = 0,
    .gil = PyInterpreterConfig_SHARED_GIL,
};

/* Arguments de construction transmis au worker (chemins), liberes par lui. */
struct WorkerInit {
    char* addScriptDir;          /* NULL : ne rien ajouter a sys.path */
    char* libraryDir;
    char* shimSrc;
    char* shimPath;              /* nom de fichier des traces du shim */
    char* debugHostSrc;          /* NULL : debogage coupe (MCU.debugEnabled) */
    char* debugHostPath;
    char* debugpyDir;            /* Resources/Debugpy, ajoute a sys.path par debug_host.py */
    char* shimDir;               /* exclu du pas a pas (PYDEVD_FILTERS) */
};

/* Issue de run_source. */
#define RUN_OK 0
#define RUN_ERROR 1                  /* exception : trace deja imprimee sur stderr */
#define RUN_EXIT 2                   /* SystemExit (sys.exit()) : effacee, sans trace */

/* Execute un source Python dans __main__ du sous-interpreteur courant, compile
   sous le nom de fichier path : les traces nomment ce fichier et citent la
   ligne fautive (linecache relit le fichier), la ou PyRun_SimpleString
   compilait sous "<string>". Meme mecanique que les scripts de peripherique
   (devscript.c). PyErr_Print n'est JAMAIS appele sur SystemExit : il
   terminerait le process par exit(), sans message et sans fin propre de la
   simulation - ce que faisait PyRun_SimpleString sur un sys.exit() du script.
   GIL tenu. */
static int run_source(const char* src, const char* path) {
    PyObject* main_module = PyImport_AddModule("__main__");   /* empruntee */
    PyObject* code = NULL;
    PyObject* result = NULL;
    if (main_module) {
        PyObject* globals = PyModule_GetDict(main_module);     /* empruntee */
        code = Py_CompileString(src, path, Py_file_input);
        if (code) {
            result = PyEval_EvalCode(code, globals, globals);
            Py_DECREF(code);
        }
    }
    if (result) {
        Py_DECREF(result);
        return RUN_OK;
    }
    if (PyErr_ExceptionMatches(PyExc_SystemExit)) {
        PyErr_Clear();
        return RUN_EXIT;
    }
    PyErr_Print();
    return RUN_ERROR;
}

/* --- Debogage (debugpy + VS Code) ---
   debug_host.py s'execute dans un module propre, _mcu_debug, et non dans
   __main__ : les globales du programme, que VS Code affiche, n'en sont pas
   encombrees. Cf. requirements.md, decision "Debogage du programme". GIL tenu. */
static int debug_host_load(const char* src, const char* path) {
    PyObject* module = PyImport_AddModule("_mcu_debug");       /* empruntee */
    if (!module) {
        return -1;
    }
    PyObject* dict = PyModule_GetDict(module);                  /* empruntee */
    PyObject* file = PyUnicode_FromString(path);
    if (!file || PyDict_SetItemString(dict, "__file__", file) != 0) {
        Py_XDECREF(file);
        return -1;
    }
    Py_DECREF(file);
    PyObject* code = Py_CompileString(src, path, Py_file_input);
    if (!code) {
        return -1;
    }
    PyObject* result = PyEval_EvalCode(code, dict, dict);
    Py_DECREF(code);
    if (!result) {
        return -1;
    }
    Py_DECREF(result);
    return 0;
}

/* Appelle _mcu_debug.<name>(*args) ; args (tuple) est consomme. 0 si l'appel
   a reussi, -1 sinon (exception posee). GIL tenu. */
static int debug_host_call(const char* name, PyObject* args) {
    if (!args) {
        return -1;
    }
    PyObject* module = PyImport_AddModule("_mcu_debug");       /* empruntee */
    PyObject* fn = module ? PyDict_GetItemString(PyModule_GetDict(module), name) : NULL;
    if (!fn) {
        Py_DECREF(args);
        if (!PyErr_Occurred()) {
            PyErr_Format(PyExc_RuntimeError, "debug_host.py has no %s()", name);
        }
        return -1;
    }
    PyObject* result = PyObject_CallObject(fn, args);
    Py_DECREF(args);
    if (!result) {
        return -1;
    }
    Py_DECREF(result);
    return 0;
}

/* Fin de simulation, avant Py_EndInterpreter : arrete pydevd et attend (au
   plus ~1 s) que ses threads aient disparu du sous-interpreteur - sinon
   worker_end_interpreter renoncerait a le terminer. ts : etat de thread du
   worker, courant, GIL tenu. */
static void debug_host_stop(PyThreadState* ts) {
    if (debug_host_call("stop", PyTuple_New(0)) != 0) {
        PyErr_Clear();
    }
    PyInterpreterState* interp = PyThreadState_GetInterpreter(ts);
    for (int i = 0; i < 100; i++) {
        if (PyInterpreterState_ThreadHead(interp) == ts && PyThreadState_Next(ts) == NULL) {
            return;
        }
        Py_BEGIN_ALLOW_THREADS
        Sleep(10);
        Py_END_ALLOW_THREADS
    }
}

/* Cree le sous-interpreteur du microcontroleur SUR LE THREAD WORKER - un etat
   de thread Python est lie au thread systeme qui le cree, et c'est ce thread
   qui executera tout le Python du MCU - puis y installe relais stdout, module
   natif, sys.path et shim. Retourne 1 si tout est pret ; le GIL est alors tenu
   par l'etat de thread du sous-interpreteur. Retourne 0 en cas d'echec, GIL
   rendu, message dans h->init_failure. */
static int worker_init(struct PyRuntimeHandle* h, struct WorkerInit* wi) {
    const char* failure = NULL;
    PyThreadState* sub = NULL;

    /* Il faut un etat de thread courant pour creer un interpreteur : celui de
       l'interpreteur principal, pris le temps de la creation puis rendu. */
    PyGILState_STATE gstate = PyGILState_Ensure();
    PyThreadState* main_ts = PyThreadState_Get();
    PyStatus status = Py_NewInterpreterFromConfig(&sub, wi->debugHostSrc ? &MCU_INTERP_CONFIG_DEBUG : &MCU_INTERP_CONFIG);
    if (PyStatus_Exception(status) || !sub) {
        PyThreadState_Swap(main_ts);
        PyGILState_Release(gstate);
        snprintf(h->init_failure, sizeof(h->init_failure), "failed to create the sub-interpreter of the microcontroller");
        return 0;
    }
    /* Rend l'etat de thread principal (GIL partage : rendre l'un relache le
       GIL commun), puis reprend la main au nom du sous-interpreteur. Le worker
       n'utilise plus ensuite aucune API PyGILState_*, qui ne connait que
       l'interpreteur principal. */
    PyThreadState_Swap(main_ts);
    PyGILState_Release(gstate);
    PyEval_RestoreThread(sub);

    if (pyhost_install_relay(&h->relay, &h->relay_err) != 0) {
        failure = "failed to install the stdout relay";
    }
    if (!failure && pyhost_register_module("_pyruntime_native", PyModule_Create(&native_module_def)) != 0) {
        failure = "failed to register the native module of the shim";
    }
    /* Import de modules auxiliaires (cf. requirements.md, decision "Import de
       modules auxiliaires") : dossier du script (addScriptDirToPath) et/ou
       d'une bibliotheque partagee (libraryPath), dans le sys.path de CE
       microcontroleur seulement. */
    if (!failure && wi->addScriptDir && pyhost_append_path(wi->addScriptDir) != 0) {
        failure = "failed to add the script folder to sys.path";
    }
    if (!failure && wi->libraryDir && pyhost_append_path(wi->libraryDir) != 0) {
        failure = "failed to add libraryPath to sys.path";
    }
    /* Debogage : debugpy est importe AVANT le shim, tant que time est le vrai
       module (pydevd refuse un time sans mktime, et ses attentes en pause
       doivent rester de vraies attentes, pas des sleep() simules). */
    if (!failure && wi->debugHostSrc
        && (debug_host_load(wi->debugHostSrc, wi->debugHostPath) != 0
            || debug_host_call("start", Py_BuildValue("(iss)", h->debug_port, wi->debugpyDir, wi->shimDir)) != 0)) {
        failure = "failed to start the debugger (debugpy) - traceback above";
    }
    if (!failure && run_source(wi->shimSrc, wi->shimPath) != RUN_OK) {
        failure = "failed to initialise the machine/time shim or the file system - traceback above";
    }
    relay_flush_buf(&h->relay);
    relay_flush_buf(&h->relay_err);
    if (failure) {
        if (PyErr_Occurred()) {
            PyErr_Print();
            relay_flush_buf(&h->relay);
            relay_flush_buf(&h->relay_err);
        }
        snprintf(h->init_failure, sizeof(h->init_failure), "%s", failure);
        PyEval_SaveThread();
        return 0;
    }
    return 1;
}

/* Issue de run_program_file. */
#define PROGRAM_ABSENT 0             /* fichier introuvable, rien d'execute */
#define PROGRAM_RAN 1                /* execute (jusqu'au bout ou jusqu'a une exception) */
#define PROGRAM_EXIT 2               /* termine par sys.exit() : la sequence de demarrage s'arrete */

/* Execute un fichier du programme (dir\name, ou name seul si dir est NULL)
   dans __main__, compile sous ce chemin : pour boot.py/main.py, celui du
   fichier dans la copie de la flash, que l'eleve peut ouvrir. Une exception
   pose script_error et un message nommant le fichier. sys.exit() termine le
   programme sans erreur, comme sur la carte (pyexec du port rp2 : un
   sys.exit() dans boot.py saute aussi main.py). */
static int run_program_file(struct PyRuntimeHandle* h, const char* dir, const char* name) {
    char* path;
    if (dir) {
        size_t len = strlen(dir) + strlen(name) + 2;
        path = (char*) malloc(len);
        snprintf(path, len, "%s\\%s", dir, name);
    } else {
        path = strdup(name);
    }
    char* buf = read_text_file(path);
    if (!buf) {
        free(path);
        return PROGRAM_ABSENT;
    }
    int rc = run_source(buf, path);
    free(buf);
    free(path);
    relay_flush_buf(&h->relay);
    relay_flush_buf(&h->relay_err);
    if (rc == RUN_ERROR) {
        char msg[128];
        snprintf(msg, sizeof(msg), "%s raised an unhandled exception - traceback above",
                 dir ? name : "the script");
        h->script_error = 1;
        h->error_message = strdup(msg);
    }
    return rc == RUN_EXIT ? PROGRAM_EXIT : PROGRAM_RAN;
}

/* Fin de vie du worker (cf. PyRuntime_destroy) : termine le sous-interpreteur
   du microcontroleur - modules et objets liberes, fichiers encore ouverts
   fermes et vides sur disque. ts est l'etat de thread du worker, courant, GIL
   tenu ; au retour, plus d'etat de thread courant ni de GIL. Py_EndInterpreter
   arreterait le process (Py_FatalError) si un autre thread Python vivait dans
   le sous-interpreteur (_thread du programme) : on abandonne alors la
   finalisation, comme avant que l'arret propre n'existe. */
static void worker_end_interpreter(struct PyRuntimeHandle* h, PyThreadState* ts) {
    relay_flush_buf(&h->relay);
    relay_flush_buf(&h->relay_err);
    if (PyInterpreterState_ThreadHead(PyThreadState_GetInterpreter(ts)) != ts
        || PyThreadState_Next(ts) != NULL) {
        ModelicaFormatWarning("PyRuntime (%s): other Python threads are still running in the microcontroller "
                              "- Python is not finalized at the end of the simulation\n", h->instanceName);
        pyhost_abandon();
        PyEval_SaveThread();
        return;
    }
    Py_EndInterpreter(ts);
    relay_flush_buf(&h->relay);
    relay_flush_buf(&h->relay_err);
}

/* Argument du thread worker : le handle et ce qu'il faut pour l'initialiser. */
struct WorkerArg {
    struct PyRuntimeHandle* h;
    struct WorkerInit init;
};

static unsigned __stdcall worker_main(void* arg) {
    struct WorkerArg* wa = (struct WorkerArg*) arg;
    struct PyRuntimeHandle* h = wa->h;
    h->worker_thread_id = GetCurrentThreadId();
    g_current = h;

    int ok = worker_init(h, &wa->init);
    free(wa->init.addScriptDir);
    free(wa->init.libraryDir);
    free(wa->init.shimSrc);
    free(wa->init.shimPath);
    free(wa->init.debugHostSrc);
    free(wa->init.debugHostPath);
    free(wa->init.debugpyDir);
    free(wa->init.shimDir);
    free(wa);

    /* Resultat de l'initialisation, attendu par PyRuntime_new. */
    EnterCriticalSection(&h->cs);
    h->init_state = ok ? INIT_OK : INIT_FAILED;
    WakeAllConditionVariable(&h->cv);
    LeaveCriticalSection(&h->cs);
    if (!ok) {
        return 0;   /* GIL deja rendu par worker_init */
    }

    /* Premier tour : attendre que Modelica nous cede la main (t=0, cf. MCU "when initial()").
       GIL RELACHE pendant l'attente : le thread Modelica peut avoir a executer du
       Python pendant ce temps (construction ou synchro d'un peripherique serie
       pilote par script) - le garder ici bloquerait ce thread indefiniment. */
    /* Carte jamais alimentee (cf. started) : ce premier tour n'arrive pas, la
       fin de simulation (shutdown) libere alors le worker sans programme. */
    Py_BEGIN_ALLOW_THREADS
    EnterCriticalSection(&h->cs);
    while (h->turn != TURN_WORKER && !h->shutdown) {
        SleepConditionVariableCS(&h->cv, &h->cs, INFINITE);
    }
    LeaveCriticalSection(&h->cs);
    Py_END_ALLOW_THREADS
    int never_started = h->shutdown && !h->started;

    /* Debogage : attente de VS Code a ce premier tour (t=0), et non dans le
       constructeur - tous les composants du modele sont alors construits, donc
       un second MCU debogue a deja ete refuse. Le thread Modelica attend dans
       PyRuntime_sync (timeout mou coupe). La copie de la flash existe :
       wait() pose aussi la correspondance des chemins image -> copie. */
    if (h->debug_enabled && !never_started
        && debug_host_call("wait", Py_BuildValue("(iss)", h->debug_port, h->fsSource,
                                                 h->fs_root ? h->fs_root : "")) != 0) {
        PyErr_Print();
        h->script_error = 1;
        h->error_message = strdup("failed while waiting for the debugger - traceback above");
    }
    relay_flush_buf(&h->relay);
    relay_flush_buf(&h->relay_err);

    /* Sequence de demarrage, comme sur la carte : boot.py de la flash s'il
       existe, puis le programme - le script (scriptPath) s'il est renseigne, a
       la place de main.py comme Thonny sur une carte deja demarree, sinon
       main.py de la flash s'il existe. Tous dans le meme espace de noms
       (__main__). Une exception ou un sys.exit() arrete la sequence.
       PyRuntime_new garantit qu'il y a un script ou un systeme de fichiers. */
    int ran = never_started;
    int boot = never_started ? PROGRAM_EXIT : PROGRAM_ABSENT;
    if (h->fs_root && !h->script_error && !never_started) {
        boot = run_program_file(h, h->fs_root, "boot.py");
        ran = boot != PROGRAM_ABSENT;
    }
    if (!h->script_error && boot != PROGRAM_EXIT) {
        if (h->scriptPath[0] != '\0') {
            if (run_program_file(h, NULL, h->scriptPath) == PROGRAM_ABSENT) {
                h->script_error = 1;
                h->error_message = strdup("cannot open the script");
            }
            ran = 1;
        } else if (h->fs_root) {
            ran |= run_program_file(h, h->fs_root, "main.py") != PROGRAM_ABSENT;
        }
    }
    if (!ran && !h->script_error) {
        ModelicaFormatMessage("PyRuntime: neither boot.py nor main.py at the root of the file system - microcontroller idle\n");
    }

    EnterCriticalSection(&h->cs);
    h->script_done = 1;
    h->turn = TURN_MODELICA;
    WakeConditionVariable(&h->cv);
    LeaveCriticalSection(&h->cs);

    /* Programme fini (ou deroule par SystemExit en fin de simulation) : le
       worker se gare, GIL rendu, jusqu'a la destruction. Le sous-interpreteur
       reste vivant d'ici la : ses objets (tampon mem= d'I2CTarget, que la
       synchro lit encore) restent valides. g_current est garde : un __del__
       execute pendant la fin du sous-interpreteur peut encore appeler une
       native (qui leve alors SystemExit, cf. yield_until). */
    PyThreadState* ts = PyEval_SaveThread();
    EnterCriticalSection(&h->cs);
    while (!h->shutdown) {
        SleepConditionVariableCS(&h->cv, &h->cs, INFINITE);
    }
    LeaveCriticalSection(&h->cs);
    PyEval_RestoreThread(ts);
    if (h->debug_enabled) {
        debug_host_stop(ts);
    }
    worker_end_interpreter(h, ts);
    g_current = NULL;
    return 0;
}

/* --- API exportee --- */

/* Retourne une copie allouee du dossier contenant 'path' (tout ce qui precede
   le dernier separateur '/' ou '\\' - un chemin choisi via le selecteur de
   fichier OMEdit sur Windows peut utiliser l'un ou l'autre), ou une chaine
   vide si aucun separateur n'est trouve. A liberer par l'appelant (free). */
static char* dirname_of(const char* path) {
    const char* last_slash = strrchr(path, '/');
    const char* last_backslash = strrchr(path, '\\');
    const char* sep = last_slash;
    if (last_backslash && (!sep || last_backslash > sep)) {
        sep = last_backslash;
    }
    if (!sep) {
        return strdup("");
    }
    size_t len = (size_t) (sep - path);
    char* result = (char*) malloc(len + 1);
    memcpy(result, path, len);
    result[len] = '\0';
    return result;
}

void* PyRuntime_new(const char* scriptPath, const char* pythonHome,
                     int addScriptDirToPath, const char* libraryPath,
                     const char* shimPath, int fsEnabled, const char* fsSource,
                     const char* fsWorkspace, int fsOpenExplorer,
                     const char* instanceName, double gpioOpTime,
                     double hangWarningTime,
                     int debugEnabled, int debugPort,
                     const int* pinIds, size_t nPinIds,
                     const int* pinCaps, size_t nPinCaps,
                     const char* boardProfile) {
    char err[512];
    size_t k;

    /* Table des broches fournie par le modele (cf. MAX_PINS) : erreur de
       construction du modele, pas de l'utilisateur. */
    if (nPinIds == 0 || nPinIds > MAX_PINS || nPinCaps != nPinIds) {
        ModelicaFormatError("PyRuntime (%s): invalid pin table (%d identifiers, %d capabilities, at most %d)",
                            instanceName, (int) nPinIds, (int) nPinCaps, MAX_PINS);
        return NULL;
    }
    if (strlen(boardProfile) >= BOARD_PROFILE_MAX) {
        ModelicaFormatError("PyRuntime (%s): board profile name too long ('%s')", instanceName, boardProfile);
        return NULL;
    }

    /* Sans script, le programme est main.py du systeme de fichiers : il en
       faut un. Verifie avant tout demarrage, l'erreur est de configuration. */
    if (scriptPath[0] == '\0' && !fsEnabled) {
        ModelicaFormatError("PyRuntime: scriptPath is empty and the file system is disabled - "
                            "give a script, or enable a file system containing main.py");
        return NULL;
    }
    /* Un seul MCU debogue par modele (cf. requirements.md, decision "Debogage
       du programme") : VS Code ne s'attache qu'a un port a la fois, et deux
       pydevd dans deux sous-interpreteurs n'ont pas ete valides. */
    if (debugEnabled && ++g_debug_count > 1) {
        ModelicaFormatError("PyRuntime (%s): debugEnabled is set on more than one MCU - "
                            "only one microcontroller can be debugged per model", instanceName);
        return NULL;
    }
    if (debugEnabled && (debugPort < 1 || debugPort > 65535)) {
        ModelicaFormatError("PyRuntime (%s): debugPort must be between 1 and 65535 (got %d)", instanceName, debugPort);
        return NULL;
    }

    /* Demarrage de CPython partage avec les peripheriques serie : l'un d'eux a
       pu le faire avant nous (ordre de construction non garanti). Au retour, le
       GIL n'est tenu par personne (cf. invariant de pyhost.c). */
    if (pyhost_ensure(pythonHome, err, sizeof(err)) != 0) {
        ModelicaFormatError("PyRuntime: %s", err);
        return NULL;
    }

    struct PyRuntimeHandle* handle = (struct PyRuntimeHandle*) calloc(1, sizeof(struct PyRuntimeHandle));
    handle->scriptPath = strdup(scriptPath);
    handle->pythonHome = strdup(pythonHome);
    handle->fsEnabled = fsEnabled;
    handle->fsSource = strdup(fsSource);
    handle->fsWorkspace = strdup(fsWorkspace);
    handle->fsOpenExplorer = fsOpenExplorer;
    handle->instanceName = strdup(instanceName);
    handle->gpio_op_time = gpioOpTime > 0 ? gpioOpTime : 0;
    handle->hang_warning_time = hangWarningTime > 0 ? hangWarningTime : 0;
    handle->debug_enabled = debugEnabled;
    handle->debug_port = debugPort;
    handle->num_pins = (int) nPinIds;
    for (k = 0; k < nPinIds; k++) {
        handle->pin_id[k] = pinIds[k];
        handle->pin_caps[k] = pinCaps[k];
    }
    strcpy(handle->board_profile, boardProfile);
    InitializeCriticalSection(&handle->cs);
    InitializeConditionVariable(&handle->cv);
    handle->turn = TURN_MODELICA;
    /* calloc met tout a zero, or 0 est un index de broche valide : les deux
       broches UART doivent donc etre remises explicitement a "non affectee". */
    handle->uart_tx_pin = -1;
    handle->uart_rx_pin = -1;
    handle->i2c_scl_pin = -1;
    handle->i2c_sda_pin = -1;
    handle->i2cm.next_time = 1.0e300;
    handle->i2ct.scl_pin = -1;
    handle->i2ct.sda_pin = -1;
    handle->init_state = INIT_PENDING;

    /* Journal : a partir du deuxieme microcontroleur, toutes les lignes des MCU
       sont prefixees par leur nom d'instance (cf. g_mcu_prefix_on). */
    handle->relay.prefix = handle->instanceName;
    handle->relay.prefix_on = &g_mcu_prefix_on;
    handle->relay.time = &handle->sim_time;
    handle->relay_err = handle->relay;
    handle->relay_err.is_err = 1;
    if (++g_mcu_count >= 2) {
        g_mcu_prefix_on = 1;
    }

    /* Module machine explicatif dans l'interpreteur principal, une fois. */
    {
        PyGILState_STATE gstate = PyGILState_Ensure();
        PyObject* modules = PyImport_GetModuleDict();
        if (!PyDict_GetItemString(modules, "machine")) {
            pyhost_register_module("machine", PyModule_Create(&main_machine_def));
        }
        PyErr_Clear();
        PyGILState_Release(gstate);
    }

    /* Le shim doit exister dans le sous-interpreteur AVANT que le script ne
       fasse "import machine"/"import time". Il vit dans un vrai fichier .py de
       la bibliotheque (Resources/Scripts/_shim/), resolu cote Modelica comme
       scriptPath/pythonHome - cf. requirements.md, decision "Conception du shim
       machine/time". Lu ici pour signaler un chemin faux sans demarrer de
       thread ; execute par le worker (worker_init). */
    struct WorkerArg* wa = (struct WorkerArg*) calloc(1, sizeof(struct WorkerArg));
    wa->h = handle;
    wa->init.shimSrc = read_text_file(shimPath);
    if (!wa->init.shimSrc) {
        ModelicaFormatError("PyRuntime: cannot read the machine/time shim ('%s')", shimPath);
        return NULL;
    }
    wa->init.shimPath = strdup(shimPath);
    /* Import de modules auxiliaires (cf. requirements.md, decision "Import de
       modules auxiliaires") : dossier du script (addScriptDirToPath) et/ou
       celui d'une bibliotheque partagee (libraryPath, desactive si chaine
       vide), ajoutes par le worker au sys.path du sous-interpreteur. */
    if (addScriptDirToPath) {
        char* dir = dirname_of(scriptPath);
        if (dir[0] != '\0') {
            wa->init.addScriptDir = dir;
        } else {
            free(dir);
        }
    }
    if (libraryPath && libraryPath[0] != '\0') {
        char* dir = dirname_of(libraryPath);
        if (dir[0] != '\0') {
            wa->init.libraryDir = dir;
        } else {
            free(dir);
        }
    }
    /* Debogage : debug_host.py est voisin du shim (Resources/Scripts/_shim/),
       debugpy est vendore a cote de la distribution Python (Resources/Debugpy).
       Lu ici, comme le shim, pour signaler un fichier manquant sans demarrer
       de thread. */
    if (debugEnabled) {
        char* shimDir = dirname_of(shimPath);
        char* resources = dirname_of(pythonHome);
        size_t len = strlen(shimDir) + 32;
        wa->init.debugHostPath = (char*) malloc(len);
        snprintf(wa->init.debugHostPath, len, "%s\\debug_host.py", shimDir);
        len = strlen(resources) + 32;
        wa->init.debugpyDir = (char*) malloc(len);
        snprintf(wa->init.debugpyDir, len, "%s\\Debugpy", resources);
        free(resources);
        wa->init.shimDir = shimDir;
        wa->init.debugHostSrc = read_text_file(wa->init.debugHostPath);
        if (!wa->init.debugHostSrc) {
            ModelicaFormatError("PyRuntime: cannot read the debugger host ('%s')", wa->init.debugHostPath);
            return NULL;
        }
    }

    handle->thread = (HANDLE) _beginthreadex(NULL, 0, worker_main, wa, 0, NULL);
    if (!handle->thread) {
        ModelicaFormatError("PyRuntime: failed to create the worker thread");
        return NULL;
    }

    /* Attend que le worker ait cree son sous-interpreteur et execute le shim :
       une erreur de configuration (systeme de fichiers introuvable...) arrete
       ainsi la simulation des la construction, comme avant. GIL non tenu ici
       (invariant de pyhost.c) : le worker peut le prendre. */
    EnterCriticalSection(&handle->cs);
    while (handle->init_state == INIT_PENDING) {
        SleepConditionVariableCS(&handle->cv, &handle->cs, INFINITE);
    }
    int init_state = handle->init_state;
    LeaveCriticalSection(&handle->cs);
    if (init_state != INIT_OK) {
        ModelicaFormatError("PyRuntime (%s): %s", handle->instanceName, handle->init_failure);
        return NULL;
    }

    return (void*) handle;
}

void PyRuntime_destroy(void* handle_) {
    /* Arret propre en fin de simulation. Le programme est presque toujours
       gare dans un sleep() : shutdown le fait derouler par SystemExit (cf.
       yield_until) - ses blocs finally/with s'executent, comme ceux d'un
       programme interrompu sur la carte -, puis le worker termine son
       sous-interpreteur (fichiers ouverts fermes et vides sur disque) et
       s'arrete. Un programme qui ne se deroule pas dans le delai (boucle qui
       avale SystemExit par un except: nu) est abandonne : plus aucune
       finalisation, l'OS recupere tout a la fin du process, comme avant. Les
       references Python des callbacks IRQ/Timer (pin_irq_handler,
       timer_callback...) partent avec le sous-interpreteur. Le dernier
       composant detruit finalise CPython (pyhost_release). Cf.
       requirements.md, decision "Mecanisme d'execution du script Python". */
    struct PyRuntimeHandle* h = (struct PyRuntimeHandle*) handle_;
    if (!h) {
        return;
    }
    EnterCriticalSection(&h->cs);
    h->shutdown = 1;
    WakeAllConditionVariable(&h->cv);
    LeaveCriticalSection(&h->cs);
    if (WaitForSingleObject(h->thread, SHUTDOWN_WAIT_MS) != WAIT_OBJECT_0) {
        ModelicaFormatWarning("PyRuntime (%s): the program did not stop at the end of the simulation "
                              "(does it catch SystemExit, e.g. with a bare except:?) - Python is not finalized, "
                              "files left open may be incomplete\n", h->instanceName);
        pyhost_abandon();
    }
    uart_report_errors(h);
    fs_at_exit(h);
    pyhost_release();
}

/* Script qui ne laisse pas avancer la simulation (timeout mou) : appele par la
   boucle de drain de PyRuntime_sync, sur le thread Modelica, cs tenu. Deux cas,
   distingues par le message : le worker n'a pas rendu la main depuis start
   (boucle de calcul, attente sur ticks_ms()...), ou il la rend sans cesse au
   meme instant simule (boucle d'acces aux broches avec gpioOpTime = 0). Un
   avertissement seulement (cf. requirements.md) : la simulation continue
   d'attendre, et un calcul long mais legitime finit normalement. Repete a
   intervalle double (10, 20, 40 s...) pour ne pas inonder le journal. */
static void hang_check(struct PyRuntimeHandle* h, double currentTime, ULONGLONG start,
                       double* next_warn, int worker_running) {
    double elapsed = (double) (GetTickCount64() - start) / 1000.0;
    if (*next_warn <= 0 || elapsed < *next_warn) {
        return;
    }
    if (worker_running) {
        ModelicaFormatWarning("[t=%.6f s] PyRuntime (%s): the script has been running for more than %g s of real time "
                              "without handing control back to the simulation (loop without sleep() nor pin access?) "
                              "- the simulation keeps waiting, stop it from OMEdit if needed\n",
                              currentTime, h->instanceName, *next_warn);
    } else {
        ModelicaFormatWarning("[t=%.6f s] PyRuntime (%s): the script has been acting for more than %g s of real time "
                              "at the same simulated instant (loop with gpioOpTime = 0?) "
                              "- the simulation keeps waiting, stop it from OMEdit if needed\n",
                              currentTime, h->instanceName, *next_warn);
    }
    *next_warn *= 2;
}

/* Etat publie quand le microcontroleur n'est pas alimente (avant son
   demarrage, ou apres une perte d'alimentation) : broches en entree sans
   tirage, ni PWM ni UART, aucun reveil demande. Cote Modelica, les broches
   sont de toute facon en haute impedance tant que powerGood est faux. */
static void publish_unpowered(struct PyRuntimeHandle* h, int* pinBoolOut, int* pinIsOutput, int* pinPull,
                              double* pwmFreqOut, double* pwmDutyOut,
                              int* displaySeqOut, const char** displayPayloadOut,
                              int* uartTxPinOut, int* uartTxLevelOut, double* nextWakeTime) {
    int i;
    for (i = 0; i < h->num_pins; i++) {
        pinBoolOut[i] = 0;
        pinIsOutput[i] = 0;
        pinPull[i] = PIN_PULL_NONE;
        pwmFreqOut[i] = 0;
        pwmDutyOut[i] = 0;
    }
    publish_display(h, displaySeqOut, displayPayloadOut);
    *uartTxPinOut = 0;
    *uartTxLevelOut = 1;
    *nextWakeTime = 1.0e300;
}

/* Perte d'alimentation d'un microcontroleur demarre : le programme se deroule
   par SystemExit (halted, cf. yield_until), comme en fin de simulation, puis
   tous ses peripheriques s'arretent. Pas de redemarrage au retour de
   l'alimentation (cf. requirements.md, restrictions). Thread Modelica, cs
   tenu. */
static void power_loss(struct PyRuntimeHandle* h, double currentTime) {
    int i;
    ModelicaFormatWarning("[t=%.6f s] PyRuntime (%s): supply lost (3V3 below the power-good threshold, or RUN low) "
                          "- program stopped, pins released; a restart when the supply comes back is not simulated\n",
                          currentTime, h->instanceName);
    if (!h->script_done) {
        h->halted = 1;
        h->turn = TURN_WORKER;
        WakeConditionVariable(&h->cv);
        while (!h->script_done) {
            SleepConditionVariableCS(&h->cv, &h->cs, INFINITE);
        }
    }
    h->powered_off = 1;
    for (i = 0; i < h->num_pins; i++) {
        h->pin_is_output[i] = 0;
        h->pin_pull[i] = PIN_PULL_NONE;
        h->pwm_freq[i] = 0;
    }
    h->uart_configured = 0;
    h->i2c_configured = 0;
    h->i2ct.configured = 0;
    for (i = 0; i < MAX_TIMERS; i++) {
        h->timer_active[i] = 0;
    }
}

void PyRuntime_sync(void* handle_, double currentTime, size_t nPins, const int* pinBoolIn,
                     const double* pinAnalogIn,
                     int* pinBoolOut, int* pinIsOutput, int* pinPull,
                     double* pwmFreqOut, double* pwmDutyOut,
                     int* displaySeqOut, const char** displayPayloadOut,
                     int* uartTxPinOut, int* uartTxLevelOut,
                     int powerGood, double adcRef,
                     double* nextWakeTime) {
    struct PyRuntimeHandle* h = (struct PyRuntimeHandle*) handle_;
    int i;

    if ((int) nPins != h->num_pins) {
        ModelicaFormatError("PyRuntime (%s): %d pins at the sync point, %d in the pin table",
                            h->instanceName, (int) nPins, h->num_pins);
        return;
    }

    /* Alimentation : le programme demarre a la premiere synchro alimentee
       (ticks_ms() compte depuis cet instant), une perte d'alimentation ensuite
       l'arrete pour de bon (cf. power_loss). */
    if (h->powered_off || (!h->started && !powerGood)) {
        publish_unpowered(h, pinBoolOut, pinIsOutput, pinPull, pwmFreqOut, pwmDutyOut,
                          displaySeqOut, displayPayloadOut, uartTxPinOut, uartTxLevelOut, nextWakeTime);
        return;
    }
    if (!h->started) {
        EnterCriticalSection(&h->cs);
        h->started = 1;
        h->boot_time = currentTime;
        LeaveCriticalSection(&h->cs);
    } else if (!powerGood) {
        EnterCriticalSection(&h->cs);
        h->sim_time = currentTime;
        power_loss(h, currentTime);
        LeaveCriticalSection(&h->cs);
        publish_unpowered(h, pinBoolOut, pinIsOutput, pinPull, pwmFreqOut, pwmDutyOut,
                          displaySeqOut, displayPayloadOut, uartTxPinOut, uartTxLevelOut, nextWakeTime);
        return;
    }

    if (h->script_done) {
        for (i = 0; i < h->num_pins; i++) {
            pinBoolOut[i] = h->pin_driven_value[i];
            pinIsOutput[i] = h->pin_is_output[i];
            pinPull[i] = h->pin_pull[i];
            pwmFreqOut[i] = h->pwm_freq[i];
            pwmDutyOut[i] = h->pwm_duty[i];
        }
        publish_display(h, displaySeqOut, displayPayloadOut);
        /* Le script est fini mais l'UART, comme le PWM, continue de tourner en
           autonome : la file d'emission doit finir de se vider. Pas de verrou
           ici, le worker est mort (meme raison que le reste de cette branche). */
        uart_tx_advance(h, currentTime);
        uart_rx_step(h, currentTime, pinBoolIn);
        uart_publish(h, currentTime, uartTxPinOut, uartTxLevelOut);
        /* La cible I2C en mode memoire continue de repondre, comme le materiel ;
           sans memoire, plus de gestionnaire pour fournir les octets (0xFF). */
        i2ct_step(h, pinBoolIn);
        i2ct_finish(h);
        for (i = 0; i < h->num_pins; i++) {
            pinBoolOut[i] = h->pin_driven_value[i];
            pinIsOutput[i] = h->pin_is_output[i];
        }
        /* Seule une echeance UART peut encore demander un reveil apres la fin
           du script (prochain front a emettre, octet recu a clore). */
        *nextWakeTime = earliest_uart_deadline(h, currentTime);
        return;
    }

    EnterCriticalSection(&h->cs);
    h->sim_time = currentTime;
    h->adc_ref = adcRef;

    /* Une vraie transition d'une broche actuellement en ENTREE justifie de
       reveiller le worker avant l'heure demandee par son sleep() (cf.
       scenario de verification "reactivite en entree" - la broche doit
       pouvoir interrompre une attente en cours, en l'absence de vraie
       interruption materielle). Une broche en SORTIE qui "change" ne compte
       pas : ce n'est que le reflet de notre propre ecriture. Meme boucle :
       si un handler machine.Pin.irq() est enregistre sur cette broche et que
       le sens du front correspond au trigger demande, on marque le callback
       comme du (consomme par run_due_callbacks au reveil du worker). */
    int input_changed = 0;
    for (i = 0; i < h->num_pins; i++) {
        int old_val = h->pin_sensed_value[i];
        int new_val = pinBoolIn[i];
        /* Une broche affectee a la reception UART est exclue : ses fronts
           appartiennent au peripherique serie, pas au script. Sans cette
           exclusion, chaque front de bit recu rendrait le reveil "authentique"
           (cf. yield_to_modelica) et ferait retourner en avance le sleep() en
           cours - a 1200 bauds, une dizaine de sleep() casses par octet recu.
           Fidele au materiel reel, ou une broche prise par le peripherique UART
           ne genere plus d'interruption GPIO. Meme exclusion pour une broche
           prise par l'ADC (etage d'entree numerique coupe sur le RP2040) : un
           signal analogique qui traverse le seuil logique casserait sinon le
           sleep() en cours a chaque passage. */
        if (!h->pin_is_output[i] && !h->uart_rx_claimed[i] && !h->i2c_claimed[i] && !h->adc_claimed[i] && old_val != new_val) {
            input_changed = 1;
            if (h->pin_irq_handler[i] != NULL) {
                int edge = new_val ? IRQ_TRIGGER_RISING : IRQ_TRIGGER_FALLING;
                if (h->pin_irq_trigger[i] & edge) {
                    h->pin_irq_pending[i] = 1;
                }
            }
        }
        h->pin_sensed_value[i] = new_val;
        h->pin_analog_value[i] = pinAnalogIn[i];
    }
    h->wake_had_input_change = input_changed;

    /* Fait avancer le peripherique UART : l'emission passe a la trame suivante
       quand la courante arrive a echeance, et la reception resout les bits
       dont le milieu est passe a partir des fronts de la ligne. Les deux se
       cadencent via nextWakeTime (cf. earliest_uart_deadline), sans jamais
       reveiller le worker : le script recupere les octets a son rythme, par
       uart.any()/uart.read(). */
    uart_tx_advance(h, currentTime);
    uart_rx_step(h, currentTime, pinBoolIn);

    /* Fait avancer le maitre I2C d'un pas (un quart de periode d'horloge) si son
       echeance est atteinte. S'il vient de terminer la transaction sur laquelle
       le script est bloque, c'est un reveil a honorer (i2c_done_wake). */
    i2c_step(h, currentTime, pinBoolIn);

    /* Fait avancer la cible I2C sur les fronts de SCL/SDA. Un evenement dont
       le script a demande l'IRQ doit etre traite AU MEME INSTANT : pour
       IRQ_READ_REQ, le gestionnaire fournit l'octet que le maitre va lire
       (cf. i2ct_finish, apres le drain ci-dessous). */
    i2ct_step(h, pinBoolIn);
    int i2ct_due = h->i2ct.irq_pending != 0 && !h->irq_disabled;

    /* Un Timer actif dont l'echeance est atteinte doit aussi faire rendre la
       main au worker (sinon son callback ne se declencherait jamais) - meme
       si ni une entree n'a change, ni le propre reveil du worker n'est du.
       yield_to_modelica distingue ensuite, cote worker, un reveil
       "authentique" d'un simple "pitstop" pour ce cas precis. */
    int timer_due = (earliest_timer_deadline(h) <= currentTime + PYRUNTIME_EPS);

    /* Sinon, ne rendre la main au worker que si son reveil demande est
       effectivement atteint (ou qu'il n'attendait rien - premier appel). Un
       appel de PyRuntime_sync qui arrive plus tot (tick periodique) ne doit
       faire que rafraichir l'etat observe, sans laisser le script avancer
       avant l'heure - sinon un sleep(1) pourrait etre ecourte a tort. */
    if (input_changed || h->i2c_done_wake || !h->wake_pending || currentTime + PYRUNTIME_EPS >= h->wake_requested_at || timer_due || i2ct_due) {
        /* Boucle interne : tant que le worker redemande un reveil immediat
           (ex. plusieurs Pin(...) construits/pilotes a la suite, sans sleep
           entre deux), on lui redonne la main tout de suite plutot que de
           rendre la main a Modelica et compter sur l'iteration d'evenements
           pour redeclencher cette fonction. Constate empiriquement : au-dela
           de 2-3 reveils immediats chaines au meme instant simule, Modelica
           ne rappelle pas PyRuntime_sync assez de fois pour tous les
           traiter, laissant le script (et la simulation) bloques en silence
           (cf. requirements.md). On ne s'arrete que si le worker demande un
           reveil dans le futur, termine, ou plante. Un "pitstop" (callback
           Timer/IRQ execute par yield_to_modelica sans faire reprendre
           l'appel bloquant en cours) se traduit ici par un seul aller-retour
           : le worker repose le MEME wake_requested_at (toujours > currentTime),
           donc cette boucle s'arrete normalement et rend la main a Modelica -
           les pitstops suivants se feront lors des appels ulterieurs de
           PyRuntime_sync, a mesure que le temps simule avance.
           Attente par tranches quand hangWarningTime > 0, pour signaler un
           script qui ne laisse pas avancer la simulation (cf. hang_check). */
        ULONGLONG start = GetTickCount64();
        /* Debogage : une pause sur un point d'arret est legitime, pas de
           timeout mou. */
        double next_warn = h->debug_enabled ? 0 : h->hang_warning_time;
        for (;;) {
            h->turn = TURN_WORKER;
            WakeConditionVariable(&h->cv);
            while (h->turn != TURN_MODELICA) {
                if (next_warn > 0) {
                    SleepConditionVariableCS(&h->cv, &h->cs, HANG_CHECK_MS);
                    if (h->turn != TURN_MODELICA) {
                        hang_check(h, currentTime, start, &next_warn, 1);
                    }
                } else {
                    SleepConditionVariableCS(&h->cv, &h->cs, INFINITE);
                }
            }
            if (h->script_done || h->script_error) {
                break;
            }
            if (!h->wake_pending || h->wake_requested_at > currentTime + PYRUNTIME_EPS) {
                break;
            }
            hang_check(h, currentTime, start, &next_warn, 0);
        }
    }

    /* Octet differe par IRQ_READ_REQ : le gestionnaire a eu son tour. */
    i2ct_finish(h);

    for (i = 0; i < h->num_pins; i++) {
        pinBoolOut[i] = h->pin_driven_value[i];
        pinIsOutput[i] = h->pin_is_output[i];
        pinPull[i] = h->pin_pull[i];
        pwmFreqOut[i] = h->pwm_freq[i];
        pwmDutyOut[i] = h->pwm_duty[i];
    }
    publish_display(h, displaySeqOut, displayPayloadOut);
    /* Publie apres le drain : le script a pu lancer une emission pendant celui-ci. */
    uart_publish(h, currentTime, uartTxPinOut, uartTxLevelOut);
    int done = h->script_done;
    int error = h->script_error;
    char* error_message = h->error_message;
    double wake_at = h->wake_pending ? h->wake_requested_at : currentTime;
    double next_timer = earliest_timer_deadline(h); /* recalcule : un Timer periodique peut avoir ete rearme pendant le drain ci-dessus */
    if (next_timer < wake_at) {
        wake_at = next_timer;
    }
    /* Meme raison : une emission/reception a pu demarrer pendant le drain. */
    double next_uart = earliest_uart_deadline(h, currentTime);
    double uart_only = next_uart;
    if (next_uart < wake_at) {
        wake_at = next_uart;
    }
    /* Meme raison : le script a pu lancer une transaction I2C pendant le drain. */
    double next_i2c = earliest_i2c_deadline(h);
    if (next_i2c < wake_at) {
        wake_at = next_i2c;
    }
    LeaveCriticalSection(&h->cs);

    if (error) {
        ModelicaFormatError("PyRuntime (%s, %s): %s", h->instanceName,
                            h->scriptPath[0] != '\0' ? h->scriptPath : h->fs_root,
                            error_message ? error_message : "unknown error");
        return;
    }
    /* Script termine : seul l'UART peut encore demander un reveil (il finit de
       vider sa file en autonome, comme le PWM continue de tourner). */
    *nextWakeTime = done ? uart_only : wake_at;
}
