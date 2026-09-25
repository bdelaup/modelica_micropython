/* Garde d'inclusion : ce .c est inclus TEXTUELLEMENT par plusieurs chapeaux
   (PyRuntimeImpl.c et UartDeviceImpl.c). omc dedoublonne les annotations
   Include par leur texte, donc les DEUX chapeaux peuvent se retrouver dans la
   MEME unite de compilation generee - sans cette garde, chaque fonction static
   y serait definie deux fois. */
#ifndef UARTCORE_C_INCLUDED
#define UARTCORE_C_INCLUDED

/* Implementation du moteur UART generique declare dans uartcore.h.

   Inclus TEXTUELLEMENT par un fichier chapeau (PyRuntimeImpl.c ou
   UartDeviceImpl.c), jamais compile seul - cf. uartcore.h pour le pourquoi.

   Ce code a d'abord vecu dans pyruntime/pyruntime_uart.c, ou il etait deja
   entierement independant de Python et des threads ; il en a ete extrait sans
   changement de comportement pour etre partage avec les peripheriques serie
   externes. Seule difference de signature : uartcore_rx_step recoit le niveau
   logique de la ligne (int level) au lieu d'aller le chercher dans un tableau
   de broches, qui est une notion propre au microcontroleur. */

/* --- Files circulaires --- */

static int uartcore_tx_count(struct UartEngine* e) {
    return (e->tx_head - e->tx_tail + UART_TX_BUF_LEN) % UART_TX_BUF_LEN;
}

static int uartcore_rx_count(struct UartEngine* e) {
    return (e->rx_head - e->rx_tail + UART_RX_BUF_LEN) % UART_RX_BUF_LEN;
}

/* Retourne 0 si la file est pleine (octet perdu, comme un vrai FIFO materiel qui deborde). */
static int uartcore_tx_push(struct UartEngine* e, unsigned char byte) {
    int next = (e->tx_head + 1) % UART_TX_BUF_LEN;
    if (next == e->tx_tail) {
        return 0;
    }
    e->tx_buf[e->tx_head] = byte;
    e->tx_head = next;
    return 1;
}

static int uartcore_rx_push(struct UartEngine* e, unsigned char byte) {
    int next = (e->rx_head + 1) % UART_RX_BUF_LEN;
    if (next == e->rx_tail) {
        return 0;
    }
    e->rx_buf[e->rx_head] = byte;
    e->rx_head = next;
    return 1;
}

/* Depile un octet recu. Retourne 0 si la file est vide. */
static int uartcore_rx_pop(struct UartEngine* e, unsigned char* out) {
    if (e->rx_head == e->rx_tail) {
        return 0;
    }
    *out = e->rx_buf[e->rx_tail];
    e->rx_tail = (e->rx_tail + 1) % UART_RX_BUF_LEN;
    return 1;
}

/* --- Configuration --- */

/* Arme le moteur pour une nouvelle liaison : duree de bit et files vides.
   Ne touche volontairement pas a rx_last_level / rx_bit_index / rx_shift /
   tx_bits, qui n'ont de sens qu'en cours de trame. */
static void uartcore_configure(struct UartEngine* e, double bit_dur) {
    e->bit_dur = bit_dur;
    e->rx_state = UART_RX_IDLE;
    e->tx_active = 0;
    e->tx_head = e->tx_tail = 0;
    e->rx_head = e->rx_tail = 0;
}

/* Interrompt emission et reception en cours, sans vider les files. */
static void uartcore_stop(struct UartEngine* e) {
    e->tx_active = 0;
    e->rx_state = UART_RX_IDLE;
}

/* --- Emission --- */

/* Serialise un octet en motif de bits 8N1 (start=0, 8 data LSB first, stop=1) et
   demarre la trame a l'instant 'now'. C'est LE seul endroit qui connait le format
   de trame : passer a un format parametrable (parite, 7/9 bits, 2 stop) ne demande
   de toucher ni Modelica ni le shim Python. */
static void uartcore_tx_begin_frame(struct UartEngine* e, unsigned char byte, double now) {
    int i;
    e->tx_bits[0] = 0.0;                      /* start */
    for (i = 0; i < 8; i++) {
        e->tx_bits[1 + i] = ((byte >> i) & 1) ? 1.0 : 0.0;   /* data, LSB first */
    }
    e->tx_bits[9] = 1.0;                      /* stop */
    for (i = 10; i < UART_MAX_FRAME_BITS; i++) {
        e->tx_bits[i] = 1.0;                  /* inutilise en 8N1 : niveau de repos */
    }
    e->tx_num_bits = 10;
    e->tx_start_time = now;
    e->tx_end_time = now + 10 * e->bit_dur;
    e->tx_active = 1;
}

