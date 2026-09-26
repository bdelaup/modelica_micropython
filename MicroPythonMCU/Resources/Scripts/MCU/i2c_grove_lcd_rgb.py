import time
from driver_grove_lcd_rgb import GroveLcd_RGB

if __name__ == '__main__':

    lcd = GroveLcd_RGB()
    while True:
        # affichage
        lcd.clear()
        lcd.setCursor(2, 0)
        lcd.write('hello World')

        # couleur
        lcd.color(255, 0, 0)
        time.sleep_ms(500)
        lcd.color(0, 255, 0)
        time.sleep_ms(500)
        lcd.color(0, 0, 255)
        time.sleep_ms(500)

