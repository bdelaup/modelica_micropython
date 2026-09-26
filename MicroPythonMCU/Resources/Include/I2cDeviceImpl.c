/* Peripheriques I2C esclaves externes (Internal.PartialI2cDevice) : un appareil
   branche electriquement sur le bus SDA/SCL, en drain ouvert, qui decode les
   vraies sequences START / adresse / octets / ACK / STOP du maitre - cf.
   requirements.md, decision "Bus I2C electrique en drain ouvert".

   FICHIER CHAPEAU : l'implementation est decoupee en parties thematiques dans
   i2cdevice/, incluses ci-dessous dans l'ordre. omc compile ce fichier comme
   UNE SEULE unite de compilation (annotation Include de Internal/
   I2cDevice_sync.mo : #include "I2cDeviceImpl.c") - meme idiome que
   PyRuntimeImpl.c et UartDeviceImpl.c.

   L'ORDRE DES INCLUSIONS EST SIGNIFICATIF : chaque fonction "static" doit etre
   definie avant son premier appel (l'hote CPython avant le script commun, le
   script avant le moteur qui l'appelle).

   NOTE : omc dedoublonne les annotations Include par leur texte, mais rien ne
   garantit que ce chapeau, UartDeviceImpl.c et PyRuntimeImpl.c atterrissent
   dans des unites de compilation distinctes - ils partagent pyhost.c et
   devscript.c. D'ou les gardes d'inclusion dans chaque partie. */

#include "I2cDeviceImpl.h"
/* Python.h avant tout en-tete standard, comme l'exige l'API C de CPython. */
#ifndef PY_SSIZE_T_CLEAN
#define PY_SSIZE_T_CLEAN                        /* formats "#" (y#) avec Py_ssize_t */
#endif
#include "cpython312/Python.h"
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include "ModelicaUtilities.h"

#include "i2cdevice/i2cdevice_core.h"           /* struct I2cDevice */
#include "pyhost.c"                             /* demarrage unique de CPython, relais stdout - partage */
#include "devscript.c"                          /* script de peripherique : espace de noms propre, conversions - partage avec UartDeviceImpl.c */
#include "i2cdevice/i2cdevice_script.c"         /* contrat on_write / on_read / outputs / lines */
#include "i2cdevice/i2cdevice_engine.c"         /* decodage du bus, construction, point de synchro */
