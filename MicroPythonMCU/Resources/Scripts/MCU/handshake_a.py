# Board A of Examples.MultiMcu.Handshake: request/acknowledge handshake with
# board B over two wires. A raises REQ (GP0), B answers on ACK (GP1) from a
# Pin.irq handler; A measures how long B took, then releases REQ and waits
# for ACK to fall. GP2 lights up once every round has been acknowledged.
from machine import Pin
import time

ROUNDS = 3
TIMEOUT_US = 20000

req = Pin(0, Pin.OUT)
ack = Pin(1, Pin.IN)
done = Pin(2, Pin.OUT)
req.off()


def wait_ack(level):
    # sleep_ms() returns early when an input changes: the latency measured is
    # the response time of B, not a multiple of the polling period.
    t0 = time.ticks_us()
    while ack.value() != level:
        if time.ticks_diff(time.ticks_us(), t0) > TIMEOUT_US:
            return None
        time.sleep_ms(1)
    return time.ticks_diff(time.ticks_us(), t0)


acknowledged = 0
for i in range(ROUNDS):
    time.sleep(0.02)
    req.on()
    up = wait_ack(1)
    time.sleep(0.03)
    req.off()
    down = wait_ack(0)
    print('round', i, '- ACK raised after', up, 'us, released after', down, 'us')
    if up is not None and down is not None:
        acknowledged += 1
    time.sleep(0.05)

print('rounds acknowledged:', acknowledged, '/', ROUNDS)
if acknowledged == ROUNDS:
    done.on()
