# Scenario de verification n°41 : sys.exit() termine le programme sans
# erreur, comme sur la carte - la simulation continue jusqu'a son terme, la
# sortie GP0 garde son dernier etat. Avant correction, sys.exit() terminait le
# process de simulation lui-meme (exit() appele par PyErr_Print).
from machine import Pin
import sys
import time

Pin(0, Pin.OUT).on()
print("before exit")
time.sleep(0.1)
sys.exit()
print("after exit")
