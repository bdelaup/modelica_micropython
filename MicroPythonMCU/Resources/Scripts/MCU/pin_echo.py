from machine import Pin
import time

PERIOD = 0.3  # seconds; toggling of GP1, slow enough to stay visible

pin1 = Pin(1, Pin.OUT)
pin2 = Pin(2, Pin.IN)
pin3 = Pin(3, Pin.OUT)

while True:
    pin1.on()
    time.sleep_ms(1)               # forces a Modelica round trip before reading GP2 back (see the user guide, page "machine / time API")
    pin3.value(pin2.value())
    time.sleep(PERIOD)
    pin1.off()
    time.sleep_ms(1)
    pin3.value(pin2.value())
    time.sleep(PERIOD)
