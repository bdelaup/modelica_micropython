/* machine.I2C : maitre I2C en drain ouvert sur deux broches GPx, primitives
   natives exposees au script, et sequencement du bus.

   Partie de l'implementation du runtime Python, incluse TEXTUELLEMENT par
   PyRuntimeImpl.c (fichier chapeau) : une seule unite de compilation, donc
   pas de #include croise ici et aucune etape de build supplementaire - cf.
   requirements.md, decision "Structure du package et interface C du runtime
   Python". Ce fichier n'est jamais compile seul.

   ELECTRIQUE. Le pont GPIO du microcontroleur sert tel quel : tirer une ligne a
   la masse, c'est la mettre en sortie a l'etat bas ; la relacher, c'est la
   repasser en entree (interrupteur ouvert, haute impedance). La ligne ne remonte
   que par les resistances de tirage du bus, portees par les peripheriques
   (Internal.PartialI2cDevice, parametre usePullUp). Sans elles, une ligne
   relachee reste basse : le maitre le constate et leve OSError(ETIMEDOUT),
   comme un vrai bus sans tirage. Les tirages internes du RP2040 ne sont pas
   modelises (trop faibles pour un vrai bus, et c'est tout le propos pedagogique).

   SEQUENCEMENT. Tout avance par echeances (nextWakeTime), un QUART DE PERIODE
   d'horloge a la fois, sans aucun front a detecter cote maitre :
       bit : SCL basse -> [q] SDA positionnee -> [q] SCL relachee
             -> [q] SDA echantillonnee (et SCL verifiee haute) -> [q] SCL basse
   START (SDA descend pendant que SCL est haute), START repete et STOP (SDA
   monte pendant que SCL est haute) suivent les memes pas. Pas de clock
   stretching ni d'arbitrage multi-maitre en v0 : une SCL qui ne remonte pas
   est une erreur, pas une attente.

   Toutes les fonctions internes prennent le handle en parametre : seules les
   natives lisent g_current, en prevision d'un microcontroleur multi-instance
   (cf. requirements.md, TODO). */

enum {
    I2CM_IDLE = 0,
    I2CM_START_CHECK,       /* bus libre ? puis SDA basse (START) */
    I2CM_START_SCL_LOW,     /* SCL basse : debut du premier bit */
    I2CM_RS_SDA_RELEASE,    /* START repete, SCL basse : relacher SDA */
    I2CM_RS_SCL_RELEASE,    /* puis relacher SCL, et revenir a START_CHECK */
    I2CM_BIT_SET,           /* SCL basse : positionner SDA */
    I2CM_BIT_SCL_HIGH,      /* relacher SCL */
    I2CM_BIT_SAMPLE,        /* SCL haute : lire SDA */
    I2CM_BIT_SCL_LOW,       /* SCL basse : fin du bit */
    I2CM_STOP_SDA_LOW,      /* STOP : SDA basse pendant que SCL est basse */
    I2CM_STOP_SCL_RELEASE,
    I2CM_STOP_SDA_RELEASE,  /* SDA monte pendant que SCL est haute : STOP */
    I2CM_FINISH             /* temps de bus libre ecoule : resultat disponible */
};

/* --- lignes : tirer a la masse ou relacher --- */
static void i2c_drive(struct PyRuntimeHandle* h, int pin, int low) {
    h->pin_is_output[pin] = low ? 1 : 0;
    h->pin_driven_value[pin] = 0;
}
static void i2c_scl(struct PyRuntimeHandle* h, int low) { i2c_drive(h, h->i2c_scl_pin, low); }
static void i2c_sda(struct PyRuntimeHandle* h, int low) { i2c_drive(h, h->i2c_sda_pin, low); }

static double earliest_i2c_deadline(struct PyRuntimeHandle* h) {
    if (!h->i2c_configured || !h->i2cm.busy) {
        return 1.0e300;
    }
    return h->i2cm.next_time;
}

