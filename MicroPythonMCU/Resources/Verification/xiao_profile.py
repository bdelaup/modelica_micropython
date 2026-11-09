from machine import ADC, I2C, Pin, UART


def check(label, operation):
    try:
        print(label, operation())
    except Exception as error:
        print(label, type(error).__name__, error)


print("D pins", [Pin(pin).id for pin in (26, 27, 28, 29, 6, 7, 0, 1, 2, 4, 3)])
print("ADC channels", [ADC(channel).id for channel in range(4)])
print("ADC temperature", ADC(ADC.CORE_TEMP).id)
uart = UART(0, baudrate=9600)
print("UART default", uart.tx, uart.rx)
i2c = I2C(1)
print("I2C default", i2c.id, i2c.scl, i2c.sda)
check("hidden GPIO", lambda: Pin(5, Pin.OUT))
