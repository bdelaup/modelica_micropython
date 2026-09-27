# Scenario de verification n°29 : la DLL python312.dll chargee dans le process de
# simulation doit etre celle de la distribution embarquee (Resources/PythonRuntime),
# jamais celle d'un Python installe sur le poste et trouve par le PATH.
# GP0 passe a 1 si c'est le cas ; sinon le script leve une exception (simulation
# en erreur). _winapi est integre a python312.dll et n'importe pas os : sans
# systeme de fichiers, le shim refuse os au code du microcontroleur.
from machine import Pin
import _winapi
import sys
import time


def normalise(chemin):
    return chemin.replace('/', '\\').rstrip('\\').lower()


dll = _winapi.GetModuleFileName(sys.dllhandle)
print("python312.dll chargee :", dll)
print("distribution embarquee :", sys.prefix)

if normalise(dll).rsplit('\\', 1)[0] != normalise(sys.prefix):
    raise RuntimeError("python312.dll ne vient pas de la distribution embarquee : " + dll)

Pin(0, Pin.OUT).on()
time.sleep(1)
