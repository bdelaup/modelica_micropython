/* Coeur du protocole de synchro : dispatch des callbacks dus et point de synchro (yield_to_modelica).

   Partie de l'implementation du runtime Python, incluse TEXTUELLEMENT par
   PyRuntimeImpl.c (fichier chapeau) : une seule unite de compilation, donc
   pas de #include croise ici et aucune etape de build supplementaire - cf.
   requirements.md, decision "Structure du package et interface C du runtime
   Python". Ce fichier n'est jamais compile seul. */

/* --- Dispatch des callbacks IRQ/Timer dus ---
   Rassemble sous verrou (incref des references recuperees, purge des drapeaux
   "pending"/rearmement des Timer periodiques), RELACHE le verrou, puis appelle
   seulement alors dans Python. Ne jamais appeler de Python en tenant cs :
   SleepConditionVariableCS (utilise par yield_to_modelica pour tout appel du
   shim, y compris ceux qu'un callback ferait a son tour, ex. piloter une
   broche ou dormir) ne relache qu'un seul niveau de section critique - un
   callback qui re-entre cs via native_pin_write/native_sleep/etc laisserait cs
   techniquement encore tenu quand Modelica devrait pouvoir le reprendre,
   deadlock reel (pas juste un style plus propre). Retourne 0 si tout s'est
   bien passe, -1 si un callback a leve une exception (PyErr deja positionne,
   a laisser remonter tel quel - cf. yield_to_modelica et les sites d'appel
   natifs). */
static int run_due_callbacks(struct PyRuntimeHandle* h) {
    struct { PyObject* callback; PyObject* arg; } due[NUM_PINS + MAX_TIMERS];
    int due_count = 0;
    int i;

    EnterCriticalSection(&h->cs);
    for (i = 0; i < NUM_PINS; i++) {
        if (h->pin_irq_pending[i]) {
            h->pin_irq_pending[i] = 0;
            due[due_count].callback = h->pin_irq_handler[i];
            due[due_count].arg = h->pin_irq_self[i];
            Py_XINCREF(due[due_count].callback);
            Py_XINCREF(due[due_count].arg);
            due_count++;
        }
    }
    for (i = 0; i < MAX_TIMERS; i++) {
        if (h->timer_active[i] && h->timer_next_fire[i] <= h->sim_time + PYRUNTIME_EPS) {
            due[due_count].callback = h->timer_callback[i];
            due[due_count].arg = h->timer_self[i];
            Py_XINCREF(due[due_count].callback);
            Py_XINCREF(due[due_count].arg);
            due_count++;
            if (h->timer_mode[i] == 1 /* PERIODIC */) {
                h->timer_next_fire[i] += h->timer_period[i];
            } else {
                h->timer_active[i] = 0;
                Py_CLEAR(h->timer_callback[i]);
                Py_CLEAR(h->timer_self[i]);
            }
        }
    }
    LeaveCriticalSection(&h->cs);

    int status = 0;
    for (i = 0; i < due_count; i++) {
        if (status == 0 && due[i].callback) {
            PyObject* result = PyObject_CallFunctionObjArgs(due[i].callback, due[i].arg, NULL);
            if (result) {
                Py_DECREF(result);
            } else {
                status = -1; /* PyErr deja positionne par l'appel - ne pas l'effacer */
            }
        }
        Py_XDECREF(due[i].callback);
        Py_XDECREF(due[i].arg);
    }
    return status;
}

/* --- Point de synchro : rend la main a Modelica et attend le tour suivant ---
   Retourne 0 en cas de reveil normal, -1 si un callback IRQ/Timer declenche
   pendant l'attente a leve une exception (l'appelant doit alors "return NULL"
   immediatement, PyErr est deja positionne - cf. run_due_callbacks). Boucle
   interne : si le reveil n'est "authentique" ni parce que l'echeance propre
   demandee (wake_at) est atteinte, ni parce qu'une broche en entree a
   vraiment change (h->wake_had_input_change), alors ce n'est qu'un "pitstop"
   (un Timer/IRQ du dispatch qui n'implique pas de reprendre l'appel bloquant
   en cours, ex. un Timer periodique pendant un sleep() long) : on reposte le
   MEME wake_at et on rattend le prochain appel de PyRuntime_sync, sans
   laisser l'appelant (native_sleep, etc.) reprendre la main trop tot. */
static int yield_to_modelica(double wake_at) {
    struct PyRuntimeHandle* h = g_current;
    for (;;) {
        EnterCriticalSection(&h->cs);
        h->wake_requested_at = wake_at;
        h->wake_pending = 1;
        h->turn = TURN_MODELICA;
        WakeConditionVariable(&h->cv);
        while (h->turn != TURN_WORKER) {
            SleepConditionVariableCS(&h->cv, &h->cs, INFINITE);
        }
        int genuine = h->wake_had_input_change || (h->sim_time + PYRUNTIME_EPS >= wake_at);
        LeaveCriticalSection(&h->cs);

        if (run_due_callbacks(h) != 0) {
            return -1;
        }
        if (genuine) {
            return 0;
        }
        /* pitstop pur : reposter le meme wake_at au tour suivant de la boucle */
    }
}
