/* Moteur I2C CIBLE (esclave) generique, PARTAGE par les peripheriques I2C
   (I2cDeviceImpl.c, Internal.PartialI2cDevice) et par machine.I2CTarget du
   microcontroleur (PyRuntimeImpl.c) : decodage des START / adresse / octets /
   ACK / STOP du maitre a partir des niveaux de SCL et SDA, et pilotage de SDA en
   drain ouvert. Sans Python ni thread : ce qu'on fait des octets (script de
   peripherique, memoire ou files du microcontroleur) passe par des crochets.

   Meme idiome que uartcore.h/.c : inclus TEXTUELLEMENT par un chapeau, jamais
   compile seul ; garde d'inclusion obligatoire, les deux chapeaux pouvant
   atterrir dans la meme unite de compilation (omc dedoublonne les Include par
   leur texte). */

#ifndef I2CTARGET_H_INCLUDED
#define I2CTARGET_H_INCLUDED

#define I2CT_MAX_ADDR 4              /* adresses auxquelles une meme cible repond (ex. ecran Grove : 0x3E et 0x62) */
#define I2CT_BUF_MAX 256             /* octets d'une phase d'ecriture (ou de lecture, pour le journal) */

/* Etat du decodeur, avance par les FRONTS de SCL et SDA. */
#define I2CT_IDLE 0                  /* bus libre : on attend un START */
#define I2CT_ADDR 1                  /* reception de l'octet d'adresse */
#define I2CT_WRITE 2                 /* adresse reconnue, le maitre ecrit */
#define I2CT_READ 3                  /* adresse reconnue, le maitre lit */
#define I2CT_WAIT 4                  /* pas pour nous, ou lecture close par NACK : on attend STOP ou START */

/* read_byte peut rendre I2CT_DEFER (si may_defer) : l'octet n'est pas encore
   disponible, l'hote doit appeler i2ct_resume() au MEME instant, apres avoir
   laisse un programme le fournir (gestionnaire IRQ_READ_REQ du microcontroleur). */
#define I2CT_DEFER (-1)

struct I2cTargetHooks {
    /* adresse reconnue ; read = 1 si le maitre va lire (facultatif) */
    void (*addr_match)(void* ctx, int addr, int read);
    /* un octet de donnees vient d'etre recu et acquitte (facultatif) */
    void (*write_byte)(void* ctx, int addr, unsigned char b);
    /* phase d'ecriture close (STOP, START repete) ; len = 0 pour une sonde d'adresse */
    void (*write_end)(void* ctx, int addr, const unsigned char* data, int len);
    /* octet a sortir (0-255), 0xFF faute de mieux, ou I2CT_DEFER si may_defer */
    int (*read_byte)(void* ctx, int addr, int may_defer);
    /* phase de lecture close (NACK du maitre, STOP, START repete) ; data = octets sortis */
    void (*read_end)(void* ctx, int addr, const unsigned char* data, int len);
};

struct I2cTarget {
    int addresses[I2CT_MAX_ADDR];
    int n_addr;

    /* niveaux vus au dernier appel (les fronts s'en deduisent) */
    int levels_known;
    int scl;
    int sda;

    int state;
    int nbits;                       /* impulsions d'horloge vues dans l'octet courant (0-9) */
    unsigned int shift;              /* bits recus, poids fort en tete */
    int addr;                        /* adresse de la phase en cours */
    int drive_low;                   /* SORTIE : SDA tiree a la masse (drain ouvert) */

    unsigned char wbuf[I2CT_BUF_MAX];
    int wlen;
    int write_open;

    unsigned char cur;               /* octet en cours de sortie */
    int master_ack;
    int read_open;
    int read_deferred;               /* octet demande, en attente de i2ct_resume() */
    unsigned char rlog[I2CT_BUF_MAX];
    int rlog_len;

    const struct I2cTargetHooks* hooks;
    void* ctx;
};

#endif /* I2CTARGET_H_INCLUDED */
