from machine import Pin
import time

led = Pin(0, Pin.OUT)
led.off()
time.sleep(3600)
led.on()
time.sleep(3600)
led.off()
