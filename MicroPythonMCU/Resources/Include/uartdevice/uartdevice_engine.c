/* Moteur d'un peripherique serie externe : construction, ordonnancement et
   point de synchro appele par Modelica.

   Inclus TEXTUELLEMENT par UartDeviceImpl.c, jamais compile seul.

   ORDRE DES OPERATIONS DANS UartDevice_sync (ne pas le changer a la legere) :
     1. recopier les grandeurs venues du modele
     2. faire avancer l'emission (trame close -> octet suivant)
     3. faire avancer le decodage de la reception
     4. drainer les octets recus vers l'accumulateur de ligne
     5. echeances d'emission (reponse armee, tick periodique)
     6. publier vers Modelica
     7. nextWakeTime = min des echeances

   Les etapes 2, 3 et 5 sont toutes de la forme "while (now >= echeance)", et
   l'etape 4 consomme les octets. Rappeler la fonction au MEME instant simule ne
   refait donc rien : c'est indispensable, Modelica rappelant une fonction
   externe plusieurs fois par instant (2-3 iterations d'evenement, cf. la boucle
   de drain de pyruntime_module.c). C'est aussi ce qui permettra a la phase 2
   d'y loger une machine d'etat sans qu'elle rejoue ses transitions. */

#ifndef UARTDEVICE_ENGINE_C_INCLUDED
#define UARTDEVICE_ENGINE_C_INCLUDED

/* =====================================================================
   LES DEUX POINTS DE DECISION - les seuls endroits ou les modes Table et
   Script different. Tout le reste du moteur (electrique, decodage,
   ordonnancement, emission) leur est commun.
   Garantie contractuelle : uartdev_on_line est appele UNE FOIS PAR LIGNE
   COMPLETE et uartdev_on_tick UNE FOIS PAR ECHEANCE FRANCHIE - c'est ce qui
   permet a un script d'y loger une machine d'etat sans qu'elle rejoue ses
   transitions a chaque iteration d'evenement de Modelica.
   ===================================================================== */

/* Ligne complete recue (len octets, terminateur exclu). Ecrit la reponse dans
   'out' et retourne sa longueur, ou 0 s'il n'y a rien a repondre. */
static int uartdev_on_line(struct UartDevice* dev, const char* line, int len, char* out, int outmax) {
    int n;
    if (dev->mode == UARTDEV_MODE_SCRIPT) {
        return uartdev_script_on_line(dev, line, len, out, outmax);
    }
    if (!dev->respond_enabled) {
        return 0;
    }
    n = uartdev_lookup(dev, line, out, outmax);
    return (n < 0) ? 0 : n;
}

/* Echeance d'emission periodique franchie. Meme convention de retour. */
static int uartdev_on_tick(struct UartDevice* dev, double now, char* out, int outmax) {
    (void) now;
    if (dev->mode == UARTDEV_MODE_SCRIPT) {
        return uartdev_script_on_tick(dev, out, outmax);
    }
    if (!dev->periodic_enabled) {
        return 0;
    }
    return uartdev_format(out, outmax, dev->periodic_template, dev->value_in);
}

/* ===================== helpers internes ===================== */

static void uartdev_copy_bounded(char* dst, int dstmax, const char* src) {
    int n = (int) strlen(src);
    if (n > dstmax) {
        n = dstmax;
    }
    memcpy(dst, src, (size_t) n);
    dst[n] = '\0';
}

/* Pousse une charge utile dans la file d'emission et note ce qui est parti.
   Le surplus au-dela de la file est perdu silencieusement, comme un FIFO
   materiel qui deborde (meme choix que machine.UART). */
static void uartdev_emit(struct UartDevice* dev, const char* payload, int len, double now) {
    int i;
    if (len <= 0) {
        return;
    }
    for (i = 0; i < len; i++) {
        if (!uartcore_tx_push(&dev->io, (unsigned char) payload[i])) {
            break;
        }
    }
    uartcore_tx_kick(&dev->io, now);
    uartdev_copy_bounded(dev->last_tx, UARTDEV_PAYLOAD_MAX, payload);
    dev->event_seq++;
}

/* Arme une reponse a emettre apres response_delay. Si une reponse est deja en attente,
   la nouvelle est CONCATENEE plutot que perdue : les deux sortiraient de toute
   facon l'une derriere l'autre sur la ligne. */
static void uartdev_arm_response(struct UartDevice* dev, const char* payload, int len, double now) {
    int room;
    if (len <= 0) {
        return;
    }
    if (!dev->pending_armed) {
        dev->pending_len = 0;
        dev->pending_armed = 1;
        dev->pending_time = now + dev->response_delay;
    }
    room = UARTDEV_PAYLOAD_MAX - dev->pending_len;
    if (len > room) {
        len = room;
    }
    memcpy(dev->pending + dev->pending_len, payload, (size_t) len);
    dev->pending_len += len;
    dev->pending[dev->pending_len] = '\0';
}

