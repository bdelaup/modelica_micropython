# (c) 2019 Christophe Gueneau
from machine import Pin, I2C
import time

i2c = I2C(scl=Pin(4), sda=Pin(5), freq=20000)      # crée un objet I2C

class GroveLcd_RGB():
    def __init__(self):

        # initialisation
        self.set_register(0x00, 0)
        self.set_register(0x01, 0)

        # toutes les Leds controllées par PWM
        self.set_register(0x08, 0xAA)

        # attente initialisation après mise sous tension
        time.sleep_ms(50)

        # envoi configuration afficheur 2 lignes
        self.cmd(0x20 | 0x04 | 0x08)
        time.sleep_us(4500)
        self.cmd(0x20 | 0x04 | 0x08)
        time.sleep_us(150)
        self.cmd(0x20 | 0x04 | 0x08)
        self.cmd(0x20 | 0x04 | 0x08)

        # allumage afficheur
        self.disp_ctrl = 0x04 | 0x00 | 0x00
        self.display1(True)
        self.clear()
        self.disp_mode = 0x02 | 0x00
        self.cmd(0x04 | self.disp_mode)

    def set_register(self, reg, val):
        val = bytes((reg, val))
        i2c.writeto(0x62, val)

    def color(self, r, g, b):
        self.set_register(0x04, r)
        self.set_register(0x03, g)
        self.set_register(0x02, b)

    def cmd(self, command):
        assert command >= 0 and command < 256
        val = bytes((0x80, command))
        i2c.writeto(0x3e, val)

    def write_char(self, c):
        assert c >= 0 and c < 256
        val = bytes((0x40, c))
        i2c.writeto(0x3e, val)

    def write(self, text):
        text = str(text)
        for char in text:
            self.write_char(ord(char))

    def setCursor(self, col, row):
        col = (col | 0x80) if row == 0 else (col | 0xc0)
        self.cmd(col)

    def display1(self, state):
        if state:
            self.disp_ctrl |= 0x04
            self.cmd(0x08  | self.disp_ctrl)
        else:
            self.disp_ctrl &= ~0x04
            self.cmd(0x08  | self.disp_ctrl)

    def clear(self):
        self.cmd(0x01)
        time.sleep_ms(2)



