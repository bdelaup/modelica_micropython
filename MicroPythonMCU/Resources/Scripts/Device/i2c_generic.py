# ---------------------------------------------------------------------------
# Script par defaut de Peripherals.I2cGenericDevice : point de depart a copier
# pour decrire un nouveau peripherique I2C esclave. Il modelise ici le cas le
# plus courant, un BANC DE REGISTRES avec pointeur auto-incremente (comme la
# plupart des capteurs, EEPROM, drivers de LED...).
#
# Le script est execute UNE FOIS, a la construction du composant. Ses variables
# de module persistent ensuite d'un appel a l'autre : c'est la que vit l'etat du
# peripherique. Deux instances du meme fichier ont chacune le leur.
#
# Le composant gere seul le protocole (START, adresse, acquittements, STOP) : le
# script ne voit que des TRANSACTIONS. Quatre fonctions, toutes facultatives :
#
#   on_write(addr, data, t, v)   une phase d'ecriture qui lui etait adressee
#                                vient de se clore (STOP ou START repete)
#       addr : adresse sur 7 bits utilisee par le maitre (utile si le composant
#              en a plusieurs, cf. parametre addresses)
#       data : bytes recus (jamais vide)
#       t    : temps simule (s)
#       v    : tuple des grandeurs du connecteur valueIn
#
#   on_read(addr, t, v)          le maitre commence a lire
#       retour : les octets a lui envoyer - bytes, str, liste d'entiers ou
#                entier. Ils sortent un par un ; si le maitre en lit davantage,
#                on_read est rappelee (et 0xFF sort si elle ne rend rien)
#
#   outputs()                    relue apres chaque appel -> connecteur valueOut
#       retour : un nombre ou une sequence de nombres
#
#   lines()                      relue apres chaque appel -> texte affiche sur
#                                l'icone d'un ecran (line1, line2)
#       retour : une chaine, ou deux
#
# Ces fonctions s'executent sur le thread de la simulation : elles doivent aller
# au bout sans attendre. Pas de sleep(), pas d'acces a machine. print() est
# prefixe du nom du composant dans le journal de simulation.
#
# Cote microcontroleur, ce gabarit repond a :
#   i2c.writeto_mem(0x42, 3, b'\x10\x20')   # ecrit les registres 3 et 4
#   i2c.readfrom_mem(0x42, 3, 2)            # relit b'\x10\x20'
# ---------------------------------------------------------------------------

registres = bytearray(16)
pointeur = 0


def on_write(addr, data, t, v):
    global pointeur
    # Premier octet : numero de registre ; les suivants s'y ecrivent a la suite.
    pointeur = data[0] % len(registres)
    for octet in data[1:]:
        registres[pointeur] = octet
        pointeur = (pointeur + 1) % len(registres)


def on_read(addr, t, v):
    global pointeur
    # Un octet a la fois : le pointeur avance a chaque octet lu.
    valeur = registres[pointeur]
    pointeur = (pointeur + 1) % len(registres)
    return valeur


def outputs():
    return registres[0]
