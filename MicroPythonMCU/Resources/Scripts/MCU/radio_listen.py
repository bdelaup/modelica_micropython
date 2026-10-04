# Board B of Examples.Radio.Overflow: accumulates what its radio modem
# delivers on the UART (RX = GP1) and prints it once nothing has arrived for
# 200 ms.
from machine import Pin, UART
import time

uart = UART(0, baudrate=9600, tx=Pin(0), rx=Pin(1))
received = b''
last = time.ticks_ms()

while True:
    if uart.any():
        received += uart.read()
        last = time.ticks_ms()
    elif received and time.ticks_diff(time.ticks_ms(), last) > 200:
        print('received', len(received), 'bytes:', received)
        received = b''
    else:
        time.sleep_ms(1)
