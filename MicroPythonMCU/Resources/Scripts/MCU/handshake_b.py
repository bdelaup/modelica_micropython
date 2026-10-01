# Board B of Examples.MultiMcu.Handshake: copies REQ (GP0, from board A) onto
# ACK (GP1, to board A) from a Pin.irq handler, while the main loop sleeps -
# the handler interrupts the sleep, as on the real board.
from machine import Pin
import time

req = Pin(0, Pin.IN)
ack = Pin(1, Pin.OUT)
ack.off()
edges = 0


def on_req(pin):
    global edges
    ack.value(pin.value())
    edges += 1


req.irq(handler=on_req, trigger=Pin.IRQ_RISING | Pin.IRQ_FALLING)

while True:
    time.sleep(1)
