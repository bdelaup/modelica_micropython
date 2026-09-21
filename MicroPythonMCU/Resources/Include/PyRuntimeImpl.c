/* Jalon M5 : thread worker + condition variable pour interception de sleep()
   et des appels au shim machine/time comme points de synchro potentiels
   (cf. requirements.md, decisions "Mecanisme d'execution" et "Protection
   contre un script qui ne rend jamais la main"). Windows uniquement (v0). */

#include "PyRuntimeImpl.h"
#include <Python.h>
#include <windows.h>
#include <process.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include "ModelicaUtilities.h"

#define NUM_PINS 9          /* 0-7 = GP0-GP7 (broches externes) ; 8 = LED embarquee (interne, pas de connecteur electrique) */
#define LED_PIN_INDEX 8
#define LED_PIN_ID 25       /* numero reel de la broche sur le Raspberry Pi Pico, non expose par MCU */
#define TURN_MODELICA 0
#define TURN_WORKER 1
#define PYRUNTIME_EPS 1e-9

#define MAX_TIMERS 4                 /* pool fixe de machine.Timer, meme esprit que les 8 broches GPIO plutot que 29 */
#define TIMER_MIN_PERIOD 0.001       /* plancher (1 ms) : evite une tempete d'evenements Modelica a duree simulee nulle si period<=0, cf. requirements.md */
#define IRQ_TRIGGER_RISING 1
#define IRQ_TRIGGER_FALLING 2

struct PyRuntimeHandle {
    char* scriptPath;

    CRITICAL_SECTION cs;
    CONDITION_VARIABLE cv;
    int turn;

    double sim_time;
    double wake_requested_at;
    int wake_pending;
    int wake_had_input_change;  /* pose par PyRuntime_sync avant de reveiller le worker : distingue un reveil "authentique" (deadline propre du worker atteinte, ou vraie transition d'entree) d'un simple "pitstop" (callback de Timer/IRQ a executer, sans faire revenir l'appel bloquant en cours), cf. yield_to_modelica */

    int pin_is_output[NUM_PINS];
    int pin_driven_value[NUM_PINS];
    int pin_sensed_value[NUM_PINS];
    double pin_analog_value[NUM_PINS];
    double pwm_freq[NUM_PINS];   /* 0 = pas en mode PWM */
    double pwm_duty[NUM_PINS];   /* 0-1, pertinent seulement si pwm_freq > 0 */

    /* machine.Pin.irq() : au plus un handler par broche */
    PyObject* pin_irq_handler[NUM_PINS];  /* NULL = pas de callback enregistre */
    PyObject* pin_irq_self[NUM_PINS];     /* l'instance Python Pin, passee en argument au handler comme sur le vrai MicroPython */
    int pin_irq_trigger[NUM_PINS];        /* bitmask IRQ_TRIGGER_RISING/FALLING */
    int pin_irq_pending[NUM_PINS];        /* pose par PyRuntime_sync sur un front correspondant, consomme par run_due_callbacks */

    /* machine.Timer : pool fixe de MAX_TIMERS minuteurs logiciels */
    int timer_allocated[MAX_TIMERS];   /* slot occupe par un objet Timer() (initialise ou non) */
    int timer_active[MAX_TIMERS];      /* arme (init() appele, pas encore deinit()/tire une fois pour un ONE_SHOT) */
    double timer_period[MAX_TIMERS];   /* secondes */
    int timer_mode[MAX_TIMERS];        /* 0 = ONE_SHOT, 1 = PERIODIC */
    double timer_next_fire[MAX_TIMERS]; /* temps simule absolu */
    PyObject* timer_callback[MAX_TIMERS];
    PyObject* timer_self[MAX_TIMERS];  /* l'instance Python Timer, passee en argument au callback comme sur le vrai MicroPython */

    int script_done;
    int script_error;
    char* error_message;

    HANDLE thread;
};

/* Handle du PyRuntime en cours d'execution sur le thread worker courant.
   Un seul worker actif a la fois (restriction v0 "une seule instance"),
   donc une variable globale suffit pour que les fonctions natives du shim
   (appelees depuis Python, qui ne recoivent pas le handle directement)
   retrouvent leur contexte. */
static struct PyRuntimeHandle* g_current = NULL;

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

