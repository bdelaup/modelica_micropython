# Auto-communication a travers les deux moteurs UART de la carte : le script
# s'envoie un paquet radio (moteur interne n°1, modem embarque, antenne), un
# RadioModem externe cable sur la meme antenne le renvoie sur ses broches P0/P1
# (machine.UART, moteur n°0) - la carte relit ses propres trames.
# Cf. verify_81.
from microbit import *
import radio, machine

uart = machine.UART(0, tx=Pin(0), rx=Pin(1), baudrate=9600)
radio.on()
n = 0
while n < 3:
    n += 1
    radio.send('SELF %d' % n)
    sleep(300)
    data = uart.read()
    if data and ('SELF %d' % n).encode() in data:
        print('BACK %d' % n)
print('DONE')
