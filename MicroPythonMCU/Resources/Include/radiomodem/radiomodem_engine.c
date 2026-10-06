/* Moteur d'un modem radio transparent : construction, ordonnancement et point
   de synchro appele par Modelica.

   Inclus TEXTUELLEMENT par RadioModemImpl.c, jamais compile seul.

   ORDRE DES OPERATIONS DANS RadioModem_sync (ne pas le changer a la legere) :
     1. UART : clore la trame rendue au microcontroleur arrivee a echeance
     2. UART : decoder la reception, octets recus -> file up (ou perdus)
     3. air : clore la trame emise arrivee a echeance
     4. air : lancer la trame suivante si la tete de la file up est prete
     5. air : decoder la reception (sourd en semi-duplex pendant l'emission,
        trame perdue sur brouillage), trames intactes -> file down
     6. UART : lancer l'octet suivant si la tete de la file down est prete
     7. publier, nextWakeTime = min des echeances

   Comme pour les appareils serie, chaque etape est pilotee par echeance ou
   consomme ce qu'elle traite : rappeler la fonction au MEME instant simule ne
   refait rien (Modelica itere sur les evenements). */

#ifndef RADIOMODEM_ENGINE_C_INCLUDED
#define RADIOMODEM_ENGINE_C_INCLUDED

/* Nombre de modems construits dans ce process : donne a chacun un identifiant
   distinct (1, 2, 3...). Une simulation = un process, donc pas de remise a zero. */
static int g_radio_instances = 0;

/* ===================== files horodatees ===================== */

static int radio_q_push(struct RadioQueue* q, unsigned char byte, double ready) {
    int tail;
    if (q->count >= q->capacity) {
        return 0;
    }
    tail = (q->head + q->count) % RADIO_BUF_MAX;
    q->data[tail] = byte;
    q->ready[tail] = ready;
    q->count++;
    return 1;
}

/* Sort l'octet de tete s'il est pret a l'instant 'now'. */
static int radio_q_pop_ready(struct RadioQueue* q, double now, unsigned char* out) {
    if (q->count == 0 || now + UARTCORE_EPS < q->ready[q->head]) {
        return 0;
    }
    *out = q->data[q->head];
    q->head = (q->head + 1) % RADIO_BUF_MAX;
    q->count--;
    return 1;
}

static double radio_q_next_ready(struct RadioQueue* q) {
    return (q->count > 0) ? q->ready[q->head] : 1.0e300;
}

/* ===================== helpers ===================== */

/* Avertissement plafonne : les RADIO_WARN_MAX premiers, puis un bilan en fin
   de simulation (RadioModem_destroy). */
static void radio_warn(struct RadioModem* m, double now, const char* what) {
    if (m->warned > RADIO_WARN_MAX) {
        return;
    }
    m->warned++;
    if (m->warned > RADIO_WARN_MAX) {
        ModelicaFormatWarning("[t=%.6f s] [%s] further losses not reported (total at the end of the simulation)\n",
                              now, m->name);
        return;
    }
    ModelicaFormatWarning("[t=%.6f s] [%s] %s\n", now, m->name, what);
}

/* Abandonne la trame radio en cours de reception (brouillage, ou emission
   propre en semi-duplex). */
static void radio_abort_air_rx(struct RadioModem* m, double now, const char* why) {
    if (m->air.rx_state == UART_RX_RECEIVING) {
        m->air.rx_state = UART_RX_IDLE;
        m->n_corrupted++;
        radio_warn(m, now, why);
    }
}

/* ===================== API exportee ===================== */

