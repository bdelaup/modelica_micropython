/* machine.UART : files circulaires TX/RX, trame 8N1, decodage de la reception, primitives natives et publication vers Modelica.

   Partie de l'implementation du runtime Python, incluse TEXTUELLEMENT par
   PyRuntimeImpl.c (fichier chapeau) : une seule unite de compilation, donc
   pas de #include croise ici et aucune etape de build supplementaire - cf.
   requirements.md, decision "Structure du package et interface C du runtime
   Python". Ce fichier n'est jamais compile seul. */

/* --- machine.UART : files circulaires TX/RX et echeances (h->cs deja tenu par l'appelant) ---
   Files a taille fixe dans le handle, comme le reste de l'etat des peripheriques
   (pas de malloc ; PyRuntime_destroy est un no-op assume, cf. requirements.md). */

static int uart_tx_count(struct PyRuntimeHandle* h) {
    return (h->uart_tx_head - h->uart_tx_tail + UART_TX_BUF_LEN) % UART_TX_BUF_LEN;
}

static int uart_rx_count(struct PyRuntimeHandle* h) {
    return (h->uart_rx_head - h->uart_rx_tail + UART_RX_BUF_LEN) % UART_RX_BUF_LEN;
}

/* Retourne 0 si la file est pleine (octet perdu, comme un vrai FIFO materiel qui deborde). */
static int uart_tx_push(struct PyRuntimeHandle* h, unsigned char byte) {
    int next = (h->uart_tx_head + 1) % UART_TX_BUF_LEN;
    if (next == h->uart_tx_tail) {
        return 0;
    }
    h->uart_tx_buf[h->uart_tx_head] = byte;
    h->uart_tx_head = next;
    return 1;
}

static int uart_rx_push(struct PyRuntimeHandle* h, unsigned char byte) {
    int next = (h->uart_rx_head + 1) % UART_RX_BUF_LEN;
    if (next == h->uart_rx_tail) {
        return 0;
    }
    h->uart_rx_buf[h->uart_rx_head] = byte;
    h->uart_rx_head = next;
    return 1;
}

/* Serialise un octet en motif de bits 8N1 (start=0, 8 data LSB first, stop=1) et
   demarre la trame a l'instant 'now'. C'est LE seul endroit qui connait le format
   de trame : passer a un format parametrable (parite, 7/9 bits, 2 stop) ne demande
   de toucher ni Modelica ni le shim Python. */
static void uart_tx_begin_frame(struct PyRuntimeHandle* h, unsigned char byte, double now) {
    int i;
    h->uart_tx_bits[0] = 0.0;                      /* start */
    for (i = 0; i < 8; i++) {
        h->uart_tx_bits[1 + i] = ((byte >> i) & 1) ? 1.0 : 0.0;   /* data, LSB first */
    }
    h->uart_tx_bits[9] = 1.0;                      /* stop */
    for (i = 10; i < UART_MAX_FRAME_BITS; i++) {
        h->uart_tx_bits[i] = 1.0;                  /* inutilise en 8N1 : niveau de repos */
    }
    h->uart_tx_num_bits = 10;
    h->uart_tx_start_time = now;
    h->uart_tx_end_time = now + 10 * h->uart_bit_dur;
    h->uart_tx_active = 1;
}

/* Fait avancer l'emission : clot la trame arrivee a echeance et charge l'octet
   suivant de la file. Appelee par PyRuntime_sync a chaque point de synchro. */
static void uart_tx_advance(struct PyRuntimeHandle* h, double now) {
    while (h->uart_tx_active && now + PYRUNTIME_EPS >= h->uart_tx_end_time) {
        if (uart_tx_count(h) > 0) {
            unsigned char next = h->uart_tx_buf[h->uart_tx_tail];
            h->uart_tx_tail = (h->uart_tx_tail + 1) % UART_TX_BUF_LEN;
            /* enchainement sans trou : la trame suivante demarre pile a la fin de la precedente */
            uart_tx_begin_frame(h, next, h->uart_tx_end_time);
        } else {
            h->uart_tx_active = 0;   /* file vide : la ligne repasse au repos (niveau haut) */
        }
    }
}

