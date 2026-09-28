from machine import Pin, UART
import time

# The peripheral speaks WITHOUT being asked (Peripherals.UartGpsModule,
# periodic transmission). The program therefore has nothing to send: it watches its
# serial input, splits the incoming NMEA sentences and checks their
# checksum - exactly what the embedded code of a GPS receiver would do.
#
# Reception never wakes the script up (no uart.irq() in v0): uart.any() must
# be polled in a loop, sleeping between two passes so as not to prevent
# simulated time from moving forward.
BAUD = 9600
WINDOW_MS = 500
EXPECTED = 4         # at one sentence every 100 ms, at least 4 must be validated

indicator = Pin(7, Pin.OUT)
uart = UART(0, baudrate=BAUD, tx=Pin(5), rx=Pin(4))


def nmea_valid(sentence):
    """'$<body>*<hh>': hh = exclusive OR of the body characters, in hex."""
    if not sentence.startswith(b'$') or b'*' not in sentence:
        return False
    body, checksum = sentence[1:].split(b'*', 1)
    x = 0
    for c in body:
        x ^= c
    return checksum[:2].upper() == b'%02X' % x


buffer = b''
sentences = []
deadline = time.ticks_ms() + WINDOW_MS
while time.ticks_diff(deadline, time.ticks_ms()) > 0:
    if uart.any():
        buffer += uart.read()
        while b'\n' in buffer:
            line, buffer = buffer.split(b'\n', 1)
            sentences.append(line.strip())
    else:
        time.sleep_ms(2)

valid = [s for s in sentences if nmea_valid(s)]
print("GPS:", len(sentences), "sentences received,", len(valid), "valid")
for s in sentences:
    print("   ", s)

if len(valid) >= EXPECTED:
    indicator.on()  # GP7 high = spontaneous stream at the right rate, correct checksums
