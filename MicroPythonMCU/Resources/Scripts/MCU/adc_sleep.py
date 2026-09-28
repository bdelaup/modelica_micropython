from machine import ADC, Pin
import time

# An analog input crossing the logic threshold must neither shorten a
# running sleep() nor trigger an IRQ: ADC(0) disconnects the digital input of
# the pin, as on the RP2040. The waits are measured to the microsecond
# (ticks_us), which also checks the resolution of the simulated clock.
edges = 0

def count(pin):
    global edges
    edges += 1

Pin(0).irq(handler=count, trigger=Pin.IRQ_RISING | Pin.IRQ_FALLING)
adc = ADC(0)
led = Pin(1, Pin.OUT)

durations = []
for i in range(5):
    start = time.ticks_us()
    adc.read_u16()
    time.sleep(0.2)
    durations.append(time.ticks_diff(time.ticks_us(), start))

start = time.ticks_us()
time.sleep_us(250)          # below the millisecond: invisible to ticks_ms()
short = time.ticks_diff(time.ticks_us(), start)

ok = durations == [200000] * 5 and short == 250 and edges == 0
print('durations of sleep(0.2) (us):', durations, '- sleep_us(250):', short, '- edges seen by the IRQ:', edges)
led.value(1 if ok else 0)
