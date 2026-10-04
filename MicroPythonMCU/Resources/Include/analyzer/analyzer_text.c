/* Garde d'inclusion : partie du chapeau AnalyzerImpl.c. */
#ifndef ANALYZER_TEXT_C_INCLUDED
#define ANALYZER_TEXT_C_INCLUDED

/* Fichier texte de la sonde LogicAnalyzer : decodage des voies (UART, I2C,
   serie synchrone) et mise en page, en FIN de simulation, a partir des fronts
   gardes en memoire - cf. requirements.md, decision "Analyseur logique".

   Le fichier a deux sections, chacune desactivable :
     - "Decoded data" : les octets de chaque voie decodee en hexa + ASCII
       (salves UART, transactions I2C, mots synchrones), et un bilan des voies
       logiques (fronts, rapport cyclique, impulsion la plus courte) ;
     - "Timing diagram" : le chronogramme en ASCII (deux lignes par voie :
       '_' en haut = niveau haut, '_' en bas = niveau bas, '|' = front), avec
       sous chaque voie decodee les bits un par un puis la valeur de chaque
       octet entre crochets.
   Une trame est une salve UART, une transaction I2C (START..STOP) ou une
   rafale d'impulsions d'horloge synchrone ; chacune commence par un en-tete,
   et un silence plus long que le seuil n'est pas dessine (une ligne "~~").

   Les decodeurs travaillent HORS LIGNE sur la liste des fronts, en lisant le
   niveau d'une voie a n'importe quel instant (an_level) : l'UART lit chaque
   bit en son milieu, comme le recepteur du MCU (uartcore.c), l'I2C lit SDA au
   front montant de SCL, comme le moteur cible (i2ctarget.c). La sonde
   observe : elle ne fait que relire ce qui est passe sur les fils. */

/* ------------------------------------------------------------- utilitaires */

static int an_push(struct AnArray* a, const void* item, size_t size) {
    if (a->n >= a->cap) {
        long cap = a->cap ? a->cap * 2 : 64;
        void* p = realloc(a->p, (size_t) cap * size);
        if (!p) {
            return 0;
        }
        a->p = p;
        a->cap = cap;
    }
    memcpy((char*) a->p + (size_t) a->n * size, item, size);
    a->n++;
    return 1;
}

static void an_free(struct AnArray* a) {
    free(a->p);
    a->p = NULL;
    a->n = a->cap = 0;
}

static void an_textf(struct AnText* t, const char* fmt, ...) {
    va_list ap;
    int need;
    va_start(ap, fmt);
    need = vsnprintf(NULL, 0, fmt, ap);
    va_end(ap);
    if (need < 0) {
        return;
    }
    if (t->len + (size_t) need + 1 > t->cap) {
        size_t cap = t->cap ? t->cap : 1024;
        char* s;
        while (t->len + (size_t) need + 1 > cap) {
            cap *= 2;
        }
        s = (char*) realloc(t->s, cap);
        if (!s) {
            return;
        }
        t->s = s;
        t->cap = cap;
    }
    va_start(ap, fmt);
    vsnprintf(t->s + t->len, t->cap - t->len, fmt, ap);
    va_end(ap);
    t->len += (size_t) need;
}

/* Instant lisible : "416.7 us", "13.750 ms", "1.100415 s". */
static const char* an_fmt_t(double t, char* buf, size_t size) {
    double a = fabs(t);
    if (a >= 1.0) {
        snprintf(buf, size, "%.6f s", t);
    } else if (a >= 1e-3) {
        snprintf(buf, size, "%.3f ms", t * 1e3);
    } else if (a >= 1e-6 || a == 0.0) {
        snprintf(buf, size, "%.1f us", t * 1e6);
    } else {
        snprintf(buf, size, "%.0f ns", t * 1e9);
    }
    return buf;
}

static char an_printable(unsigned v) {
    return (v >= 0x20 && v < 0x7F) ? (char) v : '.';
}

/* Niveau de la voie a l'instant t (dernier front <= t). */
static int an_level(const struct AnChannel* c, double t) {
    const struct AnEdge* e = (const struct AnEdge*) c->edges.p;
    long lo = 0, hi = c->edges.n - 1;
    if (c->edges.n == 0) {
        return 0;
    }
    if (t < e[0].t) {
        return e[0].v;
    }
    while (lo < hi) {
        long mid = (lo + hi + 1) / 2;
        if (e[mid].t <= t) {
            lo = mid;
        } else {
            hi = mid - 1;
        }
    }
    return e[lo].v;
}

/* Plus petit intervalle entre deux fronts successifs d'une voie (0 si moins de
   deux fronts apres le niveau initial). */
static double an_min_interval(const struct AnChannel* c) {
    const struct AnEdge* e = (const struct AnEdge*) c->edges.p;
    double m = 0.0;
    long k;
    for (k = 2; k < c->edges.n; k++) {
        double d = e[k].t - e[k - 1].t;
        if (d > 0.0 && (m == 0.0 || d < m)) {
            m = d;
        }
    }
    return m;
}

static void an_add_label(struct AnChannel* c, double t, const char* s) {
    struct AnLabel l;
    l.t = t;
    snprintf(l.s, sizeof(l.s), "%s", s);
    an_push(&c->labels, &l, sizeof(l));
}

