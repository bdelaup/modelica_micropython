# Emetteur radio : envoie PING 1..5 sur l'air, une par seconde, et montre le
# numero sur la matrice. Avec microbit_radio_rx.py sur une autre carte cablee
# a la meme antenne (un seul fil) - cf. Examples.MicroBit.RadioChat.
from microbit import *
import radio

radio.on()
n = 0
while n < 5:
    n += 1
    radio.send('PING %d' % n)
    display.scroll('S%d' % n, wait=False)
    print('TX %d' % n)
    sleep(1000)
print('TX_DONE')