void* RadioModem_new(double baudrate, int dataBits, int parity, int stopBits,
                     double airBaudrate, int txBufferSize, int rxBufferSize,
                     double txDelay, double rxDelay, int halfDuplex,
                     double drawnFMax, int warnSampling,
                     const char* instanceName) {
    struct RadioModem* m;
    size_t n;

    if (baudrate < UART_MIN_BAUD || baudrate > UART_MAX_BAUD) {
        ModelicaFormatError("RadioModem: baudrate %g out of range (%d-%d)", baudrate, UART_MIN_BAUD, UART_MAX_BAUD);
        return NULL;
    }
    if (airBaudrate < UART_MIN_BAUD || airBaudrate > UART_MAX_BAUD) {
        ModelicaFormatError("RadioModem: airBaudrate %g out of range (%d-%d)", airBaudrate, UART_MIN_BAUD, UART_MAX_BAUD);
        return NULL;
    }
    if (dataBits < UART_MIN_DATA_BITS || dataBits > UART_MAX_DATA_BITS) {
        ModelicaFormatError("RadioModem: dataBits %d out of range (%d-%d)", dataBits, UART_MIN_DATA_BITS, UART_MAX_DATA_BITS);
        return NULL;
    }
    if (parity != UART_PARITY_NONE && parity != UART_PARITY_EVEN && parity != UART_PARITY_ODD) {
        ModelicaFormatError("RadioModem: unknown parity (%d)", parity);
        return NULL;
    }
    if (stopBits != 1 && stopBits != 2) {
        ModelicaFormatError("RadioModem: stopBits %d invalid (1 or 2)", stopBits);
        return NULL;
    }
    if (txBufferSize < 1 || txBufferSize > RADIO_BUF_MAX || rxBufferSize < 1 || rxBufferSize > RADIO_BUF_MAX) {
        ModelicaFormatError("RadioModem: buffer sizes %d/%d out of range (1-%d bytes)", txBufferSize, rxBufferSize, RADIO_BUF_MAX);
        return NULL;
    }
    if (txDelay < 0 || rxDelay < 0) {
        ModelicaFormatError("RadioModem: negative delay (txDelay %g s, rxDelay %g s)", txDelay, rxDelay);
        return NULL;
    }
    if (g_radio_instances >= RADIO_MAX_INSTANCES) {
        ModelicaFormatError("RadioModem: more than %d radio modules in one model", RADIO_MAX_INSTANCES);
        return NULL;
    }

    m = (struct RadioModem*) calloc(1, sizeof(struct RadioModem));
    if (!m) {
        ModelicaFormatError("RadioModem: allocation failed");
        return NULL;
    }
    /* rx_last_level des deux decodeurs reste a 0 (calloc), comme pour les
       appareils serie : il faut voir la ligne au repos avant d'ecouter, sinon
       la broche RX encore basse a t=0 fabriquerait un octet fantome
       (cf. UartDevice_new). */
    uartcore_configure(&m->ser, 1.0 / baudrate, dataBits, parity, stopBits);
    uartcore_configure(&m->air, 1.0 / airBaudrate, RADIO_AIR_DATA_BITS, UART_PARITY_NONE, 1);
    m->up.capacity = txBufferSize;
    m->down.capacity = rxBufferSize;
    m->tx_delay = txDelay;
    m->rx_delay = rxDelay;
    m->half_duplex = halfDuplex ? 1 : 0;
    g_radio_instances++;
    m->id = (double) g_radio_instances;

    n = strlen(instanceName ? instanceName : "RadioModem");
    if (n > RADIO_NAME_MAX) {
        n = RADIO_NAME_MAX;
    }
    memcpy(m->name, instanceName ? instanceName : "RadioModem", n);
    m->name[n] = '\0';

    /* Porteuse tracee mal echantillonnee : sTx n'est enregistre qu'aux points
       de sortie, et ce n'est pas un evenement (sinus continu) - au-dela d'un
       dixieme de periode entre deux points, la courbe devient trompeuse. Les
       fronts numeriques, eux, sont des evenements, ecrits dans les resultats
       quel que soit l'intervalle : rien a signaler pour eux. Une fois par
       modem, a la construction. */
    if (warnSampling && drawnFMax > 0) {
        double step = sim_output_interval();
        double limit = 1.0 / (10.0 * drawnFMax);
        if (step > limit * 1.001) {
            ModelicaFormatWarning("[%s] output interval %g s: %.2g point(s) per period of the drawn carrier (%g Hz). "
                                  "Plotted, sTx will look wrong (aliasing); the radio link itself is not affected. "
                                  "To see the carrier, use an output interval of %.3g s or less; to hide this message, set warnSampling = false.\n",
                                  m->name, step, 1.0 / (step * drawnFMax), drawnFMax, limit);
        }
    }
    return (void*) m;
}

void RadioModem_destroy(void* modem) {
    struct RadioModem* m = (struct RadioModem*) modem;
    if (!m) {
        return;
    }
    /* Bilan d'une ligne, toujours : c'est ce que l'eleve lit pour savoir ce
       qui est passe et ce qui s'est perdu. */
    ModelicaFormatMessage("[%s] %ld byte(s) from the UART, %ld sent on air, %ld received on air, %ld to the UART"
                          " - lost: %ld (transmit buffer full), %ld (receive buffer full), %ld (corrupted radio frames)\n",
                          m->name, m->n_uart_in, m->n_sent, m->n_received, m->n_uart_out,
                          m->n_drop_up, m->n_drop_down, m->n_corrupted);
    if (m->n_uart_err > 0) {
        ModelicaFormatWarning("[%s] %ld byte(s) received from the microcontroller with a parity or framing error (kept)\n",
                              m->name, m->n_uart_err);
    }
    free(m);
}

