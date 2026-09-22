/* machine.Pin / machine.ADC / machine.PWM : primitives natives, y compris Pin.irq(), plus time.sleep/ticks_ms.

   Partie de l'implementation du runtime Python, incluse TEXTUELLEMENT par
   PyRuntimeImpl.c (fichier chapeau) : une seule unite de compilation, donc
   pas de #include croise ici et aucune etape de build supplementaire - cf.
   requirements.md, decision "Structure du package et interface C du runtime
   Python". Ce fichier n'est jamais compile seul. */

/* --- Module natif expose au shim Python (machine.Pin / time) --- */

/* Traduit un identifiant de broche tel qu'ecrit dans le script (0-7 pour les
   GPIO externes, 25 pour la LED embarquee) vers son index dans les tableaux
   pin_*[NUM_PINS]. Retourne -1 si l'identifiant n'est pas supporte. */
static int resolve_pin_index(int id) {
    if (id >= 0 && id < LED_PIN_INDEX) return id;
    if (id == LED_PIN_ID) return LED_PIN_INDEX;
    return -1;
}

static PyObject* native_pin_init(PyObject* self, PyObject* args) {
    int id, is_output;
    if (!PyArg_ParseTuple(args, "ii", &id, &is_output)) return NULL;
    int idx = resolve_pin_index(id);
    if (idx < 0) {
        PyErr_Format(PyExc_ValueError, "GPIO %d non supporte pour la v0 (0-%d ou %d pour la LED embarquee)", id, LED_PIN_INDEX - 1, LED_PIN_ID);
        return NULL;
    }
    EnterCriticalSection(&g_current->cs);
    g_current->pin_is_output[idx] = is_output;
    LeaveCriticalSection(&g_current->cs);
    if (yield_to_modelica(g_current->sim_time) != 0) return NULL;
    Py_RETURN_NONE;
}

static PyObject* native_pin_write(PyObject* self, PyObject* args) {
    int id, value;
    if (!PyArg_ParseTuple(args, "ii", &id, &value)) return NULL;
    int idx = resolve_pin_index(id);
    if (idx < 0) {
        PyErr_Format(PyExc_ValueError, "GPIO %d non supporte pour la v0 (0-%d ou %d pour la LED embarquee)", id, LED_PIN_INDEX - 1, LED_PIN_ID);
        return NULL;
    }
    EnterCriticalSection(&g_current->cs);
    if (g_current->pin_is_output[idx]) {
        g_current->pin_driven_value[idx] = value;
    }
    LeaveCriticalSection(&g_current->cs);
    if (yield_to_modelica(g_current->sim_time) != 0) return NULL;
    Py_RETURN_NONE;
}

static PyObject* native_pin_read(PyObject* self, PyObject* args) {
    int id;
    if (!PyArg_ParseTuple(args, "i", &id)) return NULL;
    int idx = resolve_pin_index(id);
    if (idx < 0) {
        PyErr_Format(PyExc_ValueError, "GPIO %d non supporte pour la v0 (0-%d ou %d pour la LED embarquee)", id, LED_PIN_INDEX - 1, LED_PIN_ID);
        return NULL;
    }
    if (yield_to_modelica(g_current->sim_time) != 0) return NULL;
    EnterCriticalSection(&g_current->cs);
    int v = g_current->pin_sensed_value[idx];
    LeaveCriticalSection(&g_current->cs);
    return PyBool_FromLong(v);
}

static PyObject* native_adc_read(PyObject* self, PyObject* args) {
    int id;
    if (!PyArg_ParseTuple(args, "i", &id)) return NULL;
    int idx = resolve_pin_index(id);
    if (idx < 0 || idx == LED_PIN_INDEX) {
        PyErr_Format(PyExc_ValueError, "GPIO %d non supporte comme entree ADC pour la v0 (0-%d uniquement)", id, LED_PIN_INDEX - 1);
        return NULL;
    }
    if (yield_to_modelica(g_current->sim_time) != 0) return NULL;
    EnterCriticalSection(&g_current->cs);
    double v = g_current->pin_analog_value[idx];
    LeaveCriticalSection(&g_current->cs);
    return PyFloat_FromDouble(v);
}

