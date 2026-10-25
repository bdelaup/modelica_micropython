/* Crochets de la carte micro:bit (profil "microbit") : L'UNIQUE endroit du
   runtime qui connait le nom du profil - PyRuntime_sync ne voit que la table
   struct BoardHooks (cf. pyruntime_board.h). Compose le moteur de
   pyruntime_matrix.c (affichage), dont l'etat vit dans board_ext : les
   profils "generic" et "pico" ne paient ni memoire ni branches (phase 4 du
   refactoring, decision D8, cf. requirements.md "Refactoring du socle des
   cartes"). La radio embarquee ne vit plus ici : c'est un modem radio
   generique monte dans la carte (Internal.OnBoardRadioModem, moteur
   RadioModemImpl.c) branche sur les broches internes du coeur, et le
   protocole microbit.radio vit dans le shim - cf. requirements.md decision
   "Radios micro:bit".

   Partie de l'implementation du runtime Python, incluse TEXTUELLEMENT par
   PyRuntimeImpl.c (fichier chapeau), APRES pyruntime_matrix.c (dont ce
   fichier appele le moteur) et AVANT pyruntime_module.c (dont la synchro
   appelle board_hooks). Ce fichier n'est jamais compile seul. */

/* Boot : alloue l'etat du moteur et demarre le balayage de la matrice, comme
   le firmware demarre ses drivers au boot - avant le programme (le shim ne
   peut pas : aucune native avec yield pendant l'init). Appele par la
   premiere synchro alimentee, cs tenu. */
static void* microbit_boot(struct PyRuntimeHandle* h, double now) {
    struct MicroBitBoard* b = (struct MicroBitBoard*) calloc(1, sizeof(struct MicroBitBoard));
    if (!b) {
        ModelicaFormatError("PyRuntime (%s): out of memory for the micro:bit engines", h->instanceName);
        return NULL;
    }
    b->h = h;
    /* Les deux broches internes de la radio (ids 34 = TX du coeur, 35 = RX)
       appartiennent au modem embarque : leurs transitions (installation de
       la ligne au demarrage, trames de la radio) ne sont jamais des entrees
       du script - reclamees ici comme machine.UART reclame ses broches RX,
       sinon le premier sommeil du programme se fait reveiller par l'etablissement de la ligne. */
    {
        int i;
        for (i = 0; i < h->num_pins; i++) {
            if (h->pin_id[i] == 34 || h->pin_id[i] == 35) {
                h->uart_rx_claimed[i] = 1;
            }
        }
    }
    matrix_boot_enable(h, b, now);
    return b;
}

/* Step : fait avancer la matrice (avant la boucle des transitions d'entree,
   une seconde fois apres le drain, en fin de script - le balayage est
   materiel autonome). */
static void microbit_step(struct PyRuntimeHandle* h, double now) {
    struct MicroBitBoard* b = (struct MicroBitBoard*) h->board_ext;
    matrix_step(h, b, now);
}

/* Le balayage de la matrice survit a la fin du script : il continue de
   demander des reveils au solveur. */
static double microbit_next_scan_deadline(struct PyRuntimeHandle* h) {
    return earliest_matrix_deadline(h, (struct MicroBitBoard*) h->board_ext);
}

/* Une broche que display.off() vient de liberer : sa premiere transition
   n'etablit que son niveau apres la haute impedance, ce n'est pas une vraie
   entree (une interruption GPIO est masquee tant que la broche appartient au
   driver d'affichage, et off() n'en genere pas). */
static int microbit_pin_released(struct PyRuntimeHandle* h, int pin) {
    struct MicroBitBoard* b = (struct MicroBitBoard*) h->board_ext;
    if (b->pin_released[pin]) {
        b->pin_released[pin] = 0;
        return 1;
    }
    return 0;
}

/* Perte d'alimentation : le balayage s'arrete, les 10 broches sont relachees
   avec les autres. */
static void microbit_power_loss(struct PyRuntimeHandle* h) {
    struct MicroBitBoard* b = (struct MicroBitBoard*) h->board_ext;
    b->matrix.enabled = 0;
}

/* Liberation de l'etat des moteurs. */
static void microbit_destroy(void* board_ext) {
    free(board_ext);
}

static const struct BoardHooks g_microbit_hooks = {
    microbit_boot,
    microbit_step,
    microbit_next_scan_deadline,
    microbit_pin_released,
    microbit_power_loss,
    NULL,                /* report : rien a signaler depuis le retrait de la radio */
    microbit_destroy,
};

const struct BoardHooks* board_hooks(const char* board_profile) {
    return (board_profile != NULL && strcmp(board_profile, "microbit") == 0)
        ? &g_microbit_hooks : NULL;
}
