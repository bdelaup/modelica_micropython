# Repondeur des deux liaisons UART ouvertes en meme temps : PING -> PONG sur
# la liaison 0 (GP0/GP1), HELLO -> WORLD sur la liaison 1 (GP4/GP5).
# Cf. Examples.Pico.UartDuo, verify_82 et verify_83.
from machine import Pin, UART
import time

u0 = UART(0, tx=Pin(0), rx=Pin(1), baudrate=9600)
u1 = UART(1, tx=Pin(4), rx=Pin(5), baudrate=9600)
seen0 = 0
seen1 = 0
while seen0 < 5 or seen1 < 5:
    time.sleep(0.05)
    a = u0.read()
    b = u1.read()
    if a:
        u0.write(b'PONG ' + a.strip().split()[1] + b'\n')
        seen0 += 1
        print('LINK0 %r' % a)
    if b:
        u1.write(b'WORLD ' + b.strip().split()[1] + b'\n')
        seen1 += 1
        print('LINK1 %r' % b)
print('DONE_B')
