/* Etat d'un peripherique I2C esclave externe (Internal.PartialI2cDevice).

   Partie de l'implementation incluse TEXTUELLEMENT par I2cDeviceImpl.c
   (fichier chapeau) : une seule unite de compilation, pas de #include croise
   ici, aucune etape de build supplementaire - meme idiome que uartdevice/.
   Ce fichier n'est jamais compile seul. */

#ifndef I2CDEVICE_CORE_H
#define I2CDEVICE_CORE_H

#define I2CDEV_MAX_VALUES 4          /* grandeurs reelles echangees avec le modele - aligne sur Interfaces.I2C_DEV_MAX_VALUES */
#define I2CDEV_MAX_ADDR I2CT_MAX_ADDR /* adresses auxquelles un meme composant repond (ex. ecran Grove : 0x3E et 0x62) */
#define I2CDEV_BUF_MAX I2CT_BUF_MAX  /* lot rendu par on_read() */
#define I2CDEV_PATH_MAX 511
#define I2CDEV_TEXT_MAX 80           /* une ligne rendue par lines() */
#define I2CDEV_EVENT_MAX 160         /* resume de la derniere transaction, pour le journal */

struct I2cDevice {
    /* decodage du bus et pilotage de SDA : moteur cible partage avec
       machine.I2CTarget du microcontroleur (cf. i2ctarget.h) */
    struct I2cTarget bus;

    /* phase de lecture : octets fournis par on_read(), sortis un par un */
    unsigned char rbuf[I2CDEV_BUF_MAX];
    int rlen;
    int rpos;

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
