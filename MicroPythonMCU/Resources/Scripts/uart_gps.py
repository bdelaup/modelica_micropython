from machine import Pin, UART
import time

# Le peripherique parle SANS qu'on le lui demande (Peripherals.UartGpsModule,
# emission periodique). Le programme n'a donc rien a envoyer : il surveille son
# entree serie, decoupe les phrases NMEA qui arrivent et verifie leur somme de
# controle - exactement ce que ferait le code embarque d'un recepteur GPS.
#
# La reception ne reveille jamais le script (pas de uart.irq() en v0) : il faut
# interroger uart.any() dans une boucle, en dormant entre deux passages pour ne
# pas empecher le temps simule d'avancer.
BAUD = 9600
FENETRE_MS = 500
ATTENDU = 4          # a une phrase toutes les 100 ms, on doit en valider au moins 4

temoin = Pin(7, Pin.OUT)
uart = UART(0, baudrate=BAUD, tx=Pin(5), rx=Pin(4))


def nmea_valide(phrase):
    """'$<corps>*<hh>' : hh = OU exclusif des caracteres du corps, en hexa."""
    if not phrase.startswith(b'$') or b'*' not in phrase:
        return False
    corps, controle = phrase[1:].split(b'*', 1)
    x = 0
    for c in corps:
        x ^= c
    return controle[:2].upper() == b'%02X' % x


tampon = b''
phrases = []
echeance = time.ticks_ms() + FENETRE_MS
while time.ticks_diff(echeance, time.ticks_ms()) > 0:
    if uart.any():
        tampon += uart.read()
        while b'\n' in tampon:
            ligne, tampon = tampon.split(b'\n', 1)
            phrases.append(ligne.strip())
    else:
        time.sleep_ms(2)

valides = [p for p in phrases if nmea_valide(p)]
print("GPS :", len(phrases), "phrases recues,", len(valides), "valides")
for p in phrases:
    print("   ", p)

if len(valides) >= ATTENDU:
    temoin.on()     # GP7 haut = flux spontane a la bonne cadence, sommes de controle correctes
