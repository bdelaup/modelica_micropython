/* Garde d'inclusion : partie du chapeau AnalyzerImpl.c, qui peut se retrouver
   dans la meme unite de compilation qu'un autre chapeau. */
#ifndef ANALYZER_LOGIC_C_INCLUDED
#define ANALYZER_LOGIC_C_INCLUDED

/* LogicAnalyzer : sonde a 8 voies (Peripherals.Analyzers.LogicAnalyzer). Le
   composant Modelica seuille la tension de chaque voie active et appelle
   LogicAnalyzer_record a chaque changement de niveau (when change(...)) : ici,
   les niveaux sont ecrits dans le VCD et gardes en memoire ; a la fin, le
   fichier texte est ecrit (analyzer_text.c) et les fichiers s'ouvrent dans
   PulseView / le Bloc-notes si demande.

   La sonde voit les niveaux ELECTRIQUES reels de n'importe quel fil, PWM
   compris (ses fronts sont de vrais evenements du modele), y compris entre
   deux peripheriques. Son cout : une fonction de franchissement de seuil par
   voie active. */

static const char* an_kind_name(int kind) {
    switch (kind) {
    case AN_KIND_OFF: return "Off";
    case AN_KIND_LOGIC: return "Logic";
    case AN_KIND_UART: return "Uart";
    case AN_KIND_I2C_SDA: return "I2cSda";
    case AN_KIND_SYNC_DATA: return "SyncData";
    default: return "?";
    }
}

/* Nom de base des fichiers : fileName sans son extension .vcd/.txt, ou le nom
   d'instance. */
static char* an_base_name(const char* fileName, const char* instanceName) {
    const char* src = (fileName && fileName[0] != '\0') ? fileName : instanceName;
    char* base = strdup(src ? src : "LogicAnalyzer");
    size_t len = base ? strlen(base) : 0;
    if (len > 4 && (strcmp(base + len - 4, ".vcd") == 0 || strcmp(base + len - 4, ".txt") == 0
                    || strcmp(base + len - 4, ".VCD") == 0 || strcmp(base + len - 4, ".TXT") == 0)) {
        base[len - 4] = '\0';
    }
    return base;
}

