/* Moteur UART generique : files circulaires TX/RX, serialisation d'une trame
   au format choisi (5-8 bits, parite, 1-2 stops), niveau de la ligne d'emission, decodage de la reception a partir des
   fronts, et calcul de la prochaine echeance.

   ECONOMIE D'EVENEMENTS (chaque evenement Modelica fait redemarrer le
   solveur) : l'emission ne demande un reveil qu'aux CHANGEMENTS de niveau, pas
   a chaque frontiere de bit ; la reception ne programme qu'UN reveil par
   octet (milieu du bit de stop), les bits de donnees etant reconstitues a
   partir des fronts, qui reveillent deja la synchro de toute facon - cf.
   requirements.md, decision "UART electrique reel".

   CE FICHIER NE DEPEND NI DE PYTHON NI DES THREADS, et c'est tout son interet :
   le meme moteur sert au peripherique UART du microcontroleur (machine.UART,
   cote PyRuntimeImpl.c) et aux peripheriques serie externes branches sur les
   broches (Peripherals.UartDevice, cote UartDeviceImpl.c). Tout ce qui touche
   aux broches, au choix des broches TX/RX ou a l'interpreteur Python reste chez
   l'appelant - cf. requirements.md, decision "Peripheriques UART externes".

   Inclus TEXTUELLEMENT par un fichier chapeau (PyRuntimeImpl.c ou
   UartDeviceImpl.c) : une unite de compilation par chapeau, tout est declare
   static, donc aucune collision de symboles entre les deux. Ce fichier n'est
   jamais compile seul.

   Le verrouillage n'est PAS du ressort de ce moteur : l'appelant garantit
   l'exclusion mutuelle (cote PyRuntime, h->cs est deja tenu par l'appelant de
   chaque fonction). */

#ifndef UARTCORE_H
#define UARTCORE_H

#define UART_TX_BUF_LEN 256          /* file d'emission : une phrase NMEA complete (82 caracteres au plus selon la norme) doit y tenir d'un bloc - a 64, sa fin etait perdue */
#define UART_RX_BUF_LEN 256          /* file de reception, meme dimensionnement */
#define UART_MAX_FRAME_BITS 13       /* 1 start + 9 data + 1 parite + 2 stop ; le port rp2 s'arrete a 8 bits de donnees (12 bits au plus) */
#define UART_MIN_DATA_BITS 5
#define UART_MAX_DATA_BITS 8
#define UART_PARITY_NONE (-1)        /* meme convention que machine.UART : None, 0 = paire, 1 = impaire */
#define UART_PARITY_EVEN 0
#define UART_PARITY_ODD 1
#define UART_MIN_BAUD 50
#define UART_MAX_BAUD 115200         /* garde-fou contre une tempete d'evenements Modelica (jusqu'a un evenement par front de bit), meme esprit que TIMER_MIN_PERIOD */
#define UART_RX_IDLE 0
#define UART_RX_RECEIVING 1

/* Erreurs de reception rendues par uartcore_rx_step (masque). L'octet est
   quand meme livre, comme le FIFO du RP2040 qui le stocke avec un drapeau
   d'erreur : c'est a l'appelant de le signaler (le moteur ne journalise rien). */
#define UART_ERR_PARITY 1
#define UART_ERR_FRAMING 2

/* Tolerance de comparaison des echeances. Duplique volontairement la valeur de
   PYRUNTIME_EPS plutot que d'en dependre : ce moteur doit rester utilisable par
   un chapeau qui n'inclut pas pyruntime_core.h. */
#define UARTCORE_EPS 1e-9

struct UartEngine {
    double bit_dur;                   /* duree d'un bit (1/baudrate), en secondes */
    int data_bits;                    /* 5 a 8 */
    int parity;                       /* UART_PARITY_NONE | _EVEN | _ODD */
    int stop_bits;                    /* 1 ou 2 (le recepteur ne controle que le premier, comme le materiel) */

    unsigned char tx_buf[UART_TX_BUF_LEN];
    int tx_head, tx_tail;             /* file circulaire : head = prochaine ecriture, tail = prochaine lecture */
    int tx_active;                    /* une trame est en cours d'emission */
    double tx_start_time;             /* instant du front de start de la trame en cours */
    double tx_end_time;               /* instant de fin de la trame en cours (rechargement de la suivante) */
    double tx_bits[UART_MAX_FRAME_BITS]; /* motif de bits complet (start + data + stop) ; Modelica ne recoit que le niveau courant (uartcore_tx_level) */
    int tx_num_bits;

    unsigned char rx_buf[UART_RX_BUF_LEN];
    int rx_head, rx_tail;
    int rx_state;                     /* UART_RX_IDLE | UART_RX_RECEIVING */
    int rx_last_level;                /* niveau vu au dernier point de synchro : c'est le niveau TENU depuis le dernier front, et le start se detecte sur un FRONT descendant, pas sur un niveau bas (cf. uartcore_rx_step) */
    double rx_next_sample;            /* milieu du prochain bit a resoudre (pas un reveil : les bits se resolvent aux fronts, cf. uartcore_rx_step) */
    double rx_stop_sample;            /* milieu du (premier) bit de stop : SEUL reveil programme par octet, remonte a Modelica via nextWakeTime */
    int rx_bit_index;                 /* 0 a data_bits-1 : bit de donnee en cours, puis bit de parite eventuel, puis bit de stop */
    unsigned int rx_shift;            /* registre a decalage */
    int rx_frame_err;                 /* erreurs vues sur la trame en cours (UART_ERR_*) */
    long rx_parity_errors;            /* cumul depuis la construction, pour le bilan de fin */
    long rx_framing_errors;
};

#endif /* UARTCORE_H */
