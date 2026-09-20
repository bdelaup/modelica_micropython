from machine import Pin
import time

led = Pin("LED", Pin.OUT)
led.on()
adc = ADC(0)

while True:
    print(adc.read_u16())
    led.toggle()
    time.sleep(0.5)
    print(adc.read_u16())
    led.toggle()
    time.sleep(0.5)
