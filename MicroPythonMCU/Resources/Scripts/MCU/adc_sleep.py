from machine import ADC, Pin
import time

# Une entree analogique qui traverse le seuil logique ne doit ni ecourter un
# sleep() en cours, ni declencher d'IRQ : ADC(0) coupe l'entree numerique de
# la broche, comme sur le RP2040. Les attentes sont mesurees a la microseconde
# (ticks_us), ce qui controle aussi la resolution de l'horloge simulee.
fronts = 0

def compte(pin):
    global fronts
    fronts += 1

Pin(0).irq(handler=compte, trigger=Pin.IRQ_RISING | Pin.IRQ_FALLING)
adc = ADC(0)
led = Pin(1, Pin.OUT)

durees = []
for i in range(5):
    debut = time.ticks_us()
    adc.read_u16()
    time.sleep(0.2)
    durees.append(time.ticks_diff(time.ticks_us(), debut))

debut = time.ticks_us()
time.sleep_us(250)          # sous la milliseconde : invisible pour ticks_ms()
court = time.ticks_diff(time.ticks_us(), debut)

ok = durees == [200000] * 5 and court == 250 and fronts == 0
print('durees des sleep(0.2) (us) :', durees, '- sleep_us(250) :', court, '- fronts vus par l\'IRQ :', fronts)
led.value(1 if ok else 0)
