/* Garde d'inclusion : partie du chapeau AnalyzerImpl.c. */
#ifndef ANALYZER_PVS_C_INCLUDED
#define ANALYZER_PVS_C_INCLUDED

/* Fichier de session PulseView (<base>.pvs) : les decodeurs de protocole
   deja regles d'apres les voies de la sonde - cf. requirements.md, decision
   "Analyseur logique".

   PulseView, quand il ouvre X.vcd, charge de lui-meme X.pvs pose a cote (que
   le fichier soit ouvert par la sonde ou a la main). Le format est celui de
   QSettings (INI) ecrit par PulseView ("Save session setup") : il n'est PAS
   documente, il a ete releve sur un fichier enregistre par PulseView et
   valide avec PulseView 0.5.0 (2026-10-03). Ce qui compte :
     - [General] decode_signals = nombre de decodeurs ;
     - [decode_signalK] : decoder0\id (uart, i2c, spi), decoder0\options = N
       puis decoder0\optionI\name / type / value, la valeur etant le GVariant
       SERIALISE (octets bruts, petit-boutiste) ecrit en @ByteArray(\xHH...),
       type au format GVariant ("x" entier 64 bits, "d" double, "s" chaine
       terminee par un NUL) ;
     - channelJ\name = nom de la voie du decodeur (RX, SCL, SDA, CLK, MISO),
       channelJ\assigned_signal_name = nom du signal dans PulseView, qui
       PREFIXE le nom du VCD par son scope : "probe.TX", pas "TX".
   Correspondance : voie Uart -> decodeur uart sur RX ; voie I2cSda -> i2c
   (SCL = voie d'horloge) ; voie SyncData -> spi (CLK = voie d'horloge, MISO
   = donnees ; cpol = niveau de repos de l'horloge, lu au debut de la capture,
   cpha deduit du front de lecture). PulseView ne connait pas les rafales :
   des impulsions en plus d'un mot (gain du HX711) decalent ses mots, le
   fichier texte, lui, les compte a part. */

#define AN_PVS_SCOPE "probe"   /* scope des voies dans le VCD (vcd_open) */

static void pvs_bytes(FILE* f, const unsigned char* b, size_t n) {
    size_t i;
    fprintf(f, "@ByteArray(");
    for (i = 0; i < n; i++) {
        fprintf(f, "\\x%x", b[i]);
    }
    fprintf(f, ")\n");
}

static void pvs_opt_int(FILE* f, int i, const char* name, long long v) {
    unsigned char b[8];
    int k;
    for (k = 0; k < 8; k++) {
        b[k] = (unsigned char) (((unsigned long long) v >> (8 * k)) & 0xFFu);
    }
    fprintf(f, "decoder0\\option%d\\name=%s\ndecoder0\\option%d\\type=x\ndecoder0\\option%d\\value=", i, name, i, i);
    pvs_bytes(f, b, 8);
}

static void pvs_opt_double(FILE* f, int i, const char* name, double v) {
    unsigned char b[8];
    unsigned long long u;
    int k;
    memcpy(&u, &v, sizeof(u));
    for (k = 0; k < 8; k++) {
        b[k] = (unsigned char) ((u >> (8 * k)) & 0xFFu);
    }
    fprintf(f, "decoder0\\option%d\\name=%s\ndecoder0\\option%d\\type=d\ndecoder0\\option%d\\value=", i, name, i, i);
    pvs_bytes(f, b, 8);
}

static void pvs_opt_string(FILE* f, int i, const char* name, const char* v) {
    fprintf(f, "decoder0\\option%d\\name=%s\ndecoder0\\option%d\\type=s\ndecoder0\\option%d\\value=", i, name, i, i);
    pvs_bytes(f, (const unsigned char*) v, strlen(v) + 1);
}

