# Scenario de verification n°42 : un script qui ne rend pas la main a la
# simulation pendant plus de hangWarningTime secondes de temps REEL est signale
# par un avertissement, sans etre interrompu. La boucle de calcul ci-dessous
# n'appelle jamais le shim (pas de sleep, pas d'acces broche) pendant environ
# 2,5 s reelles, mesurees par l'horloge de Windows (le module time du script
# est celui de MicroPython, en temps simule), puis le programme se termine
# normalement.
from machine import Pin
import ctypes
import time

clock = ctypes.windll.kernel32.GetTickCount64
clock.restype = ctypes.c_uint64

led = Pin(0, Pin.OUT)
led.on()
time.sleep(0.1)
start = clock()
n = 0
while clock() - start < 2500:
    n += 1
print("computation done")
led.off()
