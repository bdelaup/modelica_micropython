# ---------------------------------------------------------------------------
# Script par defaut de Peripherals.UartGpsModule (comportement = Script).
#
# Emet une phrase NMEA RMC complete a chaque periode : heure UTC, validite,
# latitude et longitude au format degres-minutes avec leur hemisphere, vitesse,
# date, et SOMME DE CONTROLE. C'est ce que la table de commandes ne sait pas
# faire - elle se limite a substituer des valeurs dans un gabarit fixe.
#
# Grandeurs recues du modele (valueIn) :
#   v[0] latitude  (degres decimaux, positive au nord)
#   v[1] longitude (degres decimaux, positive a l'est)
#   v[2] vitesse   (noeuds)
# Grandeur rendue au modele (valueOut) :
#   [1] nombre de phrases emises depuis le debut de la simulation
#
# Contrat d'un script de peripherique : voir docs/peripheriques-uart-externes.md.
# Les fonctions s'executent sur le thread de la simulation : elles vont au bout,
# sans sleep() et sans acces a machine.
# ---------------------------------------------------------------------------

HEURE_DEPART_S = 12 * 3600      # l'horloge UTC du module demarre a 12:00:00
DATE = '250926'                 # jjmmaa
phrases = 0                     # persiste d'un appel a l'autre


def _degres_minutes(valeur, positif, negatif, largeur_degres):
    """47.24 -> ('4714.4000', 'N') ; 5.9876 -> ('00559.2560', 'E')."""
    hemisphere = positif if valeur >= 0 else negatif
    valeur = abs(valeur)
    degres = int(valeur)
    minutes = (valeur - degres) * 60.0
    return '%0*d%07.4f' % (largeur_degres, degres, minutes), hemisphere


def _heure_utc(t):
    s = HEURE_DEPART_S + t
    h = int(s // 3600) % 24
    m = int(s // 60) % 60
    return '%02d%02d%05.2f' % (h, m, s % 60)


def _somme_controle(corps):
    """OU exclusif de tous les caracteres entre '$' et '*'."""
    x = 0
    for c in corps:
        x ^= ord(c)
    return '%02X' % x


def on_tick(t, v):
    global phrases
    lat, ns = _degres_minutes(v[0], 'N', 'S', 2)
    lon, ew = _degres_minutes(v[1], 'E', 'W', 3)
    corps = 'GPRMC,%s,A,%s,%s,%s,%s,%.1f,0.0,%s,,' % (
        _heure_utc(t), lat, ns, lon, ew, v[2], DATE)
    phrases += 1
    return '$%s*%s\r\n' % (corps, _somme_controle(corps))


def outputs():
    return phrases
