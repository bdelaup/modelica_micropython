/* machine.UART : liaison entre le moteur UART generique (uartcore.h/.c) et le
   microcontroleur - choix des broches TX/RX, primitives natives exposees au
   script, et publication de l'etat d'emission vers Modelica.

   Partie de l'implementation du runtime Python, incluse TEXTUELLEMENT par
   PyRuntimeImpl.c (fichier chapeau) : une seule unite de compilation, donc
   pas de #include croise ici et aucune etape de build supplementaire - cf.
   requirements.md, decision "Structure du package et interface C du runtime
   Python". Ce fichier n'est jamais compile seul.

   La mecanique bit/octet (files circulaires, serialisation de la trame, decodage par
   echantillonnage, echeances) a ete extraite dans uartcore.c, a la racine
   d'Include/, pour etre partagee avec les peripheriques serie externes
   (Peripherals.UartDevice) qui n'ont ni Python ni thread. Ne reste ici que ce
   qui est propre au microcontroleur.

   L'emission tourne independamment du script, comme le vrai peripherique UART
   du RP2040 une fois programme : PyRuntime_sync publie le niveau courant de la
   ligne et demande un reveil au prochain changement de niveau. La reception
   est decodee dans PyRuntime_sync a partir des fronts de la ligne (cf.
   uartcore_rx_step). */

/* Plus proche echeance UART, ou 1e300 si l'UART n'est pas configure. */
static double earliest_uart_deadline(struct PyRuntimeHandle* h, double now) {
    if (!h->uart_configured) {
        return 1.0e300;
    }
    return uartcore_deadline(&h->uart, now);
}

/* Fait avancer l'emission et le decodage. Appelees par PyRuntime_sync a chaque
   point de synchro ; le niveau de la broche RX est lu dans pinBoolIn. */
static void uart_tx_advance(struct PyRuntimeHandle* h, double now) {
    uartcore_tx_advance(&h->uart, now);
}

/* Signale au journal un octet recu avec une erreur (parite fausse, stop bas),
   livre quand meme au script comme sur le RP2040. Plafonne : un desaccord de
   debit ou de format produirait sinon un avertissement par octet ; le bilan
   complet est donne en fin de simulation (uart_report_errors). */
#define UART_ERR_REPORT_MAX 10

static void uart_warn_errors(struct PyRuntimeHandle* h, double now, int errors) {
    if (!errors || h->uart_err_reported > UART_ERR_REPORT_MAX) {
        return;
    }
    h->uart_err_reported++;
    if (h->uart_err_reported > UART_ERR_REPORT_MAX) {
        ModelicaFormatWarning("[t=%.6f s] PyRuntime (%s): UART(0): further reception errors not reported "
                              "(total at the end of the simulation)\n", now, h->instanceName);
        return;
    }
    ModelicaFormatWarning("[t=%.6f s] PyRuntime (%s): UART(0): %s%s%s error on a received byte "
                          "(kept in the receive queue) - do baud rate, bits, parity and stop match the transmitter?\n",
                          now, h->instanceName,
                          (errors & UART_ERR_PARITY) ? "parity" : "",
                          (errors & UART_ERR_PARITY) && (errors & UART_ERR_FRAMING) ? " and " : "",
                          (errors & UART_ERR_FRAMING) ? "framing" : "");
}

/* Bilan de fin de simulation, seulement si le plafond a ete atteint. */
static void uart_report_errors(struct PyRuntimeHandle* h) {
    if (h->uart_err_reported > UART_ERR_REPORT_MAX) {
        ModelicaFormatWarning("PyRuntime (%s): UART(0): %ld parity and %ld framing errors in total\n",
                              h->instanceName, h->uart.rx_parity_errors, h->uart.rx_framing_errors);
    }
}

static void uart_rx_step(struct PyRuntimeHandle* h, double now, const int* pinBoolIn) {
    if (!h->uart_configured || h->uart_rx_pin < 0) {
        return;
    }
    uart_warn_errors(h, now, uartcore_rx_step(&h->uart, now, pinBoolIn[h->uart_rx_pin]));
}

/* Un seul id supporte - meme esprit que resolve_display_index. */
static int resolve_uart_index(int id) {
    if (id == 0) return 0;
    return -1;
}

