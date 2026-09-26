/* Etat d'un peripherique I2C esclave externe (Internal.PartialI2cDevice).

   Partie de l'implementation incluse TEXTUELLEMENT par I2cDeviceImpl.c
   (fichier chapeau) : une seule unite de compilation, pas de #include croise
   ici, aucune etape de build supplementaire - meme idiome que uartdevice/.
   Ce fichier n'est jamais compile seul. */

#ifndef I2CDEVICE_CORE_H
#define I2CDEVICE_CORE_H

#define I2CDEV_MAX_VALUES 4          /* grandeurs reelles echangees avec le modele - aligne sur Interfaces.I2C_DEV_MAX_VALUES */
#define I2CDEV_MAX_ADDR 4            /* adresses auxquelles un meme composant repond (ex. ecran Grove : 0x3E et 0x62) */
#define I2CDEV_BUF_MAX 256           /* octets d'une phase d'ecriture, ou lot rendu par on_read() */
#define I2CDEV_PATH_MAX 511
#define I2CDEV_TEXT_MAX 80           /* une ligne rendue par lines() */
#define I2CDEV_EVENT_MAX 160         /* resume de la derniere transaction, pour le journal */

/* Etat du decodeur, avance par les FRONTS de SCL et SDA vus depuis Modelica. */
#define I2CDEV_IDLE 0                /* bus libre : on attend un START */
#define I2CDEV_ADDR 1                /* reception de l'octet d'adresse */
#define I2CDEV_WRITE 2               /* adresse reconnue, le maitre ecrit */
#define I2CDEV_READ 3                /* adresse reconnue, le maitre lit */
#define I2CDEV_WAIT 4                /* pas pour nous, ou lecture close par NACK : on attend STOP ou START */

struct I2cDevice {
    int addresses[I2CDEV_MAX_ADDR];
    int n_addr;

    /* niveaux vus au dernier point de synchro (les fronts s'en deduisent) */
    int levels_known;
    int scl;
    int sda;

    int state;
    int nbits;                       /* impulsions d'horloge vues dans l'octet courant (0-9) */
    unsigned int shift;              /* bits recus, poids fort en tete */
    int addr;                        /* adresse de la phase en cours */
    int drive_low;                   /* SORTIE : SDA tiree a la masse (drain ouvert) */

    /* phase d'ecriture : octets accumules, livres d'un bloc a on_write() */
    unsigned char wbuf[I2CDEV_BUF_MAX];
    int wlen;
    int write_open;

    /* phase de lecture : octets fournis par on_read(), sortis un par un */
    unsigned char rbuf[I2CDEV_BUF_MAX];
    int rlen;
    int rpos;
    unsigned char cur;
    int master_ack;
    int read_open;
    unsigned char rlog[I2CDEV_BUF_MAX];  /* octets effectivement sortis, pour le journal */
    int rlog_len;

    /* grandeurs echangees avec le reste du modele */
    double value_in[I2CDEV_MAX_VALUES];
    double value_out[I2CDEV_MAX_VALUES];

    /* observabilite (journal, icone) */
    int event_seq;                   /* incremente a chaque phase d'ecriture ou de lecture close */
    char last_event[I2CDEV_EVENT_MAX + 1];
    char line1[I2CDEV_TEXT_MAX + 1]; /* texte rendu par lines(), pour un afficheur */
    char line2[I2CDEV_TEXT_MAX + 1];

    double now;
    char script_path[I2CDEV_PATH_MAX + 1];

    /* script (cf. i2cdevice_script.c) : references fortes, jamais relachees -
       le process se termine avec la simulation, meme choix que PyRuntime_destroy */
    PyObject* py_globals;
    PyObject* py_on_write;
    PyObject* py_on_read;
    PyObject* py_outputs;
    PyObject* py_lines;
};

#endif /* I2CDEVICE_CORE_H */
