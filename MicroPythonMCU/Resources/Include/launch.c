/* Garde d'inclusion : ce .c est inclus TEXTUELLEMENT par plusieurs chapeaux
   (PyRuntimeImpl.c, AnalyzerImpl.c), qui peuvent atterrir dans la meme unite
   de compilation (omc dedoublonne les Include par leur texte) - meme idiome
   que uartcore.c. */
#ifndef LAUNCH_C_INCLUDED
#define LAUNCH_C_INCLUDED

/* Lanceur commun : ouvre un fichier ou un dossier dans un programme externe
   (explorateur de fichiers, PulseView ou editeur de texte) en fin de simulation,
   sans attendre la fermeture de l'application.

   C'est le SEUL point du runtime qui depend du systeme pour lancer un
   programme (cf. requirements.md, decision "Analyseur logique"). Sous Windows,
   CreateProcess evite de lier shell32. Sous Linux, le double fork permet de
   detacher l'application sans laisser de zombie et sans invoquer un shell.

   Inclus textuellement, jamais compile seul ; l'appelant inclut
   ModelicaUtilities.h (et windows.h sous Windows) avant ce fichier. */

#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#ifndef _WIN32
#include <errno.h>
#include <fcntl.h>
#include <sys/stat.h>
#include <sys/types.h>
#include <sys/wait.h>
#include <unistd.h>
#endif

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
    size_t count = 0;
    size_t capacity = opts ? strlen(opts) + 3 : 3;
    char** args = (char**) calloc(capacity, sizeof(*args));
    char* options = opts ? strdup(opts) : NULL;
    char* token;
    char* save = NULL;
    int pipefd[2];
    int failure = 0;
    ssize_t received;
    pid_t child;
    int status;
    if (!args || (opts && !options)) {
        ModelicaFormatWarning("Could not start %s: out of memory\n", what);
        free(options);
        free(args);
        return 0;
    }
    args[count++] = (char*) exe;
    token = options ? strtok_r(options, " \t", &save) : NULL;
    while (token) {
        args[count++] = token;
        token = strtok_r(NULL, " \t", &save);
    }
    args[count++] = (char*) file;
    args[count] = NULL;
    if (pipe(pipefd) != 0) {
        failure = errno;
    } else if (fcntl(pipefd[1], F_SETFD, FD_CLOEXEC) == -1) {
        failure = errno;
        close(pipefd[0]);
        close(pipefd[1]);
    } else {
        child = fork();
        if (child == -1) {
            failure = errno;
            close(pipefd[0]);
            close(pipefd[1]);
        } else if (child == 0) {
            pid_t grandchild;
            close(pipefd[0]);
            grandchild = fork();
            if (grandchild == 0) {
                execvp(exe, args);
                failure = errno;
                (void) write(pipefd[1], &failure, sizeof(failure));
                _exit(127);
            }
            if (grandchild == -1) {
                failure = errno;
                (void) write(pipefd[1], &failure, sizeof(failure));
            }
            _exit(grandchild == -1 ? 127 : 0);
        } else {
            close(pipefd[1]);
            do { received = read(pipefd[0], &failure, sizeof(failure)); }
            while (received == -1 && errno == EINTR);
            if (received == -1) failure = errno;
            else if (received != 0 && received != sizeof(failure)) failure = EIO;
            close(pipefd[0]);
            pid_t waited;
            while ((waited = waitpid(child, &status, 0)) == -1) {
                if (errno != EINTR) {
                    if (!failure) failure = errno;
                    break;
                }
            }
            if (waited == child && (!WIFEXITED(status) || WEXITSTATUS(status) != 0) && !failure)
                failure = EIO;
        }
    }
    free(options);
    free(args);
    if (failure) {
        ModelicaFormatWarning("Could not start %s (%s): %s - open %s by hand\n",
                              what, exe, strerror(failure), file);
        return 0;
    }
    return 1;
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
#else
    if (path[0] != '/') {
        char* cwd = getcwd(NULL, 0);
        if (cwd) {
            size_t len = strlen(cwd) + strlen(path) + 2;
            char* full = (char*) malloc(len);
            if (full) snprintf(full, len, "%s/%s", cwd, path);
            free(cwd);
            if (full) return full;
        }
    }
#endif
    return strdup(path);
}

#endif /* LAUNCH_C_INCLUDED */
