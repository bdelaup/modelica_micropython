# ---------------------------------------------------------------------------
# Program of Examples.Pico.Blink (Raspberry Pi Pico board, supplied by USB).
#
# What it does: it blinks the on-board LED and an external LED on GP15
# (physical pin 20) at 0.5 Hz, and prints the supply voltage VSYS, read on
# ADC(3) through the VSYS/3 divider of the board, and the temperature of the
# RP2040, read on ADC(4) - the formulas of the RP2040 datasheet.
# ---------------------------------------------------------------------------
from machine import Pin, ADC
import time

led = Pin("LED", Pin.OUT)
ext = Pin(15, Pin.OUT)
vsys = ADC(3)                 # GPIO29: VSYS/3
sensor = ADC(ADC.CORE_TEMP)   # ADC(4): temperature sensor

while True:
    v = vsys.read_u16() * 3.3 / 65535 * 3
    t = 27 - (sensor.read_u16() * 3.3 / 65535 - 0.706) / 0.001721
    print("VSYS = %.2f V, temperature = %.1f C" % (v, t))
    led.on()
    ext.on()
    time.sleep(1)
    led.off()
    ext.off()
    time.sleep(1)
