# Programme du scenario de verification "microbit_matrix_quantum" : fenetres de
# luminosite du balayage. Cf. verify_73_microbit_matrix_quantum.mos.
#
# Pixels poses des le demarrage (tampon pousse une fois) :
#   (x=0, y=0) = 9  -> P4 tenue basse pendant TOUT le creneau de la ligne 0,
#                      haute pendant les autres lignes ;
#   (x=1, y=1) = 4  -> P7 basse pendant les 4/9 du creneau de la ligne 1 ;
#   (x=2, y=2) = 1  -> P3 basse pendant les 1/9 du creneau de la ligne 2.
from microbit import *

display.set_pixel(0, 0, 9)
display.set_pixel(1, 1, 4)
display.set_pixel(2, 2, 1)
sleep(200)
print('quantum done')