static void an_add_span(struct AnChannel* c, double a, double b, const char* s) {
    struct AnSpan sp;
    sp.a = a;
    sp.b = b;
    snprintf(sp.s, sizeof(sp.s), "%s", s);
    an_push(&c->spans, &sp, sizeof(sp));
}

static void an_add_interval(struct AnArray* arr, double a, double b) {
    struct AnInterval iv;
    iv.a = a;
    iv.b = b;
    an_push(arr, &iv, sizeof(iv));
}

/* ------------------------------------------------------------- resolution */

/* Resolution automatique : un demi-bit pour l'UART, un demi-palier de
   l'horloge pour l'I2C et la serie synchrone (un quart de periode pour un
   SCL symetrique) ; a defaut, la moitie de l'impulsion la plus courte d'une
   voie logique (au moins 100 ns). */
static double an_auto_resolution(struct LogicAnalyzer* a) {
    double dt = 0.0;
    int i;
    for (i = 0; i < AN_NCH; i++) {
        struct AnChannel* c = &a->ch[i];
        double d = 0.0;
        if (c->kind == AN_KIND_UART) {
            d = 0.5 / c->baud;
        } else if (c->kind == AN_KIND_I2C_SDA || c->kind == AN_KIND_SYNC_DATA) {
            d = an_min_interval(&a->ch[c->clock]) / 2.0;
        }
        if (d > 0.0 && (dt == 0.0 || d < dt)) {
            dt = d;
        }
    }
    if (dt == 0.0) {
        for (i = 0; i < AN_NCH; i++) {
            if (a->ch[i].kind == AN_KIND_LOGIC) {
                double d = an_min_interval(&a->ch[i]) / 2.0;
                if (d > 0.0 && (dt == 0.0 || d < dt)) {
                    dt = d;
                }
            }
        }
        if (dt > 0.0 && dt < 1e-7) {
            dt = 1e-7;
        }
    }
    if (dt == 0.0) {
        dt = a->t_end > 0.0 ? a->t_end / a->opt_width : 1e-3;
    }
    return dt;
}

/* ------------------------------------------------------------- UART */

struct AnByte {
    double t0, t1;
    unsigned v;
    int err;                         /* 1 : parite, 2 : stop bas (trame) */
};

static void an_hex_burst(struct AnChannel* c, const struct AnByte* b, long n, int nb) {
    char t1[32], t2[32];
    long i, j, nerr = 0;
    for (i = 0; i < n; i++) {
        if (b[i].err) {
            nerr++;
        }
    }
    an_textf(&c->hex, "%s  burst %d  %s .. %s  %ld byte%s", c->name, nb,
             an_fmt_t(b[0].t0, t1, sizeof(t1)), an_fmt_t(b[n - 1].t1, t2, sizeof(t2)), n, n > 1 ? "s" : "");
    if (nerr) {
        an_textf(&c->hex, ", %ld with error (!P parity, !F stop bit low)", nerr);
    }
    an_textf(&c->hex, "\n");
    for (i = 0; i < n; i += 16) {
        long m = (n - i) < 16 ? (n - i) : 16;
        an_textf(&c->hex, "  %12s  ", an_fmt_t(b[i].t0, t1, sizeof(t1)));
        for (j = 0; j < 16; j++) {
            if (j == 8) {
                an_textf(&c->hex, " ");
            }
            if (j < m) {
                an_textf(&c->hex, "%02X%c", b[i + j].v, b[i + j].err ? '!' : ' ');
            } else {
                an_textf(&c->hex, "   ");
            }
        }
        an_textf(&c->hex, "  |");
        for (j = 0; j < m; j++) {
            an_textf(&c->hex, "%c", an_printable(b[i + j].v));
        }
        an_textf(&c->hex, "|\n");
    }
}

/* Octets d'une voie UART : un front descendant hors trame est un start s'il
   est encore bas un demi-bit plus tard ; chaque bit est lu en son milieu ; la
   parite et le PREMIER stop sont controles (comme le RP2040), l'octet est
   garde meme faux. La recherche du start suivant reprend au milieu du premier
   stop, comme un recepteur reel. */
