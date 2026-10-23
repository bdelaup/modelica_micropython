/* microbit.display : moteur de la matrice LED 5x5 de la micro:bit (profil
   "microbit"), multiplexee sur 10 GPIO (5 lignes + 5 colonnes), cf.
   requirements.md, decision "MCU micro:bit v2".

   Partie de l'implementation du runtime Python, incluse TEXTUELLEMENT par
   PyRuntimeImpl.c (fichier chapeau) : une seule unite de compilation, donc
   pas de #include croise ici et aucune etape de build supplementaire - cf.
   requirements.md, decision "Structure du package et interface C du runtime
   Python". Ce fichier n'est jamais compile seul.

   Meme esprit que uartcore.c, mais propre au microcontroleur (aucun
   peripherique externe ne s'en sert) : TIMER_MIN_PERIOD (1 ms) et MAX_TIMERS
   (4) interdisent de balayer 60 Hz x 5 lignes par des callbacks Python, et la
   comparaison continue du vrai driver (GPIOTE/PPI, quantum CODAL
   NRF52LedMatrix) serait de toute facon quantifiee par les minuteries. Le
   moteur vit ici, cadence par PyRuntime_sync :

   - matrix_step(h, now) : etat ABSOLU (idempotent, recalcule depuis t0), ecrit
     le niveau des 10 broches dans pin_is_output/pin_driven_value - le chemin
     "sortie digitale" habituel de Internal.PinBridge, aucune signature de
     synchro a changer. Aucun cout simule : le vrai balayage est materiel
     (timer + PPI), il ne consomme pas de temps processeur.
   - earliest_matrix_deadline(h) : prochaine transition REELLE (changement de
     ligne au creneau suivant, relache d'une colonne en cours de creneau) :
     un evenement Modelica par transition, pas de quantum d'horloge.
   - natives matrix_enable/matrix_disable/matrix_set_pixels, appelees par le
     shim microbit (display.on()/off(), tampon de pixels 0-9).

   Polarite du driver CODAL : ligne HIGH (source, anode de la LED), colonne LOW
   (sink, cathode) pendant [debut de creneau, debut + creneau*niveau/9], puis
   colonne relachee HIGH ; pixel a 0 : colonne tenue HIGH. Une LED est
   allumee quand sa ligne est active ET sa colonne basse. */

/* Duree d'un creneau (une ligne) : trame / 5 lignes. */
static double matrix_slot_duration(void) {
    return 1.0 / (MATRIX_FRAME_RATE * MATRIX_ROWS);
}

/* Fait avancer le moteur a l'instant now : publie le niveau des 10 broches de
   la matrice. Appellee par PyRuntime_sync, cs tenu, AVANT la boucle de
   detection des transitions d'entree (les broches de la matrice sont des
   sorties pendant le balayage) et une seconde fois apres le drain (le worker
   a pu activer, eteindre ou redessiner l'affichage pendant son tour). */
static void matrix_step(struct PyRuntimeHandle* h, double now) {
    struct MatrixEngine* m = &h->matrix;
    if (!m->enabled) {
        return;
    }
    double slot = matrix_slot_duration();
    /* (now - m->t0) ne peut pas etre negatif (t0 pose a l'activation, le temps
       simule ne recule jamais) ; +EPS pour trancher les flottants piles sur la
       frontiere (0.19999...). */
    long long k = (long long) floor((now - m->t0 + PYRUNTIME_EPS) / slot);
    if (k < 0) {
        k = 0;
    }
    int row = (int) (k % MATRIX_ROWS);
    double slot_start = m->t0 + (double) k * slot;
    int i, c;
    for (i = 0; i < MATRIX_ROWS; i++) {
        if (m->row_idx[i] >= 0) {
            h->pin_is_output[m->row_idx[i]] = 1;
            h->pin_driven_value[m->row_idx[i]] = (i == row);
        }
    }
    for (c = 0; c < MATRIX_COLS; c++) {
        if (m->col_idx[c] >= 0) {
            int level = m->pixels[row][c];
            int released = (level == 0) || (now >= slot_start + slot * level / MATRIX_MAX_LEVEL);
            h->pin_is_output[m->col_idx[c]] = 1;
            h->pin_driven_value[m->col_idx[c]] = released;  /* HIGH = relachee (LED eteinte) */
        }
    }
}

/* Prochaine transition a demander au solveur : frontiere du creneau suivant
   (changement de ligne) ou relache d'une colonne encore basse du creneau
   courant, la plus tot des deux. 1e300 si le moteur est eteint. Appellee sous
   verrou par PyRuntime_sync ; n'utilise QUE l'etat pose par matrix_step, donc
   coherent avec les niveaux publies au meme instant. */