static PyObject* native_uart_init(PyObject* self, PyObject* args) {
    REQUIRE_WORKER();
    int id, tx_id, rx_id, bits, parity, stop;
    double baudrate;
    /* Format deja verifie par le shim (memes messages que le port rp2) ; on
       revalide ici, la native pouvant etre appelee directement. */
    if (!PyArg_ParseTuple(args, "iiidiii", &id, &tx_id, &rx_id, &baudrate, &bits, &parity, &stop)) return NULL;
    if (resolve_uart_index(id) < 0) {
        PyErr_Format(PyExc_ValueError, "UART %d not supported (only UART(0) exists)", id);
        return NULL;
    }
    int tx = resolve_pin_index(tx_id);
    int rx = resolve_pin_index(rx_id);
    if (tx < 0 || tx >= LED_PIN_INDEX) {
        PyErr_Format(PyExc_ValueError, "TX pin %d not supported (0-%d expected)", tx_id, LED_PIN_INDEX - 1);
        return NULL;
    }
    if (rx < 0 || rx >= LED_PIN_INDEX) {
        PyErr_Format(PyExc_ValueError, "RX pin %d not supported (0-%d expected)", rx_id, LED_PIN_INDEX - 1);
        return NULL;
    }
    if (tx == rx) {
        PyErr_SetString(PyExc_ValueError, "TX and RX must be two different pins");
        return NULL;
    }
    if (baudrate < UART_MIN_BAUD || baudrate > UART_MAX_BAUD) {
        /* PyErr_Format ne supporte pas %f (cf. native_pwm_set_freq) */
        char baud_str[64];
        snprintf(baud_str, sizeof(baud_str), "%g", baudrate);
        PyErr_Format(PyExc_ValueError, "baud rate %s out of range (%d-%d)", baud_str, UART_MIN_BAUD, UART_MAX_BAUD);
        return NULL;
    }
    if (bits < UART_MIN_DATA_BITS || bits > UART_MAX_DATA_BITS) {
        PyErr_Format(PyExc_ValueError, "invalid bits %d (%d-%d expected)", bits, UART_MIN_DATA_BITS, UART_MAX_DATA_BITS);
        return NULL;
    }
    if (parity != UART_PARITY_NONE && parity != UART_PARITY_EVEN && parity != UART_PARITY_ODD) {
        PyErr_Format(PyExc_ValueError, "invalid parity %d (None, 0 or 1 expected)", parity);
        return NULL;
    }
    if (stop != 1 && stop != 2) {
        PyErr_Format(PyExc_ValueError, "invalid stop %d (1 or 2 expected)", stop);
        return NULL;
    }
    EnterCriticalSection(&g_current->cs);
    g_current->uart_configured = 1;
    g_current->uart_tx_pin = tx;
    g_current->uart_rx_pin = rx;
    g_current->pin_is_output[tx] = 1;   /* la broche TX est prise par le peripherique, comme sur le vrai RP2040 */
    g_current->pin_is_output[rx] = 0;
    g_current->uart_rx_claimed[rx] = 1; /* ses fronts ne reveillent plus le script (cf. PyRuntime_sync) */
    uartcore_configure(&g_current->uart, 1.0 / baudrate, bits, parity, stop);
    LeaveCriticalSection(&g_current->cs);
    if (yield_to_modelica(g_current->sim_time) != 0) return NULL;
    Py_RETURN_NONE;
}

static PyObject* native_uart_write(PyObject* self, PyObject* args) {
    REQUIRE_WORKER();
    int id;
    const char* data;
    Py_ssize_t len;
    /* "y#" : bytes + longueur. Pas "s", qui s'arrete au premier NUL et refuse les bytes. */
    if (!PyArg_ParseTuple(args, "iy#", &id, &data, &len)) return NULL;
    if (resolve_uart_index(id) < 0) {
        PyErr_Format(PyExc_ValueError, "UART %d not supported (only UART(0) exists)", id);
        return NULL;
    }
    if (!g_current->uart_configured) {
        PyErr_SetString(PyExc_RuntimeError, "UART not initialised");
        return NULL;
    }
    Py_ssize_t i;
    long written = 0;
    EnterCriticalSection(&g_current->cs);
    for (i = 0; i < len; i++) {
        if (!uartcore_tx_push(&g_current->uart, (unsigned char) data[i])) {
            break;   /* file pleine : les octets restants sont perdus, comme un FIFO materiel qui deborde */
        }
        written++;
    }
    /* Si rien n'est en cours d'emission, demarrer tout de suite la premiere trame. */
    uartcore_tx_kick(&g_current->uart, g_current->sim_time);
    LeaveCriticalSection(&g_current->cs);
    /* Non bloquant : le temps n'avance pas ici, Modelica joue la forme d'onde. */
    if (yield_to_modelica(g_current->sim_time) != 0) return NULL;
    return PyLong_FromLong(written);
}

