#ifndef UARTDEVICEIMPL_H
#define UARTDEVICEIMPL_H

/* Interface C des peripheriques serie externes (Internal.PartialUartDevice) -
   cf. requirements.md, decision "Peripheriques UART externes connectables".

   Deux modes : Table (comportement entierement decrit par des parametres
   Modelica, aucun code Python execute) et Script (gestionnaires Python
   on_receive / on_tick / outputs, executes dans l'interpreteur partage avec le
   microcontroleur). Pas de thread worker dans les deux cas. pythonHome et
   instanceName ne servent qu'en mode Script : le premier pour demarrer CPython
   si aucun microcontroleur ne l'a encore fait, le second pour prefixer les
   print() du script. */

/* Constructeur de l'External Object. mode : 1 = table de commandes parametree,
   2 = script Python (gestionnaires on_receive/on_tick/outputs). terminator :
   CHAINE dont seul le premier caractere est retenu, pour que le parametre Modelica
   s'ecrive "\n" plutot qu'un code numerique. Les validations (baudrate borne,
   periode au-dessus du plancher, terminateur non vide) echouent par
   ModelicaFormatError plutot que de laisser un peripherique silencieusement inerte. */
void* UartDevice_new(double baudrate, const char* commandTable, const char* terminator,
                      double responseDelay, int respondEnabled, int echoEnabled,
                      int periodicEnabled, double period, const char* periodicTemplate,
                      double valueOutStart, int mode, const char* scriptPath,
                      const char* pythonHome, const char* instanceName);
void UartDevice_destroy(void* dev);

/* Point de synchro, appele par le "when" de Peripherals.UartDevice.
   rxLevel : niveau logique lu sur la broche de reception (seuille cote Modelica).
   valueIn/valueOut : [UARTDEV_MAX_VALUES], grandeurs reelles echangees avec le
   reste du modele - {vN} les substitue dans une trame emise, {oN} les capture
   dans une trame recue. txActiveOut/txStartOut/txNumBitsOut/txBitsOut : motif de
   la trame en cours, dont Modelica genere la forme d'onde en continu (meme
   principe que le PWM et que machine.UART). rxBusyOut : temoin d'activite pour
   l'icone. eventSeqOut/lastRxOut/lastTxOut : observabilite (journal, afficheur),
   sur le motif de displaySeq/displayPayload. nextWakeTime : plus proche echeance
   (fin de trame, echantillon de reception, reponse armee, tick periodique). */
void UartDevice_sync(void* dev, double currentTime, int rxLevel, const double* valueIn,
                      double* valueOut, int* txActiveOut, double* txStartOut,
                      int* txNumBitsOut, double* txBitsOut, int* rxBusyOut,
                      int* eventSeqOut, const char** lastRxOut, const char** lastTxOut,
                      double* nextWakeTime);

#endif
