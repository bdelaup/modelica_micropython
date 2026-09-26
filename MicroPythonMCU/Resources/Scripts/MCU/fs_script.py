# Programme lance a la place de main.py, apres le boot.py de la flash - comme
# Thonny qui execute le script ouvert sur une carte deja demarree.
import os
from machine import Pin

# boot.py a tourne : il a cree /data. main.py, lui, n'a pas tourne : /data est
# encore vide (pas de mesures.csv).
ok = 'data' in os.listdir('/') and os.listdir('/data') == []

with open('/data/notes.txt', 'w') as f:
    f.write('ecrit par le script\n')
with open('/data/notes.txt') as f:
    ok = ok and f.read() == 'ecrit par le script\n'

print('fs_script.py : boot.py execute, main.py remplace -', 'OK' if ok else 'ECHEC')
Pin(1, Pin.OUT).value(1 if ok else 0)
