from machine import Pin, PWM

pwm = PWM(Pin(0))
pwm.freq(200)
pwm.duty_u16(19661)  # ~30% de 65535

# Rien d'autre a faire : une fois configure, le PWM tourne en continu cote
# Modelica (comme le vrai peripherique materiel du RP2040), sans avoir besoin
# que le script reste actif ou rappelle le shim.
