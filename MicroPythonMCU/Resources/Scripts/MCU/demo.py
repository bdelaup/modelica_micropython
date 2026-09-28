# ---------------------------------------------------------------------------
# Default script of the MCU model (scriptPath parameter).
#
# What it does: it blinks pin GP0 and the built-in LED at 0.5 Hz, on then
# off for one second each, forever.
#
# Why so short: it is the reference program of the library. Placing an MCU
# in a schematic and running the simulation without configuring anything must
# produce something observable right away - a square voltage on GP0 and the
# dot of the icon lighting up. It is also a starting point to copy when
# writing your own program.
#
# What it shows of the mechanism: the loop is INFINITE and the sleep() calls last
# one second, yet the simulation runs in a fraction of a second. The script's
# time is SIMULATED time, not real time: a sleep(1) hands control back to the
# solver, which jumps straight to the deadline. This is the whole point of the
# coupling - see the user guide, page "Getting started".
#
# Available API: machine.Pin / ADC / PWM / Timer / UART / I2C / Display and time,
# modelled on MicroPython (reference: Raspberry Pi Pico). See the user guide,
# page "machine / time API".
# ---------------------------------------------------------------------------
from machine import Pin
import time

led = Pin(0, Pin.OUT)
builtin = Pin(Pin.LED, Pin.OUT)

while True:
    led.on()
    builtin.on()
    time.sleep(1)
    led.off()
    builtin.off()
    time.sleep(1)
