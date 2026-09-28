# Verification scenario 28: time cost of GPIO accesses (MCU.gpioOpTime).
# Each step starts at an absolute instant, so that the .mos knows where to look.
from machine import Pin, Display, disable_irq, enable_irq, idle
import time

def until_ms(ms):
    # a sleep() is shortened by an input transition: loop again until the time is reached
    while time.ticks_us() < ms * 1000:
        time.sleep_us(ms * 1000 - time.ticks_us())

out = Pin(0, Pin.OUT)
inp = Pin(1, Pin.IN)
flag = Pin(2, Pin.OUT)
irq_in = Pin(3, Pin.IN)
irq_out = Pin(4, Pin.OUT)
disp = Display(0)

# 1) on() then off() without sleep: a pulse of width gpioOpTime, at t = 100 ms
until_ms(100)
out.on()
out.off()

# 2) burst of 10 pulses through the direct call pin(x); 20 writes = 20 x gpioOpTime
until_ms(200)
t0 = time.ticks_us()
for _ in range(10):
    out(1)
    out(0)
dt = time.ticks_diff(time.ticks_us(), t0)

# 3) busy wait without sleep: time moves forward at each read, the input
#    edge (t = 300 ms) is eventually seen
until_ms(280)
while not inp():
    pass
flag.on()

# 4) IRQ masked during the edge of GP3 (t = 450 ms): the callback waits for enable_irq()
def on_rise(p):
    irq_out.on()

irq_in.irq(handler=on_rise, trigger=Pin.IRQ_RISING)
until_ms(400)
state = disable_irq()
until_ms(500)
enable_irq(state)

# 5) idle(): returns at the next whole millisecond
time.sleep_us(250)
idle()
t_idle = time.ticks_us()

disp.write("dt=%d id=%d" % (dt, t_idle % 1000))
