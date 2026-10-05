# ---------------------------------------------------------------------------
# Program of Examples.Pico.PowerUp (Raspberry Pi Pico board on a ramping
# VSYS supply).
#
# What it does: as soon as the board is supplied, it prints the time since
# power-on - time.ticks_ms() counts from the start of the board, not from the
# start of the simulation - then toggles GP15 every 100 ms. When VSYS falls
# below the undervoltage lockout of the regulator, the board stops: the
# program is interrupted and the pins are released (warning in the log).
# ---------------------------------------------------------------------------
from machine import Pin
import time

print("power-on, ticks_ms() =", time.ticks_ms())
ext = Pin(15, Pin.OUT)
n = 0
while True:
    ext.value(n % 2)
    n += 1
    time.sleep_ms(100)
