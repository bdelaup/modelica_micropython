# Exemple Examples.MicroBit.Heart : coeur animé sur la matrice LED.
# Le meme fichier tourne tel quel sur une vraie micro:bit.
from microbit import *

while True:
    display.show(Image.HEART)
    sleep(500)
    display.show(Image.HEART_SMALL)
    sleep(500)
