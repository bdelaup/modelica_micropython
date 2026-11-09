from machine import ADC
import time

adc0 = ADC(0)
while True:
    print("D0 ADC(0) =", adc0.read_u16())
    time.sleep_ms(200)
