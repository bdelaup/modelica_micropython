from machine import Pin, UART
import time

# Serial loopback on a single microcontroller: what goes out of TX (GP0) comes
# back on RX (GP1) through a simple wire in the schematic. At 1200 baud, a bit lasts
# 833 us and the complete 8N1 frame (start + 8 data + stop) lasts 8.3 ms.
# Two bytes: they leave one after the other with no gap, the transmit queue
# chaining the second frame as soon as the first one ends (like a real hardware
# FIFO). 'H' = 0x48, 'i' = 0x69.
MESSAGE = b'Hi'
TIMEOUT_MS = 100
# Short delay before transmitting, to show the idle state on the plot:
# as soon as the UART is configured, the TX pin is actively driven
# HIGH ("mark" state), even before the first write().
# The TX holds the line, not the RX: the output is push-pull, no pull-up
# resistor is needed (unlike an I2C bus).
IDLE_MS = 5         # 6 bit times at 1200 baud, clearly visible

indicator = Pin(3, Pin.OUT)
uart = UART(0, baudrate=1200, tx=Pin(0), rx=Pin(1))

time.sleep_ms(IDLE_MS)    # the TX line is already idle (high) during this delay

uart.write(MESSAGE)   # non-blocking: Modelica plays the waveform, the script goes on

received = b''
deadline = time.ticks_ms() + TIMEOUT_MS
while len(received) < len(MESSAGE) and time.ticks_diff(deadline, time.ticks_ms()) > 0:
    if uart.any():
        received += uart.read()
    else:
        time.sleep_ms(1)

print("UART: sent", MESSAGE, "received", received)
if received == MESSAGE:
    indicator.on()    # GP3 on = the whole chain worked
