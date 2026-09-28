# Lectures brutes d'un HX711 avec le driver de robert-hh (hx711_gpio.py, pose a cote).
# Cablage : PD_SCK sur GP6, DOUT sur GP7. Resultats sur l'afficheur Display(0).
from machine import Pin, Display
from hx711_gpio import HX711
import time

disp = Display(0)
disp.write("HX711 : demarrage")

# Le constructeur regle le gain (128 par defaut) et fait deux lectures : il
# attend donc la premiere donnee, 400 ms apres la mise sous tension.
hx = HX711(Pin(6, Pin.OUT), Pin(7, Pin.IN, pull=Pin.PULL_DOWN))

# 1) Lecture brute, canal A, gain 128
raw128 = hx.read()
print("gain 128 :", raw128)

# 2) Gain 64 : set_gain() envoie 27 impulsions, la conversion SUIVANTE est a gain 64
hx.set_gain(64)
raw64 = hx.read()
print("gain 64  :", raw64)
disp.write("128:%d 64:%d" % (raw128, raw64))

# 3) Veille : PD_SCK maintenue haute plus de 60 us. Au reveil, le HX711 repart
#    a gain 128 ; le driver, reste a gain 64, recoit donc une mesure a gain 128.
hx.power_down()
time.sleep_ms(200)
hx.power_up()
raw_up = hx.read()
print("reveil   :", raw_up)
disp.write("reveil:%d" % raw_up)
