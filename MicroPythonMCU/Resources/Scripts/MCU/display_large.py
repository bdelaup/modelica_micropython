# Sends 10 numbered messages to machine.Display(0), one every 100 ms.
# Every display connected to Display0 receives them: the 20x2 Display keeps the
# last two, the large screens fill line after line, then scroll.
from machine import Display
import time

display = Display(0)

for i in range(1, 11):
    time.sleep_ms(100)
    if i == 5:
        display.write("Message 5 is too long for 32 columns: cut on the icon")
    else:
        display.write("Message %d at %d ms" % (i, time.ticks_ms()))
    print("message", i, "sent")
