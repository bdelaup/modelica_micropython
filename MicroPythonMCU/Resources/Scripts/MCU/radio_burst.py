# Board A of Examples.Radio.Overflow: writes a 40-byte burst at once on its
# UART (TX = GP0), towards a radio modem whose air data rate (1200 bit/s) is
# eight times slower than the serial link (9600 baud) and whose transmit
# buffer only holds 16 bytes: the end of the burst cannot all fit.
from machine import Pin, UART
import time

uart = UART(0, baudrate=9600, tx=Pin(0), rx=Pin(1))

time.sleep_ms(20)      # line idle (high) before the first frame
message = b'0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZabcd'
uart.write(message)
print('sent', len(message), 'bytes:', message)
