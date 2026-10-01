# Board A of Examples.MultiMcu.I2c: I2C controller (master) of board B, which
# behaves as a memory device at address 0x42 (machine.I2CTarget with mem=).
# Register map of B: 0-1 = last ADC reading of B (big endian), 4 = LED of B.
from machine import Pin, I2C
import time

TARGET = 0x42

i2c = I2C(0, scl=Pin(4), sda=Pin(5), freq=100000)
ok_led = Pin(7, Pin.OUT)

time.sleep_ms(20)                    # B has started and taken its first reading
found = i2c.scan()
print('scan:', [hex(a) for a in found])

i2c.writeto_mem(TARGET, 4, b'\x01')  # register 4: switch the LED of B on
data = i2c.readfrom_mem(TARGET, 0, 2)
raw = data[0] << 8 | data[1]
volts = raw * 3.3 / 65535
print('voltage measured by B: %.3f V' % volts)

if found == [TARGET] and abs(volts - 2.0) < 0.05:
    ok_led.on()
