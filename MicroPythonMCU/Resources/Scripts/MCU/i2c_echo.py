from machine import Pin, I2C
import time

# Dialogue avec un peripherique I2C d'echo (Peripherals.I2cEchoDevice, adresse
# 0x42) : on lui ecrit une trame de plusieurs octets, on la relit, puis on lit un
# "registre" derriere un START repete (readfrom_mem). La LED de GP7 s'allume si tout est
# conforme.
#
# A 100 kHz, un bit dure 10 us : la trame de 9 octets (plus l'adresse) dure
# environ 0,1 ms. writeto() et readfrom() sont BLOQUANTS, comme sur le vrai
# materiel : le script reprend la main quand la sequence est finie sur le bus.
ADRESSE = 0x42
MESSAGE = b'Hello I2C'

temoin = Pin(7, Pin.OUT)
i2c = I2C(0, scl=Pin(4), sda=Pin(5), freq=100000)

time.sleep_ms(1)      # laisse voir le bus au repos (deux lignes hautes)

ok = True
acquittes = i2c.writeto(ADRESSE, MESSAGE)
print("I2C echo : ecrit", MESSAGE, "-", acquittes, "octets acquittes")
ok = ok and acquittes == len(MESSAGE)

relu = i2c.readfrom(ADRESSE, len(MESSAGE))
print("I2C echo : relu", relu)
ok = ok and relu == MESSAGE

registre = i2c.readfrom_mem(ADRESSE, 0x5A, 1)
print("I2C echo : readfrom_mem(0x5A) ->", registre)
ok = ok and registre == b'\x5a'

if ok:
    temoin.on()       # LED de GP7 allumee = les trois echanges sont conformes