/* Termine la transaction (resultat disponible) et marque le reveil du script. */
static void i2c_complete(struct PyRuntimeHandle* h, int error) {
    struct I2cMaster* m = &h->i2cm;
    if (error && !m->error) {
        m->error = error;
    }
    m->busy = 0;
    m->done = 1;
    m->phase = I2CM_IDLE;
    m->next_time = 1.0e300;
    h->i2c_done_wake = 1;
}

/* Ligne bloquee : on relache tout et on abandonne, sans STOP (impossible). */
static void i2c_abort(struct PyRuntimeHandle* h, int error) {
    i2c_scl(h, 0);
    i2c_sda(h, 0);
    h->i2cm.held = 0;
    i2c_complete(h, error);
}

/* Charge l'octet suivant de la sequence, ou decide de la fin de segment.
   Appelee SCL basse, a la fin du bit d'acquittement de l'octet precedent. */
static int i2c_load_next(struct PyRuntimeHandle* h) {
    struct I2cMaster* m = &h->i2cm;
    m->bit = 0;
    m->index++;
    if (m->segment == 0 && m->has_write) {
        if (m->index < m->nwrite) {
            m->cur = m->wbuf[m->index];
            m->rx = 0;
            return I2CM_BIT_SET;
        }
        /* fin du segment d'ecriture : lecture derriere un START repete, ou fin */
        if (m->nread > 0) {
            m->segment = 1;
            m->index = -1;
            m->cur = (unsigned char) ((m->addr << 1) | 1);
            m->rx = 0;
            return I2CM_RS_SDA_RELEASE;
        }
        return m->stop ? I2CM_STOP_SDA_LOW : -1;
    }
    /* segment de lecture */
    if (m->index < m->nread) {
        m->cur = 0;
        m->rx = 1;
        return I2CM_BIT_SET;
    }
    return m->stop ? I2CM_STOP_SDA_LOW : -1;
}

/* Une action elementaire, celle programmee a next_time. La suivante est
   programmee un quart de periode plus tard, jamais au meme instant : Modelica
   doit d'abord laisser la ligne evoluer (charge du bus a travers les tirages). */