static PyMethodDef native_methods[] = {
    {"pin_init", native_pin_init, METH_VARARGS, "Configure la direction d'une broche"},
    {"pin_write", native_pin_write, METH_VARARGS, "Pilote une broche (si en sortie)"},
    {"pin_read", native_pin_read, METH_VARARGS, "Lit l'etat resolu d'une broche"},
    {"pin_irq_set", native_pin_irq_set, METH_VARARGS, "Enregistre/efface le callback IRQ d'une broche"},
    {"adc_read", native_adc_read, METH_VARARGS, "Lit la tension brute (V) mesuree sur une broche ADC"},
    {"pwm_set_freq", native_pwm_set_freq, METH_VARARGS, "Configure la frequence PWM (Hz) d'une broche, la prend en sortie"},
    {"pwm_set_duty", native_pwm_set_duty, METH_VARARGS, "Configure le rapport cyclique PWM (0-1) d'une broche"},
    {"pwm_deinit", native_pwm_deinit, METH_VARARGS, "Arrete le PWM sur une broche (retombe en sortie numerique classique)"},
    {"timer_new", native_timer_new, METH_VARARGS, "Alloue un slot de Timer() dans le pool fixe"},
    {"timer_init", native_timer_init, METH_VARARGS, "Arme un Timer (periode, mode, callback)"},
    {"timer_deinit", native_timer_deinit, METH_VARARGS, "Arrete et libere un Timer"},
    {"sleep", native_sleep, METH_VARARGS, "Attend N secondes de temps simule"},
    {"ticks_ms", native_ticks_ms, METH_VARARGS, "Horloge simulee, en millisecondes"},
    {NULL, NULL, 0, NULL}
};

static struct PyModuleDef native_module_def = {
    PyModuleDef_HEAD_INIT, "_pyruntime_native", NULL, -1, native_methods,
    NULL, NULL, NULL, NULL
};

static PyObject* PyInit_pyruntime_native(void) {
    return PyModule_Create(&native_module_def);
}

/* --- Shim machine/time, defini en Python par dessus le module natif --- */

static const char* SHIM_BOOTSTRAP =
    "import sys, types, _pyruntime_native as _native\n"
    "\n"
    "class Pin:\n"
    "    IN = 0\n"
    "    OUT = 1\n"
    "    PULL_UP = 2\n"
    "    PULL_DOWN = 3\n"
    "    LED = 25\n"  /* doit rester aligne sur LED_PIN_ID cote C (PyRuntimeImpl.c) */
    "    IRQ_RISING = 1\n"   /* doit rester aligne sur IRQ_TRIGGER_RISING cote C */
    "    IRQ_FALLING = 2\n"  /* doit rester aligne sur IRQ_TRIGGER_FALLING cote C */
    "    def __init__(self, id, mode=None, pull=None):\n"
    "        if id == 'LED':\n"
    "            id = Pin.LED\n"
    "        self.id = id\n"
    "        if mode is not None:\n"
    "            _native.pin_init(self.id, 1 if mode == Pin.OUT else 0)\n"
    "    def value(self, x=None):\n"
    "        if x is None:\n"
    "            return 1 if _native.pin_read(self.id) else 0\n"
    "        _native.pin_write(self.id, 1 if x else 0)\n"
    "    def on(self):\n"
    "        _native.pin_write(self.id, 1)\n"
    "    def off(self):\n"
    "        _native.pin_write(self.id, 0)\n"
    "    def toggle(self):\n"
    "        self.value(0 if self.value() else 1)\n"
    "    def irq(self, handler=None, trigger=IRQ_RISING | IRQ_FALLING, **kwargs):\n"
    "        _native.pin_irq_set(self.id, self, handler, trigger)\n"
    "\n"
    "class ADC:\n"
    "    def __init__(self, id):\n"
    "        if isinstance(id, Pin):\n"
    "            id = id.id\n"
    "        self.id = id\n"
    "    def read_u16(self):\n"
    "        v = _native.adc_read(self.id)\n"
    "        raw = round(v / 3.3 * 65535)\n"
    "        return 0 if raw < 0 else (65535 if raw > 65535 else raw)\n"
    "\n"
    "class PWM:\n"
    "    def __init__(self, pin, freq=None, duty_u16=None):\n"
    "        if isinstance(pin, Pin):\n"
    "            pin = pin.id\n"
    "        self.id = pin\n"
    "        self._freq = 0\n"
    "        self._duty = 0\n"
    "        if freq is not None:\n"
    "            self.freq(freq)\n"
    "        if duty_u16 is not None:\n"
    "            self.duty_u16(duty_u16)\n"
    "    def freq(self, f=None):\n"
    "        if f is None:\n"
    "            return self._freq\n"
    "        _native.pwm_set_freq(self.id, float(f))\n"
    "        self._freq = int(f)\n"
    "    def duty_u16(self, d=None):\n"
    "        if d is None:\n"
    "            return self._duty\n"
    "        _native.pwm_set_duty(self.id, d / 65535.0)\n"
    "        self._duty = d\n"
    "    def deinit(self):\n"
    "        _native.pwm_deinit(self.id)\n"
    "        self._freq = 0\n"
    "\n"
    "class Timer:\n"
    "    ONE_SHOT = 0\n"
    "    PERIODIC = 1\n"
    "    def __init__(self, id=-1):\n"
    "        self._slot = _native.timer_new()\n"
    "    def init(self, period=1000, mode=PERIODIC, callback=None):\n"
    "        _native.timer_init(self._slot, period / 1000.0, mode, callback, self)\n"
    "    def deinit(self):\n"
    "        _native.timer_deinit(self._slot)\n"
    "\n"
    "_machine = types.ModuleType('machine')\n"
    "_machine.Pin = Pin\n"
    "_machine.ADC = ADC\n"
    "_machine.PWM = PWM\n"
    "_machine.Timer = Timer\n"
    "sys.modules['machine'] = _machine\n"
    "\n"
    "def sleep(s):\n"
    "    _native.sleep(float(s))\n"
    "def sleep_ms(ms):\n"
    "    _native.sleep(ms / 1000.0)\n"
    "def sleep_us(us):\n"
    "    _native.sleep(us / 1000000.0)\n"
    "def ticks_ms():\n"
    "    return _native.ticks_ms()\n"
    "def ticks_us():\n"
    "    return _native.ticks_ms() * 1000\n"
    "def ticks_diff(a, b):\n"
    "    return a - b\n"
    "\n"
    "_time = types.ModuleType('time')\n"
    "_time.sleep = sleep\n"
    "_time.sleep_ms = sleep_ms\n"
    "_time.sleep_us = sleep_us\n"
    "_time.ticks_ms = ticks_ms\n"
    "_time.ticks_us = ticks_us\n"
    "_time.ticks_diff = ticks_diff\n"
    "sys.modules['time'] = _time\n";