static void an_decode_uart(struct LogicAnalyzer* a, struct AnChannel* c, double t_stop) {
    const struct AnEdge* e = (const struct AnEdge*) c->edges.p;
    double T = 1.0 / c->baud;
    int np = c->parity >= 0 ? 1 : 0;
    int nb = 1 + c->bits + np;               /* start + donnees + parite */
    double frame = (nb + c->stop) * T;
    double t_min = -1.0;
    struct AnArray bytes = {0};
    long k, i, burst_start = 0;
    int bursts = 0;
    char lab[4], txt[40];
    for (k = 1; k < c->edges.n; k++) {
        double tf = e[k].t;
        unsigned v = 0;
        int ones = 0, err = 0, j;
        struct AnByte by;
        if (e[k].v != 0 || tf < t_min) {
            continue;
        }
        if (tf + (nb + 0.5) * T > t_stop) {
            break;                           /* trame coupee par la fin de la capture */
        }
        if (an_level(c, tf + 0.5 * T) != 0) {
            continue;                        /* faux depart */
        }
        an_add_label(c, tf + 0.5 * T, "S");
        for (j = 0; j < c->bits; j++) {
            double tm = tf + (1.5 + j) * T;
            int bit = an_level(c, tm);
            ones += bit;
            if (c->msb) {
                v = (v << 1) | (unsigned) bit;
            } else {
                v |= (unsigned) bit << j;
            }
            snprintf(lab, sizeof(lab), "%d", bit);
            an_add_label(c, tm, lab);
        }
        if (np) {
            double tm = tf + (1.5 + c->bits) * T;
            if ((ones + an_level(c, tm)) % 2 != c->parity) {
                err |= 1;
            }
            an_add_label(c, tm, "P");
        }
        for (j = 0; j < c->stop; j++) {
            double tm = tf + (nb + 0.5 + j) * T;
            if (j == 0 && an_level(c, tm) == 0) {
                err |= 2;
            }
            an_add_label(c, tm, "s");
        }
        snprintf(txt, sizeof(txt), "%02X %c%s%s", v, an_printable(v),
                 (err & 1) ? " !P" : "", (err & 2) ? " !F" : "");
        an_add_span(c, tf, tf + nb * T, txt);
        an_add_interval(&a->busy, tf, tf + nb * T);
        by.t0 = tf;
        by.t1 = tf + frame;
        by.v = v;
        by.err = err;
        an_push(&bytes, &by, sizeof(by));
        t_min = tf + (nb + 0.5) * T;
    }
    /* salves : octets separes de moins de deux durees de trame */
    for (i = 0; i <= bytes.n; i++) {
        const struct AnByte* b = (const struct AnByte*) bytes.p;
        if (i == bytes.n || (i > burst_start && b[i].t0 - b[i - 1].t1 > 2.0 * frame)) {
            if (i > burst_start) {
                an_hex_burst(c, b + burst_start, i - burst_start, ++bursts);
                an_add_interval(&a->frames, b[burst_start].t0, b[i - 1].t1);
            }
            burst_start = i;
        }
    }
    if (bytes.n == 0) {
        an_textf(&c->hex, "%s  no byte\n", c->name);
    }
    an_free(&bytes);
}

/* ------------------------------------------------------------- I2C */

/* Transactions d'un bus I2C : START (SDA descend, SCL haute), START repete,
   bits lus au front MONTANT de SCL, 9e bit = acquittement vu sur le bus (bas =
   ACK), STOP (SDA monte, SCL haute). Le premier octet apres un START est
   l'adresse et le sens. */
static void an_decode_i2c(struct LogicAnalyzer* a, struct AnChannel* sda, double dt) {
    struct AnChannel* scl = &a->ch[sda->clock];
    const struct AnEdge* ed = (const struct AnEdge*) sda->edges.p;
    const struct AnEdge* ec = (const struct AnEdge*) scl->edges.p;
    long kd = 1, kc = 1;
    int in_tr = 0, nbits = 0, expect_addr = 0, count = 0;
    unsigned shift = 0;
    double t_start = 0.0, byte_t0 = 0.0;
    struct AnText line = {0};
    char ascii[80];
    int nascii = 0;
    char lab[4], txt[40], t1[32];
    struct AnText body = {0};
    long byte_labels = 0;                    /* etiquettes de la voie au debut de l'octet en cours */
    while (kd < sda->edges.n || kc < scl->edges.n) {
        int is_sda;
        double t;
        if (kc >= scl->edges.n || (kd < sda->edges.n && ed[kd].t < ec[kc].t)) {
            is_sda = 1;
            t = ed[kd].t;
        } else {
            is_sda = 0;
            t = ec[kc].t;
        }
        if (is_sda) {
            int v = ed[kd++].v;
            if (an_level(scl, t) == 1) {
                if (nbits > 0) {
                    /* le maitre a remonte SCL avant un START repete ou un STOP :
                       ces fronts ne portaient pas de bits */
                    sda->labels.n = byte_labels;
                    nbits = 0;
                }
                if (v == 0) {                                   /* START ou START repete */
                    if (in_tr) {
                        an_add_label(sda, t, "Sr");
                        an_textf(&line, " Sr");
                    } else {
                        in_tr = 1;
                        t_start = t;
                        line.len = 0;
                        nascii = 0;
                        an_add_label(sda, t, "S");
                        an_textf(&line, "S");
                    }
                    nbits = 0;
                    shift = 0;
                    expect_addr = 1;
                } else if (in_tr) {                             /* STOP */
                    an_add_label(sda, t, "P");
                    an_textf(&line, " P");
                    ascii[nascii] = '\0';
                    an_textf(&body, "  %12s  %s%s%s%s\n", an_fmt_t(t_start, t1, sizeof(t1)), line.s,
                             nascii ? "   |" : "", ascii, nascii ? "|" : "");
                    an_add_interval(&a->frames, t_start, t);
                    in_tr = 0;
                    count++;
                }
            }
        } else {
            int v = ec[kc++].v;
            if (v == 1 && in_tr) {
                int bit = an_level(sda, t);
                if (nbits < 8) {
                    if (nbits == 0) {
                        byte_t0 = t;
                        byte_labels = sda->labels.n;
                    }
                    shift = (shift << 1) | (unsigned) bit;
                    nbits++;
                    snprintf(lab, sizeof(lab), "%d", bit);
                    an_add_label(sda, t, lab);
                } else {
                    unsigned val = shift & 0xFFu;
                    int ack = bit == 0;
                    an_add_label(sda, t, ack ? "A" : "N");
                    if (expect_addr) {
                        snprintf(txt, sizeof(txt), "%02X %c", val >> 1, (val & 1u) ? 'R' : 'W');
                        an_textf(&line, " [%02X %c]%s", val >> 1, (val & 1u) ? 'R' : 'W', ack ? "" : "*");
                    } else {
                        snprintf(txt, sizeof(txt), "%02X %c", val, an_printable(val));
                        an_textf(&line, " %02X%s", val, ack ? "" : "*");
                        if (nascii < (int) sizeof(ascii) - 1) {
                            ascii[nascii++] = an_printable(val);
                        }
                    }
                    an_add_span(sda, byte_t0, t + (t - byte_t0) / 8.0, txt);
                    an_add_interval(&a->busy, byte_t0 - dt, t + dt);
                    expect_addr = 0;
                    nbits = 0;
                    shift = 0;
                }
            }
        }
    }
    if (in_tr) {
        ascii[nascii] = '\0';
        an_textf(&body, "  %12s  %s (no STOP before the end)%s%s%s\n", an_fmt_t(t_start, t1, sizeof(t1)), line.s,
                 nascii ? "   |" : "", ascii, nascii ? "|" : "");
        an_add_interval(&a->frames, t_start, a->t_end);
        count++;
    }
    an_textf(&sda->hex, "%s  I2C, clock %s  %d transaction%s   (* = not acknowledged, NACK)\n",
             sda->name, scl->name, count, count > 1 ? "s" : "");
    if (body.s) {
        an_textf(&sda->hex, "%s", body.s);
    }
    free(line.s);
    free(body.s);
}

