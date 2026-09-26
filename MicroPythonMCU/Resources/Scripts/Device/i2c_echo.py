# ---------------------------------------------------------------------------
# Script par defaut de Peripherals.I2cEchoDevice : ce que le maitre ecrit, il le
# relit. Sert a tester le bus (trames de plusieurs octets, START repete,
# plusieurs peripheriques a des adresses differentes).
#
# Contrat d'un peripherique I2C (toutes les fonctions sont facultatives) :
#   on_write(addr, data, t, v)   une phase d'ecriture adressee vient de se clore
#   on_read(addr, t, v)          le maitre lit : rendre les octets a lui envoyer
#   outputs()                    -> connecteur valueOut
#   lines()                      -> texte affiche (ecrans)
# Voir Resources/Scripts/Device/i2c_generic.py pour le detail.
# ---------------------------------------------------------------------------

memoire = b''    # octets de la derniere ecriture
ecritures = 0    # phases d'ecriture recues
octets = 0       # octets recus au total


def on_write(addr, data, t, v):
    global memoire, ecritures, octets
    memoire = data
    ecritures += 1
    octets += len(data)


def on_read(addr, t, v):
    # Rappelee si le maitre lit plus d'octets que la derniere ecriture n'en
    # contenait : il relit alors la meme chose, en boucle.
    return memoire


def outputs():
    return (ecritures, octets, memoire[0] if memoire else -1)