void RadioModem_sync(void* modem, double currentTime, int serRxLevel, int airLevel, int airJam,
                     int* serTxLevel, int* airTxLevel, int* carrierOn, int* airRxBusy,
                     int* txFill, int* rxFill, double* airId,
                     int* nSent, int* nReceived, int* nDropped, int* nCorrupted,
                     double* nextWakeTime) {
    struct RadioModem* m = (struct RadioModem*) modem;
    unsigned char byte;
    double best, t;
    int errors, level, n;
    unsigned char bytes[UART_RX_BUF_LEN];

    /* 1. UART : trame rendue au microcontroleur arrivee a echeance */
    uartcore_tx_advance(&m->ser, currentTime);

    /* 2. UART : reception des octets du microcontroleur. Un octet avec une
       erreur de parite ou de trame est garde, comme par les appareils serie. */
    errors = uartcore_rx_step(&m->ser, currentTime, serRxLevel);
    if (errors) {
        m->n_uart_err++;
        radio_warn(m, currentTime, "byte received from the microcontroller with a parity or framing error (kept)"
                                   " - do baudrate, dataBits, parity and stopBits match machine.UART?");
    }
    while (uartcore_rx_pop(&m->ser, &byte)) {
        m->n_uart_in++;
        if (!radio_q_push(&m->up, byte, currentTime + m->tx_delay)) {
            m->n_drop_up++;
            radio_warn(m, currentTime, "transmit buffer full: byte from the UART lost (air data rate slower than the serial link?)");
        }
    }

    /* 3. air : trame emise arrivee a echeance */
    uartcore_tx_advance(&m->air, currentTime);

    /* 4. air : trame suivante. En semi-duplex, partir en emission coupe la
       trame en cours de reception. */
    if (!m->air.tx_active && radio_q_pop_ready(&m->up, currentTime, &byte)) {
        if (m->half_duplex) {
            radio_abort_air_rx(m, currentTime, "radio frame being received cut by our own transmission (half duplex)");
        }
        uartcore_tx_push(&m->air, byte);
        uartcore_tx_kick(&m->air, currentTime);
        m->n_sent++;
    }

    /* 5. air : reception. Ligne vue au repos tant qu'on est sourd (emission en
       semi-duplex) ou brouille ; le brouillage perd la trame en cours. */
    if (airJam && !m->jam_prev) {
        /* Debut d'une collision : une trame perdue, qu'elle ait deja commence
           ou qu'elle commence avec la collision (deux emetteurs partis au
           meme instant). */
        m->air.rx_state = UART_RX_IDLE;
        m->n_corrupted++;
        radio_warn(m, currentTime, "radio frame lost: two transmitters at the same time (collision)");
    }
    m->jam_prev = airJam ? 1 : 0;
    level = (airJam || (m->half_duplex && m->air.tx_active)) ? 1 : (airLevel ? 1 : 0);
    errors = uartcore_rx_step(&m->air, currentTime, level);
    n = 0;
    while (n < UART_RX_BUF_LEN && uartcore_rx_pop(&m->air, &bytes[n])) {
        n++;
    }
    if (errors) {
        /* Trame fausse (stop bas) : jetee, comme un module reel qui controle
           ses paquets. Typiquement un debit radio different de l'emetteur. */
        m->n_corrupted += n;
        radio_warn(m, currentTime, "corrupted radio frame dropped - same air data rate on both modules?");
    } else {
        int k;
        for (k = 0; k < n; k++) {
            m->n_received++;
            if (!radio_q_push(&m->down, bytes[k], currentTime + m->rx_delay)) {
                m->n_drop_down++;
                radio_warn(m, currentTime, "receive buffer full: radio byte lost (serial link slower than the air data rate?)");
            }
        }
    }

    /* 6. UART : octet suivant vers le microcontroleur */
    if (!m->ser.tx_active && radio_q_pop_ready(&m->down, currentTime, &byte)) {
        uartcore_tx_push(&m->ser, byte);
        uartcore_tx_kick(&m->ser, currentTime);
        m->n_uart_out++;
    }

    /* 7. publier */
    *serTxLevel = uartcore_tx_level(&m->ser, currentTime);
    *airTxLevel = uartcore_tx_level(&m->air, currentTime);
    *carrierOn = m->air.tx_active;
    *airRxBusy = (m->air.rx_state == UART_RX_RECEIVING) ? 1 : 0;
    *txFill = m->up.count;
    *rxFill = m->down.count;
    *airId = m->id;
    *nSent = (int) m->n_sent;
    *nReceived = (int) m->n_received;
    *nDropped = (int) (m->n_drop_up + m->n_drop_down);
    *nCorrupted = (int) m->n_corrupted;

    best = uartcore_deadline(&m->ser, currentTime);
    t = uartcore_deadline(&m->air, currentTime);
    if (t < best) {
        best = t;
    }
    /* Tete de file : n'est une echeance que si l'emetteur concerne est libre ;
       sinon c'est la fin de sa trame qui reveillera. */
    if (!m->air.tx_active && radio_q_next_ready(&m->up) < best) {
        best = radio_q_next_ready(&m->up);
    }
    if (!m->ser.tx_active && radio_q_next_ready(&m->down) < best) {
        best = radio_q_next_ready(&m->down);
    }
    *nextWakeTime = best;
}

#endif /* RADIOMODEM_ENGINE_C_INCLUDED */