/* Decodage de la reception : machine a etats echantillonnant la ligne au MILIEU
   de chaque bit. Entierement cote C - Modelica n'a aucune machine a etats a
   porter, il se contente de rappeler PyRuntime_sync aux instants demandes via
   nextWakeTime (meme mecanisme que machine.Timer). */
static void uart_rx_step(struct PyRuntimeHandle* h, double now, const int* pinBoolIn) {
    if (!h->uart_configured || h->uart_rx_pin < 0) {
        return;
    }
    int level = pinBoolIn[h->uart_rx_pin];
    if (h->uart_rx_state == UART_RX_IDLE) {
        /* Le start se detecte sur un FRONT descendant, jamais sur un simple
           niveau bas : au tout premier point de synchro, la ligne n'est pas
           encore pilotee (le script n'a pas eu le temps de configurer l'UART)
           et vaut 0 V - un test sur le niveau y verrait un bit de start et
           fabriquerait un octet fantome. Exiger le front impose d'avoir vu la
           ligne au repos (niveau haut) au moins une fois avant d'ecouter, ce
           que fait aussi un vrai recepteur UART. */
        if (h->uart_rx_last_level && !level) {
            /* Le premier bit de donnees se lit 1.5 duree de bit plus tard
               (moitie du start + moitie du bit 0). */
            h->uart_rx_state = UART_RX_RECEIVING;
            h->uart_rx_bit_index = 0;
            h->uart_rx_shift = 0;
            h->uart_rx_next_sample = now + 1.5 * h->uart_bit_dur;
        }
        h->uart_rx_last_level = level;
        return;
    }
    h->uart_rx_last_level = level;
    /* En reception on ne se fie qu'aux echeances, jamais aux fronts. */
    while (h->uart_rx_state == UART_RX_RECEIVING && now + PYRUNTIME_EPS >= h->uart_rx_next_sample) {
        if (h->uart_rx_bit_index < 8) {
            if (level) {
                h->uart_rx_shift |= (1u << h->uart_rx_bit_index);   /* LSB first */
            }
            h->uart_rx_bit_index++;
            h->uart_rx_next_sample += h->uart_bit_dur;
        } else {
            /* Bit de stop : la ligne doit etre revenue au niveau haut. Attendre
               ce bit avant de repasser au repos est indispensable - sinon un
               dernier bit de donnees a 0 serait relu comme un nouveau bit de
               start. Trame invalide (stop bas) = octet ignore, simplification v0. */
            if (level) {
                uart_rx_push(h, (unsigned char) (h->uart_rx_shift & 0xFF));
            }
            h->uart_rx_state = UART_RX_IDLE;
        }
    }
}

static double earliest_uart_deadline(struct PyRuntimeHandle* h) {
    double best = 1.0e300;
    if (!h->uart_configured) {
        return best;
    }
    if (h->uart_tx_active && h->uart_tx_end_time < best) {
        best = h->uart_tx_end_time;
    }
    if (h->uart_rx_state == UART_RX_RECEIVING && h->uart_rx_next_sample < best) {
        best = h->uart_rx_next_sample;
    }
    return best;
}

/* --- machine.UART : liaison serie electrique reelle sur deux broches GPx ---
   L'emission est generee en continu par Modelica a partir du motif de bits publie
   ici (comme le PWM, et comme le vrai peripherique UART du RP2040 qui tourne
   independamment du CPU une fois programme) ; la reception est decodee ici meme,
   dans PyRuntime_sync, par echantillonnage au milieu de chaque bit. */

/* Un seul id supporte en v0 - meme esprit que resolve_display_index. */
static int resolve_uart_index(int id) {
    if (id == 0) return 0;
    return -1;
}

