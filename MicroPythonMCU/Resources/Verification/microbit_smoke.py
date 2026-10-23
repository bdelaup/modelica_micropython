# Programme du scenario de verification "microbit_smoke" : demarrage, capteurs,
# matrice LED multiplexee, display.off()/on(). Cf. verify_72_microbit_smoke.mos.
# NB : microbit.sleep() prend des millisecondes, comme sur la vraie carte.
from microbit import *

print('boot is_on', display.is_on())
print('accel', accelerometer.get_x(), accelerometer.get_y(), accelerometer.get_z())
print('gesture', accelerometer.current_gesture())
print('temp', temperature())
print('light', display.read_light_level())
display.show(Image.HEART)
print('pixel22', display.get_pixel(2, 2))
sleep(1000)
display.off()
print('after off is_on', display.is_on())
sleep(200)
display.on()
sleep(100)
print('done')