static void i2c_act(struct PyRuntimeHandle* h, double now, const int* pinBoolIn) {
    struct I2cMaster* m = &h->i2cm;
    int scl_high = pinBoolIn[h->i2c_scl_pin] ? 1 : 0;
    int sda_high = pinBoolIn[h->i2c_sda_pin] ? 1 : 0;
    int next = I2CM_IDLE;

    switch (m->phase) {
    case I2CM_START_CHECK:
        if (!scl_high || !sda_high) {
            /* bus occupe ou sans tirage : ligne restee basse */
            i2c_abort(h, I2C_ERR_ETIMEDOUT);
            return;
        }
        i2c_sda(h, 1);
        next = I2CM_START_SCL_LOW;
        break;
    case I2CM_START_SCL_LOW:
        i2c_scl(h, 1);
        m->bit = 0;
        next = I2CM_BIT_SET;
        break;
    case I2CM_RS_SDA_RELEASE:
        i2c_sda(h, 0);
        next = I2CM_RS_SCL_RELEASE;
        break;
    case I2CM_RS_SCL_RELEASE:
        i2c_scl(h, 0);
        next = I2CM_START_CHECK;
        break;
    case I2CM_BIT_SET:
        if (m->bit < 8) {
            /* emission : un 0 tire SDA, un 1 la relache ; reception : relachee */
            i2c_sda(h, m->rx ? 0 : !((m->cur >> (7 - m->bit)) & 1));
        } else if (m->rx) {
            /* acquittement donne par le maitre : ACK tant qu'il reste a lire, NACK sur le dernier */
            i2c_sda(h, m->index < m->nread - 1);
        } else {
            i2c_sda(h, 0);   /* acquittement donne par l'esclave : relacher */
        }
        next = I2CM_BIT_SCL_HIGH;
        break;
    case I2CM_BIT_SCL_HIGH:
        i2c_scl(h, 0);
        next = I2CM_BIT_SAMPLE;
        break;
    case I2CM_BIT_SAMPLE:
        if (!scl_high) {
            /* SCL relachee mais restee basse : pas de tirage, ou esclave qui
               etire l'horloge (non supporte en v0) */
            i2c_abort(h, I2C_ERR_ETIMEDOUT);
            return;
        }
        if (m->bit < 8) {
            if (m->rx) {
                m->cur = (unsigned char) ((m->cur << 1) | sda_high);
            }
        } else if (!m->rx) {
            m->ack = !sda_high;
        }
        next = I2CM_BIT_SCL_LOW;
        break;
    case I2CM_BIT_SCL_LOW:
        i2c_scl(h, 1);
        if (m->bit < 8) {
            m->bit++;
            next = I2CM_BIT_SET;
            break;
        }
        /* octet complet, acquittement compris */
        if (m->rx) {
            if (m->rcount < I2C_XFER_MAX) {
                m->rbuf[m->rcount++] = m->cur;
            }
        } else if (!m->ack) {
            /* NACK : sur l'adresse, personne ne repond (EIO, comme le port rp2) ;
               sur une donnee, l'esclave refuse la suite - on s'arrete la */
            if (m->index < 0) {
                m->error = I2C_ERR_EIO;
            }
            next = I2CM_STOP_SDA_LOW;
            break;
        } else if (m->index >= 0) {
            m->acks++;
        }
        next = i2c_load_next(h);
        if (next < 0) {
            /* stop=False : on garde le bus, SCL basse */
            m->held = 1;
            i2c_complete(h, 0);
            return;
        }
        break;
    case I2CM_STOP_SDA_LOW:
        i2c_sda(h, 1);
        next = I2CM_STOP_SCL_RELEASE;
        break;
    case I2CM_STOP_SCL_RELEASE:
        i2c_scl(h, 0);
        next = I2CM_STOP_SDA_RELEASE;
        break;
    case I2CM_STOP_SDA_RELEASE:
        i2c_sda(h, 0);
        m->held = 0;
        next = I2CM_FINISH;
        break;
    case I2CM_FINISH:
        i2c_complete(h, 0);
        return;
    default:
        return;
    }
    m->phase = next;
    m->next_time = now + m->quarter;
}

/* Appelee par PyRuntime_sync a chaque point de synchro. UNE action au plus par
   appel : Modelica rappelle la synchro plusieurs fois au meme instant, et la
   prochaine echeance est toujours strictement dans le futur. */
static void i2c_step(struct PyRuntimeHandle* h, double now, const int* pinBoolIn) {
    if (!h->i2c_configured || !h->i2cm.busy) {
        return;
    }
    if (now + PYRUNTIME_EPS >= h->i2cm.next_time) {
        i2c_act(h, now, pinBoolIn);
    }
}

/* Un seul bus en v0 : I2C(0) (ou I2C(1), accepte pour la compatibilite des
   scripts rp2, mais c'est le meme). */
static int resolve_i2c_index(int id) {
    return (id == 0 || id == 1) ? 0 : -1;
}

static PyObject* i2c_oserror(int err) {
    const char* name = err == I2C_ERR_EIO ? "EIO" : err == I2C_ERR_EBUSY ? "EBUSY" : err == I2C_ERR_ETIMEDOUT ? "ETIMEDOUT" : "EIO";
    PyObject* args = Py_BuildValue("(is)", err, name);
    if (args) {
        PyErr_SetObject(PyExc_OSError, args);
        Py_DECREF(args);
    }
    return NULL;
}

