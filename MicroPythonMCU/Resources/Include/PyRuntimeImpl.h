#ifndef PYRUNTIMEIMPL_H
#define PYRUNTIMEIMPL_H

/* Jalon M5 : thread worker + condition variable, interception de sleep()/des
   appels au shim comme points de synchro (cf. requirements.md). */

/* addScriptDirToPath (Boolean Modelica -> int C) et libraryPath (chaine vide
   = desactive) etendent sys.path pour permettre a l'utilisateur d'importer
   un module auxiliaire depuis le dossier du script et/ou une bibliotheque
   partagee - cf. requirements.md, decision "Import de modules auxiliaires". */
void* PyRuntime_new(const char* scriptPath, const char* pythonHome,
                     int addScriptDirToPath, const char* libraryPath);
void PyRuntime_destroy(void* handle);

/* pinBoolIn: [9] en entree (etat resolu des broches : 0-7 = GP0-GP7 externes,
   8 = LED embarquee interne, cf. PyRuntimeImpl.c). pinAnalogIn: [9] en entree,
   tension brute (V) alignee sur pinBoolIn, lue par machine.ADC (index 8/LED
   jamais utilise cote ADC). pinBoolOut/pinIsOutput: [9] en sortie (deja
   alloues par l'appelant, convention Modelica External C). pwmFreqOut/
   pwmDutyOut: [9] en sortie, frequence (Hz, 0 = pas en PWM) et rapport
   cyclique (0-1) par broche - cf. machine.PWM ; Modelica genere le creneau
   en continu a partir de ces deux valeurs, pas de va-et-vient au thread
   Python a chaque front. displaySeqOut/displayPayloadOut: sorties scalaires -
   seq incremente a chaque machine.Display.write(), payload le dernier texte
   transmis (livraison instantanee, pas de bauds simules, cf. requirements.md
   decision "Périphérique d'affichage pédagogique"). uartTxPinOut: broche
   affectee a l'emission serie (0 = aucune, sinon 1-9 aligne sur pinBoolOut) ;
   uartTxActiveOut: une trame est en cours ; uartTxStartOut: instant de son
   front de start ; uartBitDurOut: 1/baudrate ; uartTxNumBitsOut/uartTxBitsOut:
   motif de bits complet de la trame (start + data + stop), deja serialise cote
   C - Modelica en genere la forme d'onde en continu, sans va-et-vient au thread
   Python a chaque front (meme principe que le PWM). La RECEPTION, elle, est
   decodee cote C (echantillonnage au milieu de chaque bit, cadence par
   nextWakeTime) : elle n'a aucune sortie ici, le script recupere les octets par
   uart.any()/uart.read() - cf. requirements.md decision "UART electrique reel".
   nextWakeTime: sortie scalaire. */
void PyRuntime_sync(void* handle, double currentTime, const int* pinBoolIn,
                     const double* pinAnalogIn,
                     int* pinBoolOut, int* pinIsOutput,
                     double* pwmFreqOut, double* pwmDutyOut,
                     int* displaySeqOut, const char** displayPayloadOut,
                     int* uartTxPinOut, int* uartTxActiveOut,
                     double* uartTxStartOut, double* uartBitDurOut,
                     int* uartTxNumBitsOut, double* uartTxBitsOut,
                     double* nextWakeTime);

#endif
