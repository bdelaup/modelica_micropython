from machine import Pin
import time

# Ordre physique des broches en suivant les LED disposees en anneau autour
# du microcontroleur dans LedChaser.mo (descend a gauche GP0->GP3, remonte
# a droite GP7->GP4) : deux voisins consecutifs dans cette liste sont aussi
# des voisins visuels sur le schema.
order = [0, 1, 2, 3, 7, 6, 5, 4]
pins = {i: Pin(i, Pin.OUT) for i in order}
for p in pins.values():
    p.off()

i = 0
direction = 1
while True:
    pins[order[i]].on()
    time.sleep(0.15)
    pins[order[i]].off()
    if i == len(order) - 1:
        direction = -1
    elif i == 0:
        direction = 1
    i += direction
