#ifndef RADIOMODEMIMPL_H
#define RADIOMODEMIMPL_H

/* Interface C des modems radio transparents (Internal.PartialRadioModem) -
   cf. requirements.md, decision "Liaison radio modulee". Ni Python ni thread :
   le modem recoit des octets sur son UART, les emet dans l'air au debit radio
   apres un delai fixe, et fait le chemin inverse pour ce qu'il recoit.

   Le signal module lui-meme (porteuse, OOK/FSK/BPSK) est calcule cote
   Modelica a partir du niveau publie ici : le C ne connait que des bits.

   baudrate/dataBits/parity/stopBits : format de la liaison serie cote
   microcontroleur, conventions de machine.UART (parity -1 = aucune, 0 = paire,
   1 = impaire). airBaudrate : debit dans l'air, trame 8N1. txBufferSize :
   file UART -> air, rxBufferSize : file air -> UART, en octets ; un octet qui
   arrive file pleine est perdu. txDelay/rxDelay : delai fixe entre la fin de
   reception d'un octet et le moment ou il peut partir de l'autre cote.
   halfDuplex : le modem est sourd pendant qu'il emet. */
void* RadioModem_new(double baudrate, int dataBits, int parity, int stopBits,
                     double airBaudrate, int txBufferSize, int rxBufferSize,
                     double txDelay, double rxDelay, int halfDuplex,
                     const char* instanceName);
void RadioModem_destroy(void* modem);

/* Point de synchro. serRxLevel : niveau lu sur la broche RX (octets venus du
   microcontroleur). airLevel : niveau de la trame radio entendue (repos =
   haut ; deja ramene au repos cote Modelica si rien d'audible). airJam : deux
   emetteurs ou plus a la fois - la trame en cours de reception est perdue.
   Sorties : serTxLevel (niveau a tenir sur TX), airTxLevel (bit emis dans
   l'air), carrierOn (porteuse emise), airRxBusy (trame radio en cours de
   reception), txFill/rxFill (octets en file), airId (identifiant du modem,
   1, 2, 3... distinct par instance), compteurs cumules, nextWakeTime. */
void RadioModem_sync(void* modem, double currentTime, int serRxLevel, int airLevel, int airJam,
                     int* serTxLevel, int* airTxLevel, int* carrierOn, int* airRxBusy,
                     int* txFill, int* rxFill, double* airId,
                     int* nSent, int* nReceived, int* nDropped, int* nCorrupted,
                     double* nextWakeTime);

#endif
