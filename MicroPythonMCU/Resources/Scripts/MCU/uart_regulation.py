from machine import Pin, UART
import time

# Boucle de regulation fermee ENTIEREMENT dans le modele, a travers la seule
# liaison serie :
#
#   microcontroleur --AT+TEMP--> capteur --{v1}--> lit valueIn  (la mesure)
#   microcontroleur --SET x---->  capteur --{o1}--> ecrit valueOut (la commande)
#   valueOut --> modele thermique (FirstOrder) --> valueIn
#
# Le capteur n'est donc pas seulement un capteur : la commande qu'il republie
# sur sa sortie reelle pilote le procede, dont la reponse revient sur son
# entree. Aucun fil supplementaire, tout passe par les deux memes broches.
BAUD = 9600
TIMEOUT_MS = 200
CONSIGNE = 40.0       # degC
GAIN_PROC = 0.5       # degC par unite de commande, en regime etabli
KP = 4.0              # gain proportionnel du correcteur
CMD_MIN, CMD_MAX = 0.0, 100.0
CYCLES = 18

uart = UART(0, baudrate=BAUD, tx=Pin(5), rx=Pin(4))


def demande(commande):
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


def mesure():
    try:
        return float(demande(b'AT+TEMP\n').split(b'=')[1].strip())
    except Exception:
        return None


time.sleep_ms(10)

for i in range(CYCLES):
    t = mesure()
    if t is None:
        continue
    # Correcteur proportionnel avec compensation du gain statique du procede.
    cmd = CONSIGNE / GAIN_PROC + KP * (CONSIGNE - t)
    if cmd < CMD_MIN:
        cmd = CMD_MIN
    elif cmd > CMD_MAX:
        cmd = CMD_MAX
    demande(b'SET %.1f\n' % cmd)
    print("cycle", i, "mesure", t, "commande", cmd)

print("Regulation : consigne", CONSIGNE, "derniere mesure", mesure())
