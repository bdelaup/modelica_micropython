#ifndef PYRUNTIMEIMPL_H
#define PYRUNTIMEIMPL_H

/* Jalon M5 : thread worker + condition variable, interception de sleep()/des
   appels au shim comme points de synchro (cf. requirements.md). */

void* PyRuntime_new(const char* scriptPath, const char* pythonHome);
void PyRuntime_destroy(void* handle);

/* pinBoolIn: [8] en entree (etat resolu des broches). pinBoolOut/pinIsOutput:
   [8] en sortie (deja alloues par l'appelant, convention Modelica External C).
   nextWakeTime: sortie scalaire. */
void PyRuntime_sync(void* handle, double currentTime, const int* pinBoolIn,
                     int* pinBoolOut, int* pinIsOutput, double* nextWakeTime);

#endif
