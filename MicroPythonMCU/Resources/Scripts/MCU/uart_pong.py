# Board B of Examples.MultiMcu.Uart: answers every "PING n" line received from
# board A with "PONG n" (TX = GP0 -> RX of A, RX = GP1 <- TX of A).
from machine import Pin, UART
import time

uart = UART(0, baudrate=9600, tx=Pin(0), rx=Pin(1))
pending = b''

while True:
    if uart.any():
        pending += uart.read()
        while b'\n' in pending:
            line, pending = pending.split(b'\n', 1)
            if line.startswith(b'PING'):
                uart.write(b'PONG' + line[4:] + b'\n')
                print('answered', line)
    else:
        time.sleep_ms(1)
