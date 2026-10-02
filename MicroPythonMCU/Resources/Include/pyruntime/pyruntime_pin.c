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

/* Pin.init(mode, pull), appele aussi par le constructeur des qu'il recoit un
   mode ou un pull. Comme sur le port rp2, le tirage est toujours reecrit :
   pull absent (PIN_PULL_NONE) coupe un tirage pose avant. mode =
   PIN_MODE_KEEP laisse la direction telle quelle (Pin(n, pull=...)). */
static PyObject* native_pin_init(PyObject* self, PyObject* args) {
    REQUIRE_WORKER();
    int id, mode, pull;
    if (!PyArg_ParseTuple(args, "iii", &id, &mode, &pull)) return NULL;
    int idx = resolve_pin_index(id);
    if (idx < 0) {
        PyErr_Format(PyExc_ValueError, "GPIO %d not supported (0-%d, or %d for the on-board LED)", id, LED_PIN_INDEX - 1, LED_PIN_ID);
        return NULL;
    }
    if (pull != PIN_PULL_NONE && pull != PIN_PULL_UP && pull != PIN_PULL_DOWN) {
        PyErr_Format(PyExc_ValueError, "invalid pull value %d (Pin.PULL_UP, Pin.PULL_DOWN or None)", pull);
        return NULL;
    }
    EnterCriticalSection(&g_current->cs);
    if (mode != PIN_MODE_KEEP) {
        g_current->pin_is_output[idx] = mode;
        g_current->adc_claimed[idx] = 0;   /* Pin(n, mode) rend la broche au GPIO, meme apres un ADC(n) - comme sur le RP2040 */
    }
    g_current->pin_pull[idx] = pull;
    LeaveCriticalSection(&g_current->cs);
    if (yield_to_modelica(g_current->sim_time) != 0) return NULL;
    Py_RETURN_NONE;
}

static PyObject* native_pin_write(PyObject* self, PyObject* args) {
    REQUIRE_WORKER();
    int id, value;
    if (!PyArg_ParseTuple(args, "ii", &id, &value)) return NULL;
    int idx = resolve_pin_index(id);
    if (idx < 0) {
        PyErr_Format(PyExc_ValueError, "GPIO %d not supported (0-%d, or %d for the on-board LED)", id, LED_PIN_INDEX - 1, LED_PIN_ID);
        return NULL;
    }
    EnterCriticalSection(&g_current->cs);
    if (g_current->pin_is_output[idx]) {
        g_current->pin_driven_value[idx] = value;
    }
    LeaveCriticalSection(&g_current->cs);
    /* La broche change tout de suite (publiee a sim_time), puis le processeur
       reste occupe gpio_op_time : c'est ce qui donne une largeur a l'impulsion
       de on(); off(). Attente non interruptible, cf. yield_until. */
    if (yield_until(g_current->sim_time + g_current->gpio_op_time, 0) != 0) return NULL;
    Py_RETURN_NONE;
}

static PyObject* native_pin_read(PyObject* self, PyObject* args) {
    REQUIRE_WORKER();
    int id;
    if (!PyArg_ParseTuple(args, "i", &id)) return NULL;
    int idx = resolve_pin_index(id);
    if (idx < 0) {
        PyErr_Format(PyExc_ValueError, "GPIO %d not supported (0-%d, or %d for the on-board LED)", id, LED_PIN_INDEX - 1, LED_PIN_ID);
        return NULL;
    }
    /* Duree d'execution d'abord, lecture ensuite : on lit l'etat de la broche
       a la fin de l'acces, comme le processeur echantillonne son registre
       d'entree - la reponse d'un peripherique au front emis juste avant est
       alors visible. */
    if (yield_until(g_current->sim_time + g_current->gpio_op_time, 0) != 0) return NULL;
    EnterCriticalSection(&g_current->cs);
    int v = g_current->pin_sensed_value[idx];
    LeaveCriticalSection(&g_current->cs);
    return PyBool_FromLong(v);
}

