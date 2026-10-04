# Scenario de verification n°60 : programme debogue par un client DAP
# (dap_client.py, qui joue VS Code). Le client pose un point d'arret sur la
# ligne marquee BREAK, lit count, fait un pas, attend, puis reprend.
from machine import Pin
import time

led = Pin(0, Pin.OUT)
count = 0
for i in range(5):
    count += 1  # BREAK
    led.toggle()
    print("count", count)
    time.sleep(0.1)
print("done")
