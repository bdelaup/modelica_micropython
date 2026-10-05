/* machine.I2CTarget : cible (esclave) I2C du microcontroleur, en drain ouvert sur
   deux broches GPx - ce qui permet a un MCU d'etre le peripherique I2C d'un
   autre MCU (cf. requirements.md, decision "I2C cible cote microcontroleur").

   Partie de l'implementation du runtime Python, incluse TEXTUELLEMENT par
   PyRuntimeImpl.c (fichier chapeau), apres pyruntime_i2c.c dont elle reprend le
   pilotage des lignes (i2c_drive). Ce fichier n'est jamais compile seul.

   Le decodage du bus est celui des peripheriques I2C (i2ctarget.c, partage) ;
   ne reste ici que ce que le microcontroleur fait des octets, par les crochets
   du moteur, appeles sur le thread Modelica pendant PyRuntime_sync :
     - MODE MEMOIRE (mem = bytearray) : tout se passe en C. Les premiers octets
       ecrits (mem_addrsize bits) choisissent l'adresse memoire, les suivants y
       sont ecrits, une lecture sort la memoire a partir de cette adresse ;
       l'adresse avance et reboucle. Le C ecrit directement dans le tampon du
       bytearray (Py_buffer tenu depuis l'init, taille figee) SANS le GIL : le
       worker est gare pendant PyRuntime_sync (alternance stricte des tours),
       personne d'autre n'y touche. Continue de fonctionner apres la fin du
       programme, comme le materiel.
     - SANS MEMOIRE : les octets recus vont dans une file lue par readinto(), les
       octets a sortir viennent d'une file remplie par write().
   IRQ : un evenement dont le declencheur est demande pose un drapeau, et
   PyRuntime_sync donne aussitot au worker un "pitstop" pour executer le
   gestionnaire, AU MEME INSTANT simule. Pour IRQ_READ_REQ, le moteur differe
   l'octet a sortir (I2CT_DEFER, SDA relachee) : le gestionnaire appelle write(),
   puis i2ct_resume() sort l'octet - avant que Modelica ne fasse evoluer SDA.
   C'est ce qui remplace le clock stretching, non modelise. */

#define I2CT_IRQ_ADDR_MATCH_READ 0x01   /* valeurs reprises cote shim (I2CTarget.IRQ_*) */
#define I2CT_IRQ_ADDR_MATCH_WRITE 0x02
#define I2CT_IRQ_READ_REQ 0x04
#define I2CT_IRQ_WRITE_REQ 0x08
#define I2CT_IRQ_END_READ 0x10
#define I2CT_IRQ_END_WRITE 0x20

static void i2ct_flag(struct PyRuntimeHandle* h, int flag) {
    struct I2cTargetSide* s = &h->i2ct;
    if (s->irq_handler && (s->irq_trigger & flag)) {
        s->irq_pending |= flag;
    }
}

/* Un gestionnaire peut-il encore repondre au meme instant ? */
static int i2ct_can_defer(struct PyRuntimeHandle* h) {
    struct I2cTargetSide* s = &h->i2ct;
    return s->irq_handler && (s->irq_trigger & I2CT_IRQ_READ_REQ)
        && !h->script_done && !h->script_error && !h->irq_disabled;
}

/* --- crochets du moteur (thread Modelica, worker gare) --- */

static void i2ct_hook_addr_match(void* ctx, int addr, int read) {
    struct PyRuntimeHandle* h = (struct PyRuntimeHandle*) ctx;
    struct I2cTargetSide* s = &h->i2ct;
    if (!read) {
        s->mem_addr_seen = 0;
        s->mem_wrote = 0;
    }
    i2ct_flag(h, read ? I2CT_IRQ_ADDR_MATCH_READ : I2CT_IRQ_ADDR_MATCH_WRITE);
}

