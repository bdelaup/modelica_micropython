#ifndef I2CDEVICEIMPL_H
#define I2CDEVICEIMPL_H

/* Interface C des peripheriques I2C esclaves externes (Internal.PartialI2cDevice)
   - cf. requirements.md, decision "Bus I2C electrique en drain ouvert".

   Le comportement est TOUJOURS decrit par un script Python (on_write / on_read /
   outputs / lines), execute dans l'interpreteur partage avec le microcontroleur,
   sur le thread Modelica, sans thread worker : un peripherique reagit sans jamais
   se suspendre. Pas de table de commandes pour l'I2C. */

/* addresses : "0x42" ou "0x3E, 0x62" - au plus I2CDEV_MAX_ADDR adresses sur 7
   bits, hexadecimales ou decimales (Modelica n'a pas de litteraux hexadecimaux,
   d'ou une chaine). pythonHome : pour demarrer CPython si aucun autre composant
   ne l'a fait. instanceName : prefixe des print() du script. */
void* I2cDevice_new(const char* addresses, const char* scriptPath,
                     const char* pythonHome, const char* instanceName);
void I2cDevice_destroy(void* dev);

/* Point de synchro, appele par le "when" de Internal.PartialI2cDevice a chaque
   front de SCL ou de SDA. sclLevel/sdaLevel : niveaux logiques lus sur le bus
   (seuilles cote Modelica). valueIn/valueOut : [I2CDEV_MAX_VALUES].
   sdaDriveLowOut : l'esclave tire SDA a la masse (ACK, ou bit 0 d'une lecture).
   busyOut : une phase adressee a ce composant est en cours (temoin de l'icone).
   eventSeqOut/lastEventOut : journal, incremente a chaque phase close.
   line1Out/line2Out : texte rendu par lines() (afficheurs). */
void I2cDevice_sync(void* dev, double currentTime, int sclLevel, int sdaLevel, const double* valueIn,
                     double* valueOut, int* sdaDriveLowOut, int* busyOut, int* eventSeqOut,
                     const char** lastEventOut, const char** line1Out, const char** line2Out);

#endif
