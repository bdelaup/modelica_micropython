# ---------------------------------------------------------------------------
# Script par defaut de Peripherals.UartTemperatureSensor (comportement = Script).
#
# Reproduit la table de commandes du mode Table, et y ajoute ce qu'une table
# ne sait pas faire : repondre ERR a une commande inconnue ou mal formee, comme
# tout module AT reel, au lieu de rester muet.
#
#   AT+TEMP    -> TEMP=<valueIn[1]>
#   AT+ID      -> SIM-TEMP-1
#   SET <x>    -> OK, et x ressort sur valueOut[1]
#   autre      -> ERR
#
# Contrat d'un script de peripherique : voir docs/peripheriques-uart-externes.md.
# ---------------------------------------------------------------------------

consigne = 0.0      # derniere consigne recue, publiee sur valueOut[1]


def on_receive(ligne, t, v):
    global consigne
    if ligne == b'AT+TEMP':
        return 'TEMP=%.1f\r\n' % v[0]
    if ligne == b'AT+ID':
        return b'SIM-TEMP-1\r\n'
    if ligne.startswith(b'SET '):
        try:
            consigne = float(ligne[4:])
        except ValueError:
            return b'ERR\r\n'
        return b'OK\r\n'
    return b'ERR\r\n'


def outputs():
    return consigne
