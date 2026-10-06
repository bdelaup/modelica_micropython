# Scenario 69 : broches GND masquees (useGroundPin = false) sur le MCU et les
# peripheriques, references a la masse de la simulation. TX GP0 -> RX de
# l'appareil d'echo, TX de l'appareil -> RX GP1 ; bus I2C SCL GP2, SDA GP3 ;
# LED temoin sur GP7, allumee si l'echo serie et l'echo I2C sont corrects.
from machine import Pin, UART, I2C
import time

indicator = Pin(7, Pin.OUT)
u = UART(0, baudrate=9600, tx=Pin(0), rx=Pin(1))
i2c = I2C(0, scl=Pin(2), sda=Pin(3), freq=100000)
time.sleep_ms(5)
u.write(b"OK\n")
time.sleep_ms(20)
echo = u.read()
print("echo", echo)
acked = i2c.writeto(0x42, b"GND")
back = i2c.readfrom(0x42, 3)
print("i2c", acked, back)
if echo == b"OK\n" and acked == 3 and back == b"GND":
    indicator.on()
