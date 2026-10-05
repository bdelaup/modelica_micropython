# Scenario 68 : peripherique serie alimente par la broche 3V3(OUT) de la Pico
# (useSupplyPin). UART(0) par defaut : TX GP0 -> RX de l'appareil, TX de
# l'appareil -> RX GP1.
from machine import UART
import time

u = UART(0, baudrate=9600)
time.sleep_ms(5)
u.write(b"OK\n")
time.sleep_ms(20)
print("echo", u.read())
