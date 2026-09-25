from machine import Pin
import companion
import shared_helper

pin0 = Pin(0, Pin.OUT)
pin1 = Pin(1, Pin.OUT)

pin0.value(1 if companion.check() else 0)
pin1.value(1 if shared_helper.check() else 0)

print("Companion :", companion.check())
print("shared_helper :", shared_helper.check())