static void i2ct_hook_write_byte(void* ctx, int addr, unsigned char b) {
    struct PyRuntimeHandle* h = (struct PyRuntimeHandle*) ctx;
    struct I2cTargetSide* s = &h->i2ct;
    if (s->has_mem) {
        if (s->mem_addr_seen < s->mem_addr_bytes) {
            s->memaddr = (s->mem_addr_seen == 0 ? 0u : s->memaddr << 8) | b;
            if (++s->mem_addr_seen == s->mem_addr_bytes) {
                s->memaddr %= (unsigned int) s->mem.len;
            }
            return;
        }
        ((unsigned char*) s->mem.buf)[s->memaddr] = b;
        s->memaddr = (s->memaddr + 1) % (unsigned int) s->mem.len;
        s->mem_wrote = 1;
        return;
    }
    if (s->rx_len < I2CT_BUF_MAX) {
        s->rx[s->rx_len++] = b;   /* file pleine : octet perdu, comme un FIFO materiel */
    }
    i2ct_flag(h, I2CT_IRQ_WRITE_REQ);
}

static void i2ct_hook_write_end(void* ctx, int addr, const unsigned char* data, int len) {
    struct PyRuntimeHandle* h = (struct PyRuntimeHandle*) ctx;
    /* Comme MicroPython : pas d'IRQ_END_WRITE pour une ecriture qui n'a fait que
       choisir l'adresse memoire (prelude d'une lecture). */
    if (h->i2ct.has_mem && !h->i2ct.mem_wrote) {
        return;
    }
    i2ct_flag(h, I2CT_IRQ_END_WRITE);
}

static int i2ct_hook_read_byte(void* ctx, int addr, int may_defer) {
    struct PyRuntimeHandle* h = (struct PyRuntimeHandle*) ctx;
    struct I2cTargetSide* s = &h->i2ct;
    if (s->has_mem) {
        int b = ((unsigned char*) s->mem.buf)[s->memaddr];
        s->memaddr = (s->memaddr + 1) % (unsigned int) s->mem.len;
        return b;
    }
    if (s->tx_pos < s->tx_len) {
        int b = s->tx[s->tx_pos++];
        if (s->tx_pos >= s->tx_len) {
            s->tx_pos = s->tx_len = 0;
        }
        return b;
    }
    if (may_defer && i2ct_can_defer(h)) {
        i2ct_flag(h, I2CT_IRQ_READ_REQ);
        return I2CT_DEFER;
    }
    return 0xFF;   /* rien a sortir : ligne relachee */
}

static void i2ct_hook_read_end(void* ctx, int addr, const unsigned char* data, int len) {
    i2ct_flag((struct PyRuntimeHandle*) ctx, I2CT_IRQ_END_READ);
}

static const struct I2cTargetHooks I2CT_MCU_HOOKS = {
    i2ct_hook_addr_match, i2ct_hook_write_byte, i2ct_hook_write_end,
    i2ct_hook_read_byte, i2ct_hook_read_end
};

/* --- point de synchro (PyRuntime_sync, thread Modelica) --- */

/* Avance le decodeur sur les niveaux courants et applique la sortie SDA. */
static void i2ct_step(struct PyRuntimeHandle* h, const int* pinBoolIn) {
    struct I2cTargetSide* s = &h->i2ct;
    if (!s->configured) {
        return;
    }
    int low = i2ct_sync(&s->eng, pinBoolIn[s->scl_pin], pinBoolIn[s->sda_pin]);
    i2c_drive(h, s->sda_pin, low);
}

/* Apres le pitstop : sort l'octet differe (IRQ_READ_REQ) - ou 0xFF si le
   gestionnaire n'a rien fourni. */
static void i2ct_finish(struct PyRuntimeHandle* h) {
    struct I2cTargetSide* s = &h->i2ct;
    if (!s->configured || !s->eng.read_deferred) {
        return;
    }
    i2ct_resume(&s->eng);
    i2c_drive(h, s->sda_pin, s->eng.drive_low);
}

/* --- natives --- */

static void i2ct_release(struct PyRuntimeHandle* h) {
    struct I2cTargetSide* s = &h->i2ct;
    if (s->configured) {
        i2c_drive(h, s->sda_pin, 0);
        h->i2c_claimed[s->scl_pin] = 0;
        h->i2c_claimed[s->sda_pin] = 0;
    }
    if (s->has_mem) {
        PyBuffer_Release(&s->mem);
    }
    Py_CLEAR(s->irq_handler);
    Py_CLEAR(s->irq_self);
    memset(s, 0, sizeof(*s));
    s->scl_pin = -1;
    s->sda_pin = -1;
}

