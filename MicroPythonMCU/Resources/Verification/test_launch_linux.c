/* Test autonome Linux de launch.c : chemin absolu, programme absent,
   lancement detache et transmission d'un chemin contenant espaces et ';'. */
#define _POSIX_C_SOURCE 200809L
#include <stdarg.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <time.h>

static void ModelicaFormatWarning(const char* format, ...) {
    va_list args;
    va_start(args, format);
    vfprintf(stderr, format, args);
    va_end(args);
}

#include "../Include/launch.c"

int main(int argc, char** argv) {
    char* full;
    FILE* result;
    char text[64];
    char path[1024];
    struct timespec delay = { 0, 10000000L };
    if (argc == 4 && strcmp(argv[1], "--child") == 0) {
        size_t len = strlen(argv[3]) + 5;
        char* temp = (char*) malloc(len);
        if (!temp) return 1;
        snprintf(temp, len, "%s.tmp", argv[3]);
        result = fopen(temp, "w");
        if (!result) return 1;
        fprintf(result, "%s", argv[2]);
        if (fclose(result) != 0 || rename(temp, argv[3]) != 0) return 1;
        free(temp);
        return 0;
    }
    if (argc != 2) return 1;
    if (snprintf(path, sizeof(path), "%s/file with spaces;literal", argv[1]) >= (int) sizeof(path)) return 1;
    full = launch_full_path("file with spaces");
    if (!full || full[0] != '/' || !strstr(full, "/file with spaces")) {
        fprintf(stderr, "relative path was not made absolute\n");
        return 1;
    }
    free(full);
    if (launch_detached("missing test program", "/no/such/program", NULL, path)) {
        fprintf(stderr, "missing program was reported as started\n");
        return 1;
    }
    if (!launch_detached("test program", argv[0], "--child marker", path)) return 1;
    for (int i = 0; i < 200; ++i) {
        result = fopen(path, "r");
        if (result) {
            int ok = fgets(text, sizeof(text), result) && strcmp(text, "marker") == 0;
            fclose(result);
            if (!ok) return 1;
            puts("PASS: Linux detached launch and argument handling");
            return 0;
        }
        nanosleep(&delay, NULL);
    }
    fprintf(stderr, "child did not write its result\n");
    return 1;
}
