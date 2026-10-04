/* Garde d'inclusion : partie du chapeau AnalyzerImpl.c, qui peut se retrouver
   dans la meme unite de compilation qu'un autre chapeau. */
#ifndef VCD_C_INCLUDED
#define VCD_C_INCLUDED

/* Enregistreur VCD (Value Change Dump, IEEE 1364) de signaux logiques d'un
   bit : le format que lisent PulseView (import "vcd", puis decodeurs UART,
   I2C, SPI...) et GTKWave. Cf. requirements.md, decision "Analyseur logique".

   COALESCENCE PAR INSTANT. Modelica rappelle une fonction externe 2 a 3 fois
   au meme instant simule (iterations d'evenement), et une sortie publiee par
   le MCU ne devient une tension qu'a l'iteration suivante : un instant peut
   donc voir passer des valeurs intermediaires (la sonde coalesce deja de son
   cote, pour ses fronts gardes en memoire ; l'enregistreur reste autonome). On ne garde que la DERNIERE
   valeur de chaque voie a un instant donne, ecrite quand le temps avance, et
   seulement si elle differe de la derniere ecrite : les glitchs de largeur
   nulle disparaissent, le fichier ne contient que de vrais changements.

   Temps en nanosecondes entieres ($timescale 1 ns), arrondis (llround) : les
   echeances tombent souvent un poil sous la valeur ronde, comme pour
   ticks_us(). Ecriture tamponnee (setvbuf), sans aucun evenement Modelica de
   plus : l'enregistreur ne fait qu'ecrire lors d'appels qui ont lieu de toute
   facon.

   Sans Python ni thread ; inclus textuellement, jamais compile seul. L'appelant
   inclut stdio.h, string.h, math.h et ModelicaUtilities.h avant ce fichier. */

#define VCD_MAX_CH 16
#define VCD_NAME_MAX 32
#define VCD_BUF_SIZE (1 << 16)

struct VcdWriter {
    FILE* f;
    char* path;                       /* chemin absolu (journal, programme lance a la fin) */
    char* buf;                        /* tampon de setvbuf */
    int n;                            /* nombre de voies */
    int last[VCD_MAX_CH];             /* derniere valeur ecrite (-1 : jamais) */
    int pend[VCD_MAX_CH];             /* valeur courante a l'instant t_pend (-1 : inconnue) */
    long long t_pend;                 /* instant en cours (ns), -1 avant le premier appel */
    long long t_last;                 /* dernier instant ecrit (ns) */
    long changes;                     /* changements ecrits, pour le bilan */
};

/* Ouvre le fichier et ecrit l'en-tete. names : n noms de voies. Rend 1 si le
   fichier est ouvert ; sinon un avertissement, et l'enregistreur reste inerte
   (la simulation n'en depend pas). */
static int vcd_open(struct VcdWriter* w, const char* path, const char* fullPath, const char* scope,
                    int n, char names[][VCD_NAME_MAX]) {
    int i;
    memset(w, 0, sizeof(*w));
    w->t_pend = -1;
    w->t_last = -1;
    w->n = n > VCD_MAX_CH ? VCD_MAX_CH : n;
    for (i = 0; i < VCD_MAX_CH; i++) {
        w->last[i] = -1;
        w->pend[i] = -1;
    }
    w->f = fopen(path, "wb");   /* binaire : fins de ligne LF, comme tout VCD (en mode texte, Windows ecrirait CRLF) */
    if (!w->f) {
        ModelicaFormatWarning("Logic analyser: cannot create %s - no capture\n", path);
        return 0;
    }
    w->buf = (char*) malloc(VCD_BUF_SIZE);
    if (w->buf) {
        setvbuf(w->f, w->buf, _IOFBF, VCD_BUF_SIZE);
    }
    w->path = strdup(fullPath);
    fprintf(w->f, "$comment MicroPythonMCU logic capture $end\n");
    fprintf(w->f, "$timescale 1 ns $end\n");
    fprintf(w->f, "$scope module %s $end\n", scope);
    for (i = 0; i < w->n; i++) {
        /* identifiants d'un caractere, des lettres : 'A', 'B'... Les codes
           permis vont de '!' a '~', mais '$' ou '"' deroutent certains
           lecteurs de VCD. */
        fprintf(w->f, "$var wire 1 %c %s $end\n", (char) ('A' + i), names[i]);
    }
    fprintf(w->f, "$upscope $end\n$enddefinitions $end\n");
    return 1;
}

