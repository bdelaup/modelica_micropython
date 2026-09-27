# Scenario de verification 28 : cout temporel des acces GPIO (MCU.gpioOpTime).
# Chaque etape demarre a un instant absolu, pour que le .mos sache ou regarder.
from machine import Pin, Display, disable_irq, enable_irq, idle
import time

def until_ms(ms):
    # un sleep() est ecourte par une transition d'entree : on reboucle jusqu'a l'heure
    while time.ticks_us() < ms * 1000:
        time.sleep_us(ms * 1000 - time.ticks_us())

out = Pin(0, Pin.OUT)
inp = Pin(1, Pin.IN)
flag = Pin(2, Pin.OUT)
irq_in = Pin(3, Pin.IN)
irq_out = Pin(4, Pin.OUT)
disp = Display(0)

# 1) on() puis off() sans sleep : une impulsion de largeur gpioOpTime, a t = 100 ms
until_ms(100)
out.on()
out.off()

# 2) rafale de 10 impulsions par l'appel direct pin(x) ; 20 ecritures = 20 x gpioOpTime
until_ms(200)
t0 = time.ticks_us()
for _ in range(10):
    out(1)
    out(0)
dt = time.ticks_diff(time.ticks_us(), t0)

# 3) attente active sans sleep : le temps avance a chaque lecture, le front
#    d'entree (t = 300 ms) finit par etre vu
until_ms(280)
while not inp():
    pass
flag.on()

# 4) IRQ masquee pendant le front de GP3 (t = 450 ms) : le callback attend enable_irq()
def on_rise(p):
    irq_out.on()

irq_in.irq(handler=on_rise, trigger=Pin.IRQ_RISING)
until_ms(400)
state = disable_irq()
until_ms(500)
enable_irq(state)

# 5) idle() : rend la main a la milliseconde ronde suivante
time.sleep_us(250)
idle()
t_idle = time.ticks_us()

disp.write("dt=%d id=%d" % (dt, t_idle % 1000))