/* machine.ADC(n) : la broche passe en entree analogique. Sur le RP2040, cela
   coupe son etage d'entree numerique : ses variations ne declenchent plus
   d'IRQ et ne reveillent plus un sleep(), meme quand la tension franchit le
   seuil logique (cf. adc_claimed dans PyRuntime_sync), et ses tirages internes
   sont coupes. Pin(n, mode) la rend au GPIO (native_pin_init). */
static PyObject* native_adc_init(PyObject* self, PyObject* args) {
    REQUIRE_WORKER();
    int id;
    if (!PyArg_ParseTuple(args, "i", &id)) return NULL;
    int idx = resolve_pin_index(id);
    if (idx < 0 || idx == LED_PIN_INDEX) {
        PyErr_Format(PyExc_ValueError, "GPIO %d not supported as ADC input (0-%d only)", id, LED_PIN_INDEX - 1);
        return NULL;
    }
    EnterCriticalSection(&g_current->cs);
    g_current->adc_claimed[idx] = 1;
    g_current->pin_pull[idx] = PIN_PULL_NONE;   /* adc_gpio_init coupe aussi les tirages : la mesure n'est pas faussee */
    LeaveCriticalSection(&g_current->cs);
    if (yield_to_modelica(g_current->sim_time) != 0) return NULL;
    Py_RETURN_NONE;
}

static PyObject* native_adc_read(PyObject* self, PyObject* args) {
    REQUIRE_WORKER();
    int id;
    if (!PyArg_ParseTuple(args, "i", &id)) return NULL;
    int idx = resolve_pin_index(id);
    if (idx < 0 || idx == LED_PIN_INDEX) {
        PyErr_Format(PyExc_ValueError, "GPIO %d not supported as ADC input (0-%d only)", id, LED_PIN_INDEX - 1);
        return NULL;
    }
    if (yield_to_modelica(g_current->sim_time) != 0) return NULL;
    EnterCriticalSection(&g_current->cs);
    double v = g_current->pin_analog_value[idx];
    LeaveCriticalSection(&g_current->cs);
    return PyFloat_FromDouble(v);
}