/* i2ct_init(id, addr, addrsize, scl, sda, mem | None, mem_addrsize) */
static PyObject* native_i2ct_init(PyObject* self, PyObject* args) {
    REQUIRE_WORKER();
    struct PyRuntimeHandle* h = g_current;
    int id, addr, addrsize, scl_id, sda_id, mem_addrsize;
    PyObject* mem;
    if (!PyArg_ParseTuple(args, "iiiiiOi", &id, &addr, &addrsize, &scl_id, &sda_id, &mem, &mem_addrsize)) return NULL;
    if (resolve_i2c_index(id) < 0) {
        PyErr_Format(PyExc_ValueError, "I2CTarget %d not supported (single target, I2CTarget(0))", id);
        return NULL;
    }
    if (addrsize != 7) {
        PyErr_SetString(PyExc_ValueError, "only 7-bit addresses are supported (addrsize=7)");
        return NULL;
    }
    if (addr < 0 || addr > 0x7F) {
        PyErr_Format(PyExc_ValueError, "I2C address %d out of range (0-127, 7-bit address)", addr);
        return NULL;
    }
    int scl = require_pin(scl_id, PIN_CAP_DIGITAL | PIN_CAP_EXTERNAL, "SCL pin");
    if (scl < 0) return NULL;
    int sda = require_pin(sda_id, PIN_CAP_DIGITAL | PIN_CAP_EXTERNAL, "SDA pin");
    if (sda < 0) return NULL;
    if (scl == sda) {
        PyErr_SetString(PyExc_ValueError, "SCL and SDA must be two different pins");
        return NULL;
    }
    if (h->i2c_configured && (scl == h->i2c_scl_pin || scl == h->i2c_sda_pin || sda == h->i2c_scl_pin || sda == h->i2c_sda_pin)) {
        PyErr_SetString(PyExc_ValueError, "SCL/SDA pins already used by machine.I2C");
        return NULL;
    }
    if (mem != Py_None && mem_addrsize != 0 && mem_addrsize != 8 && mem_addrsize != 16 && mem_addrsize != 24 && mem_addrsize != 32) {
        PyErr_SetString(PyExc_ValueError, "mem_addrsize must be 0, 8, 16, 24 or 32");
        return NULL;
    }
    Py_buffer view;
    int has_mem = 0;
    if (mem != Py_None) {
        if (PyObject_GetBuffer(mem, &view, PyBUF_WRITABLE) != 0) {
            return NULL;   /* TypeError : bytearray (ou tampon modifiable) attendu */
        }
        if (view.len <= 0) {
            PyBuffer_Release(&view);
            PyErr_SetString(PyExc_ValueError, "mem must not be empty");
            return NULL;
        }
        has_mem = 1;
    }

    EnterCriticalSection(&h->cs);
    i2ct_release(h);
    struct I2cTargetSide* s = &h->i2ct;
    s->configured = 1;
    s->scl_pin = scl;
    s->sda_pin = sda;
    if (has_mem) {
        s->mem = view;
        s->has_mem = 1;
        s->mem_addr_bytes = mem_addrsize / 8;
    }
    s->eng.addresses[0] = addr;
    s->eng.n_addr = 1;
    i2ct_init(&s->eng, &I2CT_MCU_HOOKS, h);
    h->i2c_claimed[scl] = 1;     /* fronts du bus : ni reveil du script ni IRQ GPIO */
    h->i2c_claimed[sda] = 1;
    h->pwm_freq[scl] = 0;
    h->pwm_freq[sda] = 0;
    h->pin_pull[scl] = PIN_PULL_UP;   /* comme le maitre (pyruntime_i2c.c) */
    h->pin_pull[sda] = PIN_PULL_UP;
    h->pin_is_output[scl] = 0;  /* la cible ne tient jamais SCL (pas de clock stretching) */
    i2c_drive(h, sda, 0);
    LeaveCriticalSection(&h->cs);
    if (yield_to_modelica(h->sim_time) != 0) return NULL;
    Py_RETURN_NONE;
}

