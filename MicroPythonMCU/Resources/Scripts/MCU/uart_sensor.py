from machine import Pin, UART
import time

# Request/response dialogue with an external serial sensor
# (Peripherals.UartTemperatureSensor). The sensor only speaks when it is
# asked, and it takes 5 ms to answer - so its reply must really be waited
# for, not assumed to have already arrived.
#
# 9600 baud: a byte lasts 1.04 ms, a complete round trip about thirty
# milliseconds. Fast enough to chain two measurements in a short simulation,
# slow enough to remain a real serial link.
BAUD = 9600
TIMEOUT_MS = 200

indicator = Pin(7, Pin.OUT)
uart = UART(0, baudrate=BAUD, tx=Pin(5), rx=Pin(4))


def request(command):
    """Sends a command and waits for the reply line (ending with \\n)."""
    uart.write(command)
    line = b''
    deadline = time.ticks_ms() + TIMEOUT_MS
    while time.ticks_diff(deadline, time.ticks_ms()) > 0:
        if uart.any():
            line += uart.read()
            if line.endswith(b'\n'):
                return line
        else:
            time.sleep_ms(1)
    return line


def value(reply):
    """Extracts the number from 'TEMP=23.4\\r\\n'."""
    try:
        return float(reply.split(b'=')[1].strip())
    except Exception:
        return None


time.sleep_ms(10)

identity = request(b'AT+ID\n')
r1 = request(b'AT+TEMP\n')
time.sleep_ms(100)            # the temperature rises meanwhile
r2 = request(b'AT+TEMP\n')

v1 = value(r1)
v2 = value(r2)
print("sensor:", identity, "measurements:", v1, v2)

# Setpoint sent back to the sensor: it republishes it on its real output valueOut,
# which can drive the rest of the model. This is what makes it an actuator.
uart.write(b'SET 42.5\n')
time.sleep_ms(50)

if v1 is not None and v2 is not None and v2 > v1:
    indicator.on()   # GP7 on = two valid measurements AND the temperature did rise