static PyObject* native_pwm_set_freq(PyObject* self, PyObject* args) {
    REQUIRE_WORKER();
    int id;
    double freq;
    if (!PyArg_ParseTuple(args, "id", &id, &freq)) return NULL;
    int idx = resolve_pin_index(id);
    if (idx < 0) {
        PyErr_Format(PyExc_ValueError, "GPIO %d not supported (0-%d, or %d for the on-board LED)", id, LED_PIN_INDEX - 1, LED_PIN_ID);
        return NULL;
    }
    if (freq < 0) {
        /* PyErr_Format (PyUnicode_FromFormat) ne supporte pas %f - pas de conversion
           flottante native, seulement entiers/chaines/pointeurs (cf. doc C API Python).
           Formater la valeur soi-meme avec snprintf puis l'inserer via %s. */
        char freq_str[64];
        snprintf(freq_str, sizeof(freq_str), "%f", freq);
        PyErr_Format(PyExc_ValueError, "negative PWM frequency (%s)", freq_str);
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
    REQUIRE_WORKER();
    int id;
    double duty;
    if (!PyArg_ParseTuple(args, "id", &id, &duty)) return NULL;
    int idx = resolve_pin_index(id);
    if (idx < 0) {
        PyErr_Format(PyExc_ValueError, "GPIO %d not supported (0-%d, or %d for the on-board LED)", id, LED_PIN_INDEX - 1, LED_PIN_ID);
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
    REQUIRE_WORKER();
    int id;
    if (!PyArg_ParseTuple(args, "i", &id)) return NULL;
    int idx = resolve_pin_index(id);
    if (idx < 0) {
        PyErr_Format(PyExc_ValueError, "GPIO %d not supported (0-%d, or %d for the on-board LED)", id, LED_PIN_INDEX - 1, LED_PIN_ID);
        return NULL;
    }
    EnterCriticalSection(&g_current->cs);
    g_current->pwm_freq[idx] = 0;  /* retombe en sortie numerique classique, pilotee par pin_driven_value (bas par defaut) */
    LeaveCriticalSection(&g_current->cs);
    if (yield_to_modelica(g_current->sim_time) != 0) return NULL;
    Py_RETURN_NONE;
}

static PyObject* native_sleep(PyObject* self, PyObject* args) {
    REQUIRE_WORKER();
    double seconds;
    if (!PyArg_ParseTuple(args, "d", &seconds)) return NULL;
    double wake_at = g_current->sim_time + (seconds > 0 ? seconds : 0);
    if (yield_to_modelica(wake_at) != 0) return NULL;
    Py_RETURN_NONE;
}

/* machine.idle() : sur le RP2040, le coeur s'endort jusqu'a la prochaine
   interruption - au plus tard le tic systeme de 1 ms. Ici : attente jusqu'a la
   prochaine milliseconde ronde, ecourtee par une transition d'entree comme un
   sleep(). */
static PyObject* native_idle(PyObject* self, PyObject* args) {
    REQUIRE_WORKER();
    double wake_at = (floor(g_current->sim_time * 1000.0 + PYRUNTIME_EPS) + 1.0) / 1000.0;
    if (yield_to_modelica(wake_at) != 0) return NULL;
    Py_RETURN_NONE;
}

/* machine.disable_irq() / enable_irq(state) : masque les callbacks IRQ et
   Timer (differes, pas perdus - cf. run_due_callbacks) et rend l'etat
   precedent, a repasser a enable_irq() comme en MicroPython. Pas de point de
   synchro : rien ne change cote Modelica. */
static PyObject* native_disable_irq(PyObject* self, PyObject* args) {
    REQUIRE_WORKER();
    EnterCriticalSection(&g_current->cs);
    int previous = g_current->irq_disabled;
    g_current->irq_disabled = 1;
    LeaveCriticalSection(&g_current->cs);
    return PyLong_FromLong(previous);
}

static PyObject* native_enable_irq(PyObject* self, PyObject* args) {
    REQUIRE_WORKER();
    int state = 0;
    if (!PyArg_ParseTuple(args, "|i", &state)) return NULL;
    EnterCriticalSection(&g_current->cs);
    g_current->irq_disabled = state ? 1 : 0;
    LeaveCriticalSection(&g_current->cs);
    /* Demasquees : ce qui est arrive pendant le masquage s'execute tout de suite. */
    if (!state && run_due_callbacks(g_current) != 0) return NULL;
    Py_RETURN_NONE;
}

/* Arrondi, surtout pas troncature : l'heure simulee d'un reveil est souvent un
   poil sous la valeur ronde (0.2 atteint en 0.19999999999999998 par le tick
   periodique, accepte grace a PYRUNTIME_EPS ; 0.7 + 0.1 = 0.79999999999999993
   en double) - un cast en entier rendait alors 199 ou 799 au lieu de 200 ou
   800, une milliseconde d'erreur dans les calculs du script. */
static PyObject* native_ticks_ms(PyObject* self, PyObject* args) {
    REQUIRE_WORKER();
    return PyLong_FromLongLong(llround(g_current->sim_time * 1000.0));
}

/* Vraie resolution a la microseconde (et non ticks_ms() * 1000), arrondie pour
   la meme raison. Un double garde ici bien plus que la microseconde : 1 h de
   temps simule = 3,6e9 us, a 16 chiffres significatifs. */
static PyObject* native_ticks_us(PyObject* self, PyObject* args) {
    REQUIRE_WORKER();
    return PyLong_FromLongLong(llround(g_current->sim_time * 1000000.0));
}

/* --- machine.Pin.irq() --- */

static PyObject* native_pin_irq_set(PyObject* self, PyObject* args) {
    REQUIRE_WORKER();
    int id, trigger;
    PyObject* pin_self;
    PyObject* handler;
    if (!PyArg_ParseTuple(args, "iOOi", &id, &pin_self, &handler, &trigger)) return NULL;
    int idx = resolve_pin_index(id);
    if (idx < 0) {
        PyErr_Format(PyExc_ValueError, "GPIO %d not supported (0-%d, or %d for the on-board LED)", id, LED_PIN_INDEX - 1, LED_PIN_ID);
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