/* --- Thread worker --- */

static unsigned __stdcall worker_main(void* arg) {
    struct PyRuntimeHandle* h = (struct PyRuntimeHandle*) arg;
    PyGILState_STATE gstate = PyGILState_Ensure();
    g_current = h;

    /* Premier tour : attendre que Modelica nous cede la main (t=0, cf. MCU "when initial()"). */
    EnterCriticalSection(&h->cs);
    while (h->turn != TURN_WORKER) {
        SleepConditionVariableCS(&h->cv, &h->cs, INFINITE);
    }
    LeaveCriticalSection(&h->cs);

    FILE* f = fopen(h->scriptPath, "rb");
    if (!f) {
        h->script_error = 1;
        h->error_message = strdup("impossible d'ouvrir le script");
    } else {
        fseek(f, 0, SEEK_END);
        long size = ftell(f);
        fseek(f, 0, SEEK_SET);
        char* buf = (char*) malloc((size_t) size + 1);
        fread(buf, 1, (size_t) size, f);
        buf[size] = '\0';
        fclose(f);

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
                     int addScriptDirToPath, const char* libraryPath) {
    PyStatus status;
    PyConfig config;

    PyConfig_InitPythonConfig(&config);
    config.site_import = 0;
    config.use_environment = 0;
    config.module_search_paths_set = 1;

    {
        /* Distribution "embeddable" : le stdlib est dans <home>\python312.zip, les
           modules d'extension .pyd sont directement dans <home>. */
        size_t home_len = strlen(pythonHome);
        char* zip_path = (char*) malloc(home_len + 32);
        sprintf(zip_path, "%s\\python312.zip", pythonHome);
        status = PyWideStringList_Append(&config.module_search_paths, Py_DecodeLocale(zip_path, NULL));
        free(zip_path);
        if (PyStatus_Exception(status)) {
            PyConfig_Clear(&config);
            ModelicaFormatError("PyRuntime: echec d'ajout de python312.zip au sys.path");
            return NULL;
        }
        status = PyWideStringList_Append(&config.module_search_paths, Py_DecodeLocale(pythonHome, NULL));
        if (PyStatus_Exception(status)) {
            PyConfig_Clear(&config);
            ModelicaFormatError("PyRuntime: echec d'ajout de %s au sys.path", pythonHome);
            return NULL;
        }
    }

    /* Import de modules auxiliaires (cf. requirements.md, decision "Import de
       modules auxiliaires") : ajoute au sys.path le dossier du script
       (addScriptDirToPath) et/ou celui d'une bibliotheque partagee
       (libraryPath, desactive si chaine vide) - meme mecanisme que le zip et
       pythonHome ci-dessus, juste 0-2 entrees de plus. */
    if (addScriptDirToPath) {
        char* dir = dirname_of(scriptPath);
        if (dir[0] != '\0') {
            status = PyWideStringList_Append(&config.module_search_paths, Py_DecodeLocale(dir, NULL));
            if (PyStatus_Exception(status)) {
                free(dir);
                PyConfig_Clear(&config);
                ModelicaFormatError("PyRuntime: echec d'ajout du dossier du script au sys.path");
                return NULL;
            }
        }
        free(dir);
    }
    if (libraryPath && libraryPath[0] != '\0') {
        char* dir = dirname_of(libraryPath);
        if (dir[0] != '\0') {
            status = PyWideStringList_Append(&config.module_search_paths, Py_DecodeLocale(dir, NULL));
            if (PyStatus_Exception(status)) {
                free(dir);
                PyConfig_Clear(&config);
                ModelicaFormatError("PyRuntime: echec d'ajout de libraryPath ('%s') au sys.path", libraryPath);
                return NULL;
            }
        }
        free(dir);
    }
    status = PyConfig_SetBytesString(&config, &config.home, pythonHome);
    if (PyStatus_Exception(status)) {
        PyConfig_Clear(&config);
        ModelicaFormatError("PyRuntime: echec de configuration de PYTHONHOME ('%s')", pythonHome);
        return NULL;
    }

    if (PyImport_AppendInittab("pyruntime_stdio", PyInit_pyruntime_stdio) != 0 ||
        PyImport_AppendInittab("_pyruntime_native", PyInit_pyruntime_native) != 0) {
        PyConfig_Clear(&config);
        ModelicaFormatError("PyRuntime: echec d'enregistrement des modules shim");
        return NULL;
    }

    status = Py_InitializeFromConfig(&config);
    PyConfig_Clear(&config);
    if (PyStatus_Exception(status)) {
        ModelicaFormatError("PyRuntime: echec d'initialisation de CPython (home='%s')", pythonHome);
        return NULL;
    }

    PyObject* relay = PyImport_ImportModule("pyruntime_stdio");
    if (relay) {
        PySys_SetObject("stdout", relay);
        PySys_SetObject("stderr", relay);
        Py_DECREF(relay);
    }

    struct PyRuntimeHandle* handle = (struct PyRuntimeHandle*) calloc(1, sizeof(struct PyRuntimeHandle));
    handle->scriptPath = strdup(scriptPath);
    InitializeCriticalSection(&handle->cs);
    InitializeConditionVariable(&handle->cv);
    handle->turn = TURN_MODELICA;

    /* Le shim doit exister dans l'interprete AVANT que le script ne fasse
       "import machine"/"import time" sur le thread worker. */
    g_current = handle;
    if (PyRun_SimpleString(SHIM_BOOTSTRAP) != 0) {
        ModelicaFormatError("PyRuntime: echec d'initialisation du shim machine/time");
        return NULL;
    }
    g_current = NULL;

    /* Le thread principal (celui-ci) ne rappellera plus l'API Python avant
       PyRuntime_destroy : on libere le GIL pour que le worker puisse
       l'acquerir via PyGILState_Ensure(). */
    PyEval_SaveThread();

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
        *nextWakeTime = 1.0e300; /* pas d'autre reveil attendu */
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
        if (!h->pin_is_output[i] && old_val != new_val) {
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
    if (input_changed || !h->wake_pending || currentTime + PYRUNTIME_EPS >= h->wake_requested_at || timer_due) {
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
    int done = h->script_done;
    int error = h->script_error;
    char* error_message = h->error_message;
    double wake_at = h->wake_pending ? h->wake_requested_at : currentTime;
    double next_timer = earliest_timer_deadline(h); /* recalcule : un Timer periodique peut avoir ete rearme pendant le drain ci-dessus */
    if (next_timer < wake_at) {
        wake_at = next_timer;
    }
    LeaveCriticalSection(&h->cs);

    if (error) {
        ModelicaFormatError("PyRuntime (%s): %s", h->scriptPath, error_message ? error_message : "erreur inconnue");
        return;
    }
    *nextWakeTime = done ? 1.0e300 : wake_at;
}
