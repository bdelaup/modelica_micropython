/* Formateur minimal des gabarits de trame, dans les DEUX sens.

   Substitution (modele -> trame) : {vN} et {vN:.Pf} sont remplaces par
   value_in[N-1]. Utilise dans une REPONSE ou dans le gabarit periodique.
   Capture  (trame -> modele)     : {oN} dans une COMMANDE consomme un nombre
   et l'ecrit dans value_out[N-1]. Cf. uartdevice_match.c.

   Volontairement pauvre : pas de mini-langage, pas de conditionnelle, pas de
   boucle. Tout besoin qui depasse ce cadre releve du mode script (phase 2) -
   cf. requirements.md, decision "Peripheriques UART externes connectables".

   Inclus TEXTUELLEMENT par UartDeviceImpl.c, jamais compile seul. */

#ifndef UARTDEVICE_FORMAT_C_INCLUDED
#define UARTDEVICE_FORMAT_C_INCLUDED

/* Reconnait "{vN}" ou "{vN:.Pf}" en tete de 'p'.
   Retourne le nombre de caracteres consommes (0 si ce n'est pas un marqueur),
   et renseigne *index (0-based) et *precision (-1 si non precisee). */
static int uartdev_parse_marker(const char* p, char kind, int* index, int* precision) {
    const char* start = p;
    int n;
    if (p[0] != '{' || p[1] != kind) {
        return 0;
    }
    p += 2;
    if (*p < '1' || *p > '9') {
        return 0;
    }
    n = *p - '1';            /* {v1} -> index 0 */
    p++;
    *precision = -1;
    if (*p == ':') {
        p++;
        if (*p != '.') {
            return 0;
        }
        p++;
        if (*p < '0' || *p > '9') {
            return 0;
        }
        *precision = *p - '0';
        p++;
        if (*p != 'f') {
            return 0;
        }
        p++;
    }
    if (*p != '}') {
        return 0;
    }
    p++;
    if (n >= UARTDEV_MAX_VALUES) {
        return 0;            /* hors bornes : laisse passer tel quel plutot que d'ecrire n'importe ou */
    }
    *index = n;
    return (int) (p - start);
}

/* Ecrit dans dst le gabarit 'tmpl' avec les {vN} remplaces par values[N-1].
   Tronque proprement a dstmax. Retourne la longueur ecrite. Un marqueur non
   reconnu est recopie litteralement - une accolade reste donc utilisable. */
static int uartdev_format(char* dst, int dstmax, const char* tmpl, const double* values) {
    int len = 0;
    const char* p = tmpl;
    while (*p && len < dstmax) {
        int index, precision;
        int used = uartdev_parse_marker(p, 'v', &index, &precision);
        if (used > 0) {
            char num[64];
            int k;
            if (precision >= 0) {
                snprintf(num, sizeof(num), "%.*f", precision, values[index]);
            } else {
                snprintf(num, sizeof(num), "%g", values[index]);
            }
            for (k = 0; num[k] && len < dstmax; k++) {
                dst[len++] = num[k];
            }
            p += used;
        } else {
            dst[len++] = *p++;
        }
    }
    dst[len] = '\0';
    return len;
}

#endif /* UARTDEVICE_FORMAT_C_INCLUDED */
