from machine import Pin, I2C
import time

# Same bus as Examples.I2c.MultiDevice, but NO component carries the
# pull-up resistors (Examples.I2c.NoPullUp). When released, the lines do not
# go back up: the master notices it at the START and raises OSError(ETIMEDOUT),
# and scan() finds nobody - as on a real circuit where the resistors were
# forgotten. GP7 lights up if these two symptoms are indeed observed.
indicator = Pin(7, Pin.OUT)
i2c = I2C(0, scl=Pin(4), sda=Pin(5), freq=400000)

time.sleep_ms(1)

ok = True
try:
    i2c.writeto(0x10, b'up')
    print("I2C without pull-ups: ERROR, the write succeeded")
    ok = False
except OSError as e:
    print("I2C without pull-ups: writeto ->", e)
    ok = ok and e.errno == 110    # ETIMEDOUT: line stuck low

found = i2c.scan()
print("I2C without pull-ups: scan ->", found)
ok = ok and found == []

if ok:
    indicator.on()
