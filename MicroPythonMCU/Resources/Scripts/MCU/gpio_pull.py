from machine import Pin
import time

# Internal pull resistors (Examples.Gpio.Pull): no external resistor on the
# buttons, the program switches on the pull resistors of the microcontroller.
# GP0: push button to GND, internal pull-up: reads 1 released, 0 pressed.
# GP3: push button to 3.3 V, internal pull-down: reads 0 released, 1 pressed.
# GP6 and GP7 light up while the GP0 and GP3 buttons are pressed.
# GP4: only a weak 1 MOhm resistor to 3.3 V outside. Its internal pull is
# switched by the program: none, then pull-down, then pull-up.
button_gnd = Pin(0, Pin.IN, Pin.PULL_UP)
button_vcc = Pin(3, Pin.IN, Pin.PULL_DOWN)
led_gnd = Pin(6, Pin.OUT)
led_vcc = Pin(7, Pin.OUT)
weak = Pin(4, Pin.IN)


def follow(ms):
    t0 = time.ticks_ms()
    while time.ticks_diff(time.ticks_ms(), t0) < ms:
        led_gnd.value(not button_gnd.value())
        led_vcc.value(button_vcc.value())
        time.sleep_ms(5)


follow(300)
print("GP4 without pull (high impedance, the 1 MOhm wins):", weak.value())
weak.init(Pin.IN, Pin.PULL_DOWN)
follow(300)
print("GP4 with the internal pull-down (50 kOhm beats 1 MOhm):", weak.value())
weak.init(Pin.IN, Pin.PULL_UP)
follow(400)
print("GP4 with the internal pull-up:", weak.value())
