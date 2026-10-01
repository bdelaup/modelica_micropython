# Board A of Examples.MultiMcu.I2cIrq: sends commands to board B (I2C target at
# 0x43 answering from an IRQ handler) and checks the replies.
from machine import Pin, I2C
import time

TARGET = 0x43

i2c = I2C(0, scl=Pin(4), sda=Pin(5), freq=100000)
ok_led = Pin(7, Pin.OUT)


def ask(cmd, n):
    i2c.writeto(TARGET, cmd)
    return i2c.readfrom(TARGET, n)


time.sleep_ms(5)
ident = ask(b'ID', 5)
first = ask(b'CNT', 1)
second = ask(b'CNT', 1)
print('ID ->', ident, '/ CNT ->', first[0], 'then', second[0])

if ident == b'MCU-B' and first[0] == 2 and second[0] == 3:
    ok_led.on()