/* ------------------------------------------------------------- serie synchrone */

/* Donnees lues sur un front de l'horloge (HX711, SPI simplifie). Une rafale
   d'impulsions (intervalle de moins de 8 fois le plus court entre deux fronts
   de lecture) est une trame, decoupee en mots de 'word' bits ; les impulsions
   qui restent (moins d'un mot) sont comptees a part - le HX711 en ajoute 1 a
   3 pour choisir le gain de la mesure suivante. */
static void an_decode_sync(struct LogicAnalyzer* a, struct AnChannel* dat, double dt) {
    struct AnChannel* clk = &a->ch[dat->clock];
    const struct AnEdge* e = (const struct AnEdge*) clk->edges.p;
    int edge_level = dat->falling ? 0 : 1;
    struct AnArray st = {0};                 /* instants de lecture (double) */
    double min_int = 0.0, gap;
    long k, i, b0 = 0;
    int words = 0, hexw = (dat->word + 3) / 4;
    char t1[32], lab[4], txt[40];
    for (k = 1; k < clk->edges.n; k++) {
        if (e[k].v == edge_level) {
            an_push(&st, &e[k].t, sizeof(double));
        }
    }
    for (i = 1; i < st.n; i++) {
        double d = ((double*) st.p)[i] - ((double*) st.p)[i - 1];
        if (d > 0.0 && (min_int == 0.0 || d < min_int)) {
            min_int = d;
        }
    }
    gap = 8.0 * min_int;
    for (i = 0; i <= st.n; i++) {
        const double* s = (const double*) st.p;
        if (i < st.n && (i == b0 || s[i] - s[i - 1] <= gap)) {
            continue;
        }
        if (i > b0) {
            long n = i - b0, w, j;
            long nw = n / dat->word, extra = n % dat->word;
            for (w = 0; w < nw; w++) {
                const double* ws = s + b0 + w * dat->word;
                unsigned long long v = 0;
                long long sv;
                for (j = 0; j < dat->word; j++) {
                    int bit = an_level(dat, ws[j]);
                    if (dat->msb) {
                        v = (v << 1) | (unsigned) bit;
                    } else {
                        v |= (unsigned long long) bit << j;
                    }
                    snprintf(lab, sizeof(lab), "%d", bit);
                    an_add_label(dat, ws[j], lab);
                }
                sv = (long long) v;
                if (dat->is_signed && dat->word < 64 && (v >> (dat->word - 1)) & 1u) {
                    sv = (long long) v - (long long) (1ULL << dat->word);
                }
                snprintf(txt, sizeof(txt), "%0*llX = %lld", hexw, v, sv);
                an_add_span(dat, ws[0] - dt, ws[dat->word - 1] + dt, txt);
                an_add_interval(&a->busy, ws[0] - dt, ws[dat->word - 1] + dt);
                an_textf(&dat->hex, "  %12s  %0*llX = %lld", an_fmt_t(ws[0], t1, sizeof(t1)), hexw, v, sv);
                if (w == nw - 1 && extra) {
                    an_textf(&dat->hex, "   + %ld extra clock pulse%s", extra, extra > 1 ? "s" : "");
                }
                an_textf(&dat->hex, "\n");
                words++;
            }
            if (nw == 0) {
                an_textf(&dat->hex, "  %12s  %ld clock pulse%s, no complete word\n",
                         an_fmt_t(s[b0], t1, sizeof(t1)), n, n > 1 ? "s" : "");
            }
            for (j = nw * dat->word; j < n; j++) {     /* impulsions hors mot */
                snprintf(lab, sizeof(lab), "%d", an_level(dat, s[b0 + j]));
                an_add_label(dat, s[b0 + j], lab);
            }
            an_add_interval(&a->frames, s[b0] - (min_int > 0.0 ? min_int : dt), s[i - 1] + dt);
        }
        b0 = i;
    }
    {
        char head[200];
        snprintf(head, sizeof(head), "%s  synchronous data, clock %s  %d word%s of %d bits\n",
                 dat->name, clk->name, words, words > 1 ? "s" : "", dat->word);
        /* l'en-tete passe devant les lignes deja accumulees */
        if (dat->hex.s) {
            char* body = dat->hex.s;
            dat->hex.s = NULL;
            dat->hex.len = dat->hex.cap = 0;
            an_textf(&dat->hex, "%s%s", head, body);
            free(body);
        } else {
            an_textf(&dat->hex, "%s  (no clock pulse)\n", head);
        }
    }
    an_free(&st);
}

