from machine import Pin
import time

led = Pin(0, Pin.OUT)
led.on()
time.sleep(1)
x = 1 / 0
led.off()
