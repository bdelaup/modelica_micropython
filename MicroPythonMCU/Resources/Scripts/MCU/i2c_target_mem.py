# Board B of Examples.MultiMcu.I2c: I2C target (slave) at address 0x42, seen by
# board A as a small memory. machine.I2CTarget with mem= answers the controller
# on its own, without any handler: the program only keeps the memory up to date.
# Register map: 0-1 = ADC reading of GP2 (big endian), 4 = LED on GP3.
from machine import Pin, ADC, I2CTarget
import time

mem = bytearray(8)
target = I2CTarget(0, 0x42, mem=mem, scl=Pin(4), sda=Pin(5))
adc = ADC(2)
led = Pin(3, Pin.OUT)

while True:
    raw = adc.read_u16()
    mem[0] = raw >> 8
    mem[1] = raw & 0xFF
    led.value(1 if mem[4] else 0)    # written by A through the bus
    time.sleep_ms(5)
