# Scenario de verification n°30 : un module de la stdlib importe pour la premiere
# fois par le script du microcontroleur garde le vrai os, meme s'il vient de
# python312.zip (co_filename relatif, "ctypes\__init__.py") ; le script, lui,
# recoit toujours l'os de MicroPython. GP0 passe a 1 si tout est conforme.
from machine import Pin
import ctypes
import random
import tempfile
import time

# Chacun de ces modules se sert du vrai os de l'hote a l'import ou a l'appel.
assert ctypes.sizeof(ctypes.c_int) == 4
assert 0 <= random.random() < 1
assert tempfile.gettempdir()

# Sans systeme de fichiers, l'os de MicroPython refuse de servir le script.
try:
    import os
    os.listdir('/')
    raise RuntimeError("os de l'hote servi au code du microcontroleur")
except OSError:
    pass

Pin(0, Pin.OUT).on()
time.sleep(1)
