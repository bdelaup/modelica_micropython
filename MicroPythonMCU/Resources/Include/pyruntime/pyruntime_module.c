/* Module natif expose au shim, thread worker et API exportee vers Modelica (PyRuntime_new/_destroy/_sync).

   Partie de l'implementation du runtime Python, incluse TEXTUELLEMENT par
   PyRuntimeImpl.c (fichier chapeau) : une seule unite de compilation, donc
   pas de #include croise ici et aucune etape de build supplementaire - cf.
   requirements.md, decision "Structure du package et interface C du runtime
   Python". Ce fichier n'est jamais compile seul. */

static PyMethodDef native_methods[] = {
    {"pin_init", native_pin_init, METH_VARARGS, "Configure la direction d'une broche"},
    {"pin_write", native_pin_write, METH_VARARGS, "Pilote une broche (si en sortie)"},
    {"pin_read", native_pin_read, METH_VARARGS, "Lit l'etat resolu d'une broche"},
    {"pin_irq_set", native_pin_irq_set, METH_VARARGS, "Enregistre/efface le callback IRQ d'une broche"},
    {"adc_read", native_adc_read, METH_VARARGS, "Lit la tension brute (V) mesuree sur une broche ADC"},
    {"pwm_set_freq", native_pwm_set_freq, METH_VARARGS, "Configure la frequence PWM (Hz) d'une broche, la prend en sortie"},
    {"pwm_set_duty", native_pwm_set_duty, METH_VARARGS, "Configure le rapport cyclique PWM (0-1) d'une broche"},
    {"pwm_deinit", native_pwm_deinit, METH_VARARGS, "Arrete le PWM sur une broche (retombe en sortie numerique classique)"},
    {"display_write", native_display_write, METH_VARARGS, "Transmet un texte au périphérique d'affichage pédagogique connecté (livraison instantanee)"},
    {"uart_init", native_uart_init, METH_VARARGS, "Configure l'UART (broches TX/RX, baudrate) et prend les broches"},
    {"uart_write", native_uart_write, METH_VARARGS, "Met des octets dans la file d'emission (non bloquant), retourne le nombre accepte"},
    {"uart_any", native_uart_any, METH_VARARGS, "Nombre d'octets recus en attente de lecture"},
    {"uart_read", native_uart_read, METH_VARARGS, "Lit jusqu'a n octets recus (n < 0 = tout), None si rien"},
    {"uart_deinit", native_uart_deinit, METH_VARARGS, "Libere l'UART et ses broches"},
    {"i2c_init", native_i2c_init, METH_VARARGS, "Configure le bus I2C (broches SCL/SDA, frequence) et prend les broches"},
    {"i2c_xfer", native_i2c_xfer, METH_VARARGS, "Transaction I2C complete (ecriture, lecture apres START repete), bloquante"},
    {"i2c_deinit", native_i2c_deinit, METH_VARARGS, "Libere le bus I2C et ses broches"},
    {"timer_new", native_timer_new, METH_VARARGS, "Alloue un slot de Timer() dans le pool fixe"},
    {"timer_init", native_timer_init, METH_VARARGS, "Arme un Timer (periode, mode, callback)"},
    {"timer_deinit", native_timer_deinit, METH_VARARGS, "Arrete et libere un Timer"},
    {"sleep", native_sleep, METH_VARARGS, "Attend N secondes de temps simule"},
    {"ticks_ms", native_ticks_ms, METH_VARARGS, "Horloge simulee, en millisecondes"},
    {NULL, NULL, 0, NULL}
};

/* Enregistre dans sys.modules APRES l'initialisation (pyhost_register_module),
   et non plus par PyImport_AppendInittab : ce dernier n'est utilisable qu'avant
   Py_Initialize, or l'interpreteur peut avoir ete demarre par un peripherique
   serie construit avant le microcontroleur (cf. pyhost.c). */
static struct PyModuleDef native_module_def = {
    PyModuleDef_HEAD_INIT, "_pyruntime_native", NULL, -1, native_methods,
    NULL, NULL, NULL, NULL
};

/* read_text_file, le relais stdout et le demarrage de CPython vivent dans
   pyhost.c, partage avec les peripheriques serie. */

/* --- Thread worker --- */

