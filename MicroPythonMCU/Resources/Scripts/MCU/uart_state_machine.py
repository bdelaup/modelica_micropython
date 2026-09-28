from machine import Pin, UART
import time

# Microcontroller program for Examples.Uart.StateMachinePy: it runs a
# scenario of commands and checks that the device answers according to its STATE,
# and not only according to the command received.
#
#   READ   -> ERR   (the device is stopped)
#   START  -> OK
#   READ   -> VAL=... N=1
#   READ   -> VAL=... N=2
#   START  -> ERR   (already started)
#   STOP   -> OK
#   READ   -> ERR   (stopped again)
BAUD = 9600
TIMEOUT_MS = 200

indicator = Pin(7, Pin.OUT)
uart = UART(0, baudrate=BAUD, tx=Pin(5), rx=Pin(4))


def request(command):
    uart.write(command + b'\n')
    line = b''
    deadline = time.ticks_ms() + TIMEOUT_MS
    while time.ticks_diff(deadline, time.ticks_ms()) > 0:
        if uart.any():
            line += uart.read()
            if line.endswith(b'\n'):
                return line.strip()
        else:
            time.sleep_ms(1)
    return line.strip()


time.sleep_ms(10)
r = [request(b'READ'), request(b'START'), request(b'READ'), request(b'READ')]
time.sleep_ms(100)          # the device stays running: observable window on valueOut[1]
r += [request(b'START'), request(b'STOP'), request(b'READ')]

for c, rep in zip([b'READ', b'START', b'READ', b'READ', b'START', b'STOP', b'READ'], r):
    print(c, '->', rep)

expected = (r[0].startswith(b'ERR') and r[1] == b'OK'
            and r[2].startswith(b'VAL=') and r[2].endswith(b'N=1')
            and r[3].startswith(b'VAL=') and r[3].endswith(b'N=2')
            and r[4].startswith(b'ERR') and r[5] == b'OK' and r[6].startswith(b'ERR'))
if expected:
    indicator.on()  # GP7 high = each reply matches the expected state of the device
