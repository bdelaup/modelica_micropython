/* Intervalle de sortie de la simulation en cours (pas des points ecrits dans le
   fichier de resultats), pour avertir quand une courbe continue rapide y serait
   mal echantillonnee (porteuse tracee des modems radio, cf. requirements.md,
   decision "Liaison radio modulee").

   Modelica ne donne pas acces a l'intervalle de sortie depuis un modele. Le
   simulateur genere par omc le lit dans deux sources, que l'on relit ici :
     1. la ligne de commande : -override=...,stepSize=...,... (OMEdit y passe
        les reglages de sa fenetre de simulation), ou -overrideFile=<fichier> ;
     2. le fichier <modele>_init.xml (element DefaultExperiment, attribut
        stepSize), designe par -f, sinon <dossier>/<nom de l'exe>_init.xml, le
        dossier etant -inputPath s'il est donne, sinon celui de l'exe.
   La ligne de commande l'emporte, comme dans le simulateur. Faute de trouver
   (autre outil, autre systeme), rend -1 : l'appelant ne signale rien.

   Partage par les chapeaux qui en ont besoin : garde d'inclusion obligatoire
   (omc dedoublonne les Include par leur texte, deux chapeaux peuvent atterrir
   dans la meme unite de compilation). Windows uniquement, comme le reste. */

#ifndef MPMCU_SIMOUTPUT_C
#define MPMCU_SIMOUTPUT_C

#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#ifdef _WIN32
#include <windows.h>
#endif

#define SIMOUT_PATH_MAX 2048

/* Valeur de "<cle>=" dans une liste "a=1,b=2" (ou une ligne par reglage) ;
   rend -1 si absente. */
static double simout_value_in_list(const char* list, const char* key) {
    size_t k = strlen(key);
    const char* p = list;
    while (p && *p) {
        while (*p == ',' || *p == ' ' || *p == '\r' || *p == '\n' || *p == '"') p++;
        if (strncmp(p, key, k) == 0 && p[k] == '=') {
            return atof(p + k + 1);
        }
        while (*p && *p != ',' && *p != '\n') p++;
    }
    return -1;
}

/* Pas de sortie d'une liste de reglages : stepSize, sinon
   (stopTime - startTime)/numberOfIntervals si tout y est. */
static double simout_step_from_list(const char* list) {
    double step = simout_value_in_list(list, "stepSize");
    double n, t0, t1;
    if (step > 0) return step;
    n = simout_value_in_list(list, "numberOfIntervals");
    t0 = simout_value_in_list(list, "startTime");
    t1 = simout_value_in_list(list, "stopTime");
    if (n > 0 && t1 > 0) return (t1 - (t0 > 0 ? t0 : 0)) / n;
    return -1;
}

/* Contenu d'un fichier, alloue (a liberer), ou NULL. */
static char* simout_read_file(const char* path) {
    FILE* f = fopen(path, "rb");
    long len;
    char* buf;
    if (!f) return NULL;
    fseek(f, 0, SEEK_END);
    len = ftell(f);
    fseek(f, 0, SEEK_SET);
    if (len < 0 || len > 64L * 1024 * 1024) {
        fclose(f);
        return NULL;
    }
    buf = (char*) malloc((size_t) len + 1);
    if (!buf) {
        fclose(f);
        return NULL;
    }
    len = (long) fread(buf, 1, (size_t) len, f);
    buf[len] = '\0';
    fclose(f);
    return buf;
}

/* stepSize de l'element DefaultExperiment d'un fichier _init.xml. */
static double simout_step_from_init(const char* path) {
    char* xml = simout_read_file(path);
    char* p;
    double step = -1;
    if (!xml) return -1;
    p = strstr(xml, "<DefaultExperiment");
    if (p) p = strstr(p, "stepSize");
    if (p) p = strchr(p, '"');
    if (p) step = atof(p + 1);
    free(xml);
    return step;
}

#ifdef _WIN32
/* Argument suivant de la ligne de commande (guillemets retires), ou NULL. */
static const char* simout_next_arg(const char* p, char* out, size_t size) {
    size_t n = 0;
    int quoted = 0;
    while (*p == ' ' || *p == '\t') p++;
    if (!*p) return NULL;
    while (*p && (quoted || (*p != ' ' && *p != '\t'))) {
        if (*p == '"') {
            quoted = !quoted;
        } else if (n + 1 < size) {
            out[n++] = *p;
        }
        p++;
    }
    out[n] = '\0';
    return p;
}
#endif

/* Intervalle de sortie en secondes, ou -1 s'il n'a pas pu etre determine. */
static double sim_output_interval(void) {
#ifdef _WIN32
    static char arg[SIMOUT_PATH_MAX], prev[64], initFile[SIMOUT_PATH_MAX], inputPath[SIMOUT_PATH_MAX];
    static char exe[SIMOUT_PATH_MAX], path[SIMOUT_PATH_MAX];
    const char* p = GetCommandLineA();
    double step = -1;
    char* base;
    char* dot;
    initFile[0] = inputPath[0] = prev[0] = '\0';

    /* 1. Ligne de commande. "-x=valeur" ou "-x valeur". */
    while ((p = simout_next_arg(p, arg, sizeof(arg))) != NULL) {
        const char* value = NULL;
        if (strncmp(arg, "-override=", 10) == 0) {
            value = arg + 10;
        } else if (strcmp(prev, "-override") == 0) {
            value = arg;
        }
        if (value && step <= 0) {
            step = simout_step_from_list(value);
        }
        value = NULL;
        if (strncmp(arg, "-overrideFile=", 14) == 0) {
            value = arg + 14;
        } else if (strcmp(prev, "-overrideFile") == 0) {
            value = arg;
        }
        if (value && step <= 0) {
            char* text = simout_read_file(value);
            if (text) {
                step = simout_step_from_list(text);
                free(text);
            }
        }
        if (strcmp(prev, "-f") == 0) {
            strncpy(initFile, arg, sizeof(initFile) - 1);
        } else if (strncmp(arg, "-f=", 3) == 0) {
            strncpy(initFile, arg + 3, sizeof(initFile) - 1);
        }
        if (strncmp(arg, "-inputPath=", 11) == 0) {
            strncpy(inputPath, arg + 11, sizeof(inputPath) - 1);
        } else if (strcmp(prev, "-inputPath") == 0) {
            strncpy(inputPath, arg, sizeof(inputPath) - 1);
        }
        strncpy(prev, arg, sizeof(prev) - 1);
        prev[sizeof(prev) - 1] = '\0';
    }
    if (step > 0) return step;

    /* 2. Fichier _init.xml. */
    if (initFile[0]) {
        return simout_step_from_init(initFile);
    }
    if (!GetModuleFileNameA(NULL, exe, sizeof(exe))) return -1;
    base = strrchr(exe, '\\');
    if (!base) base = strrchr(exe, '/');
    base = base ? base + 1 : exe;
    dot = strrchr(base, '.');
    if (dot) *dot = '\0';
    if (inputPath[0]) {
        snprintf(path, sizeof(path), "%s/%s_init.xml", inputPath, base);
    } else {
        /* base pointe dans exe : ce qui le precede est le dossier de l'exe */
        snprintf(path, sizeof(path), "%.*s%s_init.xml", (int) (base - exe), exe, base);
    }
    step = simout_step_from_init(path);
    if (step <= 0) {
        snprintf(path, sizeof(path), "%s_init.xml", base);  /* dossier courant */
        step = simout_step_from_init(path);
    }
    return step;
#else
    return -1;
#endif
}

#endif /* MPMCU_SIMOUTPUT_C */