static PyObject* native_uart_init(PyObject* self, PyObject* args) {
    int id, tx_id, rx_id;
    double baudrate;
    if (!PyArg_ParseTuple(args, "iiid", &id, &tx_id, &rx_id, &baudrate)) return NULL;
    if (resolve_uart_index(id) < 0) {
        PyErr_Format(PyExc_ValueError, "UART %d non supporte pour la v0 (seul UART(0) existe)", id);
        return NULL;
    }
    int tx = resolve_pin_index(tx_id);
    int rx = resolve_pin_index(rx_id);
    if (tx < 0 || tx >= LED_PIN_INDEX) {
        PyErr_Format(PyExc_ValueError, "broche TX %d non supportee (0-%d attendu)", tx_id, LED_PIN_INDEX - 1);
        return NULL;
    }
    if (rx < 0 || rx >= LED_PIN_INDEX) {
        PyErr_Format(PyExc_ValueError, "broche RX %d non supportee (0-%d attendu)", rx_id, LED_PIN_INDEX - 1);
        return NULL;
    }
    if (tx == rx) {
        PyErr_SetString(PyExc_ValueError, "TX et RX doivent etre deux broches differentes");
        return NULL;
    }
    if (baudrate < UART_MIN_BAUD || baudrate > UART_MAX_BAUD) {
        /* PyErr_Format ne supporte pas %f (cf. native_pwm_set_freq) */
        char baud_str[64];
        snprintf(baud_str, sizeof(baud_str), "%g", baudrate);
        PyErr_Format(PyExc_ValueError, "baudrate %s hors bornes (%d-%d)", baud_str, UART_MIN_BAUD, UART_MAX_BAUD);
        return NULL;
    }
    EnterCriticalSection(&g_current->cs);
    g_current->uart_configured = 1;
    g_current->uart_tx_pin = tx;
    g_current->uart_rx_pin = rx;
    g_current->uart_bit_dur = 1.0 / baudrate;
    g_current->pin_is_output[tx] = 1;   /* la broche TX est prise par le peripherique, comme sur le vrai RP2040 */
    g_current->pin_is_output[rx] = 0;
    g_current->uart_rx_claimed[rx] = 1; /* ses fronts ne reveillent plus le script (cf. PyRuntime_sync) */
    g_current->uart_rx_state = UART_RX_IDLE;
    g_current->uart_tx_active = 0;
    g_current->uart_tx_head = g_current->uart_tx_tail = 0;
    g_current->uart_rx_head = g_current->uart_rx_tail = 0;
    LeaveCriticalSection(&g_current->cs);
    if (yield_to_modelica(g_current->sim_time) != 0) return NULL;
    Py_RETURN_NONE;
}

static PyObject* native_uart_write(PyObject* self, PyObject* args) {
    int id;
    const char* data;
    Py_ssize_t len;
    /* "y#" : bytes + longueur. Pas "s", qui s'arrete au premier NUL et refuse les bytes. */
    if (!PyArg_ParseTuple(args, "iy#", &id, &data, &len)) return NULL;
    if (resolve_uart_index(id) < 0) {
        PyErr_Format(PyExc_ValueError, "UART %d non supporte pour la v0 (seul UART(0) existe)", id);
        return NULL;
    }
    if (!g_current->uart_configured) {
        PyErr_SetString(PyExc_RuntimeError, "UART non initialise");
        return NULL;
    }
    Py_ssize_t i;
    long written = 0;
    EnterCriticalSection(&g_current->cs);
    for (i = 0; i < len; i++) {
        if (!uart_tx_push(g_current, (unsigned char) data[i])) {
            break;   /* file pleine : les octets restants sont perdus, comme un FIFO materiel qui deborde */
        }
        written++;
    }
    /* Si rien n'est en cours d'emission, demarrer tout de suite la premiere trame. */
    if (!g_current->uart_tx_active && uart_tx_count(g_current) > 0) {
        unsigned char first = g_current->uart_tx_buf[g_current->uart_tx_tail];
        g_current->uart_tx_tail = (g_current->uart_tx_tail + 1) % UART_TX_BUF_LEN;
        uart_tx_begin_frame(g_current, first, g_current->sim_time);
    }
    LeaveCriticalSection(&g_current->cs);
    /* Non bloquant : le temps n'avance pas ici, Modelica joue la forme d'onde. */
    if (yield_to_modelica(g_current->sim_time) != 0) return NULL;
    return PyLong_FromLong(written);
}

