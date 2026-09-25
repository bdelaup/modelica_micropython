/* Etat d'un peripherique serie externe (Peripherals.UartDevice).

   Partie de l'implementation incluse TEXTUELLEMENT par UartDeviceImpl.c
   (fichier chapeau) : une seule unite de compilation, pas de #include croise
   ici, aucune etape de build supplementaire - meme idiome que pyruntime/.
   Ce fichier n'est jamais compile seul.

   AUCUNE DEPENDANCE A PYTHON NI AUX THREADS en phase 1 : le comportement est
   entierement decrit par des parametres Modelica. La phase 2 n'ajoutera que le
   corps de uartdev_on_line / uartdev_on_tick - cf. requirements.md, decision
   "Peripheriques UART externes connectables". */

#ifndef UARTDEVICE_CORE_H
#define UARTDEVICE_CORE_H

#define UARTDEV_MAX_VALUES 4         /* grandeurs reelles echangees avec le modele ({v1}..{v4}, {o1}..{o4}) - dimensionnement modeste, esprit des 8 broches et des 4 Timer */
#define UARTDEV_TABLE_MAX 511        /* table "CMD=>REPONSE|CMD=>REPONSE" brute */
#define UARTDEV_LINE_MAX 127         /* accumulateur de ligne recue */
#define UARTDEV_PAYLOAD_MAX 127      /* charge utile a emettre */
#define UARTDEV_PATH_MAX 511
#define UARTDEV_MIN_PERIOD 0.001     /* plancher d'emission periodique : evite une tempete d'evenements Modelica a duree simulee nulle, meme esprit que TIMER_MIN_PERIOD */

#define UARTDEV_MODE_TABLE 1         /* aligne sur Peripherals.UartDevice.Comportement */
#define UARTDEV_MODE_SCRIPT 2

struct UartDevice {
    struct UartEngine io;            /* files TX/RX, trame 8N1, decodage : cf. uartcore.h, partage avec le microcontroleur */

    /* --- requete/reponse --- */
    int respond_enabled;
    int echo_enabled;                /* renvoie chaque octet recu tel quel (peripherique d'echo) */
    unsigned char terminator;        /* octet de fin de commande (10 = '\n' par defaut) */
    double response_delay;           /* un vrai capteur met du temps a repondre */
    char table[UARTDEV_TABLE_MAX + 1];

    char rx_line[UARTDEV_LINE_MAX + 1];
    int rx_line_len;
    int rx_line_truncated;           /* ligne plus longue que l'accumulateur : le surplus est perdu, comme un FIFO qui deborde */

    /* --- emission differee : reponse armee. Au plus une en attente ; une
       seconde correspondance pendant ce delai est CONCATENEE a la premiere
       plutot que perdue (les deux sortiraient de toute facon a la suite). --- */
    char pending[UARTDEV_PAYLOAD_MAX + 1];
    int pending_len;
    int pending_armed;
    double pending_time;

    /* --- emission periodique --- */
    int periodic_enabled;
    double period;
    double next_emit_time;
    char periodic_template[UARTDEV_PAYLOAD_MAX + 1];

    /* --- grandeurs reelles echangees avec le reste du modele --- */
    double value_in[UARTDEV_MAX_VALUES];   /* recopie du RealInput a chaque synchro, substitue par {vN} */
    double value_out[UARTDEV_MAX_VALUES];  /* alimente par la capture {oN}, MAINTENU entre deux trames */

    /* --- observabilite (journal, icone, afficheur) --- */
    int event_seq;                   /* incremente a chaque ligne recue ou charge utile emise */
    char last_rx[UARTDEV_LINE_MAX + 1];
    char last_tx[UARTDEV_PAYLOAD_MAX + 1];

    int mode;                        /* UARTDEV_MODE_TABLE | UARTDEV_MODE_SCRIPT */
    char script_path[UARTDEV_PATH_MAX + 1];
    double now;                      /* instant du point de synchro en cours, transmis aux gestionnaires */

    /* --- mode Script (cf. uartdevice_script.c) : references fortes, jamais
       relachees (le process se termine a la fin de la simulation, meme choix
       assume que PyRuntime_destroy). NULL en mode Table. --- */
    PyObject* py_globals;            /* espace de noms propre a CETTE instance */
    PyObject* py_on_receive;
    PyObject* py_on_tick;
    PyObject* py_outputs;
};

#endif /* UARTDEVICE_CORE_H */
