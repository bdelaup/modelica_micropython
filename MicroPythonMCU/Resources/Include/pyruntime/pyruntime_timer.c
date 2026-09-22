/* machine.Timer : pool fixe de minuteurs logiciels et primitives natives.

   Partie de l'implementation du runtime Python, incluse TEXTUELLEMENT par
   PyRuntimeImpl.c (fichier chapeau) : une seule unite de compilation, donc
   pas de #include croise ici et aucune etape de build supplementaire - cf.
   requirements.md, decision "Structure du package et interface C du runtime
   Python". Ce fichier n'est jamais compile seul. */

/* --- machine.Timer : plus proche echeance active (h->cs deja tenu par l'appelant) --- */

static double earliest_timer_deadline(struct PyRuntimeHandle* h) {
    double best = 1.0e300;
    int i;
    for (i = 0; i < MAX_TIMERS; i++) {
        if (h->timer_active[i] && h->timer_next_fire[i] < best) {
            best = h->timer_next_fire[i];
        }
    }
    return best;
}

/* --- machine.Timer --- */

static PyObject* native_timer_new(PyObject* self, PyObject* args) {
    int i;
    EnterCriticalSection(&g_current->cs);
    for (i = 0; i < MAX_TIMERS; i++) {
        if (!g_current->timer_allocated[i]) {
            g_current->timer_allocated[i] = 1;
            LeaveCriticalSection(&g_current->cs);
            return PyLong_FromLong(i);
        }
    }
    LeaveCriticalSection(&g_current->cs);
    PyErr_Format(PyExc_RuntimeError, "nombre maximal de Timer() atteint (%d) pour la v0", MAX_TIMERS);
    return NULL;
}

static PyObject* native_timer_init(PyObject* self, PyObject* args) {
    int slot, mode;
    double period_seconds;
    PyObject* callback;
    PyObject* timer_self;
    if (!PyArg_ParseTuple(args, "idiOO", &slot, &period_seconds, &mode, &callback, &timer_self)) return NULL;
    if (slot < 0 || slot >= MAX_TIMERS || !g_current->timer_allocated[slot]) {
        PyErr_Format(PyExc_ValueError, "Timer invalide");
        return NULL;
    }
    if (period_seconds < TIMER_MIN_PERIOD) {
        /* PyErr_Format ne supporte pas %f (cf. native_pwm_set_freq) - formater a la main. */
        char period_str[64], min_str[64];
        snprintf(period_str, sizeof(period_str), "%f", period_seconds);
        snprintf(min_str, sizeof(min_str), "%f", TIMER_MIN_PERIOD);
        PyErr_Format(PyExc_ValueError, "periode de Timer trop courte (%s s, minimum %s s pour la v0)", period_str, min_str);
        return NULL;
    }
    EnterCriticalSection(&g_current->cs);
    Py_CLEAR(g_current->timer_callback[slot]);
    Py_CLEAR(g_current->timer_self[slot]);
    Py_INCREF(callback);
    Py_INCREF(timer_self);
    g_current->timer_callback[slot] = callback;
    g_current->timer_self[slot] = timer_self;
    g_current->timer_period[slot] = period_seconds;
    g_current->timer_mode[slot] = mode;
    g_current->timer_next_fire[slot] = g_current->sim_time + period_seconds;
    g_current->timer_active[slot] = 1;
    LeaveCriticalSection(&g_current->cs);
    if (yield_to_modelica(g_current->sim_time) != 0) return NULL;
    Py_RETURN_NONE;
}

static PyObject* native_timer_deinit(PyObject* self, PyObject* args) {
    int slot;
    if (!PyArg_ParseTuple(args, "i", &slot)) return NULL;
    if (slot < 0 || slot >= MAX_TIMERS) {
        PyErr_Format(PyExc_ValueError, "Timer invalide");
        return NULL;
    }
    EnterCriticalSection(&g_current->cs);
    g_current->timer_active[slot] = 0;
    g_current->timer_allocated[slot] = 0;
    Py_CLEAR(g_current->timer_callback[slot]);
    Py_CLEAR(g_current->timer_self[slot]);
    LeaveCriticalSection(&g_current->cs);
    if (yield_to_modelica(g_current->sim_time) != 0) return NULL;
    Py_RETURN_NONE;
}
