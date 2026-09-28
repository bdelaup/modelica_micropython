# Kitchen scale.
# Wiring: HX711 (PD_SCK on GP6, DOUT on GP7), Grove LCD RGB screen (I2C: SCL
# on GP4, SDA on GP5, imposed by the driver), TARE button on GP0 (pulled
# high, a press connects it to ground).
# Drivers placed next to this file, unmodified: hx711_gpio.py (robert-hh) and
# driver_grove_lcd_rgb.py.
from machine import Pin
from hx711_gpio import HX711
from driver_grove_lcd_rgb import GroveLcd_RGB

# Calibration: number of HX711 points per gram. In a lab session, it is measured
# by placing a known mass on the pan: 1000 g give 429,497 more points than
# empty, hence 429.497 points per gram.
POINTS_PER_GRAM = 429.497
CAPACITY_G = 5000

lcd = GroveLcd_RGB()
lcd.color(255, 255, 255)
lcd.setCursor(0, 1)
lcd.write("Scale 5 kg")

# Top line: a 9-character field. Only the characters that change are sent
# to the screen: each one costs an I2C transaction.
shown = " " * 9

def show(text):
    global shown
    text = "%9s" % text
    changed = [i for i in range(9) if text[i] != shown[i]]
    if changed:
        lcd.setCursor(changed[0], 0)
        lcd.write(text[changed[0]:changed[-1] + 1])
        shown = text

show("Tare...")
hx = HX711(Pin(6, Pin.OUT), Pin(7, Pin.IN, pull=Pin.PULL_DOWN))
hx.set_scale(POINTS_PER_GRAM)
hx.set_time_constant(0.5)   # low-pass filter of the driver: more responsive than the default 0.25
hx.tare(5)                  # the empty pan becomes the zero (average of 5 readings, 0.5 s)

tare_requested = False

def on_tare(pin):
    # Interrupt: only note the request, the tare is done in the loop
    global tare_requested
    tare_requested = True

button = Pin(0, Pin.IN, Pin.PULL_UP)
button.irq(handler=on_tare, trigger=Pin.IRQ_FALLING)

overload = False
while True:
    if tare_requested:
        tare_requested = False
        show("Tare...")
        hx.tare(5)

    grams = hx.get_units()      # one reading every 100 ms, filtered, minus the tare
    if grams > CAPACITY_G:
        show("OVERLOAD")
    else:
        show("%d g" % round(grams))

    if (grams > CAPACITY_G) != overload:
        overload = grams > CAPACITY_G
        if overload:
            lcd.color(255, 0, 0)
        else:
            lcd.color(255, 255, 255)
