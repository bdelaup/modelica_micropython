from machine import Pin, I2C
import time

# Dialogue with an I2C echo peripheral (Peripherals.I2cEchoDevice, address
# 0x42): a multi-byte frame is written to it, read back, then a
# "register" is read behind a repeated START (readfrom_mem). The LED of GP7 lights up if
# everything is as expected.
#
# At 100 kHz, a bit lasts 10 us: the 9-byte frame (plus the address) lasts
# about 0.1 ms. writeto() and readfrom() are BLOCKING, as on the real
# hardware: the script resumes when the sequence is over on the bus.
ADDRESS = 0x42
MESSAGE = b'Hello I2C'

indicator = Pin(7, Pin.OUT)
i2c = I2C(0, scl=Pin(4), sda=Pin(5), freq=100000)

time.sleep_ms(1)      # shows the idle bus (both lines high)

ok = True
acked = i2c.writeto(ADDRESS, MESSAGE)
print("I2C echo: wrote", MESSAGE, "-", acked, "bytes acknowledged")
ok = ok and acked == len(MESSAGE)

read_back = i2c.readfrom(ADDRESS, len(MESSAGE))
print("I2C echo: read back", read_back)
ok = ok and read_back == MESSAGE

register = i2c.readfrom_mem(ADDRESS, 0x5A, 1)
print("I2C echo: readfrom_mem(0x5A) ->", register)
ok = ok and register == b'\x5a'

if ok:
    indicator.on()    # LED of GP7 on = the three exchanges are as expected
