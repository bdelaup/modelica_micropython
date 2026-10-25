# Radio et UART en meme temps : la radio embarquee (moteur UART interne n°1,
# par le modem embarque et l'air) dialogue avec une autre carte pendant que
# machine.UART (moteur n°0, broches P0/P1) interroge un appareil serie externe.
# Cf. Examples.MicroBit et verify_80 : les deux moteurs coexistent.
from microbit import *
import radio, machine

uart = machine.UART(0, tx=Pin(0), rx=Pin(1), baudrate=9600)
radio.on()
n = 0
while n < 5:
    n += 1
    radio.send('PING %d' % n)
    uart.write('LINE %d\n' % n)
    print('BOTH %d' % n)
    sleep(300)
    line = uart.readline()
    if line:
        print('ECHO %d %s' % (n, str(line)))
print('DONE')
