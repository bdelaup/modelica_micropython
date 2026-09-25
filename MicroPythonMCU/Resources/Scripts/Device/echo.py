# ---------------------------------------------------------------------------
# Script par defaut de Peripherals.UartEchoDevice (comportement = Script).
#
# Le plus court des scripts de peripherique : renvoie chaque ligne recue.
#
# Difference avec le mode Table : la, l'echo se fait OCTET PAR OCTET, des que
# chacun est decode. Ici, un script ne voit que des LIGNES completes - l'echo
# ne part donc qu'une fois le terminateur recu, suivi d'un saut de ligne.
# ---------------------------------------------------------------------------


def on_receive(ligne, t, v):
    return ligne + b'\n'
