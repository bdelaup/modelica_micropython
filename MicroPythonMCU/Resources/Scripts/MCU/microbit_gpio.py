# Exemple Examples.MicroBit.GpioEdge : les broches du connecteur edge se
# pilotent et se lisent comme sur la carte - P0 recopie P1 (bouclage fil), et
# la matrice affiche le niveau (pédagogie : une entrée qui agit sur l'afficheur).
# Le meme fichier tourne tel quel sur une vraie micro:bit.
from microbit import *

pin1.write_digital(1)   # sortie, alimente la boucle
while True:
    v = pin0.read_digital()
    display.set_pixel(2, 4, 9 if v else 0)
    display.set_pixel(2, 0, 0 if v else 9)
    sleep(100)
