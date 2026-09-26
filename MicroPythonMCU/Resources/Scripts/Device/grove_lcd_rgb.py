# ---------------------------------------------------------------------------
# Script de Peripherals.I2cGroveLcdRgb : ecran Grove - LCD RGB Backlight.
#
# Un meme module porte DEUX circuits sur le bus I2C, donc deux adresses :
#   0x3E  JHD1313 : controleur d'ecran caractere 16x2, compatible HD44780
#   0x62  PCA9633 : driver de LED a 4 voies (PWM), qui pilote le retroeclairage
#         RGB (voie 0 = bleu, voie 1 = vert, voie 2 = rouge)
# Le composant decode le protocole I2C ; ce script ne fait qu'emuler, octet par
# octet, ce que ces deux circuits font des donnees recues - en suivant leurs
# fiches techniques, sans rien savoir du programme qui les pilote. N'importe
# quel driver ecrit pour le vrai module doit donc fonctionner tel quel.
#
# Sorties : outputs() -> (rouge, vert, bleu, ecran allume), intensites 0-255 ;
#           lines()   -> les deux lignes de 16 caracteres visibles.
# ---------------------------------------------------------------------------

LCD_ADDR = 0x3E          # toute autre adresse du composant est le driver de LED

COLS = 16                # caracteres visibles par ligne
LINE_LEN = 40            # la memoire d'affichage (DDRAM) contient 40 caracteres par ligne
CLEAR_DURATION = 1.52e-3 # clear et home sont lents (datasheet HD44780) ; le reste prend ~40 us

# ======================= JHD1313 (HD44780) =======================
# Etat a la mise sous tension (reset interne) : ecran eteint, memoire vide,
# curseur au debut, ecriture de gauche a droite.
ddram = bytearray(b' ' * 128)
ac = 0                   # compteur d'adresse (position d'ecriture)
increment = True         # I/D : le curseur avance apres chaque caractere
entry_shift = False      # S : l'affichage defile a chaque caractere
display_on = False
two_lines = True         # N : 2 lignes (le module Grove est toujours cable en 16x2)
offset = 0               # decalage de l'affichage (commandes de defilement)
to_cgram = False         # donnees dirigees vers les caracteres personnalises (non affiches ici)
busy_until = 0.0         # fin de la derniere commande lente (clear, home)


def _next_address(a, step):
    # En mode 2 lignes, la ligne 1 occupe 0x00-0x27 et la ligne 2 0x40-0x67 :
    # le compteur saute de l'une a l'autre.
    a = (a + step) & 0x7F
    if two_lines:
        if step > 0 and a == 0x28:
            a = 0x40
        elif step > 0 and a == 0x68:
            a = 0x00
        elif step < 0 and a == 0x3F:
            a = 0x27
        elif step < 0 and a == 0x7F:
            a = 0x67
    return a


def lcd_command(cmd, t):
    global ac, increment, entry_shift, display_on, two_lines, offset, to_cgram, busy_until
    if cmd & 0x80:                      # position d'ecriture (adresse DDRAM)
        ac = cmd & 0x7F
        to_cgram = False
    elif cmd & 0x40:                    # caracteres personnalises (CGRAM) : acceptes, pas affiches
        to_cgram = True
    elif cmd & 0x20:                    # function set
        two_lines = bool(cmd & 0x08)
    elif cmd & 0x10:                    # decalage du curseur ou de tout l'affichage
        step = 1 if cmd & 0x04 else -1
        if cmd & 0x08:
            offset = (offset + step) % LINE_LEN
        else:
            ac = _next_address(ac, step)
    elif cmd & 0x08:                    # display on/off, curseur, clignotement
        display_on = bool(cmd & 0x04)
    elif cmd & 0x04:                    # entry mode
        increment = bool(cmd & 0x02)
        entry_shift = bool(cmd & 0x01)
    elif cmd & 0x02:                    # home
        ac = 0
        offset = 0
        busy_until = t + CLEAR_DURATION
    elif cmd & 0x01:                    # clear
        for i in range(len(ddram)):
            ddram[i] = 0x20
        ac = 0
        offset = 0
        increment = True
        busy_until = t + CLEAR_DURATION