/* Plus proche echeance, toutes sources confondues. */
static double uartdev_deadline(struct UartDevice* dev) {
    double best = uartcore_deadline(&dev->io);
    if (dev->pending_armed && dev->pending_time < best) {
        best = dev->pending_time;
    }
    if (dev->periodic_enabled && dev->next_emit_time < best) {
        best = dev->next_emit_time;
    }
    return best;
}

/* ===================== API exportee ===================== */

void* UartDevice_new(double baudrate, const char* commandTable, const char* terminator,
                      double responseDelay, int respondEnabled, int echoEnabled,
                      int periodicEnabled, double period, const char* periodicTemplate,
                      double valueOutStart, int mode, const char* scriptPath,
                      const char* pythonHome, const char* instanceName) {
    struct UartDevice* dev;
    int k;

    if (baudrate < UART_MIN_BAUD || baudrate > UART_MAX_BAUD) {
        ModelicaFormatError("UartDevice : baudrate %g hors bornes (%d-%d) - garde-fou contre une tempete d'evenements Modelica",
                            baudrate, UART_MIN_BAUD, UART_MAX_BAUD);
        return NULL;
    }
    if (responseDelay < 0) {
        ModelicaFormatError("UartDevice : responseDelay %g s negatif", responseDelay);
        return NULL;
    }
    /* Le terminateur arrive en CHAINE pour pouvoir s'ecrire "\n" cote Modelica ;
       seul son premier caractere compte. */
    if (!terminator || terminator[0] == '\0') {
        ModelicaFormatError("UartDevice : terminator vide - indiquer le caractere de fin de commande, par exemple un saut de ligne");
        return NULL;
    }
    if (mode != UARTDEV_MODE_TABLE && mode != UARTDEV_MODE_SCRIPT) {
        ModelicaFormatError("UartDevice : comportement inconnu (%d)", mode);
        return NULL;
    }

    dev = (struct UartDevice*) calloc(1, sizeof(struct UartDevice));
    if (!dev) {
        ModelicaFormatError("UartDevice : allocation impossible");
        return NULL;
    }

    /* rx_last_level RESTE A 0 (valeur de calloc), et ce n'est pas un oubli.
       Le decodeur exige un FRONT descendant pour armer : partir de 0 l'oblige a
       voir d'abord la ligne monter au repos avant de pouvoir ecouter, ce que
       fait aussi un vrai recepteur UART.
       Partir de 1 fabrique un octet fantome des le premier point de synchro, et
       desynchronise tout le reste : a t=0 la ligne n'est PAS au repos haut. Tant
       que le script n'a pas configure son UART, la broche du microcontroleur est
       une entree, et le tirage RPullUp se retrouve en diviseur avec la fuite de
       l'interrupteur ouvert du pont GPIO - le noeud est a ~0,3 V, donc bas. Vu
       depuis un etat initial a 1, cela ressemble a un front descendant.
       Meme piege que celui deja trouve et corrige cote microcontroleur. */
    uartcore_configure(&dev->io, 1.0 / baudrate);

    dev->respond_enabled = respondEnabled ? 1 : 0;
    dev->echo_enabled = echoEnabled ? 1 : 0;
    dev->terminator = (unsigned char) terminator[0];
    dev->response_delay = responseDelay;
    uartdev_copy_bounded(dev->table, UARTDEV_TABLE_MAX, commandTable ? commandTable : "");

    dev->periodic_enabled = periodicEnabled ? 1 : 0;
    dev->period = period;
    dev->next_emit_time = period;    /* la premiere trame part au bout d'une periode, pas a t=0 */
    uartdev_copy_bounded(dev->periodic_template, UARTDEV_PAYLOAD_MAX, periodicTemplate ? periodicTemplate : "");

    for (k = 0; k < UARTDEV_MAX_VALUES; k++) {
        dev->value_out[k] = valueOutStart;
    }

    dev->mode = mode;
    uartdev_copy_bounded(dev->script_path, UARTDEV_PATH_MAX, scriptPath ? scriptPath : "");

    /* Mode Script : le contenu des trames vient du script, pas des parametres.
       L'emission periodique est active si et seulement si le script definit
       on_tick() - la periode, elle, reste un parametre. L'echo octet par octet
       et la table n'ont plus de sens : c'est on_receive() qui decide. */
    if (mode == UARTDEV_MODE_SCRIPT) {
        uartdev_script_load(dev, pythonHome, instanceName);
        dev->periodic_enabled = dev->py_on_tick ? 1 : 0;
        dev->echo_enabled = 0;
    }

    if (dev->periodic_enabled && period < UARTDEV_MIN_PERIOD) {
        ModelicaFormatError("UartDevice : period %g s trop courte (plancher %g s) - sinon suite non bornee d'evenements a temps simule constant",
                            period, UARTDEV_MIN_PERIOD);
        return NULL;
    }

    return (void*) dev;
}

