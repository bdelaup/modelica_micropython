# Scenario avec tables horaires (Lot 7) :
# - Bouton A presse a t=2s et t=5s (table horaire du modele)
# - Bouton B presse a t=3s (table horaire du modele)
# - Secousse accelX a t=1s (table horaire du modele)
# - Temperature monte de 27 a 35 degC sur 10s (table horaire)
# - Lumiere baisse de 200 a 50 sur 5s (table horaire)
# Le script reagit a chaque evenement et affiche l'etat sur la matrice.

from microbit import *
import time

count_a = 0
count_b = 0
last_shake = 0
last_temp = 0
last_light = 0

# Image de depart : coeur
display.show(Image.HEART)
sleep(500)

def show_status():
    """Affiche l'etat courant sur la matrice (scroll)."""
    msg = "A%d B%d T%d L%d" % (count_a, count_b, temperature(), display.read_light_level())
    display.scroll(msg, delay=80)

while True:
    # Bouton A : compte les presses
    if button_a.was_pressed():
        count_a += 1
        display.show(str(count_a))
        sleep(300)

    # Bouton B : remet le compteur a zero
    if button_b.was_pressed():
        count_b += 1
        count_a = 0
        display.show(Image.SAD)
        sleep(500)

    # Secousse detectee (accelX > 2 m/s^2)
    ax = accelerometer.get_x()
    if abs(ax) > 2000:  # mg
        now = running_time()
        if now - last_shake > 500:  # anti-rebond 500 ms
            last_shake = now
            display.show(Image.SURPRISED)
            sleep(400)

    # Temperature change
    t = temperature()
    if abs(t - last_temp) >= 2:
        last_temp = t
        display.scroll("T=%dC" % t, delay=100)

    # Lumiere change
    l = display.read_light_level()
    if abs(l - last_light) >= 30:
        last_light = l
        display.scroll("L=%d" % l, delay=100)

    sleep(100)
