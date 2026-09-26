/* Jalon M5 : thread worker + condition variable pour interception de sleep()
   et des appels au shim machine/time comme points de synchro potentiels
   (cf. requirements.md, decisions "Mecanisme d'execution" et "Protection
   contre un script qui ne rend jamais la main"). Windows uniquement (v0).

   FICHIER CHAPEAU : l'implementation est decoupee en parties thematiques dans
   pyruntime/, incluses ci-dessous dans l'ordre. omc compile ce fichier comme
   UNE SEULE unite de compilation (annotation Include de Internal/
   PyRuntime_sync.mo : #include "PyRuntimeImpl.c"), donc les parties sont
   incluses textuellement plutot que compilees et liees separement - aucun
   changement d'annotation ni etape de build supplementaire, cf.
   requirements.md, decision "Structure du package et interface C du runtime
   Python".

   L'ORDRE DES INCLUSIONS EST SIGNIFICATIF : en une seule unite de compilation,
   chaque fonction "static" doit etre definie avant son premier appel. L'ordre
   ci-dessous suit les dependances reelles (le coeur de synchro avant les
   primitives natives qui l'appellent, les peripheriques avant la table des
   methodes et l'API exportee qui les referencent), ce qui evite d'avoir a
   declarer des prototypes croises. */

#include "PyRuntimeImpl.h"
#define PY_SSIZE_T_CLEAN   /* exige par l'API C Python pour les formats "#" (cf. native_uart_write, qui recoit des bytes + longueur) - doit preceder Python.h */
/* Les en-tetes de CPython 3.12 sont vendores dans le sous-dossier cpython312/
   pour ne pas noyer nos propres sources a la racine d'Include/. L'inclusion est
   "quoted" et non <...> : les en-tetes de CPython s'incluent entre eux sans
   prefixe, et un include quoted est resolu d'abord relativement au dossier du
   fichier qui l'inclut - donc depuis cpython312/. Aucun chemin d'inclusion
   supplementaire n'est necessaire, IncludeDirectory reste Resources/Include. */
#include "cpython312/Python.h"
#include <windows.h>
#include <process.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include "ModelicaUtilities.h"

#include "uartcore.h"                      /* moteur UART generique (sans Python ni thread), partage avec UartDeviceImpl.c */
#include "pyruntime/pyruntime_core.h"      /* constantes, PyRuntimeHandle, handle courant */
#include "uartcore.c"                      /* files TX/RX, trame 8N1, decodage - avant pyruntime_uart.c qui l'utilise */
#include "pyhost.c"                        /* demarrage unique de CPython, relais stdout, lecture de fichier - partage avec UartDeviceImpl.c */
#include "pyruntime/pyruntime_sync.c"      /* dispatch des callbacks + yield_to_modelica */
#include "pyruntime/pyruntime_pin.c"       /* machine.Pin / ADC / PWM / Pin.irq + time.sleep */
#include "pyruntime/pyruntime_display.c"   /* machine.Display */
#include "pyruntime/pyruntime_uart.c"      /* machine.UART (TX/RX, trame 8N1) */
#include "pyruntime/pyruntime_i2c.c"       /* machine.I2C (maitre, drain ouvert) */
#include "pyruntime/pyruntime_timer.c"     /* machine.Timer */
#include "pyruntime/pyruntime_module.c"    /* module natif, thread worker, API exportee */
