/* Garde d'inclusion : partie du chapeau AnalyzerImpl.c. */
#ifndef ANALYZER_CORE_H_INCLUDED
#define ANALYZER_CORE_H_INCLUDED

/* Sonde d'analyseur logique (Peripherals.Analyzers.LogicAnalyzer) : constantes
   et structures partagees par analyzer_text.c (decodage et fichier texte) et
   analyzer_logic.c (capture, API exportee) - cf. requirements.md, decision
   "Analyseur logique".

   La sonde garde en memoire les fronts de chaque voie active (apres
   coalescence par instant, comme le VCD) : le fichier texte est ecrit en FIN
   de simulation, a partir de ces fronts, sans aucun evenement de plus. */

#define AN_NCH 8                         /* voies CH0..CH7 */
#define AN_NAME_MAX 32                   /* = VCD_NAME_MAX */
#define AN_MAX_EDGES 2000000L            /* fronts gardes pour le fichier texte, toutes voies (16 octets chacun) ; au-dela, le texte s'arrete la, le VCD continue */
#define AN_INIT_WINDOW 1e-6              /* un front avant 1 us n'est que l'etablissement des niveaux initiaux (sources qui montent a t=0) : il remplace le niveau initial */

/* Type d'une voie : Interfaces.ChannelKind, passe par Integer(kind). */
#define AN_KIND_OFF 1
#define AN_KIND_LOGIC 2
#define AN_KIND_UART 3
#define AN_KIND_I2C_SDA 4
#define AN_KIND_SYNC_DATA 5

/* Fichier texte : plafond de colonnes de chronogramme, toutes lignes
   confondues (environ 2000 lignes de 100 colonnes) ; au-dela, le chronogramme
   s'interrompt sur une note, la section hexa reste complete. */
#define AN_TEXT_MAX_COLUMNS 200000L
#define AN_SILENCE_COLUMNS 40            /* silence automatique : 40 colonnes */
#define AN_MIN_WIDTH 40
#define AN_MAX_WIDTH 1000

struct AnEdge {
    double t;
    int v;
};

/* Un bit etiquete sous le chronogramme ("S", "0", "1", "P", "s", "A", "N", "Sr"). */
struct AnLabel {
    double t;
    char s[4];
};

/* Valeur decodee, affichee entre crochets sous les bits qu'elle couvre. */
struct AnSpan {
    double a, b;
    char s[40];
};

/* Intervalle de temps (trame, zone ou une ligne ne doit pas etre coupee). */
struct AnInterval {
    double a, b;
};

/* Tableau dynamique : donnees + nombre + capacite. */
struct AnArray {
    void* p;
    long n, cap;
};

/* Texte accumule (section hexa d'une voie). */
struct AnText {
    char* s;
    size_t len, cap;
};

struct AnChannel {
    int kind;                        /* AN_KIND_* */
    char name[AN_NAME_MAX];
    double baud;                     /* UART */
    int bits, parity, stop, msb;     /* UART : parity -1/0/1 (convention machine.UART) ; msb : bits de poids fort en tete (UART, serie synchrone) */
    int clock;                       /* I2C SDA, donnees synchrones : voie d'horloge (0-7) */
    int falling;                     /* donnees synchrones : lues au front descendant de l'horloge (sinon montant) */
    int word;                        /* donnees synchrones : bits par mot */
    int is_signed;                   /* donnees synchrones : mot en complement a deux */
    struct AnArray edges;            /* struct AnEdge, edges[0] = niveau initial (t = 0) */
    int vcd_index;                   /* rang dans le VCD (voies actives seulement), -1 : voie Off */
    /* rempli par le decodage, en fin de simulation */
    struct AnArray labels;           /* struct AnLabel, par temps croissant */
    struct AnArray spans;            /* struct AnSpan, par debut croissant */
    struct AnText hex;               /* lignes de la section hexa + ASCII */
};

struct LogicAnalyzer {
    struct AnChannel ch[AN_NCH];
    char* name;                      /* nom d'instance */
    char* base;                      /* nom de base des fichiers (sans extension) */
    struct VcdWriter vcd;
    int write_vcd, open_pulseview, write_pvs;
    char* pulseview_path;
    int write_text, open_text;
    int opt_hex, opt_wave, opt_bits, opt_split, opt_compress;
    double opt_silence, opt_resolution;
    int opt_width;
    double t_end;                    /* dernier instant connu (terminal() ou dernier appel) */
    int calls;
    /* coalescence par instant des fronts gardes en memoire */
    long long t_pend;                /* instant en cours (ns), -1 avant le premier appel */
    int pend[AN_NCH];
    long total_edges;
    int edges_full;                  /* plafond AN_MAX_EDGES atteint : texte arrete a t_full */
    double t_full;
    /* rempli en fin de simulation */
    struct AnArray busy;             /* struct AnInterval, triees par debut */
    double* busy_maxb;               /* maximum courant des fins de busy (recherche dichotomique) */
    struct AnArray frames;           /* struct AnInterval */
};

#endif /* ANALYZER_CORE_H_INCLUDED */
