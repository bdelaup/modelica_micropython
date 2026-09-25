from machine import Pin, UART
import time

# Dialogue requete/reponse avec un capteur serie externe
# (Peripherals.UartTemperatureSensor). Le capteur ne parle que si on le
# questionne, et il met 5 ms a repondre - il faut donc vraiment attendre sa
# reponse, pas la supposer deja arrivee.
#
# 9600 bauds : un octet dure 1,04 ms, un aller-retour complet une trentaine de
# millisecondes. Assez rapide pour enchainer deux mesures dans une simulation
# courte, assez lent pour rester une vraie liaison serie.
BAUD = 9600
TIMEOUT_MS = 200

temoin = Pin(7, Pin.OUT)
uart = UART(0, baudrate=BAUD, tx=Pin(5), rx=Pin(4))


def demande(commande):
    """Envoie une commande et attend la ligne de reponse (terminee par \\n)."""
    uart.write(commande)
    ligne = b''
    echeance = time.ticks_ms() + TIMEOUT_MS
    while time.ticks_diff(echeance, time.ticks_ms()) > 0:
        if uart.any():
            ligne += uart.read()
            if ligne.endswith(b'\n'):
                return ligne
        else:
            time.sleep_ms(1)
    return ligne


def valeur(reponse):
    """Extrait le nombre de 'TEMP=23.4\\r\\n'."""
    try:
        return float(reponse.split(b'=')[1].strip())
    except Exception:
        return None


time.sleep_ms(10)

identite = demande(b'AT+ID\n')
r1 = demande(b'AT+TEMP\n')
time.sleep_ms(100)            # la temperature monte pendant ce temps
r2 = demande(b'AT+TEMP\n')

v1 = valeur(r1)
v2 = valeur(r2)
print("capteur :", identite, "mesures :", v1, v2)

# Consigne renvoyee au capteur : il la republie sur sa sortie reelle valueOut,
# qui peut piloter le reste du modele. C'est ce qui en fait un actionneur.
uart.write(b'SET 42.5\n')
time.sleep_ms(50)

if v1 is not None and v2 is not None and v2 > v1:
    temoin.on()   # GP7 allume = deux mesures valides ET la temperature a bien monte
