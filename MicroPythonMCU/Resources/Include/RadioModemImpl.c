/* Modems radio transparents (Peripherals.Radio) : un module branche sur
   l'UART du microcontroleur, qui reemet dans l'air ce qu'il recoit et
   inversement - cf. requirements.md, decision "Liaison radio modulee".

   FICHIER CHAPEAU, meme idiome que UartDeviceImpl.c : les parties de
   radiomodem/ sont incluses textuellement, une seule unite de compilation,
   l'ordre des inclusions est significatif. Ni Python ni thread : python312.dll
   n'est jamais chargee pour un modem.

   Le moteur bit/octet est uartcore.c, deux fois par modem : une liaison cote
   microcontroleur, une cote air. Partage avec PyRuntimeImpl.c et
   UartDeviceImpl.c, d'ou sa garde d'inclusion (omc peut regrouper les
   chapeaux dans une meme unite de compilation). */

#include "RadioModemImpl.h"
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include "ModelicaUtilities.h"

#include "uartcore.h"                           /* struct UartEngine + constantes du protocole */
#include "radiomodem/radiomodem_core.h"         /* struct RadioModem, files horodatees */
#include "uartcore.c"                           /* files TX/RX, trame, decodage */
#include "simoutput.c"                          /* intervalle de sortie de la simulation (avertissement d'echantillonnage) */
#include "radiomodem/radiomodem_engine.c"       /* construction, ordonnancement, point de synchro */
