# ---------------------------------------------------------------------------
# Script par defaut du modele MCU (parametre scriptPath).
#
# Ce qu'il fait : il fait clignoter a 0,5 Hz la broche GP0 et la LED integree,
# allumees puis eteintes une seconde chacune, indefiniment.
#
# Pourquoi si court : c'est le programme temoin de la bibliotheque. Poser un
# MCU dans un schema et lancer la simulation sans rien configurer doit produire
# quelque chose d'observable immediatement - une tension carree sur GP0 et la
# pastille de l'icone qui s'allume. Il sert aussi de point de depart a copier
# pour ecrire son propre programme.
#
# Ce qu'il montre du mecanisme : la boucle est INFINIE et les sleep() durent une
# seconde, pourtant la simulation s'execute en une fraction de seconde. Le temps
# du script est le temps SIMULE, pas le temps reel : un sleep(1) rend la main au
# solveur, qui avance d'un coup jusqu'a l'echeance. C'est tout l'interet du
# couplage - voir docs/cycle-de-vie.md.
#
# API disponible : machine.Pin / ADC / PWM / Timer / UART / Display et time,
# calquees sur MicroPython (reference : Raspberry Pi Pico). Voir docs/api-machine.md.
# ---------------------------------------------------------------------------
from machine import Pin
import time

led = Pin(0, Pin.OUT)
builtin = Pin(Pin.LED, Pin.OUT)

while True:
    led.on()
    builtin.on()
    time.sleep(1)
    led.off()
    builtin.off()
    time.sleep(1)
