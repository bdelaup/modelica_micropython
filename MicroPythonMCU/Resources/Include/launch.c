/* Garde d'inclusion : ce .c est inclus TEXTUELLEMENT par plusieurs chapeaux
   (PyRuntimeImpl.c, AnalyzerImpl.c), qui peuvent atterrir dans la meme unite
   de compilation (omc dedoublonne les Include par leur texte) - meme idiome
   que uartcore.c. */
#ifndef LAUNCH_C_INCLUDED
#define LAUNCH_C_INCLUDED

/* Lanceur commun : ouvre un fichier ou un dossier dans un programme externe
   (Explorateur Windows sur la copie du systeme de fichiers, PulseView et le
   Bloc-notes sur les fichiers de l'analyseur logique) a la fin de la simulation, SANS l'attendre : la simulation se
   termine sans dependre de la fenetre.

   C'est le SEUL point du runtime qui depend du systeme pour lancer un
   programme (cf. requirements.md, decision "Analyseur logique") : un portage Linux/macOS n'aura que launch_detached a
   completer (posix_spawnp), d'ou la branche hors Windows qui se contente de
   dire au journal quoi ouvrir. Sous Windows, CreateProcess plutot que
   ShellExecute : pas de bibliotheque shell32 a lier.

   Inclus textuellement, jamais compile seul ; l'appelant inclut
   ModelicaUtilities.h (et windows.h sous Windows) avant ce fichier. */

#include <stdio.h>
#include <stdlib.h>
#include <string.h>

/* Lance 'exe' sur 'file', precede des options 'opts' (ajoutees telles
   quelles AVANT le fichier, NULL si aucune : "pulseview [OPTIONS] [FILE]").
   'what' nomme le programme dans les messages. Rend 1 si le programme a pu
   etre lance. Un echec (programme absent, chemin faux) n'est qu'un
   avertissement : la simulation est finie, ses resultats sont la. */
static int launch_detached(const char* what, const char* exe, const char* opts, const char* file) {
#ifdef _WIN32
    size_t len = strlen(exe) + strlen(file) + (opts ? strlen(opts) : 0) + 16;
    char* cmd = (char*) malloc(len);
    STARTUPINFOA si;
    PROCESS_INFORMATION pi;
    int ok;
    if (!cmd) {
        return 0;
    }
    snprintf(cmd, len, "\"%s\" %s%s\"%s\"", exe, opts ? opts : "", opts ? " " : "", file);
    memset(&si, 0, sizeof(si));
    si.cb = sizeof(si);
    ok = CreateProcessA(NULL, cmd, NULL, NULL, FALSE, 0, NULL, NULL, &si, &pi) ? 1 : 0;
    if (ok) {
        CloseHandle(pi.hThread);
        CloseHandle(pi.hProcess);
    } else {
        ModelicaFormatWarning("Could not start %s (%s) - open %s by hand\n", what, exe, file);
    }
    free(cmd);
    return ok;
#else
    (void) exe;
    (void) opts;
    ModelicaFormatMessage("Open %s with %s\n", file, what);
    return 0;
#endif
}

/* Chemin absolu d'un fichier du dossier de simulation, pour un programme
   lance avec un autre dossier courant (et pour le journal). Rend une chaine a
   liberer par free(), ou une copie telle quelle faute de mieux. */
static char* launch_full_path(const char* path) {
#ifdef _WIN32
    char* full = _fullpath(NULL, path, 0);
    if (full) {
        return full;
    }
#endif
    return strdup(path);
}

#endif /* LAUNCH_C_INCLUDED */
