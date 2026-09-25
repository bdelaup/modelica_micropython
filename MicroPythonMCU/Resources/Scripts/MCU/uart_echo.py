from machine import Pin, UART
import time

# Dialogue avec un VRAI peripherique serie externe (Peripherals.UartEchoDevice),
# et non plus un bouclage du microcontroleur sur lui-meme : GP5 (TX) part vers
# le RX du peripherique, le TX du peripherique revient sur GP4 (RX). Deux
# composants distincts relies par deux fils, sans reseau R+C de contournement.
#
# A 1200 bauds, un bit dure 833 us et une trame 8N1 dure 8.3 ms. Le peripherique
# renvoie chaque octet des qu'il l'a entierement decode (bit de stop compris),
# donc avec environ une trame de decalage - comme un repeteur reel.
MESSAGE = b'Hi\n'
TIMEOUT_MS = 250
REPOS_MS = 5        # laisse voir l'etat de repos (haut) avant la premiere trame

temoin = Pin(7, Pin.OUT)
uart = UART(0, baudrate=1200, tx=Pin(5), rx=Pin(4))

time.sleep_ms(REPOS_MS)

uart.write(MESSAGE)   # non bloquant : Modelica joue la forme d'onde, le script continue

recu = b''
echeance = time.ticks_ms() + TIMEOUT_MS
while len(recu) < len(MESSAGE) and time.ticks_diff(echeance, time.ticks_ms()) > 0:
    if uart.any():
        recu += uart.read()
    else:
        time.sleep_ms(1)

print("UART echo : envoye", MESSAGE, "recu", recu)
if recu == MESSAGE:
    temoin.on()       # GP7 allume = l'aller-retour complet a fonctionne
