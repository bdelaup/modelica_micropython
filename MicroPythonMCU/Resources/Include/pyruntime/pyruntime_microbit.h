/* Moteur de la carte micro:bit (profil "microbit") : definition du moteur et
   de son etat, alloue dans board_ext du handle - pas dans le handle
   lui-meme, pour que les cartes sans moteurs ne paient ni memoire ni
   branches (phase 4 du refactoring, cf. pyruntime_board.h).
   Implementation : pyruntime_matrix.c (affichage), pyruntime_microbit.c
   (crochets qui le composent). La radio embarquee n'est plus un moteur du
   runtime : c'est un modem radio generique monte dans la carte, branche sur
   les broches internes du coeur, cf. requirements.md decision "Radios
   micro:bit".

   Partie de l'implementation du runtime Python, incluse TEXTUELLEMENT par
   PyRuntimeImpl.c (fichier chapeau) : une seule unite de compilation, donc
   pas de #include croise ici - ce fichier n'est jamais compile seul. */
#ifndef PYRUNTIME_MICROBIT_H
#define PYRUNTIME_MICROBIT_H

struct PyRuntimeHandle;

/* Matrice LED 5x5 de la micro:bit : moteur cadence cote C comme l'UART l'est
   pour ses bits (TIMER_MIN_PERIOD et MAX_TIMERS interdisent un balayage
   60 Hz x 5 lignes en callbacks Python). Valeurs du firmware CODAL
   (NRF52LedMatrix) : trame de 60 Hz, un creneau par ligne, LED allumee quand
   sa ligne est HIGH (source, anode) et sa colonne LOW (sink, cathode), la
   colonne restant basse une fraction du creneau proportionnelle au niveau du
   pixel (quantum), puis relachee. Le moteur pilote les 10 broches par la
   table pin_*[] habituelle et demande un reveil a chaque transition reelle -
   pas de quantification, pas de timer Python. */
#define MATRIX_ROWS 5
#define MATRIX_COLS 5
#define MATRIX_FRAME_RATE 60.0       /* Hz, NRF52_LED_MATRIX_FREQUENCY de CODAL */
#define MATRIX_MAX_LEVEL 9          /* niveaux de display.set_pixel() de MicroPython */

/* Moteur de balayage ligne par ligne, cf. pyruntime_matrix.c. */
struct MatrixEngine {
    int enabled;                             /* display.is_on() : le moteur possede les 10 broches */
    int row_idx[MATRIX_ROWS];                /* index interne (table pin_*) de chaque ligne, -1 tant que non configure */
    int col_idx[MATRIX_COLS];                /* idem colonnes */
    unsigned char pixels[MATRIX_ROWS][MATRIX_COLS];  /* niveaux 0-9, pixels[ligne][colonne] */
    double t0;                               /* ancre des trames (instant d'activation, phase arbitraire) */
};

/* Etat du moteur de la micro:bit : alloue au boot (crochet boot de
   pyruntime_microbit.c) et pointe par PyRuntimeHandle.board_ext. Les
   broches liberees par display.off() y marquent leur premiere transition a
   ignorer (crochet pin_released). */
struct MicroBitBoard {
    struct MatrixEngine matrix;              /* cf. pyruntime_matrix.c */
    int pin_released[MAX_PINS];              /* broches liberees par display.off(), cf. le hook pin_released */
    struct PyRuntimeHandle* h;
};

#endif
