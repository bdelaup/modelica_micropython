/* Reconnaissance d'une commande recue dans la table compacte.

   Format de la table : "CMD=>REPONSE|CMD=>REPONSE|..."
   '|' separe les entrees, "=>" separe la commande de sa reponse. Ces deux
   suites sont RESERVEES et ne peuvent pas apparaitre dans une commande ou une
   reponse (restriction v0 documentee). Les echappements usuels (\r, \n) sont
   deja resolus par Modelica dans le litteral de chaine : le C recoit les vrais
   octets, il n'a rien a desechapper.

   La comparaison porte sur la LIGNE COMPLETE, delimiteur exclu : une commande
   fragmentee en plusieurs trames est donc reconnue sans effort, puisque c'est
   l'accumulateur de ligne qui la reassemble.

   Une commande peut contenir des marqueurs de CAPTURE {oN} : le nombre trouve
   a cet endroit de la ligne recue est ecrit dans value_out[N-1], ce qui fait du
   peripherique un actionneur autant qu'un capteur.

   Inclus TEXTUELLEMENT par UartDeviceImpl.c, jamais compile seul. */

#ifndef UARTDEVICE_MATCH_C_INCLUDED
#define UARTDEVICE_MATCH_C_INCLUDED

/* Confronte la ligne recue a un motif de commande, en capturant les {oN}.
   Les captures sont ecrites dans 'captured'/'has_capture' et ne sont reportees
   dans value_out par l'appelant QU'EN CAS DE CORRESPONDANCE COMPLETE : une
   commande a moitie reconnue ne doit pas laisser de trace.
   'pat'/'patlen' delimitent le motif (la table n'est pas decoupee en copies).
   Retourne 1 si la ligne entiere correspond au motif entier. */
static int uartdev_match_pattern(const char* pat, int patlen, const char* line,
                                  double* captured, int* has_capture) {
    int i = 0;
    const char* l = line;
    while (i < patlen) {
        int index, precision;
        int used = uartdev_parse_marker(pat + i, 'o', &index, &precision);
        if (used > 0 && i + used <= patlen) {
            char* end = NULL;
            double v = strtod(l, &end);
            if (end == l) {
                return 0;          /* aucun nombre la ou le motif en attend un */
            }
            captured[index] = v;
            has_capture[index] = 1;
            l = end;
            i += used;
        } else {
            if (*l == '\0' || *l != pat[i]) {
                return 0;
            }
            l++;
            i++;
        }
    }
    return *l == '\0';             /* le motif doit consommer TOUTE la ligne */
}

/* Parcourt la table et, a la premiere correspondance, ecrit la reponse formatee
   dans 'out'. Retourne sa longueur, ou -1 si aucune entree ne correspond.
   Effet de bord assume en cas de correspondance : les captures {oN} sont
   reportees dans dev->value_out. */
static int uartdev_lookup(struct UartDevice* dev, const char* line, char* out, int outmax) {
    const char* p = dev->table;
    while (*p) {
        const char* entry = p;
        const char* sep = NULL;      /* position de "=>" dans cette entree */
        const char* end;             /* fin de l'entree ('|' ou fin de table) */
        const char* q;

        for (q = entry; *q && *q != '|'; q++) {
            if (!sep && q[0] == '=' && q[1] == '>') {
                sep = q;
            }
        }
        end = q;

        if (sep) {
            double captured[UARTDEV_MAX_VALUES];
            int has_capture[UARTDEV_MAX_VALUES];
            int k;
            for (k = 0; k < UARTDEV_MAX_VALUES; k++) {
                captured[k] = 0.0;
                has_capture[k] = 0;
            }
            if (uartdev_match_pattern(entry, (int) (sep - entry), line, captured, has_capture)) {
                char tmpl[UARTDEV_PAYLOAD_MAX + 1];
                int tlen = (int) (end - (sep + 2));
                int n;
                for (k = 0; k < UARTDEV_MAX_VALUES; k++) {
                    if (has_capture[k]) {
                        dev->value_out[k] = captured[k];
                    }
                }
                if (tlen > UARTDEV_PAYLOAD_MAX) {
                    tlen = UARTDEV_PAYLOAD_MAX;
                }
                memcpy(tmpl, sep + 2, (size_t) tlen);
                tmpl[tlen] = '\0';
                n = uartdev_format(out, outmax, tmpl, dev->value_in);
                return n;
            }
        }

        if (*end == '\0') {
            break;
        }
        p = end + 1;                 /* entree suivante, apres le '|' */
    }
    return -1;
}

#endif /* UARTDEVICE_MATCH_C_INCLUDED */
