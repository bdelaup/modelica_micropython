# Recepteur radio : ecoute l'air, affiche et compte chaque PING recu.
# Avec microbit_radio_tx.py sur l'autre carte cablee a la meme
# meme antenne (un seul fil) - cf. Examples.MicroBit.RadioChat.
from microbit import *
import radio

radio.on()
seen = 0
while seen < 5:
    msg = radio.receive()
    if msg:
        seen += 1
        display.scroll(msg, wait=False)
        print('RX %s' % msg)
    sleep(100)
print('RX_DONE %d' % seen)
