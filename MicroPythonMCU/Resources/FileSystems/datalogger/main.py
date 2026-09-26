# main.py : execute apres boot.py. Enregistreur de mesures : lit la tension
# sur GP0 (ADC) a intervalle regulier et l'ajoute a /data/mesures.csv.
# Les reglages viennent de /config.txt, le module Journal de /lib.
import os
import time
from machine import ADC, Pin
from journal import Journal

reglages = {}
with open('config.txt') as f:
    for ligne in f:
        if '=' in ligne:
            cle, valeur = ligne.strip().split('=', 1)
            reglages[cle] = valeur
periode_ms = int(reglages['periode_ms'])
mesures = int(reglages['mesures'])

adc = ADC(0)
journal = Journal('/data/mesures.csv', 't_ms;tension_V')
for i in range(mesures):
    tension = adc.read_u16() * 3.3 / 65535
    journal.ajoute('%d;%.3f' % (time.ticks_ms(), tension))
    time.sleep_ms(periode_ms)

# Auto-controle (utilise par le scenario de verification) : la LED sur GP1
# s'allume si tout ce qui precede s'est passe comme prevu.
with open('/data/mesures.csv') as f:
    lignes = f.read().split('\n')
ok = lignes[0] == 't_ms;tension_V' and len(lignes) == mesures + 2 and lignes[-1] == ''
ok = ok and [int(l.split(';')[0]) for l in lignes[1:-1]] == [i * periode_ms for i in range(mesures)]
ok = ok and os.getcwd() == '/' and os.stat('/data')[0] == 0x4000
ok = ok and os.listdir('/lib') == ['journal.py']      # pas de __pycache__ dans la flash
with open('../../hors_flash.txt', 'w') as f:          # ".." s'arrete a la racine :
    f.write('reste dans la flash\n')                   # le fichier atterrit en /hors_flash.txt
ok = ok and os.listdir('/') == ['boot.py', 'config.txt', 'data', 'hors_flash.txt', 'lib', 'main.py']
print('main.py :', len(lignes) - 2, 'mesures enregistrees, auto-controle', 'OK' if ok else 'ECHEC')
Pin(1, Pin.OUT).value(1 if ok else 0)
