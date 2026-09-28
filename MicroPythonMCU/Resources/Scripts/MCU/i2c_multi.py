from machine import Pin, I2C
import time

# Three echo peripherals on the SAME bus, at addresses 0x10, 0x11 and 0x12
# (Examples.I2c.MultiDevice). The script finds them with scan(), writes to each
# a frame of a different length, then reads them back one by one: each one must
# return only what was written to it (no crosstalk). A missing address
# (0x20) must raise OSError(EIO). GP7 lights up if everything is as expected.
#
# 400 kHz (Fast-mode, default value of the RP2040): a bit lasts 2.5 us.
MESSAGES = {0x10: b'up', 0x11: b'down!', 0x12: b'three..'}
MISSING = 0x20

indicator = Pin(7, Pin.OUT)
i2c = I2C(0, scl=Pin(4), sda=Pin(5), freq=400000)

time.sleep_ms(1)

ok = True
found = i2c.scan()
print("I2C multi: scan ->", [hex(a) for a in found])
ok = ok and found == sorted(MESSAGES)

for address, message in MESSAGES.items():
    i2c.writeto(address, message)

for address, message in MESSAGES.items():
    read_back = i2c.readfrom(address, len(message))
    print("I2C multi:", hex(address), "read back", read_back)
    ok = ok and read_back == message

try:
    i2c.writeto(MISSING, b'?')
    print("I2C multi: ERROR, the missing address answered")
    ok = False
except OSError as e:
    print("I2C multi: missing address", hex(MISSING), "->", e)
    ok = ok and e.errno == 5      # EIO: address not acknowledged

if ok:
    indicator.on()
