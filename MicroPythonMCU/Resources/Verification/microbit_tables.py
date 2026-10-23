# Verification des tables horaires (Lot 7) :
# - Bouton A presse vers t=0,175 s et t=0,475 s (table horaire, rampe 0->1,
#   seuil du RealToBoolean franchi a mi-rampe)
# - Bouton B presse vers t=0,275 s (table horaire)
# - accelX secoue vers t=0,1 s (table : 0 -> 5 -> 0 m/s^2, pic ~510 mg)
# - temperature monte de 20 a 30 degC sur 1 s (table)
# - light baisse de 200 a 50 sur 0,5 s (table)
# Le script verifie chaque evenement et imprime des marqueurs lus par le .mos.

from microbit import *
import time

display.show(Image.HEART)
sleep(50)

count_a = 0
count_b = 0
shake_detected = False
temp_min = None
temp_max = None
light_min = None
light_max = None
temp_seen = []
light_seen = []

t0 = running_time()
while running_time() - t0 < 1100:  # 1100 ms pour voir la temperature atteindre 30 C
    if button_a.was_pressed():
        count_a += 1
        print("PRESS_A %d" % count_a)
    if button_b.was_pressed():
        count_b += 1
        print("PRESS_B %d" % count_b)
    ax = accelerometer.get_x()
    if abs(ax) > 300 and not shake_detected:  # 300 mg ~ 3 m/s^2, pic table a ~510 mg
        shake_detected = True
        print("SHAKE ax=%d mg" % ax)
    t = temperature()
    temp_min = t if temp_min is None else min(temp_min, t)
    temp_max = t if temp_max is None else max(temp_max, t)
    if not temp_seen or abs(t - temp_seen[-1]) >= 5:
        temp_seen.append(t)
        print("TEMP %d C" % t)
    l = display.read_light_level()
    light_min = l if light_min is None else min(light_min, l)
    light_max = l if light_max is None else max(light_max, l)
    if not light_seen or abs(l - light_seen[-1]) >= 30:
        light_seen.append(l)
        print("LIGHT %d" % l)
    sleep(10)

print("COUNTS a=%d b=%d" % (count_a, count_b))
print("SHAKE_DONE %s" % shake_detected)
print("TEMPS %s" % ",".join(str(t) for t in temp_seen))
print("LIGHTS %s" % ",".join(str(l) for l in light_seen))
# Verdicts : la rampe de temperature doit monter d'au moins 8 C et depasser
# 28 C ; la rampe de lumiere doit couvrir au moins 100 points entre ~200 et ~50.
temp_ok = temp_max - temp_min >= 8 and temp_max >= 28
light_ok = light_max - light_min >= 100 and light_max >= 180 and light_min <= 70
print("TEMP_RAMP %s (min=%d max=%d)" % ("ok" if temp_ok else "ko", temp_min, temp_max))
print("LIGHT_RAMP %s (min=%d max=%d)" % ("ok" if light_ok else "ko", light_min, light_max))
print("TABLES_DONE")
