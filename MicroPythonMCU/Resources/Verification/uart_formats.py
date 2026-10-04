# Scenario de verification n°46 : les 24 formats de trame du port rp2 (bits
# 5-8, parite aucune/paire/impaire, 1 ou 2 stops), en bouclage TX -> RX
# (Examples.Uart.Loopback, GP0 -> GP1). Pour chaque format, 16 octets sont
# emis puis relus ; avec moins de 8 bits, seuls les bits de poids faible
# voyagent (octet attendu = octet & masque), comme sur le materiel. GP3
# s'allume si les 24 formats passent et si les formats invalides sont refuses.
from machine import Pin, UART
import time

BAUD = 9600
PAYLOAD = bytes(range(0, 256, 17))  # 16 octets, de 0x00 a 0xFF

led = Pin(3, Pin.OUT)
uart = UART(0, baudrate=BAUD, tx=Pin(0), rx=Pin(1))
time.sleep_ms(2)

ok = 0
for bits in (5, 6, 7, 8):
    for parity in (None, 0, 1):
        for stop in (1, 2):
            uart.init(baudrate=BAUD, bits=bits, parity=parity, stop=stop, tx=Pin(0), rx=Pin(1))
            time.sleep_ms(1)
            uart.write(PAYLOAD)
            frame_bits = 1 + bits + (parity is not None) + stop
            time.sleep_us(int(len(PAYLOAD) * frame_bits * 1e6 / BAUD) + 1000)
            got = uart.read() or b''
            mask = (1 << bits) - 1
            want = bytes(b & mask for b in PAYLOAD)
            if got == want:
                ok += 1
            else:
                print("format", bits, parity, stop, "FAILED: got", got, "want", want)

refused = 0
for kw in ({'bits': 9}, {'parity': 2}, {'stop': 3}):
    try:
        UART(0, baudrate=BAUD, tx=Pin(0), rx=Pin(1), **kw)
    except ValueError:
        refused += 1

print("formats ok:", ok, "/ 24, invalid refused:", refused, "/ 3")
if ok == 24 and refused == 3:
    led.on()