/* Ecrit l'instant en cours s'il porte au moins un changement. */
static void vcd_flush_instant(struct VcdWriter* w) {
    int i, header = 0;
    if (!w->f || w->t_pend < 0) {
        return;
    }
    for (i = 0; i < w->n; i++) {
        if (w->pend[i] >= 0 && w->pend[i] != w->last[i]) {
            if (!header) {
                fprintf(w->f, "#%lld\n", w->t_pend);
                header = 1;
                w->t_last = w->t_pend;
            }
            fprintf(w->f, "%d%c\n", w->pend[i], (char) ('A' + i));
            w->last[i] = w->pend[i];
            w->changes++;
        }
    }
}

/* Valeur de la voie ch a l'instant t (s). Les instants doivent etre croissants
   (egaux autorises : la derniere valeur l'emporte) ; un instant anterieur a
   l'instant en cours est ramene a celui-ci. */
static void vcd_set(struct VcdWriter* w, double t, int ch, int level) {
    long long ns;
    if (!w->f || ch < 0 || ch >= w->n) {
        return;
    }
    ns = llround(t * 1e9);
    if (ns > w->t_pend) {
        vcd_flush_instant(w);
        w->t_pend = ns;
    }
    w->pend[ch] = level ? 1 : 0;
}

/* Clot la capture : dernier instant, puis un horodatage de fin a t_end pour
   que les visionneuses montrent toute la duree simulee. */
static void vcd_close(struct VcdWriter* w, double t_end) {
    long long ns;
    if (!w->f) {
        return;
    }
    vcd_flush_instant(w);
    ns = llround(t_end * 1e9);
    if (ns > w->t_last) {
        fprintf(w->f, "#%lld\n", ns);
    }
    fclose(w->f);
    w->f = NULL;
    free(w->buf);
    w->buf = NULL;
}

/* Decoupe "TX,RX,SCL" en noms de voies ; les voies sans nom (ou au-dela de la
   liste) prennent default_prefix suivi de leur numero. Espaces de tete et de
   queue retires, caracteres hors [A-Za-z0-9_] remplaces par '_' (un nom VCD ne
   contient pas d'espace). */
static void vcd_parse_names(const char* list, int n, const char* default_prefix, char names[][VCD_NAME_MAX]) {
    int i = 0;
    const char* p = list ? list : "";
    for (i = 0; i < n; i++) {
        snprintf(names[i], VCD_NAME_MAX, "%s%d", default_prefix, i);
    }
    i = 0;
    while (*p && i < n) {
        const char* end = strchr(p, ',');
        size_t len = end ? (size_t) (end - p) : strlen(p);
        size_t a = 0, b = len, k, m = 0;
        while (a < b && (p[a] == ' ' || p[a] == '\t')) a++;
        while (b > a && (p[b - 1] == ' ' || p[b - 1] == '\t')) b--;
        if (b > a) {
            for (k = a; k < b && m < VCD_NAME_MAX - 1; k++) {
                char c = p[k];
                int ok = (c >= 'A' && c <= 'Z') || (c >= 'a' && c <= 'z') || (c >= '0' && c <= '9') || c == '_';
                names[i][m++] = ok ? c : '_';
            }
            names[i][m] = '\0';
        }
        i++;
        if (!end) {
            break;
        }
        p = end + 1;
    }
}

#endif /* VCD_C_INCLUDED */
