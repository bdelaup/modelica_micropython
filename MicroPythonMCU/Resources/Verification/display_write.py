# Scenario 70 : Display.write() comme print() et ecriture a t = 0, plus
# Timer(...) construit avec les arguments de init().
from machine import Display, Timer
import time

d = Display(0)
# Avant le premier sleep : t = 0, pendant l'initialisation de la simulation.
d.write("Zero")

ticks = 0
def tick(t):
    global ticks
    ticks += 1

shots = 0
def shot(t):
    global shots
    shots += 1

periodic = Timer(period=10, mode=Timer.PERIODIC, callback=tick)
one_shot = Timer(mode=Timer.ONE_SHOT, freq=20, callback=shot)

time.sleep(0.105)
periodic.deinit()
print("timer ticks", ticks, "shots", shots)

d.write("T =", 25, end="")   # ligne en attente de son '\n'
d.write(" C")                # -> "T = 25 C"
d.write("a", "b", sep="-")   # -> "a-b"
d.write("L1\nL2")            # -> deux lignes
time.sleep(0.1)
