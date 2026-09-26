from machine import Pin, I2C
import time

# Trois peripheriques d'echo sur le MEME bus, aux adresses 0x10, 0x11 et 0x12
# (Examples.I2c.MultiDevice). Le script les retrouve par scan(), ecrit a chacun
# une trame de longueur differente, puis les relit un par un : chacun ne doit
# rendre que ce qui lui a ete ecrit (pas de diaphonie). Une adresse absente
# (0x20) doit lever OSError(EIO). GP7 s'allume si tout est conforme.
#
# 400 kHz (Fast-mode, valeur par defaut du RP2040) : un bit dure 2,5 us.
MESSAGES = {0x10: b'un', 0x11: b'deux!', 0x12: b'trois..'}
ABSENTE = 0x20

temoin = Pin(7, Pin.OUT)
i2c = I2C(0, scl=Pin(4), sda=Pin(5), freq=400000)

time.sleep_ms(1)

ok = True
trouves = i2c.scan()
print("I2C multi : scan ->", [hex(a) for a in trouves])
ok = ok and trouves == sorted(MESSAGES)

for adresse, message in MESSAGES.items():
    i2c.writeto(adresse, message)

for adresse, message in MESSAGES.items():
    relu = i2c.readfrom(adresse, len(message))
    print("I2C multi :", hex(adresse), "relu", relu)
    ok = ok and relu == message

try:
    i2c.writeto(ABSENTE, b'?')
    print("I2C multi : ERREUR, l'adresse absente a repondu")
    ok = False
except OSError as e:
    print("I2C multi : adresse absente", hex(ABSENTE), "->", e)
    ok = ok and e.errno == 5      # EIO : adresse non acquittee

if ok:
    temoin.on()
