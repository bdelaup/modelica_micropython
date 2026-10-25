/* Moteurs de la carte micro:bit (profil "microbit") : definitions des deux
   moteurs et de l'etat qu'ils partagent, alloue dans board_ext du handle -
   pas dans le handle lui-meme, pour que les cartes sans moteurs ne paient ni
   memoire ni branches (phase 4 du refactoring, cf. pyruntime_board.h).
   Implementation : pyruntime_matrix.c (affichage), pyruntime_radio.c
   (radio), pyruntime_microbit.c (crochets qui les composent).

   Partie de l'implementation du runtime Python, incluse TEXTUELLEMENT par
   PyRuntimeImpl.c (fichier chapeau) : une seule unite de compilation, donc
   pas de #include croise ici - ce fichier n'est jamais compile seul. */
#ifndef PYRUNTIME_MICROBIT_H
#define PYRUNTIME_MICROBIT_H

struct PyRuntimeHandle;

/* Matrice LED 5x5 de la micro:bit : moteur cadence cote C comme l'UART l'est
   pour ses bits (TIMER_MIN_PERIOD et MAX_TIMERS interdisent un balayage
   60 Hz x 5 lignes en callbacks Python). Valeurs du firmware CODAL
   (NRF52LedMatrix) : trame de 60 Hz, un creneau par ligne, LED allumee quand
   sa ligne est HIGH (source, anode) et sa colonne LOW (sink, cathode), la
   colonne restant basse une fraction du creneau proportionnelle au niveau du
   pixel (quantum), puis relachee. Le moteur pilote les 10 broches par la
   table pin_*[] habituelle et demande un reveil a chaque transition reelle -
   pas de quantification, pas de timer Python. */
#define MATRIX_ROWS 5
#define MATRIX_COLS 5
#define MATRIX_FRAME_RATE 60.0       /* Hz, NRF52_LED_MATRIX_FREQUENCY de CODAL */
#define MATRIX_MAX_LEVEL 9          /* niveaux de display.set_pixel() de MicroPython */

/* Moteur de balayage ligne par ligne, cf. pyruntime_matrix.c. */
struct MatrixEngine {
    int enabled;                             /* display.is_on() : le moteur possede les 10 broches */
    int row_idx[MATRIX_ROWS];                /* index interne (table pin_*) de chaque ligne, -1 tant que non configure */
    int col_idx[MATRIX_COLS];                /* idem colonnes */
    unsigned char pixels[MATRIX_ROWS][MATRIX_COLS];  /* niveaux 0-9, pixels[ligne][colonne] */
    double t0;                               /* ancre des trames (instant d'activation, phase arbitraire) */
};

/* microbit.radio : moteur de paquets, cf. pyruntime_radio.c. Les paquets
   voyagent ENTRE les moteurs radio du process (tous les microcontroleurs
   d'un meme modele partagent l'exe) : l'emetteur les pose dans la file
   d'arrivee du recepteur avec l'instant ou l'air les livre, le recepteur les
   filtre (channel/group/address de SA config, comme le materiel qui filtre
   a la reception) et les met en file a la profondeur queue. Defauts et
   bornes du firmware micro:bit (radio.config). */
#define RADIO_MAX_PAYLOAD 251        /* radio.config(length=...) : 251 max */
#define RADIO_MAX_QUEUE 32           /* profondeur de la file de reception (queue) */
#define RADIO_INBOX_MAX 64           /* paquets en transit vers ce moteur (file d'arrivee) */
#define RADIO_OVERHEAD 6             /* en-tete micro:bit : address(4) + group(1) + length(1) */
#define RADIO_REGISTRY_MAX 32        /* moteurs radio du process (un par micro:bit demarree) */
#define RADIO_DEFAULT_LENGTH 32
#define RADIO_DEFAULT_QUEUE 3
#define RADIO_DEFAULT_CHANNEL 7
#define RADIO_DEFAULT_POWER 6        /* puissance d'emission 0-7 : pas simulee, acceptee */
#define RADIO_DEFAULT_ADDRESS 0x75626974  /* "ubit", petit-boutiste, defaut du firmware */
#define RADIO_DEFAULT_GROUP 0
#define RADIO_WARN_MAX 10            /* avertissements de paquets jetes, plafonnes comme UART */

struct RadioPacket {
    double arrival;                  /* temps simule auquel l'air livre le paquet au recepteur */
    int channel;                     /* canal de l'EMETTEUR : frequence physique, filtre a la reception */
    int group;                       /* groupe de l'en-tete de l'emetteur : filtre par le RECEPTEUR */
    int address;                     /* adresse de l'en-tete de l'emetteur : idem */
    unsigned char payload[RADIO_MAX_PAYLOAD];
    int len;
};

struct RadioEngine {
    int on;
    int network_id;                  /* ecrit par PyRuntime_sync (vient du modele), -1 = pas d'antenne cablee */
    int length, queue, channel, group, address, power;
    int data_rate;                   /* 1 ou 2 : Mbit/s, duree de trame a l'air */
    struct RadioPacket inbox[RADIO_INBOX_MAX];  /* en transit, triee par arrival croissante */
    int inbox_len;
    struct RadioPacket rx[RADIO_MAX_QUEUE];     /* livres et filtres, la plus ancienne en tete */
    int rx_len;
    int rx_dropped;                  /* paquets perdus (file pleine, radio eteinte), bilan de fin */
    int warned;                      /* avertissements deja emis (plafond RADIO_WARN_MAX) */
};

/* Etat des moteurs de la micro:bit : alloue au boot (crochet boot de
   pyruntime_microbit.c) et pointe par PyRuntimeHandle.board_ext. Les
   broches liberees par display.off() y marquent leur premiere transition a
   ignorer (crochet pin_released). */
struct MicroBitBoard {
    struct MatrixEngine matrix;              /* cf. pyruntime_matrix.c */
    struct RadioEngine radio;                /* cf. pyruntime_radio.c */
    int pin_released[MAX_PINS];              /* broches liberees par display.off(), cf. le hook pin_released */
    struct PyRuntimeHandle* h;              /* pour le registre radio et les avertissements */
};

#endif
