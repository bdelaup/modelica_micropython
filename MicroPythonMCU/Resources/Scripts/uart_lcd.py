from machine import Pin, UART
import time

# Afficheur serie 20x2 (Peripherals.UartLcd20x2) : on lui ecrit du texte ligne
# par ligne sur une vraie liaison serie. C'est le saut de ligne qui valide la
# ligne et declenche l'affichage, exactement comme le terminateur d'une commande.
#
# A comparer avec Examples.DisplayDemo, qui fait la meme chose a travers la
# liaison logique machine.Display : la livraison y est instantanee, ici le texte
# met un temps reel a traverser le fil (1,04 ms par caractere a 9600 bauds).
BAUD = 9600

uart = UART(0, baudrate=BAUD, tx=Pin(5), rx=Pin(4))

time.sleep_ms(5)
uart.write(b'Cuve 3   45.2 degC\n')
time.sleep_ms(60)          # laisse la ligne finir de traverser le fil
uart.write(b'Debit    12.8 L-min\n')
time.sleep_ms(60)

print("LCD : deux lignes envoyees")
