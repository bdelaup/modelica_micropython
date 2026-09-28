# Balance de cuisine.
# Cablage : HX711 (PD_SCK sur GP6, DOUT sur GP7), ecran Grove LCD RGB (I2C : SCL
# sur GP4, SDA sur GP5, imposes par le driver), bouton TARE sur GP0 (tire au
# niveau haut, un appui le met a la masse).
# Drivers poses a cote, sans modification : hx711_gpio.py (robert-hh) et
# driver_grove_lcd_rgb.py.
from machine import Pin
from hx711_gpio import HX711
from driver_grove_lcd_rgb import GroveLcd_RGB

# Etalonnage : nombre de points du HX711 par gramme. En TP, il se mesure en
# posant une masse connue sur le plateau : 1000 g donnent 429 497 points de plus
# qu'a vide, d'ou 429,497 points par gramme.
POINTS_PAR_GRAMME = 429.497
PORTEE_G = 5000

lcd = GroveLcd_RGB()
lcd.color(255, 255, 255)
lcd.setCursor(0, 1)
lcd.write("Balance 5 kg")

# Ligne du haut : un champ de 9 caracteres. Seuls les caracteres qui changent
# sont envoyes a l'ecran : chacun coute une transaction I2C.
affiche = " " * 9

def afficher(texte):
    global affiche
    texte = "%9s" % texte
    change = [i for i in range(9) if texte[i] != affiche[i]]
    if change:
        lcd.setCursor(change[0], 0)
        lcd.write(texte[change[0]:change[-1] + 1])
        affiche = texte

afficher("Tare...")
hx = HX711(Pin(6, Pin.OUT), Pin(7, Pin.IN, pull=Pin.PULL_DOWN))
hx.set_scale(POINTS_PAR_GRAMME)
hx.set_time_constant(0.5)   # filtre passe-bas du driver : plus reactif que 0,25 par defaut
hx.tare(5)                  # le plateau vide devient le zero (moyenne de 5 mesures, 0,5 s)

demande_tare = False

def appui_tare(pin):
    # Interruption : on note seulement la demande, la tare se fait dans la boucle
    global demande_tare
    demande_tare = True

bouton = Pin(0, Pin.IN, Pin.PULL_UP)
bouton.irq(handler=appui_tare, trigger=Pin.IRQ_FALLING)

surcharge = False
while True:
    if demande_tare:
        demande_tare = False
        afficher("Tare...")
        hx.tare(5)

    grammes = hx.get_units()    # une mesure toutes les 100 ms, filtree, moins la tare
    if grammes > PORTEE_G:
        afficher("SURCHARGE")
    else:
        afficher("%d g" % round(grammes))

    if (grammes > PORTEE_G) != surcharge:
        surcharge = grammes > PORTEE_G
        if surcharge:
            lcd.color(255, 0, 0)
        else:
            lcd.color(255, 255, 255)