/* ------------------------------------------------------------- voie logique */

static void an_logic_summary(struct LogicAnalyzer* a, struct AnChannel* c) {
    const struct AnEdge* e = (const struct AnEdge*) c->edges.p;
    long k, rising = 0;
    double high = 0.0, min_hi = 0.0, min_lo = 0.0;
    char t1[32], t2[32], t3[32];
    if (c->edges.n <= 1) {
        an_textf(&c->hex, "%s  logic, constant %d\n", c->name, c->edges.n ? e[0].v : 0);
        return;
    }
    for (k = 0; k < c->edges.n; k++) {
        double tn = (k + 1 < c->edges.n) ? e[k + 1].t : a->t_end;
        if (e[k].v) {
            high += tn - e[k].t;
        }
        if (k >= 1) {
            rising += e[k].v;
            if (k + 1 < c->edges.n) {          /* impulsion complete entre deux fronts */
                double d = tn - e[k].t;
                if (e[k].v && (min_hi == 0.0 || d < min_hi)) {
                    min_hi = d;
                }
                if (!e[k].v && (min_lo == 0.0 || d < min_lo)) {
                    min_lo = d;
                }
            }
        }
    }
    an_textf(&c->hex, "%s  logic, %ld edge%s (%ld rising), first at %s, high %.1f %% of the time",
             c->name, c->edges.n - 1, c->edges.n > 2 ? "s" : "", rising, an_fmt_t(e[1].t, t1, sizeof(t1)),
             a->t_end > 0.0 ? 100.0 * high / a->t_end : 0.0);
    if (min_hi > 0.0 || min_lo > 0.0) {
        an_textf(&c->hex, ", shortest pulse high %s, low %s",
                 min_hi > 0.0 ? an_fmt_t(min_hi, t2, sizeof(t2)) : "-",
                 min_lo > 0.0 ? an_fmt_t(min_lo, t3, sizeof(t3)) : "-");
    }
    an_textf(&c->hex, "\n");
}

/* ------------------------------------------------------------- trames */

static int an_cmp_interval(const void* x, const void* y) {
    double a = ((const struct AnInterval*) x)->a, b = ((const struct AnInterval*) y)->a;
    return a < b ? -1 : (a > b ? 1 : 0);
}

/* Vrai si une valeur est en cours a l'instant t sur une voie (au milieu d'un
   octet, d'un mot) : une ligne n'y est pas coupee. */
static int an_is_busy(const struct LogicAnalyzer* a, double t) {
    const struct AnInterval* b = (const struct AnInterval*) a->busy.p;
    long lo = 0, hi = a->busy.n - 1;
    if (a->busy.n == 0 || b[0].a >= t) {
        return 0;
    }
    while (lo < hi) {                          /* dernier intervalle commence avant t */
        long mid = (lo + hi + 1) / 2;
        if (b[mid].a < t) {
            lo = mid;
        } else {
            hi = mid - 1;
        }
    }
    return a->busy_maxb[lo] > t;
}

/* Vrai si t tombe dans l'une des n trames f (triees par debut ; maxb : maximum
   courant de leurs fins, car elles peuvent se chevaucher). */
static int an_inside(const struct AnInterval* f, const double* maxb, long n, double t) {
    long lo = 0, hi = n - 1;
    if (n == 0 || f[0].a > t) {
        return 0;
    }
    while (lo < hi) {
        long mid = (lo + hi + 1) / 2;
        if (f[mid].a <= t) {
            lo = mid;
        } else {
            hi = mid - 1;
        }
    }
    return maxb[lo] >= t;
}

static int an_cmp_double(const void* x, const void* y) {
    double a = *(const double*) x, b = *(const double*) y;
    return a < b ? -1 : (a > b ? 1 : 0);
}

/* Zones a dessiner : les trames des voies decodees, plus les fronts des voies
   logiques qui tombent hors de toute trame (groupes separes par un silence),
   rattaches a une trame voisine a moins d'un silence ; les trames qui se
   chevauchent (les deux sens d'une liaison) n'en font qu'une. */
