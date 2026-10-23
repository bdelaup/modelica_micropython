# Exemple Examples.MicroBit.Buttons : réaction aux boutons A et B - le
# compteur d'appuis défile sur la matrice, A ajoute 1, B remet à zéro.
# Le meme fichier tourne tel quel sur une vraie micro:bit.
from microbit import *

count = 0
display.scroll('A=+1 B=0', delay=80)

while True:
    if button_a.was_pressed():
        count += 1
        print('count', count)
        display.scroll(str(count), delay=80)
    if button_b.was_pressed():
        count = 0
        print('reset')
        display.scroll('0', delay=80)
    sleep(20)