static PyObject* native_i2ct_deinit(PyObject* self, PyObject* args) {
    REQUIRE_WORKER();
    struct PyRuntimeHandle* h = g_current;
    EnterCriticalSection(&h->cs);
    i2ct_release(h);
    LeaveCriticalSection(&h->cs);
    if (yield_to_modelica(h->sim_time) != 0) return NULL;
    Py_RETURN_NONE;
}

/* i2ct_irq(handler | None, trigger, target) */
static PyObject* native_i2ct_irq(PyObject* self, PyObject* args) {
    REQUIRE_WORKER();
    struct PyRuntimeHandle* h = g_current;
    PyObject* handler;
    PyObject* target;
    int trigger;
    if (!PyArg_ParseTuple(args, "OiO", &handler, &trigger, &target)) return NULL;
    if (handler != Py_None && !PyCallable_Check(handler)) {
        PyErr_SetString(PyExc_TypeError, "handler must be callable or None");
        return NULL;
    }
    EnterCriticalSection(&h->cs);
    struct I2cTargetSide* s = &h->i2ct;
    Py_CLEAR(s->irq_handler);
    Py_CLEAR(s->irq_self);
    if (handler != Py_None) {
        Py_INCREF(handler);
        Py_INCREF(target);
        s->irq_handler = handler;
        s->irq_self = target;
    }
    s->irq_trigger = trigger;
    s->irq_pending = 0;
    LeaveCriticalSection(&h->cs);
    Py_RETURN_NONE;
}

/* Drapeaux de l'evenement en cours de traitement (irq().flags()). */
static PyObject* native_i2ct_flags(PyObject* self, PyObject* args) {
    REQUIRE_WORKER();
    return PyLong_FromLong(g_current->i2ct.irq_flags);
}

static PyObject* native_i2ct_memaddr(PyObject* self, PyObject* args) {
    REQUIRE_WORKER();
    return PyLong_FromUnsignedLong(g_current->i2ct.memaddr);
}

/* readinto(buf) : octets recus du maitre (mode sans memoire). Instantane. */
static PyObject* native_i2ct_readinto(PyObject* self, PyObject* args) {
    REQUIRE_WORKER();
    struct PyRuntimeHandle* h = g_current;
    Py_buffer buf;
    if (!PyArg_ParseTuple(args, "w*", &buf)) return NULL;
    EnterCriticalSection(&h->cs);
    struct I2cTargetSide* s = &h->i2ct;
    int n = s->rx_len < (int) buf.len ? s->rx_len : (int) buf.len;
    memcpy(buf.buf, s->rx, (size_t) n);
    memmove(s->rx, s->rx + n, (size_t) (s->rx_len - n));
    s->rx_len -= n;
    LeaveCriticalSection(&h->cs);
    PyBuffer_Release(&buf);
    return PyLong_FromLong(n);
}

/* write(buf) : octets a sortir aux prochaines lectures du maitre. Instantane. */
static PyObject* native_i2ct_write(PyObject* self, PyObject* args) {
    REQUIRE_WORKER();
    struct PyRuntimeHandle* h = g_current;
    Py_buffer buf;
    if (!PyArg_ParseTuple(args, "y*", &buf)) return NULL;
    EnterCriticalSection(&h->cs);
    struct I2cTargetSide* s = &h->i2ct;
    if (s->tx_pos > 0) {
        memmove(s->tx, s->tx + s->tx_pos, (size_t) (s->tx_len - s->tx_pos));
        s->tx_len -= s->tx_pos;
        s->tx_pos = 0;
    }
    int room = I2CT_BUF_MAX - s->tx_len;
    int n = (int) buf.len < room ? (int) buf.len : room;
    memcpy(s->tx + s->tx_len, buf.buf, (size_t) n);
    s->tx_len += n;
    LeaveCriticalSection(&h->cs);
    PyBuffer_Release(&buf);
    return PyLong_FromLong(n);
}