static void an_build_regions(struct LogicAnalyzer* a, double dt, double silence, struct AnArray* regions) {
    struct AnArray loose = {0};
    struct AnInterval* f;
    double* maxb;
    long nf, k, i;
    int c;
    if (a->frames.n > 1) {
        qsort(a->frames.p, (size_t) a->frames.n, sizeof(struct AnInterval), an_cmp_interval);
    }
    f = (struct AnInterval*) a->frames.p;
    nf = a->frames.n;
    maxb = (double*) malloc((size_t) (nf > 0 ? nf : 1) * sizeof(double));
    if (!maxb) {
        return;
    }
    for (i = 0; i < nf; i++) {
        maxb[i] = (i == 0 || f[i].b > maxb[i - 1]) ? f[i].b : maxb[i - 1];
    }
    for (c = 0; c < AN_NCH; c++) {
        const struct AnEdge* e = (const struct AnEdge*) a->ch[c].edges.p;
        if (a->ch[c].kind == AN_KIND_OFF) {
            continue;
        }
        for (k = 1; k < a->ch[c].edges.n; k++) {
            if (!an_inside(f, maxb, nf, e[k].t)) {
                an_push(&loose, &e[k].t, sizeof(double));
            }
        }
    }
    free(maxb);
    if (loose.n > 1) {
        qsort(loose.p, (size_t) loose.n, sizeof(double), an_cmp_double);
    }
    {
        const double* t = (const double*) loose.p;
        long g0 = 0;
        for (k = 0; k <= loose.n; k++) {
            if (k < loose.n && (k == g0 || t[k] - t[k - 1] <= silence)) {
                continue;
            }
            if (k > g0) {
                double ga = t[g0], gb = t[k - 1];
                int attached = 0;
                for (i = 0; i < nf; i++) {
                    if (f[i].a - silence <= gb && ga <= f[i].b + silence) {
                        if (ga < f[i].a) f[i].a = ga;
                        if (gb > f[i].b) f[i].b = gb;
                        attached = 1;
                        break;
                    }
                }
                if (!attached) {
                    an_add_interval(&a->frames, ga, gb);
                    f = (struct AnInterval*) a->frames.p;
                    nf = a->frames.n;
                }
            }
            g0 = k;
        }
    }
    an_free(&loose);
    if (a->frames.n > 1) {
        qsort(a->frames.p, (size_t) a->frames.n, sizeof(struct AnInterval), an_cmp_interval);
    }
    f = (struct AnInterval*) a->frames.p;
    for (i = 0; i < a->frames.n; i++) {
        struct AnInterval* r = (struct AnInterval*) regions->p;
        int merge = 0;
        if (regions->n > 0) {
            double gapv = f[i].a - r[regions->n - 1].b;
            merge = gapv < 0.0
                || (!a->opt_split && gapv <= silence)
                || !a->opt_compress;
        }
        if (merge) {
            if (f[i].b > r[regions->n - 1].b) {
                r[regions->n - 1].b = f[i].b;
            }
        } else {
            an_add_interval(regions, f[i].a, f[i].b);
        }
    }
}

/* ------------------------------------------------------------- chronogramme */

static void an_place(char* row, int n, int col, const char* text) {
    int len = (int) strlen(text), k;
    for (k = 0; k < len; k++) {
        int c = col + k;
        if (c >= 0 && c < n) {
            row[c] = text[k];
        }
    }
}

static void an_rtrim_print(FILE* f, const char* lead, char* row, int n) {
    int end = n;
    while (end > 0 && row[end - 1] == ' ') {
        end--;
    }
    row[end] = '\0';
    if (end == 0 && lead[0] == '\0') {
        fprintf(f, "\n");
    } else {
        fprintf(f, "  %-8s %s\n", lead, row);
    }
}

