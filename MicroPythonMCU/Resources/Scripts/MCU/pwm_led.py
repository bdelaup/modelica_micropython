from machine import Pin, PWM

pwm = PWM(Pin(0))
pwm.freq(200)
pwm.duty_u16(19661)  # ~30% of 65535

# Nothing else to do: once configured, the PWM runs continuously on the
# Modelica side (like the real hardware peripheral of the RP2040), without the
# script having to stay active or call the shim again.
