from machine import Pin
import time

red = Pin(17, Pin.OUT)
green = Pin(16, Pin.OUT)
blue = Pin(25, Pin.OUT)
external = Pin(0, Pin.OUT)
channels = (red, green, blue)

for channel in channels:
    channel.value(1)
external.value(0)

while True:
    for selected, channel in enumerate(channels):
        for index, output in enumerate(channels):
            output.value(0 if index == selected else 1)
        external.toggle()
        print(("red", "green", "blue")[selected])
        time.sleep_ms(200)
