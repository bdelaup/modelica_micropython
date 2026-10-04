/* Instrument de mesure (Peripherals.Analyzers) : sonde d'analyseur logique
   qui observe des lignes du montage sans jamais les piloter - cf.
   requirements.md, decision "Analyseur logique".

   FICHIER CHAPEAU, meme idiome que UartDeviceImpl.c : les parties
   thematiques de analyzer/ sont incluses textuellement, une seule unite de
   compilation, l'ordre des inclusions est significatif. Ni Python ni thread.

   NOTE : omc dedoublonne les annotations Include par leur texte, mais rien ne
   garantit que ce chapeau et PyRuntimeImpl.c atterrissent dans des unites de
   compilation distinctes - ils partagent launch.c, d'ou sa garde
   d'inclusion (et celles des parties de analyzer/). */

#include "AnalyzerImpl.h"
#ifdef _WIN32
#include <windows.h>
#endif
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <stdarg.h>
#include <math.h>
#include "ModelicaUtilities.h"

#include "launch.c"                    /* lanceur commun (PulseView, Bloc-notes) - partage avec PyRuntimeImpl.c */
#include "analyzer/analyzer_vcd.c"     /* enregistreur VCD */
#include "analyzer/analyzer_core.h"    /* constantes et structures de la sonde - apres analyzer_vcd.c (struct VcdWriter) */
#include "analyzer/analyzer_text.c"    /* decodage UART / I2C / serie synchrone et fichier texte */
#include "analyzer/analyzer_pvs.c"     /* session PulseView : decodeurs regles d'apres les voies */
#include "analyzer/analyzer_logic.c"   /* capture, API exportee */
