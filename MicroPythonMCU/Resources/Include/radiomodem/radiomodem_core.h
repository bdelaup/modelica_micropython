/* Etat d'un modem radio transparent (Internal.PartialRadioModem).

   Partie de l'implementation incluse TEXTUELLEMENT par RadioModemImpl.c
   (fichier chapeau), jamais compilee seule. Aucune dependance a Python ni aux
   threads.

   Chemin d'un octet, dans chaque sens :
     UART du microcontroleur -> ser (reception) -> file up (delai txDelay)
       -> air (emission, au debit radio)
     air (reception) -> file down (delai rxDelay) -> ser (emission) -> UART

   Les files up/down sont les tampons du module : un octet y reste de la fin de
   sa reception jusqu'au debut de sa reemission. File pleine = octet perdu,
   comme sur le module reel. Les files internes des deux UartEngine ne servent
   jamais de tampon supplementaire : on n'y pousse un octet que quand
   l'emetteur est libre. */

#ifndef RADIOMODEM_CORE_H
#define RADIOMODEM_CORE_H

#define RADIO_BUF_MAX 4096           /* plafond des tampons parametrables (l'APC220 en a 256) */
#define RADIO_NAME_MAX 127
#define RADIO_WARN_MAX 10            /* avertissements au journal, ensuite bilan en fin de simulation */
#define RADIO_MAX_INSTANCES 48       /* identifiants 1..48 : deux emetteurs simultanes gardent une variance relative des identifiants >= 1e-4, loin de la tolerance 1e-6 du test cote Modelica */
#define RADIO_AIR_DATA_BITS 8        /* trame radio : 8N1, quel que soit le format cote UART */

/* File d'octets horodatee : chaque octet porte l'instant a partir duquel il
   peut repartir (fin de reception + delai fixe). */
struct RadioQueue {
    unsigned char data[RADIO_BUF_MAX];
    double ready[RADIO_BUF_MAX];
    int head;                        /* prochain octet a sortir */
    int count;
    int capacity;                    /* taille parametree, <= RADIO_BUF_MAX */
};

struct RadioModem {
    struct UartEngine ser;           /* liaison avec le microcontroleur : rx = octets recus de lui, tx = octets qu'on lui rend */
    struct UartEngine air;           /* liaison radio : tx = trames emises, rx = trames entendues */
    struct RadioQueue up;            /* UART -> air */
    struct RadioQueue down;          /* air -> UART */
    double tx_delay;
    double rx_delay;
    int half_duplex;
    double id;                       /* 1, 2, 3... propre a l'instance, publie dans l'air : reconnaitre sa propre emission et les collisions */
    char name[RADIO_NAME_MAX + 1];

    /* compteurs cumules (bilan de fin, sorties pour les courbes) */
    long n_uart_in;                  /* octets recus du microcontroleur */
    long n_sent;                     /* trames emises dans l'air */
    long n_received;                 /* trames radio recues intactes */
    long n_uart_out;                 /* octets rendus au microcontroleur */
    long n_drop_up;                  /* perdus : tampon d'emission plein */
    long n_drop_down;                /* perdus : tampon de reception plein */
    long n_corrupted;                /* trames radio fausses (erreur de trame), brouillees, ou coupees par l'emission en semi-duplex */
    long n_uart_err;                 /* octets recus du microcontroleur avec erreur de parite/trame (gardes) */
    int warned;
    int jam_prev;                    /* brouillage vu au point de synchro precedent : une collision ne compte qu'une fois, a son debut */
};

#endif /* RADIOMODEM_CORE_H */
