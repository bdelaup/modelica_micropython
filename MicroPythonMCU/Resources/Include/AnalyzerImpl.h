#ifndef ANALYZERIMPL_H
#define ANALYZERIMPL_H

#include <stddef.h>   /* size_t */

/* Interface C de la sonde d'analyseur logique (Peripherals.Analyzers.
   LogicAnalyzer) - cf. requirements.md, decision "Analyseur logique". Ni
   Python ni thread : la sonde observe des lignes sans jamais les piloter.

   fileName : nom de base des fichiers du dossier de simulation (extension
   .vcd/.txt retiree), vide = instanceName. channelNames : les 8 noms separes
   par des virgules, CH0, CH1... pour un nom vide.
   Tableaux de 8 (un element par voie, CH0 en tete) : kinds (Interfaces.
   ChannelKind, 1 = Off ... 5 = SyncData), baudrates, dataBits, parities
   (convention machine.UART : -1 aucune, 0 paire, 1 impaire), stopBits,
   msbFirst, clocks (voie d'horloge d'une voie I2cSda/SyncData), clockFalling,
   wordBits, signedWords - entiers 0/1, jamais des tableaux de Boolean (cf.
   requirements.md, decision "Tableaux de booleens et fonctions externes").
   textFlags[5] : section hexa, chronogramme, bits un par un, trames separees,
   silences comprimes. textSilence, textResolution : 0 = automatique.
   writePulseViewSession : <base>.pvs a cote du VCD, decodeurs regles.
   pulseViewPath : chemin absolu, ou relatif au dossier de simulation. */
void* LogicAnalyzer_new(const char* fileName, const char* instanceName, const char* channelNames,
                        const int* kinds, const double* baudrates, const int* dataBits, const int* parities,
                        const int* stopBits, const int* msbFirst, const int* clocks, const int* clockFalling,
                        const int* wordBits, const int* signedWords,
                        int writeVcd, int writePulseViewSession, int openPulseView, const char* pulseViewPath,
                        int writeText, int openText, const int* textFlags,
                        double textSilence, double textResolution, int textWidth);

/* Fin de simulation : clot le VCD, ecrit le fichier texte, les ouvre si
   demande. */
void LogicAnalyzer_destroy(void* an);

/* Niveaux des 8 voies a l'instant currentTime (levels : Integer 0/1). Rend le
   nombre d'appels, pour que le "when" ait une variable a affecter. */
int LogicAnalyzer_record(void* an, double currentTime, const int* levels, size_t n);

/* Fin de simulation (when terminal()) : note l'instant final, pour que la
   capture couvre toute la duree simulee. */
int LogicAnalyzer_finish(void* an, double currentTime);

#endif
