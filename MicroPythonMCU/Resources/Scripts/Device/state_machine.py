# ---------------------------------------------------------------------------
# Script de peripherique a machine d'etat (Examples.Uart.StateMachinePy).
#
# L'appareil n'accepte une lecture que s'il a ete demarre, et compte les
# lectures servies. C'est precisement ce que la table de commandes ne sait pas
# faire : une table associe une commande a une reponse, sans memoire. Ici, la
# reponse a READ depend de ce qui s'est passe AVANT.
#
#   START -> OK             (ERR si deja demarre)
#   READ  -> VAL=<v1> N=<n> si demarre, ERR sinon
#   STOP  -> OK
#   autre -> ERR
#
# L'etat vit dans des variables de module : le script est execute une seule
# fois, a la construction du composant, et ces variables persistent d'un appel
# a l'autre. Chaque ligne recue n'est livree qu'une fois a on_receive, meme si
# la simulation reevalue plusieurs fois le meme instant : une transition n'est
# donc jamais rejouee.
# ---------------------------------------------------------------------------

etat = 'ARRET'
lectures = 0


def on_receive(ligne, t, v):
    global etat, lectures
    if ligne == b'START':
        if etat == 'MARCHE':
            return b'ERR deja demarre\r\n'
        etat = 'MARCHE'
        print('demarrage a t =', round(t, 4))
        return b'OK\r\n'
    if ligne == b'STOP':
        etat = 'ARRET'
        return b'OK\r\n'
    if ligne == b'READ':
        if etat != 'MARCHE':
            return b'ERR arrete\r\n'
        lectures += 1
        return 'VAL=%.2f N=%d\r\n' % (v[0], lectures)
    return b'ERR commande\r\n'


def outputs():
    # valueOut[1] : etat (1 = en marche), valueOut[2] : lectures servies
    return (1.0 if etat == 'MARCHE' else 0.0, lectures)
