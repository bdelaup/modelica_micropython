# Raw readings of an HX711 with the robert-hh driver (hx711_gpio.py, placed next to this file).
# Wiring: PD_SCK on GP6, DOUT on GP7. Results on the Display(0) display.
from machine import Pin, Display
from hx711_gpio import HX711
import time

disp = Display(0)
disp.write("HX711: starting")

# The constructor sets the gain (128 by default) and takes two readings: it
# therefore waits for the first data, 400 ms after power-up.
hx = HX711(Pin(6, Pin.OUT), Pin(7, Pin.IN, pull=Pin.PULL_DOWN))

# 1) Raw reading, channel A, gain 128
raw128 = hx.read()
print("gain 128:", raw128)

# 2) Gain 64: set_gain() sends 27 pulses, the NEXT conversion is at gain 64
hx.set_gain(64)
raw64 = hx.read()
print("gain 64: ", raw64)
disp.write("128:%d 64:%d" % (raw128, raw64))

# 3) Power-down: PD_SCK held high for more than 60 us. On wake-up, the HX711
#    restarts at gain 128; the driver, still at gain 64, therefore gets a gain 128 reading.
hx.power_down()
time.sleep_ms(200)
hx.power_up()
raw_up = hx.read()
print("wake-up: ", raw_up)
disp.write("wakeup:%d" % raw_up)