static PyObject* native_i2c_init(PyObject* self, PyObject* args) {
    REQUIRE_WORKER();
    struct PyRuntimeHandle* h = g_current;
    int id, scl_id, sda_id;
    double freq;
    if (!PyArg_ParseTuple(args, "iiid", &id, &scl_id, &sda_id, &freq)) return NULL;
    if (resolve_i2c_index(id) < 0) {
        PyErr_Format(PyExc_ValueError, "I2C %d non supporte pour la v0 (un seul bus, I2C(0))", id);
        return NULL;
    }
    int scl = resolve_pin_index(scl_id);
    int sda = resolve_pin_index(sda_id);
    if (scl < 0 || scl >= LED_PIN_INDEX) {
        PyErr_Format(PyExc_ValueError, "broche SCL %d non supportee (0-%d attendu)", scl_id, LED_PIN_INDEX - 1);
        return NULL;
    }
    if (sda < 0 || sda >= LED_PIN_INDEX) {
        PyErr_Format(PyExc_ValueError, "broche SDA %d non supportee (0-%d attendu)", sda_id, LED_PIN_INDEX - 1);
        return NULL;
    }
    if (scl == sda) {
        PyErr_SetString(PyExc_ValueError, "SCL et SDA doivent etre deux broches differentes");
        return NULL;
    }
    if (freq < I2C_MIN_FREQ || freq > I2C_MAX_FREQ) {
        char freq_str[64];
        snprintf(freq_str, sizeof(freq_str), "%g", freq);
        PyErr_Format(PyExc_ValueError, "frequence I2C %s Hz hors bornes (%d-%d)", freq_str, (int) I2C_MIN_FREQ, (int) I2C_MAX_FREQ);
        return NULL;
    }
    EnterCriticalSection(&h->cs);
    if (h->i2cm.busy) {
        LeaveCriticalSection(&h->cs);
        return i2c_oserror(I2C_ERR_EBUSY);
    }
    if (h->i2c_configured) {
        h->i2c_claimed[h->i2c_scl_pin] = 0;
        h->i2c_claimed[h->i2c_sda_pin] = 0;
    }
    memset(&h->i2cm, 0, sizeof(h->i2cm));
    h->i2cm.next_time = 1.0e300;
    h->i2cm.quarter = 0.25 / freq;
    h->i2c_configured = 1;
    h->i2c_scl_pin = scl;
    h->i2c_sda_pin = sda;
    h->i2c_claimed[scl] = 1;
    h->i2c_claimed[sda] = 1;
    h->pwm_freq[scl] = 0;          /* la broche change de fonction, comme sur le vrai RP2040 */
    h->pwm_freq[sda] = 0;
    i2c_scl(h, 0);                 /* bus au repos : les deux lignes relachees */
    i2c_sda(h, 0);
    LeaveCriticalSection(&h->cs);
    if (yield_to_modelica(h->sim_time) != 0) return NULL;
    Py_RETURN_NONE;
}

/* i2c_xfer(id, addr, wbuf | None, nread, stop) -> (acks, bytes)
   Une transaction complete : segment d'ecriture si wbuf n'est pas None (meme
   vide : sonde d'adresse), puis segment de lecture derriere un START repete si
   nread > 0. BLOQUANT : le script attend la fin reelle de la sequence sur le
   bus, en temps simule, comme machine.I2C sur le vrai materiel. */