static double earliest_matrix_deadline(struct PyRuntimeHandle* h) {
    struct MatrixEngine* m = &h->matrix;
    if (!m->enabled) {
        return 1.0e300;
    }
    double now = h->sim_time;
    double slot = matrix_slot_duration();
    long long k = (long long) floor((now - m->t0 + PYRUNTIME_EPS) / slot);
    if (k < 0) {
        k = 0;
    }
    int row = (int) (k % MATRIX_ROWS);
    double slot_start = m->t0 + (double) k * slot;
    double next = slot_start + slot;   /* frontiere du creneau suivant : toujours une transition */
    int c;
    for (c = 0; c < MATRIX_COLS; c++) {
        int level = m->pixels[row][c];
        if (level > 0 && level < MATRIX_MAX_LEVEL) {   /* niveau 9 : relache = frontiere du creneau, deja dans next */
            double release = slot_start + slot * level / MATRIX_MAX_LEVEL;
            /* Strictement future : une relache deja passee (le temps present a
               quelques 1e-12 pres) rabotee a now+EPS ferait redemarrer le when
               de Modelica en boucle au meme instant (chattering constate au
               premier essai avec un niveau intermediaire). */
            if (release > now + PYRUNTIME_EPS && release < next) {
                next = release;
            }
        }
    }
    if (next < now + PYRUNTIME_EPS) {
        /* Impossible en theorie (la frontiere suivante est dans le futur) ;
           garde-fou pour ne jamais figer le solveur dans le passe. */
        next = now + PYRUNTIME_EPS;
    }
    return next;
}

/* --- Natives exposees au shim microbit (thread worker uniquement) ---

   Activation AU DEMARRAGE : interdite au shim lui-meme. Le corps du module est
   execute par worker_init AVANT le premier tour du worker (PyRuntime_new
   attend la fin de l'init), donc tout appel d'une native qui rend la main a
   Modelica y deadlock (le constructeur n'echange pas de tours). Comme le vrai
   firmware, qui demarre son driver d'affichage au boot avant le programme,
   c'est PyRuntime_sync qui active le moteur a la premiere synchro alimentee
   d'une carte "microbit" (cf. matrix_boot_enable). Le display du shim nait
   alors simplement dans l'etat "on". */

/* Active le moteur pour le profil micro:bit a la premiere synchro alimentee :
   convention de brochage de la carte (lignes internes 21-25, colonnes = P4, P7,
   P3, P6, P10, cf. requirements.md) - la table de broches vient du modele.
   Thread Modelica, cs tenu, une seule fois par demarrage. Une table de broches
   incomplete (modele incoherent) laisse la matrice eteinte avec un
   avertissement plutot qu'une erreur. */
static void matrix_boot_enable(struct PyRuntimeHandle* h, double now) {
    static const int row_ids[MATRIX_ROWS] = {21, 22, 23, 24, 25};
    static const int col_ids[MATRIX_COLS] = {4, 7, 3, 6, 10};
    int i, ok = 1;
    int idx[MATRIX_ROWS + MATRIX_COLS];
    for (i = 0; i < MATRIX_ROWS + MATRIX_COLS; i++) {
        int id = (i < MATRIX_ROWS) ? row_ids[i] : col_ids[i - MATRIX_ROWS];
        int j;
        idx[i] = -1;
        for (j = 0; j < h->num_pins; j++) {
            if (h->pin_id[j] == id && (h->pin_caps[j] & PIN_CAP_DIGITAL)) {
                idx[i] = j;
                break;
            }
        }
        if (idx[i] < 0) {
            ok = 0;
        }
    }
    if (!ok) {
        ModelicaFormatWarning("PyRuntime (%s): micro:bit LED matrix not found in the pin table - display left off\\n",
                              h->instanceName);
        return;
    }
    for (i = 0; i < MATRIX_ROWS; i++) {
        h->matrix.row_idx[i] = idx[i];
        h->pwm_freq[idx[i]] = 0;
    }
    for (i = 0; i < MATRIX_COLS; i++) {
        h->matrix.col_idx[i] = idx[MATRIX_ROWS + i];
        h->pwm_freq[idx[MATRIX_ROWS + i]] = 0;
    }
    h->matrix.t0 = now;
    h->matrix.enabled = 1;
}

/* display.on() : prend possession des 10 broches (5 lignes puis 5 colonnes,
   identifiants tels qu'ecrits dans le modele - lignes internes 21-25,
   colonnes = broches edge P3/P4/P6/P7/P10). Comme enable() de CODAL : la
   broche est reconfiguree, un PWM en cours dessus est coupe. */