static void pvs_channel(FILE* f, int j, const char* name, const char* signal) {
    fprintf(f, "channel%d\\name=%s\nchannel%d\\initial_pin_state=2\nchannel%d\\assigned_signal_name=%s.%s\n",
            j, name, j, j, AN_PVS_SCOPE, signal);
}

/* Ecrit <path> ; rend le nombre de decodeurs (0 : pas de fichier, aucune
   voie decodee). */
static int an_write_pvs(struct LogicAnalyzer* a, const char* path) {
    FILE* f;
    int i, n = 0, k = 0;
    for (i = 0; i < AN_NCH; i++) {
        int kind = a->ch[i].kind;
        if (kind == AN_KIND_UART || kind == AN_KIND_I2C_SDA || kind == AN_KIND_SYNC_DATA) {
            n++;
        }
    }
    if (n == 0) {
        return 0;
    }
    f = fopen(path, "wb");
    if (!f) {
        ModelicaFormatWarning("Logic analyser %s: cannot create %s - no PulseView session\n", a->name, path);
        return 0;
    }
    fprintf(f, "[General]\ndecode_signals=%d\ngenerated_signals=0\nviews=0\nmeta_objs=0\n", n);
    for (i = 0; i < AN_NCH; i++) {
        struct AnChannel* c = &a->ch[i];
        if (c->kind == AN_KIND_UART) {
            fprintf(f, "\n[decode_signal%d]\nname=UART %s\nenabled=true\ndecoders=1\ndecoder0\\id=uart\n"
                       "decoder0\\visible=true\ndecoder0\\options=6\n", k++, c->name);
            pvs_opt_int(f, 0, "baudrate", llround(c->baud));
            pvs_opt_int(f, 1, "data_bits", c->bits);
            pvs_opt_string(f, 2, "parity", c->parity < 0 ? "none" : (c->parity == 0 ? "even" : "odd"));
            pvs_opt_double(f, 3, "stop_bits", (double) c->stop);
            pvs_opt_string(f, 4, "bit_order", c->msb ? "msb-first" : "lsb-first");
            pvs_opt_string(f, 5, "format", "ascii");
            fprintf(f, "channels=1\n");
            pvs_channel(f, 0, "RX", c->name);
        } else if (c->kind == AN_KIND_I2C_SDA) {
            fprintf(f, "\n[decode_signal%d]\nname=I2C %s\nenabled=true\ndecoders=1\ndecoder0\\id=i2c\n"
                       "decoder0\\visible=true\ndecoder0\\options=0\nchannels=2\n", k++, c->name);
            pvs_channel(f, 0, "SCL", a->ch[c->clock].name);
            pvs_channel(f, 1, "SDA", c->name);
        } else if (c->kind == AN_KIND_SYNC_DATA) {
            const struct AnChannel* clk = &a->ch[c->clock];
            int cpol = clk->edges.n > 0 ? ((const struct AnEdge*) clk->edges.p)[0].v : 0;
            /* SPI : cpha = 0 lit au premier front apres le repos (montant si
               cpol = 0), cpha = 1 au second */
            int first_edge_falling = cpol;
            int cpha = (c->falling == first_edge_falling) ? 0 : 1;
            fprintf(f, "\n[decode_signal%d]\nname=Sync %s\nenabled=true\ndecoders=1\ndecoder0\\id=spi\n"
                       "decoder0\\visible=true\ndecoder0\\options=4\n", k++, c->name);
            pvs_opt_int(f, 0, "cpol", cpol);
            pvs_opt_int(f, 1, "cpha", cpha);
            pvs_opt_string(f, 2, "bitorder", c->msb ? "msb-first" : "lsb-first");
            pvs_opt_int(f, 3, "wordsize", c->word);
            fprintf(f, "channels=2\n");
            pvs_channel(f, 0, "CLK", clk->name);
            pvs_channel(f, 1, "MISO", c->name);   /* donnees venant de l'esclave, comme DOUT du HX711 */
        }
    }
    fclose(f);
    return n;
}

#endif /* ANALYZER_PVS_C_INCLUDED */
