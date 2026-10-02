/* Module natif expose au shim, thread worker et API exportee vers Modelica (PyRuntime_new/_destroy/_sync).

   Partie de l'implementation du runtime Python, incluse TEXTUELLEMENT par
   PyRuntimeImpl.c (fichier chapeau) : une seule unite de compilation, donc
   pas de #include croise ici et aucune etape de build supplementaire - cf.
   requirements.md, decision "Structure du package et interface C du runtime
   Python". Ce fichier n'est jamais compile seul. */

static PyMethodDef native_methods[] = {
    {"pin_init", native_pin_init, METH_VARARGS, "Sets the direction of a pin"},
    {"pin_write", native_pin_write, METH_VARARGS, "Drives a pin (if it is an output)"},
    {"pin_read", native_pin_read, METH_VARARGS, "Reads the resolved state of a pin"},
    {"pin_irq_set", native_pin_irq_set, METH_VARARGS, "Registers/clears the IRQ callback of a pin"},
    {"adc_init", native_adc_init, METH_VARARGS, "Switches a pin to analog input (disconnects its digital input: no IRQ nor wake-up)"},
    {"adc_read",native_adc_read, METH_VARARGS, "Reads the raw voltage (V) measured on an ADC pin"},
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

/* Arguments de construction transmis au worker (chemins), liberes par lui. */
struct WorkerInit {
    char* addScriptDir;          /* NULL : ne rien ajouter a sys.path */
    char* libraryDir;
    char* shimSrc;
};

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
    PyStatus status = Py_NewInterpreterFromConfig(&sub, &MCU_INTERP_CONFIG);
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
    if (!failure && PyRun_SimpleString(wi->shimSrc) != 0) {
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

/* Execute un fichier du programme (dir\name, ou name seul si dir est NULL)
   dans __main__. Retourne 0 si le fichier n'existe pas (rien d'execute), 1
   sinon ; une exception pose script_error et un message nommant le fichier. */
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
    free(path);
    if (!buf) {
        return 0;
    }
    int rc = PyRun_SimpleString(buf);
    free(buf);
    relay_flush_buf(&h->relay);
    relay_flush_buf(&h->relay_err);
    if (rc != 0) {
        char msg[128];
        snprintf(msg, sizeof(msg), "%s raised an unhandled exception - traceback above",
                 dir ? name : "the script");
        h->script_error = 1;
        h->error_message = strdup(msg);
    }
    return 1;
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
    Py_BEGIN_ALLOW_THREADS
    EnterCriticalSection(&h->cs);
    while (h->turn != TURN_WORKER) {
        SleepConditionVariableCS(&h->cv, &h->cs, INFINITE);
    }
    LeaveCriticalSection(&h->cs);
    Py_END_ALLOW_THREADS

    /* Sequence de demarrage, comme sur la carte : boot.py de la flash s'il
       existe, puis le programme - le script (scriptPath) s'il est renseigne, a
       la place de main.py comme Thonny sur une carte deja demarree, sinon
       main.py de la flash s'il existe. Tous dans le meme espace de noms
       (__main__). Une exception arrete la sequence. PyRuntime_new garantit
       qu'il y a un script ou un systeme de fichiers. */
    int ran = 0;
    if (h->fs_root) {
        ran |= run_program_file(h, h->fs_root, "boot.py");
    }
    if (!h->script_error) {
        if (h->scriptPath[0] != '\0') {
            if (!run_program_file(h, NULL, h->scriptPath)) {
                h->script_error = 1;
                h->error_message = strdup("cannot open the script");
            }
            ran = 1;
        } else if (h->fs_root) {
            ran |= run_program_file(h, h->fs_root, "main.py");
        }
    }
    if (!ran) {
        ModelicaFormatMessage("PyRuntime: neither boot.py nor main.py at the root of the file system - microcontroller idle\n");
    }

    EnterCriticalSection(&h->cs);
    h->script_done = 1;
    h->turn = TURN_MODELICA;
    WakeConditionVariable(&h->cv);
    LeaveCriticalSection(&h->cs);

    /* Rend le GIL commun pour de bon. Le sous-interpreteur n'est pas finalise :
       ses objets (callbacks, tampon de mem) restent valides jusqu'a la fin du
       process, comme le reste (cf. PyRuntime_destroy). */
    g_current = NULL;
    PyEval_SaveThread();
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
                     const char* instanceName, double gpioOpTime) {
    char err[512];

    /* Sans script, le programme est main.py du systeme de fichiers : il en
       faut un. Verifie avant tout demarrage, l'erreur est de configuration. */
    if (scriptPath[0] == '\0' && !fsEnabled) {
        ModelicaFormatError("PyRuntime: scriptPath is empty and the file system is disabled - "
                            "give a script, or enable a file system containing main.py");
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
    /* Chaque simulation tourne dans son propre process (simulate() genere
       un executable independant a chaque run - verifie en session), qui se
       termine juste apres cet appel. On ne tente donc pas de reveiller/joindre
       proprement le thread worker (probablement bloque en plein sleep()) ni
       de finaliser CPython : l'OS recupere tout a la sortie du process. Choix
       delibere pour eviter les pieges d'un arret propre multi-thread pour un
       gain nul - a revisiter si ce choix s'avere un jour gener (cf.
       principe de revisabilite, requirements.md). Les references Python
       accumulees par les callbacks IRQ/Timer (pin_irq_handler/timer_callback
       etc.) suivent le meme principe : jamais decref explicitement, le
       process recupere tout. Seule action : signaler la copie du systeme de
       fichiers (journal, Explorateur), cf. fs_at_exit. */
    if (handle_) {
        fs_at_exit((struct PyRuntimeHandle*) handle_);
    }
}

void PyRuntime_sync(void* handle_, double currentTime, const int* pinBoolIn,
                     const double* pinAnalogIn,
                     int* pinBoolOut, int* pinIsOutput, int* pinPull,
                     double* pwmFreqOut, double* pwmDutyOut,
                     int* displaySeqOut, const char** displayPayloadOut,
                     int* uartTxPinOut, int* uartTxLevelOut,
                     double* nextWakeTime) {
    struct PyRuntimeHandle* h = (struct PyRuntimeHandle*) handle_;
    int i;

    if (h->script_done) {
        for (i = 0; i < NUM_PINS; i++) {
            pinBoolOut[i] = h->pin_driven_value[i];
            pinIsOutput[i] = h->pin_is_output[i];
            pinPull[i] = h->pin_pull[i];
            pwmFreqOut[i] = h->pwm_freq[i];
            pwmDutyOut[i] = h->pwm_duty[i];
        }
        *displaySeqOut = h->display_seq;
        *displayPayloadOut = ModelicaAllocateString(strlen(h->display_payload));
        strcpy((char*) *displayPayloadOut, h->display_payload);
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
        for (i = 0; i < NUM_PINS; i++) {
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
    for (i = 0; i < NUM_PINS; i++) {
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
           PyRuntime_sync, a mesure que le temps simule avance. */
        for (;;) {
            h->turn = TURN_WORKER;
            WakeConditionVariable(&h->cv);
            while (h->turn != TURN_MODELICA) {
                SleepConditionVariableCS(&h->cv, &h->cs, INFINITE);
            }
            if (h->script_done || h->script_error) {
                break;
            }
            if (!h->wake_pending || h->wake_requested_at > currentTime + PYRUNTIME_EPS) {
                break;
            }
        }
    }

    /* Octet differe par IRQ_READ_REQ : le gestionnaire a eu son tour. */
    i2ct_finish(h);

    for (i = 0; i < NUM_PINS; i++) {
        pinBoolOut[i] = h->pin_driven_value[i];
        pinIsOutput[i] = h->pin_is_output[i];
        pinPull[i] = h->pin_pull[i];
        pwmFreqOut[i] = h->pwm_freq[i];
        pwmDutyOut[i] = h->pwm_duty[i];
    }
    *displaySeqOut = h->display_seq;
    *displayPayloadOut = ModelicaAllocateString(strlen(h->display_payload));
    strcpy((char*) *displayPayloadOut, h->display_payload);
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