void* LogicAnalyzer_new(const char* fileName, const char* instanceName, const char* channelNames,
                        const int* kinds, const double* baudrates, const int* dataBits, const int* parities,
                        const int* stopBits, const int* msbFirst, const int* clocks, const int* clockFalling,
                        const int* wordBits, const int* signedWords,
                        int writeVcd, int writePulseViewSession, int openPulseView, const char* pulseViewPath,
                        int writeText, int openText, const int* textFlags,
                        double textSilence, double textResolution, int textWidth) {
    struct LogicAnalyzer* a;
    char names[AN_NCH][VCD_NAME_MAX];
    char vcd_names[AN_NCH][VCD_NAME_MAX];
    int i, nact = 0;
    a = (struct LogicAnalyzer*) calloc(1, sizeof(struct LogicAnalyzer));
    if (!a) {
        ModelicaFormatError("LogicAnalyzer: allocation failed");
        return NULL;
    }
    a->name = strdup(instanceName ? instanceName : "LogicAnalyzer");
    a->base = an_base_name(fileName, a->name);
    a->t_pend = -1;
    vcd_parse_names(channelNames, AN_NCH, "CH", names);
    for (i = 0; i < AN_NCH; i++) {
        struct AnChannel* c = &a->ch[i];
        c->kind = kinds[i];
        snprintf(c->name, sizeof(c->name), "%s", names[i]);
        c->baud = baudrates[i];
        c->bits = dataBits[i];
        c->parity = parities[i];
        c->stop = stopBits[i];
        c->msb = msbFirst[i] ? 1 : 0;
        c->clock = clocks[i];
        c->falling = clockFalling[i] ? 1 : 0;
        c->word = wordBits[i];
        c->is_signed = signedWords[i] ? 1 : 0;
        c->vcd_index = -1;
        a->pend[i] = -1;
        if (c->kind < AN_KIND_OFF || c->kind > AN_KIND_SYNC_DATA) {
            ModelicaFormatError("%s: CH%d has an unknown kind (%d)", a->name, i, c->kind);
        }
        if (c->kind == AN_KIND_UART) {
            if (!(c->baud > 0.0) || c->bits < 5 || c->bits > 8 || c->parity < -1 || c->parity > 1
                || c->stop < 1 || c->stop > 2) {
                ModelicaFormatError("%s: CH%d, invalid UART setting (baudrate %g, %d data bits, stop bits %d): "
                                    "baudrate > 0, 5 to 8 data bits, 1 or 2 stop bits", a->name, i, c->baud, c->bits, c->stop);
            }
        }
        if (c->kind == AN_KIND_I2C_SDA || c->kind == AN_KIND_SYNC_DATA) {
            if (c->clock < 0 || c->clock >= AN_NCH || c->clock == i) {
                ModelicaFormatError("%s: CH%d (%s) needs a clock channel other than itself, from 0 to 7 (clockChannel = %d)",
                                    a->name, i, an_kind_name(c->kind), c->clock);
            }
            if (kinds[c->clock] != AN_KIND_LOGIC) {
                ModelicaFormatError("%s: CH%d takes its clock on CH%d, which must be a Logic channel (it is %s)",
                                    a->name, i, c->clock, an_kind_name(kinds[c->clock]));
            }
        }
        if (c->kind == AN_KIND_SYNC_DATA && (c->word < 1 || c->word > 32)) {
            ModelicaFormatError("%s: CH%d, wordBits = %d out of range (1-32)", a->name, i, c->word);
        }
        if (c->kind != AN_KIND_OFF) {
            c->vcd_index = nact;
            snprintf(vcd_names[nact], VCD_NAME_MAX, "%s", c->name);
            nact++;
        }
    }
    a->write_vcd = writeVcd;
    a->write_pvs = writePulseViewSession;
    a->open_pulseview = openPulseView;
    /* chemin relatif : depuis le dossier de simulation (dossier courant), rendu
       absolu tout de suite pour le message d'un echec */
    a->pulseview_path = (pulseViewPath && pulseViewPath[0] != '\0') ? launch_full_path(pulseViewPath) : strdup("");
    a->write_text = writeText;
    a->open_text = openText;
    a->opt_hex = textFlags[0];
    a->opt_wave = textFlags[1];
    a->opt_bits = textFlags[2];
    a->opt_split = textFlags[3];
    a->opt_compress = textFlags[4];
    a->opt_silence = textSilence;
    a->opt_resolution = textResolution;
    a->opt_width = textWidth < AN_MIN_WIDTH ? AN_MIN_WIDTH : (textWidth > AN_MAX_WIDTH ? AN_MAX_WIDTH : textWidth);
    if (nact == 0) {
        ModelicaFormatWarning("Logic analyser %s: all channels are Off - nothing recorded\n", a->name);
        return (void*) a;
    }
    if (writeVcd) {
        size_t len = strlen(a->base) + 8;
        char* file = (char*) malloc(len);
        char* full;
        snprintf(file, len, "%s.vcd", a->base);
        full = launch_full_path(file);
        if (vcd_open(&a->vcd, file, full, "probe", nact, vcd_names)) {
            ModelicaFormatMessage("Logic analyser %s: %d channel(s) recorded in %s\n", a->name, nact, full);
        }
        free(full);
        free(file);
    }
    return (void*) a;
}

/* Fronts gardes en memoire : instant en cours clos quand le temps avance, et
   seulement les voies qui ont change (meme coalescence que le VCD). */
