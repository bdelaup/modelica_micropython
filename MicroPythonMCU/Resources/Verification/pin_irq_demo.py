from machine import Pin
import time

led0 = Pin(0, Pin.OUT)
btn = Pin(1, Pin.IN)


def on_rise(pin):
    led0.toggle()


btn.irq(handler=on_rise, trigger=Pin.IRQ_RISING)

while True:
    time.sleep(3600)
