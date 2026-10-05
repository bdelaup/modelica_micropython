# Scenario 67 : profil "pico" du shim sur RPi_Pico.
# GP0 (TX de UART(0) par defaut) est relie a GP1 (RX par defaut) dans le modele.
from machine import Pin, ADC, UART, I2C, SoftI2C
import time

def check(label, fn):
    try:
        fn()
        print(label, "ok")
    except Exception as e:
        print(label, type(e).__name__, e)

check("adc5", lambda: ADC(Pin(5)))                                  # pas d'ADC sur GP5
check("adc26", lambda: ADC(Pin(26)))                                 # ADC(0)
check("uart_bad_tx", lambda: UART(0, tx=Pin(4), rx=Pin(1)))          # GP4 = TX de UART(1)
check("i2c_bad_scl", lambda: I2C(0, scl=Pin(3), sda=Pin(4)))         # GP3 = SCL de I2C(1)
check("pin30", lambda: Pin(30, Pin.OUT))                             # pas de GPIO 30
check("uart2", lambda: UART(2))

u = UART(0, baudrate=9600)        # broches par defaut : TX GP0, RX GP1
check("uart1_busy", lambda: UART(1))
time.sleep_ms(2)                  # ligne au repos (haute) avant la premiere trame
u.write(b"hi")
time.sleep_ms(10)
print("loopback", u.read())

i = I2C(1, freq=100000)           # broches par defaut : SCL GP7, SDA GP6
print("i2c1 pins", i.scl, i.sda)
j = I2C(scl=Pin(19), sda=Pin(18)) # sans identifiant : celui des broches, I2C(1)
print("i2c id", j.id)
s = SoftI2C(scl=Pin(10), sda=Pin(11))   # n'importe quelles broches
print("soft pins", s.scl, s.sda)
print("adc4", ADC(ADC.CORE_TEMP).read_u16())
print("ticks", time.ticks_ms())