static unsigned __stdcall worker_main(void* arg) {
    struct PyRuntimeHandle* h = (struct PyRuntimeHandle*) arg;
    h->worker_thread_id = GetCurrentThreadId();
    PyGILState_STATE gstate = PyGILState_Ensure();
    g_current = h;

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

    char* buf = read_text_file(h->scriptPath);
    if (!buf) {
        h->script_error = 1;
        h->error_message = strdup("impossible d'ouvrir le script");
    } else {
        int rc = PyRun_SimpleString(buf);
        free(buf);
        if (rc != 0) {
            h->script_error = 1;
            h->error_message = strdup("le script a leve une exception non geree - trace ci-dessus");
        }
        relay_emit_pending();
    }

    EnterCriticalSection(&h->cs);
    h->script_done = 1;
    h->turn = TURN_MODELICA;
    WakeConditionVariable(&h->cv);
    LeaveCriticalSection(&h->cs);

    g_current = NULL;
    PyGILState_Release(gstate);
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
                     const char* shimPath) {
    char err[512];

    /* Demarrage de CPython partage avec les peripheriques serie : l'un d'eux a
       pu le faire avant nous (ordre de construction non garanti). Au retour, le
       GIL n'est tenu par personne (cf. invariant de pyhost.c). */
    if (pyhost_ensure(pythonHome, err, sizeof(err)) != 0) {
        ModelicaFormatError("PyRuntime: %s", err);
        return NULL;
    }

    struct PyRuntimeHandle* handle = (struct PyRuntimeHandle*) calloc(1, sizeof(struct PyRuntimeHandle));
    handle->scriptPath = strdup(scriptPath);
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

    /* Le shim doit exister dans l'interprete AVANT que le script ne fasse
       "import machine"/"import time" sur le thread worker. Il vit dans un vrai
       fichier .py de la bibliotheque (Resources/Scripts/_shim/), resolu cote
       Modelica comme scriptPath/pythonHome - cf. requirements.md, decision
       "Conception du shim machine/time". */
    char* shim_src = read_text_file(shimPath);
    if (!shim_src) {
        ModelicaFormatError("PyRuntime: impossible de lire le shim machine/time ('%s')", shimPath);
        return NULL;
    }

    PyGILState_STATE gstate = PyGILState_Ensure();
    const char* failure = NULL;

    /* Module natif du shim : enregistre apres coup dans sys.modules. */
    if (pyhost_register_module("_pyruntime_native", PyModule_Create(&native_module_def)) != 0) {
        failure = "echec d'enregistrement du module natif du shim";
    }

    /* Import de modules auxiliaires (cf. requirements.md, decision "Import de
       modules auxiliaires") : ajoute a sys.path le dossier du script
       (addScriptDirToPath) et/ou celui d'une bibliotheque partagee
       (libraryPath, desactive si chaine vide). Ajoutes a l'execution plutot que
       dans la configuration d'initialisation, puisque l'interpreteur peut deja
       etre demarre ; l'ordre obtenu dans sys.path est le meme. */
    if (!failure && addScriptDirToPath) {
        char* dir = dirname_of(scriptPath);
        if (dir[0] != '\0' && pyhost_append_path(dir) != 0) {
            failure = "echec d'ajout du dossier du script au sys.path";
        }
        free(dir);
    }
    if (!failure && libraryPath && libraryPath[0] != '\0') {
        char* dir = dirname_of(libraryPath);
        if (dir[0] != '\0' && pyhost_append_path(dir) != 0) {
            failure = "echec d'ajout de libraryPath au sys.path";
        }
        free(dir);
    }

    if (!failure) {
        g_current = handle;
        if (PyRun_SimpleString(shim_src) != 0) {
            failure = "echec d'initialisation du shim machine/time";
        }
        g_current = NULL;
    }
    free(shim_src);

    /* Rend le GIL avant toute sortie en erreur : ModelicaFormatError ne revient
       pas, et un GIL garde ici bloquerait tout autre composant. */
    PyGILState_Release(gstate);
    if (failure) {
        ModelicaFormatError("PyRuntime: %s", failure);
        return NULL;
    }

    handle->thread = (HANDLE) _beginthreadex(NULL, 0, worker_main, handle, 0, NULL);
    if (!handle->thread) {
        ModelicaFormatError("PyRuntime: echec de creation du thread worker");
        return NULL;
    }

    return (void*) handle;
}

void PyRuntime_destroy(void* handle_) {
    /* v0 : chaque simulation tourne dans son propre process (simulate() genere
       un executable independant a chaque run - verifie en session), qui se
       termine juste apres cet appel. On ne tente donc pas de reveiller/joindre
       proprement le thread worker (probablement bloque en plein sleep()) ni
       de finaliser CPython : l'OS recupere tout a la sortie du process. Choix
       delibere pour eviter les pieges d'un arret propre multi-thread pour un
       gain nul en v0 - a revisiter si ce choix s'avere un jour gener (cf.
       principe de revisabilite, requirements.md). Les references Python
       accumulees par les callbacks IRQ/Timer (pin_irq_handler/timer_callback
       etc.) suivent le meme principe : jamais decref explicitement, le
       process recupere tout. */
    (void) handle_;
}

