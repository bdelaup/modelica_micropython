from machine import Pin, I2C
import time

# Meme bus que Examples.I2c.MultiDevice, mais AUCUN composant ne porte les
# resistances de tirage (Examples.I2c.NoPullUp). Relachees, les lignes ne
# remontent pas : le maitre le constate des le START et leve OSError(ETIMEDOUT),
# et scan() ne trouve personne - comme sur un vrai montage ou l'on a oublie les
# resistances. GP7 s'allume si ces deux symptomes sont bien observes.
temoin = Pin(7, Pin.OUT)
i2c = I2C(0, scl=Pin(4), sda=Pin(5), freq=400000)

time.sleep_ms(1)

ok = True
try:
    i2c.writeto(0x10, b'un')
    print("I2C sans tirage : ERREUR, l'ecriture a abouti")
    ok = False
except OSError as e:
    print("I2C sans tirage : writeto ->", e)
    ok = ok and e.errno == 110    # ETIMEDOUT : ligne restee basse

trouves = i2c.scan()
print("I2C sans tirage : scan ->", trouves)
ok = ok and trouves == []

if ok:
    temoin.on()
