# Board of Examples.Radio.Modulations: writes the character 'U' once on its
# UART (TX = GP0). 'U' = 0x55 = 01010101: on air, with the start and stop
# bits, the frame alternates 0 and 1 at every bit, which makes the
# modulation easy to read on the drawn signal.
from machine import Pin, UART
import time

uart = UART(0, baudrate=9600, tx=Pin(0), rx=Pin(1))

time.sleep_ms(20)      # line idle (high) before the first frame
uart.write(b'U')
print('sent U')