void PyRuntime_sync(void* handle_, double currentTime, const int* pinBoolIn,
                     const double* pinAnalogIn,
                     int* pinBoolOut, int* pinIsOutput,
                     double* pwmFreqOut, double* pwmDutyOut,
                     int* displaySeqOut, const char** displayPayloadOut,
                     int* uartTxPinOut, int* uartTxActiveOut,
                     double* uartTxStartOut, double* uartBitDurOut,
                     int* uartTxNumBitsOut, double* uartTxBitsOut,
                     double* nextWakeTime) {
    struct PyRuntimeHandle* h = (struct PyRuntimeHandle*) handle_;
    int i;

    if (h->script_done) {
        for (i = 0; i < NUM_PINS; i++) {
            pinBoolOut[i] = h->pin_driven_value[i];
            pinIsOutput[i] = h->pin_is_output[i];
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
        uart_publish(h, uartTxPinOut, uartTxActiveOut, uartTxStartOut, uartBitDurOut,
                     uartTxNumBitsOut, uartTxBitsOut);
        /* Seule une echeance UART peut encore demander un reveil apres la fin
           du script (trame suivante a charger, bit a echantillonner). */
        *nextWakeTime = earliest_uart_deadline(h);
        return;
    }

    EnterCriticalSection(&h->cs);
    h->sim_time = currentTime;

    /* Une vraie transition d'une broche actuellement en ENTREE justifie de
       reveiller le worker avant l'heure demandee par son sleep() (cf.
       scenario de verification "reactivite en entree" - la broche doit
       pouvoir interrompre une attente en cours, cote v0 sans vraie
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
           ne genere plus d'interruption GPIO. */
        if (!h->pin_is_output[i] && !h->uart_rx_claimed[i] && !h->i2c_claimed[i] && old_val != new_val) {
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
       quand la courante arrive a echeance, et la reception echantillonne la
       ligne au milieu de chaque bit. Les deux se cadencent via nextWakeTime
       (cf. earliest_uart_deadline), sans jamais reveiller le worker : le script
       recupere les octets a son rythme, par uart.any()/uart.read(). */
    uart_tx_advance(h, currentTime);
    uart_rx_step(h, currentTime, pinBoolIn);

    /* Fait avancer le maitre I2C d'un pas (un quart de periode d'horloge) si son
       echeance est atteinte. S'il vient de terminer la transaction sur laquelle
       le script est bloque, c'est un reveil a honorer (i2c_done_wake). */
    i2c_step(h, currentTime, pinBoolIn);

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
    if (input_changed || h->i2c_done_wake || !h->wake_pending || currentTime + PYRUNTIME_EPS >= h->wake_requested_at || timer_due) {
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

    for (i = 0; i < NUM_PINS; i++) {
        pinBoolOut[i] = h->pin_driven_value[i];
        pinIsOutput[i] = h->pin_is_output[i];
        pwmFreqOut[i] = h->pwm_freq[i];
        pwmDutyOut[i] = h->pwm_duty[i];
    }
    *displaySeqOut = h->display_seq;
    *displayPayloadOut = ModelicaAllocateString(strlen(h->display_payload));
    strcpy((char*) *displayPayloadOut, h->display_payload);
    /* Publie apres le drain : le script a pu lancer une emission pendant celui-ci. */
    uart_publish(h, uartTxPinOut, uartTxActiveOut, uartTxStartOut, uartBitDurOut,
                 uartTxNumBitsOut, uartTxBitsOut);
    int done = h->script_done;
    int error = h->script_error;
    char* error_message = h->error_message;
    double wake_at = h->wake_pending ? h->wake_requested_at : currentTime;
    double next_timer = earliest_timer_deadline(h); /* recalcule : un Timer periodique peut avoir ete rearme pendant le drain ci-dessus */
    if (next_timer < wake_at) {
        wake_at = next_timer;
    }
    /* Meme raison : une emission/reception a pu demarrer pendant le drain. */
    double next_uart = earliest_uart_deadline(h);
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
        ModelicaFormatError("PyRuntime (%s): %s", h->scriptPath, error_message ? error_message : "erreur inconnue");
        return;
    }
    /* Script termine : seul l'UART peut encore demander un reveil (il finit de
       vider sa file en autonome, comme le PWM continue de tourner). */
    *nextWakeTime = done ? uart_only : wake_at;
}