static PyObject* native_pwm_set_freq(PyObject* self, PyObject* args) {
    int id;
    double freq;
    if (!PyArg_ParseTuple(args, "id", &id, &freq)) return NULL;
    int idx = resolve_pin_index(id);
    if (idx < 0) {
        PyErr_Format(PyExc_ValueError, "GPIO %d non supporte pour la v0 (0-%d ou %d pour la LED embarquee)", id, LED_PIN_INDEX - 1, LED_PIN_ID);
        return NULL;
    }
    if (freq < 0) {
        /* PyErr_Format (PyUnicode_FromFormat) ne supporte pas %f - pas de conversion
           flottante native, seulement entiers/chaines/pointeurs (cf. doc C API Python).
           Formater la valeur soi-meme avec snprintf puis l'inserer via %s. */
        char freq_str[64];
        snprintf(freq_str, sizeof(freq_str), "%f", freq);
        PyErr_Format(PyExc_ValueError, "frequence PWM negative (%s)", freq_str);
        return NULL;
    }
    EnterCriticalSection(&g_current->cs);
    g_current->pin_is_output[idx] = 1;  /* le PWM prend la broche en sortie, comme sur le vrai RP2040 */
    g_current->pwm_freq[idx] = freq;
    LeaveCriticalSection(&g_current->cs);
    if (yield_to_modelica(g_current->sim_time) != 0) return NULL;
    Py_RETURN_NONE;
}

static PyObject* native_pwm_set_duty(PyObject* self, PyObject* args) {
    int id;
    double duty;
    if (!PyArg_ParseTuple(args, "id", &id, &duty)) return NULL;
    int idx = resolve_pin_index(id);
    if (idx < 0) {
        PyErr_Format(PyExc_ValueError, "GPIO %d non supporte pour la v0 (0-%d ou %d pour la LED embarquee)", id, LED_PIN_INDEX - 1, LED_PIN_ID);
        return NULL;
    }
    if (duty < 0.0) duty = 0.0;
    if (duty > 1.0) duty = 1.0;
    EnterCriticalSection(&g_current->cs);
    g_current->pwm_duty[idx] = duty;
    LeaveCriticalSection(&g_current->cs);
    if (yield_to_modelica(g_current->sim_time) != 0) return NULL;
    Py_RETURN_NONE;
}

static PyObject* native_pwm_deinit(PyObject* self, PyObject* args) {
    int id;
    if (!PyArg_ParseTuple(args, "i", &id)) return NULL;
    int idx = resolve_pin_index(id);
    if (idx < 0) {
        PyErr_Format(PyExc_ValueError, "GPIO %d non supporte pour la v0 (0-%d ou %d pour la LED embarquee)", id, LED_PIN_INDEX - 1, LED_PIN_ID);
        return NULL;
    }
    EnterCriticalSection(&g_current->cs);
    g_current->pwm_freq[idx] = 0;  /* retombe en sortie numerique classique, pilotee par pin_driven_value (bas par defaut) */
    LeaveCriticalSection(&g_current->cs);
    if (yield_to_modelica(g_current->sim_time) != 0) return NULL;
    Py_RETURN_NONE;
}

static PyObject* native_sleep(PyObject* self, PyObject* args) {
    double seconds;
    if (!PyArg_ParseTuple(args, "d", &seconds)) return NULL;
    double wake_at = g_current->sim_time + (seconds > 0 ? seconds : 0);
    if (yield_to_modelica(wake_at) != 0) return NULL;
    Py_RETURN_NONE;
}

static PyObject* native_ticks_ms(PyObject* self, PyObject* args) {
    return PyLong_FromLongLong((long long)(g_current->sim_time * 1000.0));
}

/* --- machine.Pin.irq() --- */

static PyObject* native_pin_irq_set(PyObject* self, PyObject* args) {
    int id, trigger;
    PyObject* pin_self;
    PyObject* handler;
    if (!PyArg_ParseTuple(args, "iOOi", &id, &pin_self, &handler, &trigger)) return NULL;
    int idx = resolve_pin_index(id);
    if (idx < 0) {
        PyErr_Format(PyExc_ValueError, "GPIO %d non supporte pour la v0 (0-%d ou %d pour la LED embarquee)", id, LED_PIN_INDEX - 1, LED_PIN_ID);
        return NULL;
    }
    EnterCriticalSection(&g_current->cs);
    Py_CLEAR(g_current->pin_irq_handler[idx]);
    Py_CLEAR(g_current->pin_irq_self[idx]);
    g_current->pin_irq_pending[idx] = 0;
    if (handler != Py_None) {
        Py_INCREF(handler);
        Py_INCREF(pin_self);
        g_current->pin_irq_handler[idx] = handler;
        g_current->pin_irq_self[idx] = pin_self;
        g_current->pin_irq_trigger[idx] = trigger;
    } else {
        g_current->pin_irq_trigger[idx] = 0;
    }
    LeaveCriticalSection(&g_current->cs);
    if (yield_to_modelica(g_current->sim_time) != 0) return NULL;
    Py_RETURN_NONE;
}
