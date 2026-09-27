#ifndef PYRUNTIMEIMPL_H
#define PYRUNTIMEIMPL_H

/* Jalon M5 : thread worker + condition variable, interception de sleep()/des
   appels au shim comme points de synchro (cf. requirements.md). */

/* addScriptDirToPath (Boolean Modelica -> int C) et libraryPath (chaine vide
   = desactive) etendent sys.path pour permettre a l'utilisateur d'importer
   un module auxiliaire depuis le dossier du script et/ou une bibliotheque
   partagee - cf. requirements.md, decision "Import de modules auxiliaires".
   shimPath : chemin du shim machine/time (Resources/Scripts/_shim/
   machine_time_shim.py), execute avant le script utilisateur.
   fsEnabled/fsSource/fsWorkspace : systeme de fichiers (flash simulee), copie de
   fsSource (vide = flash vierge) dans un dossier horodate de fsWorkspace (vide ou
   relatif = depuis le dossier de simulation) ; fsOpenExplorer : ouvrir
   l'Explorateur sur cette copie a la fin ; instanceName (getInstanceName())
   entre dans le nom du dossier. Programme : boot.py de la flash s'il existe,
   puis scriptPath, ou main.py de la flash si scriptPath est vide - cf.
   requirements.md, decision "Systeme de fichiers". gpioOpTime : duree
   d'execution (s) d'un acces a une broche (Pin.value()/on()/off()), 0 = acces
   instantanes - cf. requirements.md, decision "Cout temporel des acces GPIO". */
void* PyRuntime_new(const char* scriptPath, const char* pythonHome,
                     int addScriptDirToPath, const char* libraryPath,
                     const char* shimPath, int fsEnabled, const char* fsSource,
                     const char* fsWorkspace, int fsOpenExplorer,
                     const char* instanceName, double gpioOpTime);
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
   uartTxLevelOut: niveau a tenir sur cette broche jusqu'au point de synchro
   suivant, que nextWakeTime place sur le prochain CHANGEMENT de niveau de la
   trame - sans va-et-vient au thread Python (le worker n'est pas reveille). La
   RECEPTION, elle, est decodee cote C a partir des fronts de la ligne (un seul
   reveil programme par octet, au milieu du stop) : elle n'a aucune sortie ici,
   le script recupere les octets par uart.any()/uart.read() - cf.
   requirements.md decision "UART electrique reel". nextWakeTime: sortie
   scalaire. */
void PyRuntime_sync(void* handle, double currentTime, const int* pinBoolIn,
                     const double* pinAnalogIn,
                     int* pinBoolOut, int* pinIsOutput,
                     double* pwmFreqOut, double* pwmDutyOut,
                     int* displaySeqOut, const char** displayPayloadOut,
                     int* uartTxPinOut, int* uartTxLevelOut,
                     double* nextWakeTime);

#endif
