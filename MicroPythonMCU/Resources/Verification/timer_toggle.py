from machine import Pin, Timer
import time

led0 = Pin(0, Pin.OUT)


def on_tick(t):
    led0.toggle()


tim = Timer()
tim.init(period=500, mode=Timer.PERIODIC, callback=on_tick)

time.sleep(3600)
