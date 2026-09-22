from machine import Pin, UART
import time

# Bouclage serie sur un seul microcontroleur : ce qui sort de TX (GP0) revient
# sur RX (GP1) par un simple fil dans le schema. A 1200 bauds, un bit dure
# 833 us et la trame 8N1 complete (start + 8 data + stop) dure 8.3 ms.
# Deux octets : ils partent l'un apres l'autre sans trou, la file d'emission
# enchainant la seconde trame des la fin de la premiere (comme un vrai FIFO
# materiel). 'H' = 0x48, 'i' = 0x69.
MESSAGE = b'Hi'
TIMEOUT_MS = 100
# Petit delai avant d'emettre, pour laisser voir l'etat de repos sur
# l'oscillogramme : des que l'UART est configure, la broche TX est pilotee
# activement au niveau HAUT (etat "mark"), avant meme le premier write().
# C'est le TX qui tient la ligne, pas le RX : la sortie est push-pull, aucune
# resistance de tirage n'est necessaire (contrairement a un bus I2C).
REPOS_MS = 5        # 6 durees de bit a 1200 bauds, bien visible

temoin = Pin(3, Pin.OUT)
uart = UART(0, baudrate=1200, tx=Pin(0), rx=Pin(1))

time.sleep_ms(REPOS_MS)   # la ligne TX est deja au repos (haut) pendant ce delai

uart.write(MESSAGE)   # non bloquant : Modelica joue la forme d'onde, le script continue

recu = b''
echeance = time.ticks_ms() + TIMEOUT_MS
while len(recu) < len(MESSAGE) and time.ticks_diff(echeance, time.ticks_ms()) > 0:
    if uart.any():
        recu += uart.read()
    else:
        time.sleep_ms(1)

print("UART : envoye", MESSAGE, "recu", recu)
if recu == MESSAGE:
    temoin.on()       # GP3 allume = toute la chaine a fonctionne
