from machine import Pin
import time

# Physical order of the pins, following the LEDs laid out in a ring around
# the microcontroller in Gpio/LedChaser.mo (down on the left GP0->GP3, up
# on the right GP7->GP4): two consecutive neighbours in this list are also
# visual neighbours on the schematic.
order = [0, 1, 2, 3, 7, 6, 5, 4]
pins = {i: Pin(i, Pin.OUT) for i in order}
for p in pins.values():
    p.off()

i = 0
direction = 1
while True:
    pins[order[i]].on()
    time.sleep(0.15)
    pins[order[i]].off()
    if i == len(order) - 1:
        direction = -1
    elif i == 0:
        direction = 1
    i += direction
