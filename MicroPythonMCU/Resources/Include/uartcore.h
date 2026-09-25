/* Moteur UART generique : files circulaires TX/RX, serialisation d'une trame
   8N1, decodage de la reception par echantillonnage au milieu de chaque bit,
   et calcul de la prochaine echeance.

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
#define UART_MAX_FRAME_BITS 13       /* 1 start + 9 data + 1 parite + 2 stop : dimensionne pour un futur format parametrable, seul 8N1 (10 bits) est emis en v0 - doit rester aligne sur Interfaces.UART_MAX_FRAME_BITS cote Modelica */
#define UART_MIN_BAUD 50
#define UART_MAX_BAUD 115200         /* garde-fou contre une tempete d'evenements Modelica (un evenement par front de bit), meme esprit que TIMER_MIN_PERIOD */
#define UART_RX_IDLE 0
#define UART_RX_RECEIVING 1

/* Tolerance de comparaison des echeances. Duplique volontairement la valeur de
   PYRUNTIME_EPS plutot que d'en dependre : ce moteur doit rester utilisable par
   un chapeau qui n'inclut pas pyruntime_core.h. */
#define UARTCORE_EPS 1e-9

struct UartEngine {
    double bit_dur;                   /* duree d'un bit (1/baudrate), en secondes */

    unsigned char tx_buf[UART_TX_BUF_LEN];
    int tx_head, tx_tail;             /* file circulaire : head = prochaine ecriture, tail = prochaine lecture */
    int tx_active;                    /* une trame est en cours d'emission */
    double tx_start_time;             /* instant du front de start de la trame en cours */
    double tx_end_time;               /* instant de fin de la trame en cours (rechargement de la suivante) */
    double tx_bits[UART_MAX_FRAME_BITS]; /* motif de bits complet (start + data + stop), publie tel quel vers Modelica */
    int tx_num_bits;

    unsigned char rx_buf[UART_RX_BUF_LEN];
    int rx_head, rx_tail;
    int rx_state;                     /* UART_RX_IDLE | UART_RX_RECEIVING */
    int rx_last_level;                /* niveau vu au dernier point de synchro : le start se detecte sur un FRONT descendant, pas sur un niveau bas (cf. uartcore_rx_step) */
    double rx_next_sample;            /* prochain instant d'echantillonnage, que l'appelant remonte a Modelica via nextWakeTime */
    int rx_bit_index;                 /* 0-7 : bit de donnee en cours */
    unsigned int rx_shift;            /* registre a decalage */
};

#endif /* UARTCORE_H */
