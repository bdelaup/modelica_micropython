from machine import Pin
import time

led = Pin(0, Pin.OUT)
btn = Pin(1, Pin.IN)

led.off()
time.sleep(3600)
print("reveil, GP1 =", btn.value())
led.on()
time.sleep(3600)