static PyObject* native_uart_any(PyObject* self, PyObject* args) {
    REQUIRE_WORKER();
    int id;
    if (!PyArg_ParseTuple(args, "i", &id)) return NULL;
    if (resolve_uart_index(id) < 0) {
        PyErr_Format(PyExc_ValueError, "UART %d not supported (only UART(0) exists)", id);
        return NULL;
    }
    if (yield_to_modelica(g_current->sim_time) != 0) return NULL;
    EnterCriticalSection(&g_current->cs);
    long n = uartcore_rx_count(&g_current->uart);
    LeaveCriticalSection(&g_current->cs);
    return PyLong_FromLong(n);
}

/* n < 0 : lire tout ce qui est disponible. Retourne None si rien (comme MicroPython). */
static PyObject* native_uart_read(PyObject* self, PyObject* args) {
    REQUIRE_WORKER();
    int id, n;
    if (!PyArg_ParseTuple(args, "ii", &id, &n)) return NULL;
    if (resolve_uart_index(id) < 0) {
        PyErr_Format(PyExc_ValueError, "UART %d not supported (only UART(0) exists)", id);
        return NULL;
    }
    if (yield_to_modelica(g_current->sim_time) != 0) return NULL;
    char out[UART_RX_BUF_LEN];
    int count = 0;
    EnterCriticalSection(&g_current->cs);
    int avail = uartcore_rx_count(&g_current->uart);
    int want = (n < 0 || n > avail) ? avail : n;
    while (count < want) {
        unsigned char byte;
        if (!uartcore_rx_pop(&g_current->uart, &byte)) {
            break;
        }
        out[count++] = (char) byte;
    }
    LeaveCriticalSection(&g_current->cs);
    if (count == 0) {
        Py_RETURN_NONE;
    }
    return PyBytes_FromStringAndSize(out, count);
}

static PyObject* native_uart_deinit(PyObject* self, PyObject* args) {
    REQUIRE_WORKER();
    int id;
    if (!PyArg_ParseTuple(args, "i", &id)) return NULL;
    if (resolve_uart_index(id) < 0) {
        PyErr_Format(PyExc_ValueError, "UART %d not supported (only UART(0) exists)", id);
        return NULL;
    }
    EnterCriticalSection(&g_current->cs);
    if (g_current->uart_configured && g_current->uart_rx_pin >= 0) {
        g_current->uart_rx_claimed[g_current->uart_rx_pin] = 0;
    }
    g_current->uart_configured = 0;
    g_current->uart_tx_pin = -1;
    g_current->uart_rx_pin = -1;
    uartcore_stop(&g_current->uart);
    LeaveCriticalSection(&g_current->cs);
    if (yield_to_modelica(g_current->sim_time) != 0) return NULL;
    Py_RETURN_NONE;
}

/* Publie l'etat UART vers Modelica : la broche d'emission et le niveau a y
   tenir jusqu'au point de synchro suivant. uartTxPin vaut 0 tant qu'aucune
   broche n'est affectee en TX ; une fois affectee, elle le reste meme hors
   trame (la ligne au repos doit etre HAUTE, pas retomber sur pinBoolOut qui
   vaut bas par defaut). */
static void uart_publish(struct PyRuntimeHandle* h, double now, int* uartTxPinOut, int* uartTxLevelOut) {
    *uartTxPinOut = (h->uart_configured && h->uart_tx_pin >= 0) ? h->uart_tx_pin + 1 : 0;
    *uartTxLevelOut = uartcore_tx_level(&h->uart, now);
}
