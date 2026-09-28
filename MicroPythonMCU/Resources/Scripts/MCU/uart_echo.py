from machine import Pin, UART
import time

# Dialogue with a REAL external serial peripheral (Peripherals.UartEchoDevice),
# and no longer a loopback of the microcontroller onto itself: GP5 (TX) goes to
# the RX of the peripheral, the TX of the peripheral comes back to GP4 (RX). Two
# distinct components connected by two wires, with no R+C workaround network.
#
# At 1200 baud, a bit lasts 833 us and an 8N1 frame lasts 8.3 ms. The peripheral
# sends each byte back as soon as it has fully decoded it (stop bit included),
# hence with a delay of about one frame - like a real repeater.
MESSAGE = b'Hi\n'
TIMEOUT_MS = 250
IDLE_MS = 5         # shows the idle state (high) before the first frame

indicator = Pin(7, Pin.OUT)
uart = UART(0, baudrate=1200, tx=Pin(5), rx=Pin(4))

time.sleep_ms(IDLE_MS)

uart.write(MESSAGE)   # non-blocking: Modelica plays the waveform, the script goes on

received = b''
deadline = time.ticks_ms() + TIMEOUT_MS
while len(received) < len(MESSAGE) and time.ticks_diff(deadline, time.ticks_ms()) > 0:
    if uart.any():
        received += uart.read()
    else:
        time.sleep_ms(1)

print("UART echo: sent", MESSAGE, "received", received)
if received == MESSAGE:
    indicator.on()    # GP7 on = the complete round trip worked
