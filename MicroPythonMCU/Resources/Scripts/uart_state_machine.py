from machine import Pin, UART
import time

# Programme du microcontroleur pour Examples.UartStateMachine : il deroule un
# scenario de commandes et verifie que l'appareil repond selon son ETAT, et
# pas seulement selon la commande recue.
#
#   READ   -> ERR   (l'appareil est a l'arret)
#   START  -> OK
#   READ   -> VAL=... N=1
#   READ   -> VAL=... N=2
#   START  -> ERR   (deja demarre)
#   STOP   -> OK
#   READ   -> ERR   (de nouveau a l'arret)
BAUD = 9600
TIMEOUT_MS = 200

temoin = Pin(7, Pin.OUT)
uart = UART(0, baudrate=BAUD, tx=Pin(5), rx=Pin(4))


def demande(commande):
    uart.write(commande + b'\n')
    ligne = b''
    echeance = time.ticks_ms() + TIMEOUT_MS
    while time.ticks_diff(echeance, time.ticks_ms()) > 0:
        if uart.any():
            ligne += uart.read()
            if ligne.endswith(b'\n'):
                return ligne.strip()
        else:
            time.sleep_ms(1)
    return ligne.strip()


time.sleep_ms(10)
r = [demande(b'READ'), demande(b'START'), demande(b'READ'), demande(b'READ')]
time.sleep_ms(100)          # l'appareil reste en marche : fenetre observable sur valueOut[1]
r += [demande(b'START'), demande(b'STOP'), demande(b'READ')]

for c, rep in zip([b'READ', b'START', b'READ', b'READ', b'START', b'STOP', b'READ'], r):
    print(c, '->', rep)

attendu = (r[0].startswith(b'ERR') and r[1] == b'OK'
           and r[2].startswith(b'VAL=') and r[2].endswith(b'N=1')
           and r[3].startswith(b'VAL=') and r[3].endswith(b'N=2')
           and r[4].startswith(b'ERR') and r[5] == b'OK' and r[6].startswith(b'ERR'))
if attendu:
    temoin.on()     # GP7 haut = chaque reponse correspond a l'etat attendu de l'appareil