static PyObject* native_matrix_enable(PyObject* self, PyObject* args) {
    REQUIRE_WORKER();
    struct PyRuntimeHandle* h = g_current;
    int ids[MATRIX_ROWS + MATRIX_COLS];
    int i;
    if (!PyArg_ParseTuple(args, "iiiiiiiiii",
                          &ids[0], &ids[1], &ids[2], &ids[3], &ids[4],
                          &ids[5], &ids[6], &ids[7], &ids[8], &ids[9])) return NULL;
    int idx[MATRIX_ROWS + MATRIX_COLS];
    for (i = 0; i < MATRIX_ROWS + MATRIX_COLS; i++) {
        idx[i] = require_pin(ids[i], PIN_CAP_DIGITAL, "matrix pin");
        if (idx[i] < 0) return NULL;
    }
    EnterCriticalSection(&h->cs);
    for (i = 0; i < MATRIX_ROWS + MATRIX_COLS; i++) {
        h->matrix.row_idx[i] = idx[i];
        h->pwm_freq[idx[i]] = 0;   /* CODAL reconfigure la broche : le PWM en cours est coupe */
    }
    for (i = 0; i < MATRIX_COLS; i++) {
        h->matrix.col_idx[i] = idx[MATRIX_ROWS + i];
    }
    h->matrix.t0 = h->sim_time;
    h->matrix.enabled = 1;
    LeaveCriticalSection(&h->cs);
    if (yield_to_modelica(h->sim_time) != 0) return NULL;
    Py_RETURN_NONE;
}

/* display.off() : rend les 10 broches en haute impedance, comme disable() de
   CODAL ("releases control of the GPIO pins used by the display, which are
   exposed on the edge connector"). Le reste de leur etat (direction, tirage)
   est rendu au shim. */
static PyObject* native_matrix_disable(PyObject* self, PyObject* args) {
    REQUIRE_WORKER();
    struct PyRuntimeHandle* h = g_current;
    int i;
    EnterCriticalSection(&h->cs);
    if (h->matrix.enabled) {
        for (i = 0; i < MATRIX_ROWS; i++) {
            if (h->matrix.row_idx[i] >= 0) {
                h->pin_is_output[h->matrix.row_idx[i]] = 0;
                h->matrix_pin_released[h->matrix.row_idx[i]] = 1;
            }
        }
        for (i = 0; i < MATRIX_COLS; i++) {
            if (h->matrix.col_idx[i] >= 0) {
                h->pin_is_output[h->matrix.col_idx[i]] = 0;
                h->matrix_pin_released[h->matrix.col_idx[i]] = 1;
            }
        }
        h->matrix.enabled = 0;
    }
    LeaveCriticalSection(&h->cs);
    if (yield_to_modelica(h->sim_time) != 0) return NULL;
    Py_RETURN_NONE;
}

/* Tampon 5x5 des niveaux (0-9), dans l'ordre du shim : pixels[ligne][colonne],
   25 octets. Les valeurs hors limite sont bornees a 0-9, comme le vrai
   set_pixel borne son argument. */
static PyObject* native_matrix_set_pixels(PyObject* self, PyObject* args) {
    REQUIRE_WORKER();
    struct PyRuntimeHandle* h = g_current;
    const char* buf;
    Py_ssize_t len;
    if (!PyArg_ParseTuple(args, "y#", &buf, &len)) return NULL;
    if (len != MATRIX_ROWS * MATRIX_COLS) {
        PyErr_Format(PyExc_ValueError, "matrix buffer must be %d bytes, got %zd",
                     MATRIX_ROWS * MATRIX_COLS, (Py_ssize_t) len);
        return NULL;
    }
    EnterCriticalSection(&h->cs);
    int i;
    for (i = 0; i < MATRIX_ROWS * MATRIX_COLS; i++) {
        int level = buf[i];
        level = level < 0 ? 0 : (level > MATRIX_MAX_LEVEL ? MATRIX_MAX_LEVEL : level);
        h->matrix.pixels[i / MATRIX_COLS][i % MATRIX_COLS] = (unsigned char) level;
    }
    LeaveCriticalSection(&h->cs);
    /* Aucun yield : le tampon n'a pas d'effet avant le prochain creneau de
       toute facon (une trame dure 16,7 ms), et display.show()/scroll()
       enchainent souvent plusieurs rafraichissements - chacun rendrait la main
       a Modelica pour rien. Le prochain matrix_step le prend en compte. */
    Py_RETURN_NONE;
}
