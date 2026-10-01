# Board A of Examples.MultiMcu.Uart: sends "PING n" lines to board B over a
# real electrical serial link (TX = GP0 -> RX of B, RX = GP1 <- TX of B) and
# checks that B answers "PONG n". GP7 lights up once every reply is right.
from machine import Pin, UART
import time

ROUNDS = 3
TIMEOUT_MS = 100

uart = UART(0, baudrate=9600, tx=Pin(0), rx=Pin(1))
ok_led = Pin(7, Pin.OUT)


def read_line(timeout_ms):
    line = b''
    t0 = time.ticks_ms()
    while not line.endswith(b'\n'):
        if time.ticks_diff(time.ticks_ms(), t0) > timeout_ms:
            return None
        if uart.any():
            line += uart.read(1)
        else:
            time.sleep_ms(1)
    return line


time.sleep_ms(20)      # both lines idle (high) before the first frame
good = 0
for i in range(ROUNDS):
    uart.write(b'PING %d\n' % i)
    reply = read_line(TIMEOUT_MS)
    print('sent PING', i, '- received', reply)
    if reply == b'PONG %d\n' % i:
        good += 1
    time.sleep_ms(20)

print('replies:', good, '/', ROUNDS)
if good == ROUNDS:
    ok_led.on()
