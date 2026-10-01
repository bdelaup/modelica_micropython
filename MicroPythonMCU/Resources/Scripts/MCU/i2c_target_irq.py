# Board B of Examples.MultiMcu.I2cIrq: I2C target at address 0x43 that answers
# commands from an IRQ handler (no mem=). The controller writes a command, then
# reads the reply:
#   b'ID'  -> b'MCU-B'
#   b'CNT' -> one byte, number of commands received so far
# IRQ_END_WRITE: the command is complete, read it with readinto().
# IRQ_READ_REQ: the controller wants a byte and none is queued, write() the
# reply - it is sent at once, the simulation does not need clock stretching.
from machine import Pin, I2CTarget
import time

command = bytearray(8)
reply = b''
count = 0


def on_i2c(t):
    global reply, count
    flags = t.irq().flags()
    if flags & I2CTarget.IRQ_END_WRITE:
        cmd = bytes(command[:t.readinto(command)])
        count += 1
        if cmd == b'ID':
            reply = b'MCU-B'
        elif cmd == b'CNT':
            reply = bytes([count])
        else:
            reply = b'?'
        print('command', cmd, '-> reply', reply)
    if flags & I2CTarget.IRQ_READ_REQ:
        t.write(reply)


target = I2CTarget(0, 0x43, scl=Pin(4), sda=Pin(5))
target.irq(on_i2c, trigger=I2CTarget.IRQ_END_WRITE | I2CTarget.IRQ_READ_REQ, hard=True)

while True:
    time.sleep(1)
