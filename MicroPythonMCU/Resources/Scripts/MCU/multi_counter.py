# Program run by BOTH microcontrollers of Examples.MultiMcu.Independent.
# Each one must see its own copy of everything: the globals of the program,
# the imported modules (multi_counter_lib and its counter), machine and time.
from machine import Pin
import time
import multi_counter_lib as lib

already_ran = 'RUNS' in globals()   # a shared namespace would show the other run
RUNS = 1

led = Pin(0, Pin.OUT)       # blinks with this board's own ticks
isolated_led = Pin(1, Pin.OUT)

for i in range(5):
    n = lib.tick()
    led.value(n % 2)
    time.sleep(0.1)

isolated = lib.count == 5 and not already_ran
isolated_led.value(1 if isolated else 0)
print('ticks counted by this microcontroller:', lib.count, '- isolated' if isolated else '- SHARED STATE')
