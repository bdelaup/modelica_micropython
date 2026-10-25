/* Crochets de la carte micro:bit (profil "microbit") : L'UNIQUE endroit du
   runtime qui connait le nom du profil - PyRuntime_sync ne voit que la table
   struct BoardHooks (cf. pyruntime_board.h). Compose les moteurs de
   pyruntime_matrix.c (affichage) et pyruntime_radio.c (radio), dont l'etat
   vit dans board_ext : les profils "generic" et "pico" ne paient ni memoire
   ni branches (phase 4 du refactoring, decision D8, cf. requirements.md
   "Refactoring du socle des cartes").

   Partie de l'implementation du runtime Python, incluse TEXTUELLEMENT par
   PyRuntimeImpl.c (fichier chapeau), APRES pyruntime_matrix.c et
   pyruntime_radio.c (dont ce fichier appele les moteurs) et AVANT
   pyruntime_module.c (dont la synchro appelle board_hooks). Ce fichier n'est
   jamais compile seul. */

/* Boot : alloue l'etat des moteurs, enregistre la radio au registre du
   process (thread Modelica, cf. le threadage dans pyruntime_radio.c) et
   demarre le balayage de la matrice, comme le firmware demarre ses drivers
   au boot - avant le programme (le shim ne peut pas : aucune native avec
   yield pendant l'init). Appele par la premiere synchro alimentee, cs tenu. */
static void* microbit_boot(struct PyRuntimeHandle* h, double now) {
    struct MicroBitBoard* b = (struct MicroBitBoard*) calloc(1, sizeof(struct MicroBitBoard));
    if (!b) {
        ModelicaFormatError("PyRuntime (%s): out of memory for the micro:bit engines", h->instanceName);
        return NULL;
    }
    b->h = h;
    radio_engine_init(b);
    radio_registry_add(b);
    matrix_boot_enable(h, b, now);
    return b;
}

/* Step : fait avancer la matrice (avant la boucle des transitions d'entree,
   une seconde fois apres le drain, en fin de script - le balayage est
   materiel autonome) puis la radio (livraison des paquets arrives). */
static void microbit_step(struct PyRuntimeHandle* h, double now) {
    struct MicroBitBoard* b = (struct MicroBitBoard*) h->board_ext;
    matrix_step(h, b, now);
    radio_step(h, b, now);
}

/* Le balayage de la matrice survit a la fin du script : il continue de
   demander des reveils au solveur. */
static double microbit_next_scan_deadline(struct PyRuntimeHandle* h) {
    return earliest_matrix_deadline(h, (struct MicroBitBoard*) h->board_ext);
}

/* Les paquets radio en vol, eux, s'annulent avec la fin du script : plus
   personne ne les lit, ils ne font que gonfler les compteurs de pertes. */
static double microbit_next_inbox_deadline(struct PyRuntimeHandle* h) {
    return earliest_radio_deadline((struct MicroBitBoard*) h->board_ext);
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

/* Identifiant du reseau radio porte par l'antenne du schema, -1 si elle n'est
   pas cablee (radio.on() le signale). */
static void microbit_set_network(struct PyRuntimeHandle* h, int network_id) {
    struct MicroBitBoard* b = (struct MicroBitBoard*) h->board_ext;
    b->radio.network_id = network_id;
}

/* Perte d'alimentation : le balayage s'arrete, les 10 broches sont relachees
   avec les autres. */
static void microbit_power_loss(struct PyRuntimeHandle* h) {
    struct MicroBitBoard* b = (struct MicroBitBoard*) h->board_ext;
    b->matrix.enabled = 0;
}

/* Bilan de fin de simulation : statistiques de pertes radio. */
static void microbit_report(struct PyRuntimeHandle* h) {
    radio_report(h, (struct MicroBitBoard*) h->board_ext);
}

/* Liberation : retire la radio du registre du process, libere l'etat. */
static void microbit_destroy(void* board_ext) {
    struct MicroBitBoard* b = (struct MicroBitBoard*) board_ext;
    radio_registry_remove(b);
    free(b);
}

static const struct BoardHooks g_microbit_hooks = {
    microbit_boot,
    microbit_step,
    microbit_next_scan_deadline,
    microbit_next_inbox_deadline,
    microbit_pin_released,
    microbit_set_network,
    microbit_power_loss,
    microbit_report,
    microbit_destroy,
};

const struct BoardHooks* board_hooks(const char* board_profile) {
    return (board_profile != NULL && strcmp(board_profile, "microbit") == 0)
        ? &g_microbit_hooks : NULL;
}