void UartDevice_destroy(void* dev_) {
    /* Chaque simulation tourne dans son propre process, qui se termine juste
       apres cet appel : l'OS recupere tout. Meme choix delibere que
       PyRuntime_destroy - cf. requirements.md. */
    (void) dev_;
}

void UartDevice_sync(void* dev_, double currentTime, int rxLevel, const double* valueIn,
                      double* valueOut, int* txActiveOut, double* txStartOut,
                      int* txNumBitsOut, double* txBitsOut, int* rxBusyOut,
                      int* eventSeqOut, const char** lastRxOut, const char** lastTxOut,
                      double* nextWakeTime) {
    struct UartDevice* dev = (struct UartDevice*) dev_;
    char payload[UARTDEV_PAYLOAD_MAX + 1];
    unsigned char byte;
    double deadline;
    int k, n, echoed = 0;

    /* 1. grandeurs venues du modele */
    dev->now = currentTime;
    for (k = 0; k < UARTDEV_MAX_VALUES; k++) {
        dev->value_in[k] = valueIn[k];
    }

    /* 2. emission : clore la trame arrivee a echeance, charger la suivante */
    uartcore_tx_advance(&dev->io, currentTime);

    /* 3. reception : front de start, puis un echantillon par bit */
    uartcore_rx_step(&dev->io, currentTime, rxLevel);

    /* 4. drainer les octets recus vers l'accumulateur de ligne */
    while (uartcore_rx_pop(&dev->io, &byte)) {
        if (dev->echo_enabled) {
            uartcore_tx_push(&dev->io, byte);
            echoed = 1;
        }
        if (byte == dev->terminator) {
            dev->rx_line[dev->rx_line_len] = '\0';
            uartdev_copy_bounded(dev->last_rx, UARTDEV_LINE_MAX, dev->rx_line);
            dev->event_seq++;
            /* UNE SEULE FOIS PAR LIGNE : elle est consommee dans le meme geste. */
            n = uartdev_on_line(dev, dev->rx_line, dev->rx_line_len, payload, UARTDEV_PAYLOAD_MAX);
            if (n > 0) {
                uartdev_arm_response(dev, payload, n, currentTime);
            }
            dev->rx_line_len = 0;
            dev->rx_line_truncated = 0;
        } else if (dev->rx_line_len < UARTDEV_LINE_MAX) {
            dev->rx_line[dev->rx_line_len++] = (char) byte;
        } else {
            dev->rx_line_truncated = 1;
        }
    }
    if (echoed) {
        uartcore_tx_kick(&dev->io, currentTime);
    }

    /* 5. echeances d'emission */
    if (dev->pending_armed && currentTime + UARTCORE_EPS >= dev->pending_time) {
        uartdev_emit(dev, dev->pending, dev->pending_len, currentTime);
        dev->pending_armed = 0;
        dev->pending_len = 0;
    }
    while (dev->periodic_enabled && currentTime + UARTCORE_EPS >= dev->next_emit_time) {
        /* UNE SEULE FOIS PAR ECHEANCE FRANCHIE : next_emit_time avance a chaque tour. */
        n = uartdev_on_tick(dev, currentTime, payload, UARTDEV_PAYLOAD_MAX);
        if (n > 0) {
            uartdev_emit(dev, payload, n, currentTime);
        }
        dev->next_emit_time += dev->period;
    }

    /* 6. publier */
    *txActiveOut = dev->io.tx_active;
    *txStartOut = dev->io.tx_start_time;
    *txNumBitsOut = dev->io.tx_num_bits;
    for (k = 0; k < UART_MAX_FRAME_BITS; k++) {
        txBitsOut[k] = dev->io.tx_bits[k];
    }
    for (k = 0; k < UARTDEV_MAX_VALUES; k++) {
        valueOut[k] = dev->value_out[k];
    }
    *rxBusyOut = (dev->io.rx_state == UART_RX_RECEIVING) ? 1 : 0;
    *eventSeqOut = dev->event_seq;
    *lastRxOut = ModelicaAllocateString(strlen(dev->last_rx));
    strcpy((char*) *lastRxOut, dev->last_rx);
    *lastTxOut = ModelicaAllocateString(strlen(dev->last_tx));
    strcpy((char*) *lastTxOut, dev->last_tx);

    /* 7. prochain reveil */
    deadline = uartdev_deadline(dev);
    *nextWakeTime = deadline;
}

#endif /* UARTDEVICE_ENGINE_C_INCLUDED */
