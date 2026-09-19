from machine import Pin
import time

led = Pin(7, Pin.OUT)

while True:
    led.on()
    print("On")
    time.sleep(1)
    led.off()
    print("Off")
    time.sleep(1)
