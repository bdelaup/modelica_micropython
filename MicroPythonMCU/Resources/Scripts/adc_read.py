from machine import ADC, Pin
import time

adc = ADC(1)
led_pin = Pin(0, Pin.OUT)

while True:
    v = adc.read_u16()
    led_pin.value(1 if v > 32768 else 0)
    time.sleep(0.2)
