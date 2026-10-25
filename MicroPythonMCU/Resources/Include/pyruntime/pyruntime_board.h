/* Crochets de carte : ce qu'un profil de carte ajoute au runtime au-dela du
   coeur generique (moteurs, deadlines, broches qu'il gere). Le coeur ne
   connait que cette table - le NOM du profil n'apparait que dans
   l'implementation des crochets (pyruntime_microbit.c pour "microbit"), et
   les profils sans moteurs ne paient ni memoire ni branches : phase 4 du
   refactoring (decision D8, cf. requirements.md "Refactoring du socle des
   cartes").

   Partie de l'implementation du runtime Python, incluse TEXTUELLEMENT par
   PyRuntimeImpl.c (fichier chapeau) : une seule unite de compilation, donc
   pas de #include croise ici - ce fichier n'est jamais compile seul.

   Threadage : les crochets sont appeles UNIQUEMENT par le thread Modelica
   (PyRuntime_sync, cs du handle tenu ; PyRuntime_new/destroy), les natives
   du profil touchant board_ext depuis le worker sous le cs du handle -
   meme discipline que le reste du runtime, cf. pyruntime_core.h. */
#ifndef PYRUNTIME_BOARD_H
#define PYRUNTIME_BOARD_H

struct PyRuntimeHandle;

struct BoardHooks {
    /* Alloue l'etat des moteurs et l'active (ex. demarre le balayage de la
       matrice au boot, comme le firmware demarre ses drivers) : premiere
       synchro alimentee, cs tenu, une seule fois. Renvoie board_ext. */
    void* (*boot)(struct PyRuntimeHandle* h, double now);
    /* Fait avancer les moteurs a l'instant now : a chaque synchro, avant la
       boucle de detection des transitions d'entree, une seconde fois apres
       le drain du worker, et apres la fin du script (le materiel autonome
       continue, comme l'UART vide sa file). */
    void (*step)(struct PyRuntimeHandle* h, double now);
    /* Prochaine transition du materiel qui SURVIT a la fin du script (ex.
       balayage de la matrice), 1e300 si rien : entre dans nextWakeTime. */
    double (*next_scan_deadline)(struct PyRuntimeHandle* h);
    /* Consomme la liberation d'une broche par un moteur (ex. display.off()) :
       sa premiere transition ensuite n'etablit que son niveau apres la haute
       impedance, ce n'est pas une vraie entree - renvoie 1 (et efface) si la
       transition de la broche doit etre ignoree, 0 sinon. */
    int (*pin_released)(struct PyRuntimeHandle* h, int pin);
    /* Perte d'alimentation : tout le materiel de la carte s'arrete, ses
       broches sont relachees avec les autres. */
    void (*power_loss)(struct PyRuntimeHandle* h);
    /* Bilan de fin de simulation (avertissements plafonnes, thread
       Modelica). */
    void (*report)(struct PyRuntimeHandle* h);
    /* Liberation de board_ext (retire aussi la carte des registres du
       process, thread Modelica). */
    void (*destroy)(void* board_ext);
};

/* Crochets du profil, NULL si le profil n'a pas de moteurs. */
const struct BoardHooks* board_hooks(const char* board_profile);

#endif