/* Si rien n'est en cours d'emission et que la file n'est pas vide, demarre tout
   de suite la trame suivante a l'instant 'now'. Sert au demarrage d'une salve
   (uart.write()) comme a l'enchainement d'une trame a la suivante. */
static void uartcore_tx_kick(struct UartEngine* e, double now) {
    if (!e->tx_active && uartcore_tx_count(e) > 0) {
        unsigned char next = e->tx_buf[e->tx_tail];
        e->tx_tail = (e->tx_tail + 1) % UART_TX_BUF_LEN;
        uartcore_tx_begin_frame(e, next, now);
    }
}

/* Fait avancer l'emission : clot la trame arrivee a echeance et charge l'octet
   suivant de la file. A appeler a chaque point de synchro. Pilotee par echeance
   (while now >= tx_end_time), donc rappeler au MEME instant simule ne refait rien. */
static void uartcore_tx_advance(struct UartEngine* e, double now) {
    while (e->tx_active && now + UARTCORE_EPS >= e->tx_end_time) {
        if (uartcore_tx_count(e) > 0) {
            unsigned char next = e->tx_buf[e->tx_tail];
            e->tx_tail = (e->tx_tail + 1) % UART_TX_BUF_LEN;
            /* enchainement sans trou : la trame suivante demarre pile a la fin de la precedente */
            uartcore_tx_begin_frame(e, next, e->tx_end_time);
        } else {
            e->tx_active = 0;   /* file vide : la ligne repasse au repos (niveau haut) */
        }
    }
}

/* --- Reception --- */

/* Decodage de la reception : machine a etats echantillonnant la ligne au MILIEU
   de chaque bit. Entierement ici - Modelica n'a aucune machine a etats a porter,
   il se contente de rappeler la fonction de synchro aux instants demandes via
   nextWakeTime (meme mecanisme que machine.Timer).

   'level' est le niveau logique de la ligne de reception au point de synchro. */
static void uartcore_rx_step(struct UartEngine* e, double now, int level) {
    if (e->rx_state == UART_RX_IDLE) {
        /* Le start se detecte sur un FRONT descendant, jamais sur un simple
           niveau bas : au tout premier point de synchro, la ligne n'est pas
           encore pilotee et vaut 0 V - un test sur le niveau y verrait un bit
           de start et fabriquerait un octet fantome. Exiger le front impose
           d'avoir vu la ligne au repos (niveau haut) au moins une fois avant
           d'ecouter, ce que fait aussi un vrai recepteur UART. */
        if (e->rx_last_level && !level) {
            /* Le premier bit de donnees se lit 1.5 duree de bit plus tard
               (moitie du start + moitie du bit 0). */
            e->rx_state = UART_RX_RECEIVING;
            e->rx_bit_index = 0;
            e->rx_shift = 0;
            e->rx_next_sample = now + 1.5 * e->bit_dur;
        }
        e->rx_last_level = level;
        return;
    }
    e->rx_last_level = level;
    /* En reception on ne se fie qu'aux echeances, jamais aux fronts. */
    while (e->rx_state == UART_RX_RECEIVING && now + UARTCORE_EPS >= e->rx_next_sample) {
        if (e->rx_bit_index < 8) {
            if (level) {
                e->rx_shift |= (1u << e->rx_bit_index);   /* LSB first */
            }
            e->rx_bit_index++;
            e->rx_next_sample += e->bit_dur;
        } else {
            /* Bit de stop : la ligne doit etre revenue au niveau haut. Attendre
               ce bit avant de repasser au repos est indispensable - sinon un
               dernier bit de donnees a 0 serait relu comme un nouveau bit de
               start. Trame invalide (stop bas) = octet ignore, simplification v0. */
            if (level) {
                uartcore_rx_push(e, (unsigned char) (e->rx_shift & 0xFF));
            }
            e->rx_state = UART_RX_IDLE;
        }
    }
}

/* --- Echeances --- */

/* Plus proche echeance propre au moteur (fin de trame en cours, prochain
   echantillon de reception), ou 1e300 si rien n'est en cours. L'appelant y
   ajoute ses propres echeances avant de publier nextWakeTime. */
static double uartcore_deadline(struct UartEngine* e) {
    double best = 1.0e300;
    if (e->tx_active && e->tx_end_time < best) {
        best = e->tx_end_time;
    }
    if (e->rx_state == UART_RX_RECEIVING && e->rx_next_sample < best) {
        best = e->rx_next_sample;
    }
    return best;
}

#endif /* UARTCORE_C_INCLUDED */
