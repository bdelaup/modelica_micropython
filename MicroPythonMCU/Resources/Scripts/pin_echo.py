from machine import Pin
import time

PERIOD = 0.3  # secondes ; oscillation de GP1, assez lente pour rester visible

pin1 = Pin(1, Pin.OUT)
pin2 = Pin(2, Pin.IN)
pin3 = Pin(3, Pin.OUT)

while True:
    pin1.on()
    time.sleep_ms(1)               # force un aller-retour Modelica avant de relire GP2 (cf. requirements.md / docs/api-machine.md)
    pin3.value(pin2.value())
    time.sleep(PERIOD)
    pin1.off()
    time.sleep_ms(1)
    pin3.value(pin2.value())
    time.sleep(PERIOD)