/* Dessine les voies sur n colonnes a partir de t0. */
static void an_draw_block(FILE* f, struct LogicAnalyzer* a, double t0, double dt, int n, char* top, char* bot) {
    int c, k;
    char tb[32];
    fprintf(f, "\n  %s\n", an_fmt_t(t0, tb, sizeof(tb)));
    for (c = 0; c < AN_NCH; c++) {
        struct AnChannel* ch = &a->ch[c];
        int prev, any_top = 0;
        char shortname[9];
        if (ch->kind == AN_KIND_OFF) {
            continue;
        }
        snprintf(shortname, sizeof(shortname), "%s", ch->name);
        prev = an_level(ch, t0 - dt / 2);
        for (k = 0; k < n; k++) {
            int lv = an_level(ch, t0 + (k + 0.5) * dt);
            if (lv != prev) {
                top[k] = ' ';
                bot[k] = '|';
            } else if (lv) {
                top[k] = '_';
                bot[k] = ' ';
                any_top = 1;
            } else {
                top[k] = ' ';
                bot[k] = '_';
            }
            prev = lv;
        }
        if (any_top) {
            an_rtrim_print(f, "", top, n);
        }
        an_rtrim_print(f, shortname, bot, n);
        if (ch->kind == AN_KIND_UART || ch->kind == AN_KIND_I2C_SDA || ch->kind == AN_KIND_SYNC_DATA) {
            double t1 = t0 + n * dt;
            long i;
            if (a->opt_bits) {
                const struct AnLabel* l = (const struct AnLabel*) ch->labels.p;
                memset(top, ' ', (size_t) n);
                for (i = 0; i < ch->labels.n; i++) {
                    if (l[i].t >= t0 && l[i].t < t1) {
                        an_place(top, n, (int) ((l[i].t - t0) / dt + 0.25), l[i].s);
                    }
                }
                an_rtrim_print(f, "", top, n);
            }
            {
                const struct AnSpan* s = (const struct AnSpan*) ch->spans.p;
                memset(top, ' ', (size_t) n);
                for (i = 0; i < ch->spans.n; i++) {
                    int ca = (int) floor((s[i].a - t0) / dt + 0.5), cb = (int) floor((s[i].b - t0) / dt + 0.5);
                    int len = (int) strlen(s[i].s), va, vb, m, room, start;
                    if (cb <= 0 || ca >= n) {
                        continue;
                    }
                    /* partie visible [va, vb[ ; crochets aux vraies extremites
                       seulement : une valeur peut etre coupee par la fin d'une ligne,
                       son texte va dans la partie qui porte son debut (ou, si le
                       debut est sur la ligne precedente et que le texte n'y tenait
                       pas, dans celle-ci) */
                    va = ca < 0 ? 0 : ca;
                    vb = cb > n ? n : cb;
                    for (m = va; m < vb; m++) {
                        top[m] = ' ';
                    }
                    if (ca >= 0 && cb - ca >= 2) {
                        top[ca] = '[';
                    }
                    if (cb <= n && cb - ca >= 2) {
                        top[cb - 1] = ']';
                    }
                    room = vb - va - ((ca >= 0) ? 1 : 0) - ((cb <= n) ? 1 : 0);
                    start = va + ((ca >= 0) ? 1 : 0);
                    if (ca >= 0) {
                        if (room >= len) {
                            an_place(top, n, start + (room - len) / 2, s[i].s);
                        } else if (cb <= n) {
                            char cell[64];          /* valeur entiere trop etroite : sans crochets, tronquee */
                            snprintf(cell, sizeof(cell), "%.*s", (vb - va) > 1 ? (vb - va) : 1, s[i].s);
                            for (m = va; m < vb; m++) {
                                top[m] = ' ';
                            }
                            an_place(top, n, va, cell);
                        }
                    } else if (room >= len && (-ca - 1) < len) {
                        /* debut sur la ligne precedente, ou le texte ne tenait pas */
                        an_place(top, n, start + (room - len) / 2, s[i].s);
                    }
                }
                an_rtrim_print(f, "", top, n);
            }
        }
    }
}

static void an_write_waveform(FILE* f, struct LogicAnalyzer* a, double dt, double silence) {
    struct AnArray regions = {0};
    const struct AnInterval* r;
    int W = a->opt_width;
    long i, columns = 0;
    char tb[32], tb2[32];
    char* top = (char*) malloc((size_t) W * 2 + 8);
    char* bot = (char*) malloc((size_t) W * 2 + 8);
    if (!top || !bot) {
        free(top);
        free(bot);
        return;
    }
    an_build_regions(a, dt, silence, &regions);
    r = (const struct AnInterval*) regions.p;
    if (regions.n == 0) {
        fprintf(f, "\n  (no activity on the channels)\n");
    }
    for (i = 0; i < regions.n; i++) {
        double t0 = r[i].a - 2 * dt, tend = r[i].b + 2 * dt;
        if (i > 0) {
            double g = r[i].a - r[i - 1].b;
            fprintf(f, "\n");
            if (g > silence) {
                fprintf(f, "  ~~~~~~~~ %s of silence ~~~~~~~~\n", an_fmt_t(g, tb, sizeof(tb)));
            } else {
                fprintf(f, "  -------- %s later\n", an_fmt_t(g, tb, sizeof(tb)));
            }
        }
        if (a->opt_split) {
            fprintf(f, "\n=== frame %ld   %s .. %s\n", i + 1, an_fmt_t(r[i].a, tb, sizeof(tb)), an_fmt_t(r[i].b, tb2, sizeof(tb2)));
        }
        while (t0 < tend - dt / 2) {
            int n;
            if (tend <= t0 + 1.15 * W * dt) {
                n = (int) ceil((tend - t0) / dt - 1e-9);
            } else {
                double cut = t0 + W * dt, tt;
                for (tt = cut; tt > t0 + W * dt / 2; tt -= dt) {
                    if (!an_is_busy(a, tt)) {
                        cut = tt;
                        break;
                    }
                }
                n = (int) floor((cut - t0) / dt + 0.5);
            }
            if (n < 1) {
                n = 1;
            }
            if (n > 2 * W) {
                n = 2 * W;
            }
            if (columns + n > AN_TEXT_MAX_COLUMNS) {
                fprintf(f, "\n  ... timing diagram stopped here (limit of %ld columns reached): shorten the simulation,\n"
                           "      raise textResolution or keep only the hex section (textWaveform = false)\n",
                        AN_TEXT_MAX_COLUMNS);
                an_free(&regions);
                free(top);
                free(bot);
                return;
            }
            an_draw_block(f, a, t0, dt, n, top, bot);
            columns += n;
            t0 += n * dt;
        }
    }
    an_free(&regions);
    free(top);
    free(bot);
}

