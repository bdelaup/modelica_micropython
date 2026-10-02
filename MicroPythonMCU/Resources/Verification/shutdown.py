# Scenario de verification n°43 : arret propre en fin de simulation. Le
# programme ouvre un fichier qu'il ne ferme jamais et y ecrit une ligne toutes
# les 100 ms, dans une boucle sans fin protegee par try/finally. En fin de
# simulation, le sleep() en cours leve SystemExit : le bloc finally s'execute,
# puis la fin du sous-interpreteur ferme le fichier et vide son tampon sur
# disque. Avant l'arret propre, le process se terminait sans rien de tout
# cela : finally jamais execute, fichier vide (lignes restees dans le tampon).
from machine import Pin
import time

log = open('log.txt', 'w')
Pin(0, Pin.OUT).on()
n = 0
try:
    while True:
        n += 1
        log.write('line %d\n' % n)
        time.sleep(0.1)
finally:
    print('finally ran after %d lines' % n)
