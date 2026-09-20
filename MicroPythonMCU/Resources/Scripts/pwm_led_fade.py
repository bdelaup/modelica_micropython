from machine import Pin, PWM
from time import sleep

steps = 1000
ramp_duration = 1
step_time = ramp_duration/steps
pwm_max = 65536


pwm0 = PWM(Pin(0), freq=1000, duty_u16=0)

sleep(ramp_duration/2)
for step in range (steps):
    pwm = round(step/steps * 65536)
    pwm0.duty_u16(pwm) 
    sleep(step_time)

sleep(ramp_duration/2)
for step in range (steps):
    pwm = round(65536 * (1-step/steps))
    pwm0.duty_u16(pwm) 
    sleep(step_time)

pwm0.duty_u16(65536) 
pwm0.deinit() 
sleep(ramp_duration/2)
