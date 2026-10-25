# Deux liaisons UART en meme temps : UART(0) sur GP0/GP1 et UART(1) sur
# GP4/GP5 (les broches par defaut des deux UART du RP2040 sur la Pico ; sur
# MCU, GP0-GP7 indifferemment). La carte B (uart_duo_b.py) repond PONG sur la
# premiere et WORLD sur la seconde. Cf. Examples.Pico.UartDuo, verify_82 et
# verify_83.
from machine import Pin, UART
import time

u0 = UART(0, tx=Pin(0), rx=Pin(1), baudrate=9600)
u1 = UART(1, tx=Pin(4), rx=Pin(5), baudrate=9600)
time.sleep(0.01)     # laisse les lignes se poser a l'etat de repos avant la
                     # premiere trame (le temps de mise en route du hardware)
n = 0
while n < 5:
    n += 1
    u0.write('PING %d\n' % n)
    u1.write('HELLO %d\n' % n)
    print('SENT %d' % n)
    time.sleep(0.2)
    r0 = u0.read()
    r1 = u1.read()
    if r0 and r1:
        print('BOTH %d %r %r' % (n, r0, r1))
print('DONE')
