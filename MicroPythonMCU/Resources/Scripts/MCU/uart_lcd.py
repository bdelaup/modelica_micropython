from machine import Pin, UART
import time

# Serial 20x2 display (Peripherals.UartLcd20x2): text is written to it line
# by line over a real serial link. The line feed validates the line and
# triggers the display, exactly like the terminator of a command.
#
# Compare with Examples.Display.Demo, which does the same thing through the
# logical link machine.Display: delivery is instantaneous there, here the text
# takes real time to go through the wire (1.04 ms per character at 9600 baud).
BAUD = 9600

uart = UART(0, baudrate=BAUD, tx=Pin(5), rx=Pin(4))

time.sleep_ms(5)
uart.write(b'Tank 3   45.2 degC\n')
time.sleep_ms(60)          # let the line finish going through the wire
uart.write(b'Flow     12.8 L-min\n')
time.sleep_ms(60)

print("LCD: two lines sent")