/* ------------------------------------------------------------- fichier */

static void an_channel_desc(const struct LogicAnalyzer* a, const struct AnChannel* c, char* buf, size_t size) {
    switch (c->kind) {
    case AN_KIND_UART:
        snprintf(buf, size, "UART %g baud, %d%c%d, %s first", c->baud, c->bits,
                 c->parity < 0 ? 'N' : (c->parity == 0 ? 'E' : 'O'), c->stop, c->msb ? "MSB" : "LSB");
        break;
    case AN_KIND_I2C_SDA:
        snprintf(buf, size, "I2C data, clock on CH%d (%s)", c->clock, a->ch[c->clock].name);
        break;
    case AN_KIND_SYNC_DATA:
        snprintf(buf, size, "synchronous data, read on the %s edge of CH%d (%s), %d-bit words, %s first%s",
                 c->falling ? "falling" : "rising", c->clock, a->ch[c->clock].name, c->word,
                 c->msb ? "MSB" : "LSB", c->is_signed ? ", signed" : "");
        break;
    default:
        snprintf(buf, size, "logic");
        break;
    }
}

/* Ecrit le fichier texte (fin de simulation). Rend 1 si le fichier est ecrit. */
static int an_write_text(struct LogicAnalyzer* a, const char* path) {
    FILE* f;
    double dt, silence, t_stop;
    int i, W = a->opt_width;
    char rule[AN_MAX_WIDTH + 16], tb[32], tb2[32], desc[200];
    int rl = W + 11 < (int) sizeof(rule) - 1 ? W + 11 : (int) sizeof(rule) - 1;
    t_stop = a->edges_full ? a->t_full : a->t_end;
    dt = a->opt_resolution > 0.0 ? a->opt_resolution : an_auto_resolution(a);
    silence = a->opt_silence > 0.0 ? a->opt_silence : AN_SILENCE_COLUMNS * dt;
    for (i = 0; i < AN_NCH; i++) {
        struct AnChannel* c = &a->ch[i];
        switch (c->kind) {
        case AN_KIND_UART:
            an_decode_uart(a, c, t_stop);
            break;
        case AN_KIND_I2C_SDA:
            an_decode_i2c(a, c, dt);
            break;
        case AN_KIND_SYNC_DATA:
            an_decode_sync(a, c, dt);
            break;
        case AN_KIND_LOGIC:
            an_logic_summary(a, c);
            break;
        default:
            break;
        }
    }
    if (a->busy.n > 1) {
        qsort(a->busy.p, (size_t) a->busy.n, sizeof(struct AnInterval), an_cmp_interval);
    }
    if (a->busy.n > 0) {
        const struct AnInterval* b = (const struct AnInterval*) a->busy.p;
        long k;
        a->busy_maxb = (double*) malloc((size_t) a->busy.n * sizeof(double));
        if (!a->busy_maxb) {
            a->busy.n = 0;
        }
        for (k = 0; k < a->busy.n; k++) {
            a->busy_maxb[k] = (k == 0 || b[k].b > a->busy_maxb[k - 1]) ? b[k].b : a->busy_maxb[k - 1];
        }
    }
    f = fopen(path, "wb");   /* fins de ligne LF, comme le VCD : le Bloc-notes les lit depuis Windows 10 */
    if (!f) {
        ModelicaFormatWarning("Logic analyser %s: cannot create %s - no text file\n", a->name, path);
        return 0;
    }
    memset(rule, '=', (size_t) rl);
    rule[rl] = '\0';
    fprintf(f, "%s\n MicroPythonMCU logic analyser - %s\n", rule, a->name);
    fprintf(f, " Simulation 0 s .. %s", an_fmt_t(a->t_end, tb, sizeof(tb)));
    if (a->edges_full) {
        fprintf(f, "   (recording for this file stopped at %s: limit of %ld level changes)", an_fmt_t(a->t_full, tb2, sizeof(tb2)), AN_MAX_EDGES);
    }
    fprintf(f, "\n%s\nChannels\n", rule);
    for (i = 0; i < AN_NCH; i++) {
        if (a->ch[i].kind != AN_KIND_OFF) {
            an_channel_desc(a, &a->ch[i], desc, sizeof(desc));
            fprintf(f, "  CH%d  %-8s %s\n", i, a->ch[i].name, desc);
        }
    }
    memset(rule, '-', (size_t) rl);
    if (a->opt_hex) {
        fprintf(f, "\n%s\nDecoded data (hex + ASCII)\n%s\n", rule, rule);
        for (i = 0; i < AN_NCH; i++) {
            if (a->ch[i].hex.s) {
                fprintf(f, "%s", a->ch[i].hex.s);
            }
        }
    }
    if (a->opt_wave) {
        fprintf(f, "\n%s\nTiming diagram    1 column = %s", rule, an_fmt_t(dt, tb, sizeof(tb)));
        if (a->opt_compress) {
            fprintf(f, ",  silence > %s not drawn (~~)", an_fmt_t(silence, tb2, sizeof(tb2)));
        }
        fprintf(f, "\n%s\n", rule);
        an_write_waveform(f, a, dt, silence);
    }
    fclose(f);
    return 1;
}

#endif /* ANALYZER_TEXT_C_INCLUDED */
