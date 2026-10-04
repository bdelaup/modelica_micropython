from machine import Pin, Timer
import time

# Program to debug step by step with VS Code (Examples.Program.Debug).
# Put a breakpoint on a line below (click left of its number), then
# watch count, presses and the LEDs: while the program is paused,
# simulated time is frozen.

led = Pin(0, Pin.OUT)          # GP0: toggled by the main loop
tick_led = Pin(1, Pin.OUT)     # GP1: toggled by the timer callback
button = Pin(2, Pin.IN, Pin.PULL_UP)

presses = 0


def on_tick(timer):
    # A breakpoint here stops in the timer callback.
    tick_led.toggle()


timer = Timer()
timer.init(period=250, mode=Timer.PERIODIC, callback=on_tick)

count = 0
while count < 20:
    count += 1
    led.toggle()
    if button.value() == 0:
        presses += 1
        print('button pressed, count =', count)
    time.sleep(0.1)

timer.deinit()
print('done:', count, 'loops,', presses, 'with the button pressed')
