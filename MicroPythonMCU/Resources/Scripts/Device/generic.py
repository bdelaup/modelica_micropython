# ---------------------------------------------------------------------------
# Script par defaut de Peripherals.UartGenericDevice (comportement = Script).
# Point de depart a copier pour decrire un nouvel appareil serie.
#
# Le script est execute UNE FOIS, a la construction du composant. Ses variables
# de module persistent ensuite d'un appel a l'autre : c'est la que vit l'etat
# de l'appareil. Deux instances du meme fichier ont chacune le leur.
#
# Trois fonctions, toutes facultatives :
#
#   on_receive(ligne, t, v)  appelee une fois par ligne complete recue
#       ligne : bytes, sans le terminateur
#       t     : temps simule (s)
#       v     : tuple des grandeurs du connecteur valueIn
#       retour: bytes ou str a emettre (apres responseDelay), ou None
#
#   on_tick(t, v)            appelee toutes les `period` secondes, si definie
#       retour: bytes ou str a emettre, ou None
#
#   outputs()                relue apres chaque appel des deux precedentes
#       retour: un nombre ou une sequence de nombres -> connecteur valueOut
#
# Ces fonctions s'executent sur le thread de la simulation : elles doivent aller
# au bout sans attendre. Pas de sleep(), pas d'acces a machine - pour differer
# une reponse, c'est le parametre responseDelay qui s'en charge. print() est
# prefixe du nom du composant dans le journal de simulation.
# ---------------------------------------------------------------------------

recues = 0


def on_receive(ligne, t, v):
    global recues
    recues += 1
    return b'ACK ' + ligne + b'\r\n'


# def on_tick(t, v):
#     return 'VAL=%.2f\r\n' % v[0]


def outputs():
    return recues
