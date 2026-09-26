/* Peripheriques serie externes (Peripherals.UartDevice) : un appareil branche
   electriquement sur deux broches GPx, qui recoit de vraies trames et en emet
   de vraies - cf. requirements.md, decision "Peripheriques UART externes
   connectables".

   FICHIER CHAPEAU : l'implementation est decoupee en parties thematiques dans
   uartdevice/, incluses ci-dessous dans l'ordre. omc compile ce fichier comme
   UNE SEULE unite de compilation (annotation Include de Internal/
   UartDevice_sync.mo : #include "UartDeviceImpl.c"), donc les parties sont
   incluses textuellement plutot que compilees et liees separement - aucun
   changement d'annotation ni etape de build supplementaire, meme idiome que
   PyRuntimeImpl.c.

   L'ORDRE DES INCLUSIONS EST SIGNIFICATIF : en une seule unite de compilation,
   chaque fonction "static" doit etre definie avant son premier appel. Le
   formateur avant la reconnaissance (qui s'en sert pour les reponses et pour
   analyser les marqueurs de capture), la reconnaissance avant le moteur.

   Python n'intervient qu'en mode Script : le comportement est alors decrit par
   un fichier .py dont les gestionnaires s'executent sur le thread Modelica,
   dans l'interpreteur partage avec le microcontroleur (pyhost.c) - sans thread
   worker ni sleep(), puisqu'un peripherique reagit sans jamais se suspendre.
   En mode Table, aucun code Python n'est execute, mais l'unite de compilation
   est liee a python312 dans tous les cas. Le moteur bit/octet (uartcore) est
   exactement celui du microcontroleur, partage et non duplique.

   NOTE : omc dedoublonne les annotations Include par leur texte, mais rien ne
   garantit que ce chapeau et PyRuntimeImpl.c atterrissent dans des unites de
   compilation distinctes - ils partagent uartcore.c. D'ou les gardes
   d'inclusion dans chaque partie. */

#include "UartDeviceImpl.h"
/* Python.h avant tout en-tete standard, comme l'exige l'API C de CPython. */
#ifndef PY_SSIZE_T_CLEAN
#define PY_SSIZE_T_CLEAN                        /* formats "#" (y#) avec Py_ssize_t */
#endif
#include "cpython312/Python.h"
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include "ModelicaUtilities.h"

#include "uartcore.h"                           /* struct UartEngine + constantes du protocole */
#include "uartdevice/uartdevice_core.h"         /* struct UartDevice */
#include "uartcore.c"                           /* files TX/RX, trame 8N1, decodage */
#include "pyhost.c"                             /* demarrage unique de CPython, relais stdout - partage avec PyRuntimeImpl.c */
#include "devscript.c"                          /* script de peripherique : espace de noms propre, conversions - partage avec I2cDeviceImpl.c */
#include "uartdevice/uartdevice_format.c"       /* substitution {vN} et analyse des marqueurs */
#include "uartdevice/uartdevice_match.c"        /* table de commandes + capture {oN} */
#include "uartdevice/uartdevice_script.c"       /* mode Script : chargement et appel des gestionnaires Python */
#include "uartdevice/uartdevice_engine.c"       /* construction, ordonnancement, point de synchro */
