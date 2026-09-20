#ifndef PYRUNTIMEIMPL_H
#define PYRUNTIMEIMPL_H

/* Jalon M5 : thread worker + condition variable, interception de sleep()/des
   appels au shim comme points de synchro (cf. requirements.md). */

void* PyRuntime_new(const char* scriptPath, const char* pythonHome);
void PyRuntime_destroy(void* handle);

/* pinBoolIn: [9] en entree (etat resolu des broches : 0-7 = GP0-GP7 externes,
   8 = LED embarquee interne, cf. PyRuntimeImpl.c). pinAnalogIn: [9] en entree,
   tension brute (V) alignee sur pinBoolIn, lue par machine.ADC (index 8/LED
   jamais utilise cote ADC). pinBoolOut/pinIsOutput: [9] en sortie (deja
   alloues par l'appelant, convention Modelica External C). nextWakeTime:
   sortie scalaire. */
void PyRuntime_sync(void* handle, double currentTime, const int* pinBoolIn,
                     const double* pinAnalogIn,
                     int* pinBoolOut, int* pinIsOutput, double* nextWakeTime);

#endif
