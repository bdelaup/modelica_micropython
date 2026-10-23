# Programme du scenario de verification "microbit_buttons" : boutons A/B.
# Cf. verify_74_microbit_buttons.mos (appui A sur [0,05 ; 0,15] s, B sur
# [0,25 ; 0,35] s, pulses electriques cablees dans le modele).
from microbit import *

print('start', button_a.is_pressed(), button_b.is_pressed())
sleep(100)   # -> 0,1 s : appui A en cours
print('during a', button_a.is_pressed())
sleep(100)   # -> 0,2 s : A relache
print('after a', button_a.is_pressed(), button_a.was_pressed(), button_b.was_pressed())
print('presses a b', button_a.get_presses(), button_b.get_presses())
sleep(100)   # -> 0,3 s : appui B en cours
print('during b', button_b.is_pressed())
sleep(100)   # -> 0,4 s : B relache
print('after b', button_b.was_pressed(), button_a.was_pressed())
print('presses2 a b', button_a.get_presses(), button_b.get_presses())
print('buttons done')
