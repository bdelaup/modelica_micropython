/* Utilitaire partage, independant de PyRuntime : convertit les n premiers
   caracteres d'une String en codes ASCII (0-255), complete par des espaces
   (32) si la chaine est plus courte que n. Sert a afficher du texte
   caractere par caractere sur l'icone de Peripherals.Display via
   DynamicSelect(textString, if abs(code-...)<0.5 then "X" ...) - une String
   n'est pas stockee dans les resultats de simulation (.mat/.csv, verifie
   empiriquement, cf. requirements.md decision "Périphérique d'affichage
   pédagogique"), mais un tableau
   d'Integer l'est, comme n'importe quelle autre grandeur numerique. */
#include <string.h>

void string_to_char_codes(const char* s, int n, int* codes) {
    int len = (int) strlen(s);
    int i;
    for (i = 0; i < n; i++) {
        codes[i] = (i < len) ? (int) (unsigned char) s[i] : 32;
    }
}
