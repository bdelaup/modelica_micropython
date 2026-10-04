from machine import Pin, UART
import time

# Frame format other than 8N1: 8 data bits, EVEN parity, 2 stop bits (8E2).
# The external device (Peripherals.UartEchoDevice) must be configured the same
# way (echo.dataBits, echo.parity, echo.stopBits), as on a real circuit.
#
# At 1200 baud a bit lasts 833 us; an 8E2 frame has 12 bits (start, 8 data,
# parity, 2 stops) and lasts 10 ms instead of 8.3 ms in 8N1. The parity bit makes
# the total number of 1 bits (data + parity) even: 'H' = 0x48 has two 1 bits,
# so its parity bit is 0.
#
# In Examples.Uart.FormatMismatch the device uses ODD parity instead: every byte
# then arrives with a wrong parity bit. It is still delivered (as on the RP2040),
# but each side logs a "parity error" warning - the first ten, then a total.
MESSAGE = b'Hello, parity!\n'
TIMEOUT_MS = 400
IDLE_MS = 5         # shows the idle state (high) before the first frame

indicator = Pin(7, Pin.OUT)
uart = UART(0, baudrate=1200, bits=8, parity=0, stop=2, tx=Pin(5), rx=Pin(4))
print(uart)

time.sleep_ms(IDLE_MS)
uart.write(MESSAGE)

received = b''
deadline = time.ticks_ms() + TIMEOUT_MS
while len(received) < len(MESSAGE) and time.ticks_diff(deadline, time.ticks_ms()) > 0:
    if uart.any():
        received += uart.read()
    else:
        time.sleep_ms(1)

print("UART format: sent", MESSAGE, "received", received)
if received == MESSAGE:
    indicator.on()    # GP7 on = the round trip worked