static PyObject* native_uart_any(PyObject* self, PyObject* args) {
    int id;
    if (!PyArg_ParseTuple(args, "i", &id)) return NULL;
    if (resolve_uart_index(id) < 0) {
        PyErr_Format(PyExc_ValueError, "UART %d non supporte pour la v0 (seul UART(0) existe)", id);
        return NULL;
    }
    if (yield_to_modelica(g_current->sim_time) != 0) return NULL;
    EnterCriticalSection(&g_current->cs);
    long n = uart_rx_count(g_current);
    LeaveCriticalSection(&g_current->cs);
    return PyLong_FromLong(n);
}

/* n < 0 : lire tout ce qui est disponible. Retourne None si rien (comme MicroPython). */
static PyObject* native_uart_read(PyObject* self, PyObject* args) {
    int id, n;
    if (!PyArg_ParseTuple(args, "ii", &id, &n)) return NULL;
    if (resolve_uart_index(id) < 0) {
        PyErr_Format(PyExc_ValueError, "UART %d non supporte pour la v0 (seul UART(0) existe)", id);
        return NULL;
    }
    if (yield_to_modelica(g_current->sim_time) != 0) return NULL;
    char out[UART_RX_BUF_LEN];
    int count = 0;
    EnterCriticalSection(&g_current->cs);
    int avail = uart_rx_count(g_current);
    int want = (n < 0 || n > avail) ? avail : n;
    while (count < want) {
        out[count++] = (char) g_current->uart_rx_buf[g_current->uart_rx_tail];
        g_current->uart_rx_tail = (g_current->uart_rx_tail + 1) % UART_RX_BUF_LEN;
    }
    LeaveCriticalSection(&g_current->cs);
    if (count == 0) {
        Py_RETURN_NONE;
    }
    return PyBytes_FromStringAndSize(out, count);
}

static PyObject* native_uart_deinit(PyObject* self, PyObject* args) {
    int id;
    if (!PyArg_ParseTuple(args, "i", &id)) return NULL;
    if (resolve_uart_index(id) < 0) {
        PyErr_Format(PyExc_ValueError, "UART %d non supporte pour la v0 (seul UART(0) existe)", id);
        return NULL;
    }
    EnterCriticalSection(&g_current->cs);
    if (g_current->uart_configured && g_current->uart_rx_pin >= 0) {
        g_current->uart_rx_claimed[g_current->uart_rx_pin] = 0;
    }
    g_current->uart_configured = 0;
    g_current->uart_tx_active = 0;
    g_current->uart_rx_state = UART_RX_IDLE;
    g_current->uart_tx_pin = -1;
    g_current->uart_rx_pin = -1;
    LeaveCriticalSection(&g_current->cs);
    if (yield_to_modelica(g_current->sim_time) != 0) return NULL;
    Py_RETURN_NONE;
}

/* Publie l'etat UART vers Modelica, qui genere la forme d'onde en continu a
   partir de ces valeurs. uartTxPin vaut 0 tant qu'aucune broche n'est affectee
   en TX ; une fois affectee, elle le reste meme hors trame (la ligne au repos
   doit etre HAUTE, pas retomber sur pinBoolOut qui vaut bas par defaut). */
static void uart_publish(struct PyRuntimeHandle* h, int* uartTxPinOut, int* uartTxActiveOut,
                          double* uartTxStartOut, double* uartBitDurOut,
                          int* uartTxNumBitsOut, double* uartTxBitsOut) {
    int k;
    *uartTxPinOut = (h->uart_configured && h->uart_tx_pin >= 0) ? h->uart_tx_pin + 1 : 0;
    *uartTxActiveOut = h->uart_tx_active;
    *uartTxStartOut = h->uart_tx_start_time;
    *uartBitDurOut = (h->uart_bit_dur > 0) ? h->uart_bit_dur : 1.0;
    *uartTxNumBitsOut = h->uart_tx_num_bits;
    for (k = 0; k < UART_MAX_FRAME_BITS; k++) {
        uartTxBitsOut[k] = h->uart_tx_bits[k];
    }
}