static PyObject* native_i2c_xfer(PyObject* self, PyObject* args) {
    REQUIRE_WORKER();
    struct PyRuntimeHandle* h = g_current;
    int id, addr, nread, stop;
    PyObject* wobj;
    const char* wdata = NULL;
    Py_ssize_t wlen = 0;
    if (!PyArg_ParseTuple(args, "iiOip", &id, &addr, &wobj, &nread, &stop)) return NULL;
    if (resolve_i2c_index(id) < 0) {
        PyErr_Format(PyExc_ValueError, "I2C %d non supporte pour la v0 (un seul bus, I2C(0))", id);
        return NULL;
    }
    if (!h->i2c_configured) {
        PyErr_SetString(PyExc_RuntimeError, "I2C non initialise");
        return NULL;
    }
    if (addr < 0 || addr > 0x7F) {
        PyErr_Format(PyExc_ValueError, "adresse I2C %d hors bornes (0-127, adresse sur 7 bits)", addr);
        return NULL;
    }
    if (wobj != Py_None) {
        if (!PyBytes_Check(wobj)) {
            PyErr_SetString(PyExc_TypeError, "i2c_xfer : bytes ou None attendu");
            return NULL;
        }
        wdata = PyBytes_AS_STRING(wobj);
        wlen = PyBytes_GET_SIZE(wobj);
        if (wlen > I2C_XFER_MAX) {
            PyErr_Format(PyExc_ValueError, "au plus %d octets par transaction I2C en v0", I2C_XFER_MAX);
            return NULL;
        }
    }
    if (nread < 0 || nread > I2C_XFER_MAX) {
        PyErr_Format(PyExc_ValueError, "nombre d'octets a lire hors bornes (0-%d)", I2C_XFER_MAX);
        return NULL;
    }

    EnterCriticalSection(&h->cs);
    struct I2cMaster* m = &h->i2cm;
    if (m->busy) {
        /* ex. callback de Timer/IRQ appele pendant qu'une transaction est en cours */
        LeaveCriticalSection(&h->cs);
        return i2c_oserror(I2C_ERR_EBUSY);
    }
    m->addr = addr;
    m->has_write = (wobj != Py_None) || nread == 0;
    m->nwrite = (int) wlen;
    if (wlen > 0) {
        memcpy(m->wbuf, wdata, (size_t) wlen);
    }
    m->nread = nread;
    m->stop = stop;
    m->segment = m->has_write ? 0 : 1;
    m->index = -1;
    m->cur = (unsigned char) ((addr << 1) | (m->has_write ? 0 : 1));
    m->bit = 0;
    m->rx = 0;
    m->ack = 0;
    m->rcount = 0;
    m->acks = 0;
    m->error = 0;
    m->done = 0;
    m->busy = 1;
    /* bus garde par un stop=False precedent : on enchaine par un START repete */
    m->phase = m->held ? I2CM_RS_SDA_RELEASE : I2CM_START_CHECK;
    m->held = 0;
    m->next_time = h->sim_time + m->quarter;
    h->i2c_done_wake = 0;
    LeaveCriticalSection(&h->cs);

    for (;;) {
        int done;
        EnterCriticalSection(&h->cs);
        done = m->done;
        LeaveCriticalSection(&h->cs);
        if (done) {
            break;
        }
        /* Aucune echeance propre : c'est la fin de transaction (i2c_done_wake)
           qui rendra ce reveil authentique. */
        if (yield_to_modelica(1.0e300) != 0) {
            /* un callback Timer/IRQ a leve une exception : on libere le bus */
            EnterCriticalSection(&h->cs);
            i2c_abort(h, I2C_ERR_EIO);
            h->i2c_done_wake = 0;
            LeaveCriticalSection(&h->cs);
            return NULL;
        }
    }

    EnterCriticalSection(&h->cs);
    h->i2c_done_wake = 0;
    int error = m->error;
    int acks = m->acks;
    PyObject* data = PyBytes_FromStringAndSize((const char*) m->rbuf, m->rcount);
    LeaveCriticalSection(&h->cs);
    if (error) {
        Py_XDECREF(data);
        return i2c_oserror(error);
    }
    if (!data) {
        return NULL;
    }
    return Py_BuildValue("(iN)", acks, data);
}

static PyObject* native_i2c_deinit(PyObject* self, PyObject* args) {
    REQUIRE_WORKER();
    struct PyRuntimeHandle* h = g_current;
    int id;
    if (!PyArg_ParseTuple(args, "i", &id)) return NULL;
    EnterCriticalSection(&h->cs);
    if (h->i2c_configured) {
        i2c_scl(h, 0);
        i2c_sda(h, 0);
        h->i2c_claimed[h->i2c_scl_pin] = 0;
        h->i2c_claimed[h->i2c_sda_pin] = 0;
    }
    h->i2c_configured = 0;
    h->i2c_scl_pin = -1;
    h->i2c_sda_pin = -1;
    memset(&h->i2cm, 0, sizeof(h->i2cm));
    h->i2cm.next_time = 1.0e300;
    LeaveCriticalSection(&h->cs);
    if (yield_to_modelica(h->sim_time) != 0) return NULL;
    Py_RETURN_NONE;
}