def lcd_data(byte):
    global ac, offset
    if to_cgram:
        return
    ddram[ac] = byte
    ac = _next_address(ac, 1 if increment else -1)
    if entry_shift:
        offset = (offset + (1 if increment else -1)) % LINE_LEN


def lcd_write(data, t):
    # Chaque octet de donnee est precede d'un octet de CONTROLE :
    #   bit 7 (Co) : 1 = un autre octet de controle suivra, 0 = tout le reste
    #                de la transaction est de la donnee
    #   bit 6 (RS) : 0 = commande, 1 = caractere a afficher
    # Le driver de reference envoie [0x80, commande] et [0x40, caractere].
    if t < busy_until:
        # Sur le vrai module, l'octet serait perdu : le controleur est occupe.
        print("t=%.4f s : ecran occupe (clear/home en cours depuis moins de %.2f ms), octets ignores :"
              % (t, CLEAR_DURATION * 1e3), data.hex(' '))
        return
    i = 0
    while i < len(data):
        control = data[i]
        i += 1
        rs = control & 0x40
        last = not (control & 0x80)
        while i < len(data):
            if rs:
                lcd_data(data[i])
            else:
                lcd_command(data[i], t)
            i += 1
            if not last:
                break


def _visible(base):
    out = ''
    for col in range(COLS):
        c = ddram[base + (offset + col) % LINE_LEN]
        out += chr(c) if 0x20 <= c <= 0x7D and c != 0x5C else ' '   # ROM A00 : ASCII de 0x20 a 0x7D, sauf 0x5C (yen)
    return out


# ======================= PCA9633 =======================
# Registres : 0 MODE1, 1 MODE2, 2-5 PWM0-PWM3, 6 GRPPWM, 7 GRPFREQ, 8 LEDOUT,
# 9-12 adresses secondaires. Valeurs a la mise sous tension (datasheet) :
# MODE1 = 0x11 (oscillateur en veille), LEDOUT = 0 (toutes les voies eteintes).
regs = bytearray([0x11, 0x05, 0, 0, 0, 0, 0xFF, 0x00, 0x00, 0xE2, 0xE4, 0xE8, 0xE0])
pointer = 0
auto_increment = 0       # bits AI2-AI0 de l'octet de controle


def _advance():
    global pointer
    if auto_increment == 0b100:      # tous les registres
        pointer = (pointer + 1) % len(regs)
    elif auto_increment == 0b101:    # luminosites individuelles seulement
        pointer = 2 if pointer >= 5 else pointer + 1
    elif auto_increment == 0b110:    # registres de groupe seulement
        pointer = 6 if pointer >= 7 else pointer + 1
    elif auto_increment == 0b111:    # individuelles + groupe
        pointer = 2 if pointer >= 7 else pointer + 1


def rgb_write(data):
    global pointer, auto_increment
    # Premier octet : registre de controle (pointeur + drapeaux d'auto-increment),
    # puis les valeurs, ecrites a partir du registre pointe.
    auto_increment = data[0] >> 5
    pointer = (data[0] & 0x0F) % len(regs)
    for value in data[1:]:
        regs[pointer] = value
        _advance()


def rgb_read():
    value = regs[pointer]
    _advance()
    return value


def _channel(n):
    mode = (regs[8] >> (2 * n)) & 0x03
    asleep = regs[0] & 0x10          # oscillateur arrete : plus de PWM
    if mode == 0:
        return 0
    if mode == 1:
        return 255                   # voie forcee a l'etat passant
    if asleep:
        return 0
    if mode == 2:
        return regs[2 + n]
    return regs[2 + n] * regs[6] // 255   # PWM individuel x gradation de groupe


# ======================= contrat du composant =======================

def on_write(addr, data, t, v):
    if addr == LCD_ADDR:
        lcd_write(data, t)
    else:
        rgb_write(data)


def on_read(addr, t, v):
    if addr == LCD_ADDR:
        return ac        # lecture du compteur d'adresse (drapeau occupe toujours a 0)
    return rgb_read()


def outputs():
    return (_channel(2), _channel(1), _channel(0), 1 if display_on else 0)


def lines():
    if not display_on:
        return ('', '')
    if not two_lines:
        return (_visible(0x00), '')
    return (_visible(0x00), _visible(0x40))