static void an_commit_instant(struct LogicAnalyzer* a) {
    int i;
    double t;
    if (a->t_pend < 0 || a->edges_full) {
        return;
    }
    t = (double) a->t_pend * 1e-9;
    for (i = 0; i < AN_NCH; i++) {
        struct AnChannel* c = &a->ch[i];
        struct AnEdge e;
        if (c->kind == AN_KIND_OFF || a->pend[i] < 0) {
            continue;
        }
        if (c->edges.n > 0 && ((struct AnEdge*) c->edges.p)[c->edges.n - 1].v == a->pend[i]) {
            continue;
        }
        if (c->edges.n == 1 && t < AN_INIT_WINDOW) {
            ((struct AnEdge*) c->edges.p)[0].v = a->pend[i];   /* etablissement : niveau initial */
            continue;
        }
        if (a->total_edges >= AN_MAX_EDGES) {
            a->edges_full = 1;
            a->t_full = t;
            ModelicaFormatWarning("Logic analyser %s: %ld level changes recorded, the text file stops at t = %g s "
                                  "(the VCD file is complete)\n", a->name, AN_MAX_EDGES, t);
            return;
        }
        e.t = c->edges.n == 0 ? 0.0 : t;
        e.v = a->pend[i];
        if (an_push(&c->edges, &e, sizeof(e))) {
            a->total_edges++;
        }
    }
}

int LogicAnalyzer_record(void* an, double currentTime, const int* levels, size_t n) {
    struct LogicAnalyzer* a = (struct LogicAnalyzer*) an;
    long long ns = llround(currentTime * 1e9);
    int i;
    if (ns > a->t_pend) {
        an_commit_instant(a);
        a->t_pend = ns;
    }
    for (i = 0; i < AN_NCH && (size_t) i < n; i++) {
        struct AnChannel* c = &a->ch[i];
        if (c->kind == AN_KIND_OFF) {
            continue;
        }
        a->pend[i] = levels[i] ? 1 : 0;
        vcd_set(&a->vcd, currentTime, c->vcd_index, levels[i]);
    }
    a->t_end = currentTime;
    return ++a->calls;
}

int LogicAnalyzer_finish(void* an, double currentTime) {
    struct LogicAnalyzer* a = (struct LogicAnalyzer*) an;
    a->t_end = currentTime;
    return 1;
}

/* Fin de simulation : clot le VCD, ecrit le fichier texte, dit ou ils sont,
   et les ouvre si demande (lanceur commun, launch.c). */
void LogicAnalyzer_destroy(void* an) {
    struct LogicAnalyzer* a = (struct LogicAnalyzer*) an;
    int i;
    if (!a) {
        return;
    }
    an_commit_instant(a);
    if (a->vcd.f) {
        vcd_close(&a->vcd, a->t_end);
        ModelicaFormatMessage("Logic analyser %s: end of simulation, recording in %s (%ld level changes)\n",
                              a->name, a->vcd.path, a->vcd.changes);
        if (a->write_pvs) {
            /* meme nom que le VCD, extension .pvs : PulseView le charge de lui-meme */
            size_t len = strlen(a->base) + 8;
            char* file = (char*) malloc(len);
            if (file) {
                int n;
                snprintf(file, len, "%s.pvs", a->base);
                n = an_write_pvs(a, file);
                if (n > 0) {
                    ModelicaFormatMessage("Logic analyser %s: PulseView session with %d decoder(s) in %s.pvs\n", a->name, n, a->base);
                }
                free(file);
            }
        }
        if (a->open_pulseview && a->vcd.path) {
            launch_detached("PulseView", a->pulseview_path, "-c -I vcd", a->vcd.path);
        }
    }
    if (a->write_text && a->total_edges > 0) {
        size_t len = strlen(a->base) + 8;
        char* file = (char*) malloc(len);
        char* full;
        snprintf(file, len, "%s.txt", a->base);
        full = launch_full_path(file);
        if (an_write_text(a, file)) {
            ModelicaFormatMessage("Logic analyser %s: decoded frames in %s\n", a->name, full);
            if (a->open_text) {
                launch_detached("Notepad", "notepad.exe", NULL, full);
            }
        }
        free(full);
        free(file);
    }
    for (i = 0; i < AN_NCH; i++) {
        an_free(&a->ch[i].edges);
        an_free(&a->ch[i].labels);
        an_free(&a->ch[i].spans);
        free(a->ch[i].hex.s);
    }
    an_free(&a->busy);
    an_free(&a->frames);
    free(a->busy_maxb);
    free(a->vcd.path);
    free(a->pulseview_path);
    free(a->base);
    free(a->name);
    free(a);
}

#endif /* ANALYZER_LOGIC_C_INCLUDED */
