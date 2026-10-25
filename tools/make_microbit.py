# Genere MicroPythonMCU/MicroBit_v2.mo : brochage et cotes reelles de la carte
# BBC micro:bit v2 (icone a la disposition reelle de la carte : connecteur
# edge au pas de 1,27 mm dans l'ordre reel des pads, boutons A/B sur les bords
# lateraux, USB en haut a gauche, matrice LED 5x5 animee sur les courants
# reels, nRF52833 sous la matrice), schema interne lisible (coeur
# Internal.McuCore, matrice de 25 Peripherals.LED multiplexee sur 10 GPIO,
# boutons A/B, tirages edge, capteurs integres et boutons pilotes chacun par
# un menu deroulant InputSource (constante / table horaire / connecteur),
# alimentation USB -> RT6150 -> rail 3,0 V). A relancer apres toute
# modification ici ; ne pas editer MicroBit_v2.mo a la main.
#
#   python tools/make_microbit.py
import os

ROOT = os.path.join(os.path.dirname(os.path.dirname(os.path.abspath(__file__))), 'MicroPythonMCU')
MM = 2.54 / 20          # 1 unite d'icone = 0,127 mm (meme echelle que make_pico.py)


def u(mm):
    return round(mm / MM, 1)


DOC = '''<html>
<p>Replica of the <b>BBC micro:bit v2</b> board (nRF52833, programmable in MicroPython): real pinout (edge connector, 19 GPIO pins <code>P0</code>-<code>P16</code>, <code>P19</code>, <code>P20</code>, plus <code>3V</code> and <code>GND</code>) and real dimensions (52 x 43 mm), its <b>LED matrix</b>, <b>buttons</b>, <b>sensors</b> and <b>power supply</b>. It contains the same programmable core as <code>MCU</code> (<code>Internal.McuCore</code>: Python program, sync point), wired to the on-board components - see the internal diagram.</p>
<h4>Program</h4>
<p>The script is written for the <code>microbit</code> module API of the official MicroPython port (<code>from microbit import *</code>): <code>display</code>, <code>Image</code>, <code>button_a</code>/<code>button_b</code>, <code>pin0</code>...<code>pin20</code>, <code>accelerometer</code>, <code>compass</code>, <code>temperature()</code>, <code>uart</code>, <code>i2c</code>. The <code>machine</code> module is also available, as on the real port. The same file runs unchanged on a physical micro:bit.</p>
<h4>LED matrix (5x5, multiplexed)</h4>
<p>Like the real board: 25 LEDs on <b>10 GPIO</b> (5 rows, 5 columns), scanned at 60 Hz row by row by the display driver - a LED is on while its row is high and its column low, for a fraction of the row slot set by the pixel brightness (0-9). The 5 <b>columns</b> (<code>P3</code>, <code>P4</code>, <code>P6</code>, <code>P7</code>, <code>P10</code>) are shared with the edge connector: while the display is on they belong to the driver, and <code>display.off()</code> releases them. The 25 LED currents are computed by the solver: the dots of the icon light up accordingly during the animated replay of a result.</p>
<h4>Buttons and sensors</h4>
<ul>
<li><code>buttonA</code>/<code>buttonB</code>: each button is driven by a <b>source dropdown</b> (<code>buttonASource</code>, <code>buttonBSource</code>). <b>Connector</b> (default): logical input to wire (boolean signal or source; blue pin on the icon edge); pressed = pin pulled to GND through the button, 10 kOhm pull-up otherwise - like the real board (<code>button_a.is_pressed()</code>, <code>was_pressed()</code>, <code>get_presses()</code>). <b>Table</b>: (time, 0 released / 1 pressed) time table. <b>Constant</b>: fixed state (<code>buttonAPressed</code>).</li>
<li>Integrated sensors: each is driven by its own <b>source dropdown</b> (<code>accelXSource</code>... <code>lightSource</code>) - <b>Constant</b> (default): parameter value; <b>Table</b>: (time, value) time table; <b>Connector</b>: input to wire from the diagram - its labelled port then appears on the edge of the icon (accelerometer on the right edge, compass on the left edge, temperature and light on the top edge). Accelerometer (m/s^2, default gravity on Z), compass (uT), temperature (degC, read by <code>temperature()</code>), light level (0-255, read by <code>display.read_light_level()</code>).</li>
</ul>
<h4>Power supply</h4>
<p><code>usbConnected</code> (true by default): the USB cable supplies 5 V to the buck-boost regulator, which makes the <b>3.0 V rail</b> (<code>3V</code> pin, sensor reference). The nRF52833 draws <code>ICore</code>; the program starts the first time the rail rises above <code>VPowerOn</code> and stops for good if it falls below <code>VPowerOff</code> (no restart simulated).</p>
<h4>Pull resistors (as on the board)</h4>
<p>10 MOhm to 3V on the ring pins <code>P0</code>/<code>P1</code>/<code>P2</code> (touch sensing), 10 kOhm to 3V on the button pins <code>P5</code>/<code>P11</code>, 4.7 kOhm to 3V on the I2C pins <code>P19</code>/<code>P20</code>.</p>
<h4>Radio (<code>microbit.radio</code>)</h4>
<p>The on-board 2.4 GHz radio is a <b>generic radio modem</b> mounted inside the board on two internal pins, always present as on the real hardware: wire the <code>Antenna</code> port (top of the icon) with <b>one</b> antenna wire between the boards that must hear each other (as with <code>Peripherals.Radio.RadioModem</code>), and the programs exchange messages with the firmware API (<code>radio.on()</code>, <code>config()</code>, <code>send()</code>, <code>receive()</code>, filtering by <code>channel</code>/<code>group</code>/<code>address</code>, receive queue of depth <code>queue</code>), implemented in the Python shim on top of the internal modem. A packet travels at the pace of the modem (air at 1 Mbit/s); an unwired antenna means nobody hears the emission, like a modem in the void. No modulated signal is plotted: <code>Peripherals.Radio.RadioModem</code> remains the tool for that.</p>
<p>Not simulated (see the user guide): the touch logo, SPI, microphone and speaker of the v2. See <code>requirements.md</code>, decision "MCU micro:bit v2".</p>
</html>'''

# ---------------------------------------------------------------- brochage
# Broches edge dans l'ordre du connecteur (P17/P18 n'existent pas).
EDGE = ['P0', 'P1', 'P2', 'P3', 'P4', 'P5', 'P6', 'P7', 'P8', 'P9', 'P10',
        'P11', 'P12', 'P13', 'P14', 'P15', 'P16', 'P19', 'P20']
ADC_EDGE = {'P0', 'P1', 'P2', 'P3', 'P4', 'P10'}       # entrees analogiques v2
COL_IDS = [4, 7, 3, 6, 10]                             # colonne x -> COL(x+1)
ROW_IDS = [21, 22, 23, 24, 25]                         # lignes internes (modele)


def pin_idx(n):
    """Index 1-based dans core.pin[] d'une broche edge."""
    return EDGE.index(n) + 1


COL_PIN = [pin_idx('P%d' % i) for i in COL_IDS]        # [5, 8, 4, 7, 11]
ROW_PIN = [20 + y for y in range(5)]                    # core.pin[20..24]
SENS_PIN = [25 + k for k in range(8)]                   # accel XYZ, mag XYZ, temp, lumiere

# ---------------------------------------------------------------- connecteur edge
# Ordre physique reel des pads de gauche a droite (tech.microbit.org), petits
# pads au pas de 1,27 mm, les 5 anneaux (P0/P1/P2/3V/GND) larges de 3 pas
# (~4 mm) ; None = pad present mais non connecte (P17/P18 et extremites).
EDGE_SEQ = [None, 'P3', 'P0', 'P4', 'P5', 'P6', 'P7', 'P1', 'P8', 'P9', 'P10',
            'P11', 'P12', 'P2', 'P13', 'P14', 'P15', 'P16', None, None, 'P_3V',
            'P19', 'P20', 'GND', None]
RING_PADS = ('P0', 'P1', 'P2', 'P_3V', 'GND')
RING_LABEL = {'P0': '0', 'P1': '1', 'P2': '2', 'P_3V': '3V', 'GND': 'GND'}
ICX, _steps = {}, 0.0
for _n in EDGE_SEQ:
    _w = 3 if _n in RING_PADS else 1
    if _n:
        ICX[_n] = _steps + _w / 2
    _steps += _w
EDGE_STEPS = _steps


def edge_x(steps):
    """Abcisse d'icone d'un pad du connecteur (0 = milieu de la carte)."""
    return round((steps - EDGE_STEPS / 2) * 1.27 / MM, 1)


# Carte 52 x 43 mm ; broches de l'icone montees sur les pads du connecteur edge
HALF_W, HALF_L = u(52 / 2), u(43 / 2)
PAD_Y = -HALF_L + u(2.1)                    # centre des pads (broches icone)
PAD_BOT, PAD_TOP = -HALF_L + u(0.4), -HALF_L + u(4)   # bas/haut de la bande de pads

# ---------------------------------------------------------------- capteurs
# (nom, unite affichee, valeur par defaut, formule v = vRail * f(valeur),
#  description, groupe du dialogue, table horaire par defaut)
SENSORS = [
    ('accelX', 'm/s2', '0', '(0.5 + v/39.24)', 'X axis of the accelerometer', 'Accelerometer', '{{0, 0}, {0.5, 0}, {1, 5}, {1.5, 0}, {5, 0}}'),
    ('accelY', 'm/s2', '0', '(0.5 + v/39.24)', 'Y axis of the accelerometer', 'Accelerometer', '{{0, 0}}'),
    ('accelZ', 'm/s2', '-9.81', '(0.5 + v/39.24)', 'Z axis of the accelerometer (default: gravity, board lying display up)', 'Accelerometer', '{{0, -9.81}}'),
    ('magX', 'uT', '0', '(0.5 + v/400)', 'X axis of the magnetometer/compass', 'Magnetometer/compass', '{{0, 0}}'),
    ('magY', 'uT', '50', '(0.5 + v/400)', 'Y axis of the magnetometer/compass (default: field pointing along +Y)', 'Magnetometer/compass', '{{0, 50}}'),
    ('magZ', 'uT', '0', '(0.5 + v/400)', 'Z axis of the magnetometer/compass', 'Magnetometer/compass', '{{0, 0}}'),
    ('temp', 'degC', '27', '((v + 20)/100)', 'Temperature read by microbit.temperature()', 'Temperature', '{{0, 27}, {10, 35}}'),
    ('light', '1', '100', '(v/255)', 'Light level 0-255 read by display.read_light_level()', 'Light', '{{0, 200}, {5, 50}}'),
]

# ---------------------------------------------------------------- boutons
# (nom du bouton, broche, table horaire par defaut)
BUTTONS = [
    ('buttonA', 'P5', '{{0, 0}, {1, 0}, {2, 1}, {3, 0}, {4, 0}, {5, 1}, {6, 0}}'),
    ('buttonB', 'P11', '{{0, 0}, {2.5, 0}, {3, 1}, {4, 0}}'),
]

# ---------------------------------------------------------------- points du schema
D = {}
for k, n in enumerate(EDGE):
    D[n] = (-330, 300 - 26 * k)
D['P_3V'] = (-330, -190)
D['GND'] = (-330, -230)
D['buttonA'] = (-330, -300)
D['buttonB'] = (-330, -330)
GND_RAIL = -250
CORE_O, CORE_S = (-110, 40), 0.65


def core_pt(lx, ly):
    return (CORE_O[0] + lx * CORE_S, CORE_O[1] + ly * CORE_S)


CORE = {'pin': core_pt(-110, 0), 'vdd': core_pt(0, 110), 'gnd': core_pt(0, -110), 'vref': core_pt(-60, 110)}


def route(a, b, first='h'):
    (ax, ay), (bx, by) = a, b
    if ax == bx or ay == by:
        pts = [a, b]
    elif first == 'h':
        pts = [a, (bx, ay), b]
    else:
        pts = [a, (ax, by), b]
    return '{' + ', '.join('{%g, %g}' % pt for pt in pts) + '}'


def pts(plist):
    return '{' + ', '.join('{%g, %g}' % q for q in plist) + '}'


def wire(c1, c2, pts, color='{0, 0, 255}'):
    return '  connect(%s, %s) annotation(\n    Line(points = %s, color = %s));' % (c1, c2, pts, color)


def two_pin(origin, rot, half=10):
    x, y = origin
    if rot == 0:
        return (x - half, y), (x + half, y)
    return (x, y + half), (x, y - half)


P = {}
comp = {}


def place(name, origin, rot, half=10):
    comp[name] = two_pin(origin, rot, half)
    P[name] = (origin, rot)


# ---------------------------------------------------------------- composants
wires = []
# Matrice LED : led[x, y] en grille, anode a gauche (ligne), cathode a droite (colonne)
LED_X0, LED_Y0, LED_STEP = 40, 200, 36
for x in range(5):
    for y in range(5):
        place('led_%d_%d' % (x, y), (LED_X0 + x * LED_STEP, LED_Y0 - y * LED_STEP), 0)
# Lignes : core.pin[20+y] -> anodes des 5 LED de la ligne
for y in range(5):
    for x in range(5):
        lp, _ = comp['led_%d_%d' % (x, y)]
        wires.append(wire('core.pin[%d]' % ROW_PIN[y], 'led_%d_%d.p' % (x, y),
                          '{{%g, %g}, {%g, %g}, {%g, %g}}' % (CORE['pin'][0], CORE['pin'][1], lp[0], CORE['pin'][1], lp[0], lp[1])))
# Colonnes : cathodes -> core.pin[COL_PIN[x]] (meme noeud que la broche edge)
COL_X = LED_X0 + 5 * LED_STEP + 40
for x in range(5):
    for y in range(5):
        _, ln = comp['led_%d_%d' % (x, y)]
        wires.append(wire('led_%d_%d.n' % (x, y), 'core.pin[%d]' % COL_PIN[x],
                          pts([ln, (COL_X, ln[1]), (COL_X, 40 - 26 * (x + 4)), CORE['pin']])))
# Broches edge -> coeur
for n in EDGE:
    x, y = D[n]
    wires.append(wire(n, 'core.pin[%d]' % pin_idx(n), '{{%g, %g}, {%g, %g}, {%g, %g}}' % (x, y, -240, y, CORE['pin'][0], CORE['pin'][1])))
# Boutons : entrees logiques, tirages 10 k, interrupteurs vers la masse
place('pullBtnA', (-160, -280), 90)
place('switchA', (-60, -280), 0)
place('pullBtnB', (-160, -315), 90)
place('switchB', (-60, -315), 0)
# Tirages I2C 4,7 k (P19/P20) ; anneaux 10 M (P0/P1/P2) horizontaux, a gauche
# du couloir du fan de broches (leurs fils remontent hors de la colonne edge)
place('pullI2cScl', (-140, -170), 90)
place('pullI2cSda', (-140, -200), 90)
place('pullRing0', (-220, 120), 0)
place('pullRing1', (-220, 90), 0)
place('pullRing2', (-220, 60), 0)
# Capteurs : SignalVoltage en colonne a droite (le bus de colonnes de la
# matrice, x = 260, reste dans la bande libre entre matrice et capteurs)
SENS_X = 340
for k, (name, _u, _d, _f, _doc, _g, _t) in enumerate(SENSORS):
    place('sensor_%s' % name, (SENS_X, -60 - 40 * k), 0)
# Alimentation : USB -> regulateur -> rail, en bande verticale au-dessus de la
# matrice, dans la zone reservee (cf. ZONES) - rien ne chevauche la matrice
place('usbSupply', (240, 300), 270)
place('usbCable', (240, 250), 270)
place('regulator', (240, 195), 270, half=20)

# ---------------------------------------------------------------- cablage
# 3V (rail) et masse : l'alimentation vit dans sa bande verticale (zone
# reservee au-dessus de la matrice) ; le rail 3V descend a droite de la
# matrice puis suit le couloir y = -190 jusqu'a la broche P_3V ; la masse
# converge sur le bus y = -250 puis remonte a core.gnd - aucun fil ne traverse
# un composant ni l'icone du coeur
RAIL_COLOR = '{220, 0, 0}'
USB_COLOR = '{230, 120, 0}'
GND_COLOR = '{90, 90, 90}'
GND_BUS = (CORE['gnd'][0], GND_RAIL)   # point de convergence du bus de masse
GND_LEG = CORE['gnd']                  # remontee du bus vers core.gnd
sp, sn = comp['usbSupply']
cp, cn = comp['usbCable']
wires.append(wire('usbSupply.p', 'usbCable.p', route(sp, cp), USB_COLOR))
wires.append(wire('usbCable.n', 'regulator.vin', route(cn, comp['regulator'][0]), USB_COLOR))
wires.append(wire('usbSupply.n', 'core.gnd',
                  pts([sn, (210, sn[1]), (210, GND_BUS[1]), GND_BUS, GND_LEG]), GND_COLOR))
rx, ry = P['regulator'][0]
reg_vout = (rx, ry - 20)
reg_gnd = (rx - 20, ry)
reg_en = (rx - 20, ry + 12)
wires.append(wire('regulator.vout', 'P_3V',
                  pts([reg_vout, (reg_vout[0], D['P_3V'][1]), D['P_3V']]), RAIL_COLOR))
wires.append(wire('regulator.gnd', 'core.gnd',
                  pts([reg_gnd, (200, reg_gnd[1]), (200, GND_BUS[1]), GND_BUS, GND_LEG]), GND_COLOR))
# Enable du regulateur : a l'entree VIN (pas de broche enable sur la micro:bit,
# le regulateur demarre avec l'alimentation ; sur le rail il ne demarrerait jamais)
wires.append(wire('regulator.en', 'regulator.vin',
                  pts([reg_en, (reg_en[0] - 5, reg_en[1]), (reg_en[0] - 5, ry + 30), (rx, ry + 30), (rx, ry + 20)]), USB_COLOR))
# Rail 3V vers le coeur : remonte a gauche du coeur (x = -190, hors du fan)
# puis arrive par le dessus, sans traverser l'icone du coeur
wires.append(wire('P_3V', 'core.vdd',
                  pts([(D['P_3V'][0], D['P_3V'][1]), (-190, D['P_3V'][1]), (-190, 130), (CORE['vdd'][0], 130), CORE['vdd']]), RAIL_COLOR))
wires.append(wire('P_3V', 'core.vref',
                  pts([(D['P_3V'][0], D['P_3V'][1]), (-190, D['P_3V'][1]), (-190, 125), (CORE['vref'][0], 125), CORE['vref']]), '{0, 150, 0}'))
# GND
wires.append(wire('GND', 'core.gnd',
                  pts([(D['GND'][0], D['GND'][1]), (GND_BUS[0], D['GND'][1]), GND_BUS, GND_LEG]), GND_COLOR))
# Boutons : tirages 10 k sur le rail, interrupteurs vers le bus de masse ;
# les fils vers P5/P11 passent a GAUCHE de la colonne de broches (x = -344 et
# -352), jamais a travers les connecteurs edge
BTN_BUS = {'buttonA': -344, 'buttonB': -352}
BTN_SWY = {'buttonA': -296, 'buttonB': -345}
for btn, pin, sw in (('buttonA', 'P5', 'A'), ('buttonB', 'P11', 'B')):
    pb, pbn = comp['pullBtn%s' % sw]
    sb, snsw = comp['switch%s' % sw]
    busx, swy = BTN_BUS[btn], BTN_SWY[btn]
    tapx = pb[0] if sw == 'A' else pb[0] - 25   # B : ne pas traverser pullBtnA
    tap = [(D['P_3V'][0], D['P_3V'][1]), (tapx, D['P_3V'][1]), (tapx, pb[1])]
    if tapx != pb[0]:
        tap.append(pb)
    wires.append(wire('P_3V', 'pullBtn%s.p' % sw, pts(tap), RAIL_COLOR))
    wires.append(wire('pullBtn%s.n' % sw, pin, pts([pbn, (busx, pbn[1]), (busx, D[pin][1]), D[pin]])))
    wires.append(wire('switch%s.p' % sw, pin, pts([sb, (sb[0] - 20, sb[1]), (sb[0] - 20, swy), (busx, swy), (busx, D[pin][1]), D[pin]])))
    wires.append(wire('switch%s.n' % sw, 'core.gnd', pts([snsw, (snsw[0], GND_BUS[1]), GND_BUS, GND_LEG]), GND_COLOR))
# Tirages I2C (P19/P20) : sur le rail 3V, vers les broches au-dessus
for res, pin in (('pullI2cScl', 'P19'), ('pullI2cSda', 'P20')):
    pp, pn = comp[res]
    wires.append(wire('P_3V', '%s.p' % res, pts([(D['P_3V'][0], D['P_3V'][1]), (pp[0], D['P_3V'][1]), pp]), RAIL_COLOR))
    wires.append(wire('%s.n' % res, pin, pts([pn, (D[pin][0], pn[1]), D[pin]])))
# Anneaux tactiles (P0/P1/P2) : tirages 10 M horizontaux, fils vers les
# broches remontant a gauche du fan (x = -252..-236, un par anneau)
for i, (res, pin) in enumerate((('pullRing0', 'P0'), ('pullRing1', 'P1'), ('pullRing2', 'P2'))):
    pp, pn = comp[res]
    busx = -252 + 8 * i
    wires.append(wire('P_3V', '%s.p' % res, pts([(D['P_3V'][0], D['P_3V'][1]), (pp[0], D['P_3V'][1]), pp]), RAIL_COLOR))
    wires.append(wire('%s.n' % res, pin, pts([pn, (busx, pn[1]), (busx, D[pin][1]), D[pin]])))
# Capteurs : sortie -> pseudo-broche du coeur par une diagonale du fan
# (corridor vide entre le bus de colonnes et les boutons) ; masse -> tronc
# commun x = 365 rejoignant le bus de masse (meme net, fils fusionnes)
for k, (name, _u, _d, _f, _doc, _g, _t) in enumerate(SENSORS):
    sp2, sn2 = comp['sensor_%s' % name]
    wires.append(wire('sensor_%s.p' % name, 'core.pin[%d]' % SENS_PIN[k],
                      pts([sp2, (250, sp2[1]), CORE['pin']]), '{0, 150, 0}'))
    wires.append(wire('sensor_%s.n' % name, 'core.gnd',
                      pts([sn2, (365, sn2[1]), (365, GND_BUS[1]), GND_BUS, GND_LEG]), GND_COLOR))

# ---------------------------------------------------------------- declarations
conns = []
for n in EDGE:
    x, y = D[n]
    analog = ', analog input (pin%s.read_analog())' % n[1:] if n in ADC_EDGE else ''
    conns.append('  Modelica.Electrical.Analog.Interfaces.PositivePin %s "GPIO %s, edge connector (microbit.pin%s%s)" annotation(\n    Placement(transformation(origin = {%g, %g}, extent = {{-6, -6}, {6, 6}}), iconTransformation(origin = {%g, %g}, extent = {{-4, -4}, {4, 4}})));'
                 % (n, n[1:], n[1:], analog, x, y, edge_x(ICX[n]), PAD_Y))
conns.append('  Modelica.Electrical.Analog.Interfaces.PositivePin P_3V "3V supply of the edge connector: output of the on-board regulator (3.0 V rail)" annotation(\n    Placement(transformation(origin = {%g, %g}, extent = {{-6, -6}, {6, 6}}), iconTransformation(origin = {%g, %g}, extent = {{-4, -4}, {4, 4}})));' % (D['P_3V'][0], D['P_3V'][1], edge_x(ICX['P_3V']), PAD_Y))
conns.append('  Modelica.Electrical.Analog.Interfaces.NegativePin GND if useGroundPin "Common reference (ground) - shown when useGroundPin is checked, otherwise the board is referenced to the simulation ground (0 V)" annotation(\n    Placement(transformation(origin = {%g, %g}, extent = {{-6, -6}, {6, 6}}), iconTransformation(origin = {%g, %g}, extent = {{-4, -4}, {4, 4}})));' % (D['GND'][0], D['GND'][1], edge_x(ICX['GND']), PAD_Y))
conns.append('  Modelica.Blocks.Interfaces.BooleanInput buttonA if buttonASource == InputSource.Connector "Button A (P5): true while pressed - wire a boolean signal or source; pressed = pin to GND, 10 kOhm pull-up otherwise" annotation(\n    Placement(transformation(origin = {%g, %g}, extent = {{-6, -6}, {6, 6}}), iconTransformation(origin = {%g, %g}, extent = {{-5, -5}, {5, 5}})));' % (D['buttonA'][0], D['buttonA'][1], -HALF_W - 12, 0))
conns.append('  Modelica.Blocks.Interfaces.BooleanInput buttonB if buttonBSource == InputSource.Connector "Button B (P11): true while pressed - same as buttonA" annotation(\n    Placement(transformation(origin = {%g, %g}, extent = {{-6, -6}, {6, 6}}), iconTransformation(origin = {%g, %g}, extent = {{-5, -5}, {5, 5}}, rotation = 180)));' % (D['buttonB'][0], D['buttonB'][1], HALF_W + 12, 0))
# Antenne radio : port permanent (la radio est toujours la, comme sur le materiel),
# borde haut a droite de l'icone.
# Le meme connecteur acausal que les RadioModem : un seul fil entre toutes les
# cartes qui partagent le meme air.
conns.append('  Interfaces.Antenna Antenna "Antenna of the on-board 2.4 GHz radio (microbit.radio): wire it with ONE wire to the antenna of the other boards (or Peripherals.Radio.RadioModem) that share the same air" annotation('
             '\n    Placement(transformation(origin = {330, 300}, extent = {{-10, -10}, {10, 10}}), iconTransformation(origin = {140, 183.3}, extent = {{-10, -10}, {10, 10}}, rotation = 270)));')

sensor_params = []
for name, unit, default, formula, doc, group, tbl in SENSORS:
    sensor_params.append('  parameter InputSource %sSource = InputSource.Constant "How %s is driven: constant parameter, time table, or connector wired from the diagram" annotation(\n    Dialog(tab = "Sensors", group = "%s"));' % (name, name, group))
    sensor_params.append('  parameter Real %s = %s "%s, constant value (%s)" annotation(\n    Dialog(tab = "Sensors", group = "%s", enable = %sSource == InputSource.Constant));' % (name, default, doc, unit, group, name))
    sensor_params.append('  parameter Real %sTable[:, 2] = %s "Time table of %s (column 1 = time in s, column 2 = value in %s)" annotation(\n    Dialog(tab = "Sensors", group = "%s", enable = %sSource == InputSource.Table));' % (name, tbl, name, unit, group, name))

button_params = []
for btn, pin, tbl in BUTTONS:
    sw = btn[-1]
    button_params.append('  parameter InputSource %sSource = InputSource.Connector "How button %s is driven: connector wired from the diagram, time table, or constant state" annotation(\n    Dialog(tab = "Buttons", group = "Button %s"));' % (btn, sw, sw))
    button_params.append('  parameter Boolean %sPressed = false "State of button %s in constant mode (true = pressed)" annotation(\n    Dialog(tab = "Buttons", group = "Button %s", enable = %sSource == InputSource.Constant),\n    choices(checkBox = true));' % (btn, sw, sw, btn))
    button_params.append('  parameter Real %sTable[:, 2] = %s "Time table of button %s (column 1 = time in s, column 2 = 0 released / 1 pressed)" annotation(\n    Dialog(tab = "Buttons", group = "Button %s", enable = %sSource == InputSource.Table));' % (btn, tbl, sw, sw, btn))


def comp_decl(cls, name, mods, doc, extra=''):
    o, r = P[name]
    rot = ', rotation = %d' % r if r else ''
    return '  %s %s%s%s "%s" annotation(\n    Placement(transformation(origin = {%g, %g}, extent = {{-10, -10}, {10, 10}}%s)));' % (cls, name, mods, extra, doc, o[0], o[1], rot)


public_decls = []
for x in range(5):
    for y in range(5):
        public_decls.append(comp_decl('MicroPythonMCU.Peripherals.LED', 'led_%d_%d' % (x, y), '(IMax = 0.0004)',
                                       'Matrix LED, column %d, row %d (anode on row %d, cathode on column %d)' % (x, y, y + 1, x + 1)))

decls = []
for sw, pin in (('A', 'P5'), ('B', 'P11')):
    decls.append(comp_decl('Modelica.Electrical.Analog.Basic.Resistor', 'pullBtn%s' % sw, '(R = 10000)', 'External 10 kOhm pull-up of button %s to 3V' % sw))
    decls.append(comp_decl('Modelica.Electrical.Analog.Ideal.IdealClosingSwitch', 'switch%s' % sw, '(Goff = 1e-9)', 'Button %s: to GND while pressed' % sw))
decls.append(comp_decl('Modelica.Electrical.Analog.Basic.Resistor', 'pullI2cScl', '(R = 4700)', 'External 4.7 kOhm pull-up of P19 (I2C SCL)'))
decls.append(comp_decl('Modelica.Electrical.Analog.Basic.Resistor', 'pullI2cSda', '(R = 4700)', 'External 4.7 kOhm pull-up of P20 (I2C SDA)'))
for ring, pin in (('0', 'P0'), ('1', 'P1'), ('2', 'P2')):
    decls.append(comp_decl('Modelica.Electrical.Analog.Basic.Resistor', 'pullRing%s' % ring, '(R = 10e6)', 'External 10 MOhm pull-up of %s (touch ring)' % pin))
for name, unit, default, formula, doc, group, tbl in SENSORS:
    decls.append(comp_decl('Modelica.Electrical.Analog.Sources.SignalVoltage', 'sensor_%s' % name, '', 'Integrated sensor %s, as seen by the ADC' % doc))
    decls.append('  MicroPythonMCU.Internal.SensorSource src_%s(source = %sSource, k = %s, table = %sTable) "Source of %s: constant, time table or connector wired from the diagram" annotation(\n    Placement(visible = false));' % (name, name, name, name, doc))

for btn, pin, tbl in BUTTONS:
    sw = btn[-1]
    decls.append('  MicroPythonMCU.Internal.ButtonSource src_%s(source = %sSource, pressed = %sPressed, table = %sTable) "Source of button %s: constant state, time table or connector wired from the diagram" annotation(\n    Placement(visible = false));' % (btn, btn, btn, btn, sw))

sensor_eqs = []
for name, unit, default, formula, doc, group, tbl in SENSORS:
    sensor_eqs.append('  if %sSource == InputSource.Connector then\n    connect(%sIn, src_%s.u);\n  end if;' % (name, name, name))
    sensor_eqs.append('  sensor_%s.v = vRail*%s;' % (name, formula.replace('v', 'src_%s.y' % name)))

# Commande des interrupteurs de boutons selon le mode (le fil du connecteur
# garde son trace ; les autres modes passent par des composants invisibles)
button_eqs = []
for btn, pin, tbl in BUTTONS:
    sw = btn[-1]
    sb, _ = comp['switch%s' % sw]
    ctrl_x = sb[0] if sw == 'A' else sb[0] - 5   # B : decolle du fil de commande de A
    btn_pts = '{{%g, %g}, {%g, %g}, {%g, %g}}' % (D[btn][0], D[btn][1], ctrl_x, D[btn][1], ctrl_x, sb[1] + 20)
    button_eqs.append('  connect(src_%s.y, switch%s.control);' % (btn, sw))
    button_eqs.append('  if %(b)sSource == InputSource.Connector then\n    connect(%(b)s, src_%(b)s.u) annotation(\n    Line(points = %(pts)s, color = {150, 0, 200}));\n  end if;' % dict(b=btn, pts=btn_pts))

# Radio embarquee : modem radio generique interne (meme moteur que
# Peripherals.Radio.RadioModem), branche sur les broches internes du coeur
# (pin[33] = TX du coeur id 34 -> RX du modem, pin[34] = RX du coeur id 35 <-
# TX du modem), sa masse au bus commun et son antenne au port de la carte.
# Comme sur le materiel, le modem est toujours la : rien de conditionnel.
place('radioModem', (250, 230), 0)
decls.append(comp_decl('MicroPythonMCU.Internal.OnBoardRadioModem', 'radioModem', '',
                       'On-board 2.4 GHz radio of the micro:bit, as a transparent modem on two internal pins of the core - the microbit.radio protocol lives in the Python shim'))
RAD = (250, 230)
RAD_RX = (RAD[0] - 12, RAD[1] - 3)     # RX du modem (bas gauche)
RAD_TX = (RAD[0] - 12, RAD[1] + 3)     # TX du modem (haut gauche)
RAD_GND = (RAD[0], RAD[1] - 10)
RAD_ANT = (RAD[0], RAD[1] + 10)
button_eqs.append(
                   '    connect(core.pin[33], radioModem.RX) annotation(\n'
                   '    Line(points = %s, color = {0, 0, 255}));\n' % pts([CORE['pin'], (CORE['pin'][0] + 60, CORE['pin'][1]), (RAD_RX[0] - 20, CORE['pin'][1]), RAD_RX]) +
                   '    connect(core.pin[34], radioModem.TX) annotation(\n'
                   '    Line(points = %s, color = {0, 0, 255}));\n' % pts([CORE['pin'], (CORE['pin'][0] + 50, CORE['pin'][1] - 8), (RAD_TX[0] - 30, CORE['pin'][1] - 8), RAD_TX]) +
                   '    connect(radioModem.GND, core.gnd) annotation(\n'
                   '    Line(points = %s, color = %s));\n' % (pts([RAD_GND, (RAD_GND[0], GND_BUS[1]), GND_BUS, GND_LEG]), GND_COLOR) +
                   '    connect(radioModem.antenna, Antenna) annotation(\n'
                   '    Line(points = %s, color = {160, 90, 0}));\n'
                   % pts([RAD_ANT, (RAD_ANT[0], 335), (330, 335), (330, 310)]))


# ---------------------------------------------------------------- icone
icon = []
icon.append('Rectangle(lineColor = {0, 90, 40}, fillColor = {0, 120, 60}, fillPattern = FillPattern.Solid, extent = {{%g, %g}, {%g, %g}}, radius = 6)' % (-HALF_W, HALF_L, HALF_W, -HALF_L))
# Connecteur edge (bas) : petits pads au pas de 1,27 mm + 5 anneaux de 4 mm a
# coeur noir, dans l'ordre reel de la carte (P3, P0, P4, ..., 3V, P19, P20, GND)
# ; etiquettes des anneaux en blanc sur barres noires, comme sur la vraie carte
_step = 0.0
for _n in EDGE_SEQ:
    _w = 3 if _n in RING_PADS else 1
    cx = edge_x(_step + _w / 2)
    if _n in RING_PADS:
        cy, r = -HALF_L + u(2), u(2)
        icon.append('Ellipse(lineColor = {200, 160, 40}, fillColor = {230, 190, 60}, fillPattern = FillPattern.Solid, extent = {{%g, %g}, {%g, %g}})' % (cx - r, cy + r, cx + r, cy - r))
        icon.append('Ellipse(lineColor = {20, 20, 20}, fillColor = {25, 25, 25}, fillPattern = FillPattern.Solid, extent = {{%g, %g}, {%g, %g}})' % (cx - u(1.5), cy + u(1.5), cx + u(1.5), cy - u(1.5)))
        bw = u(4) / 2 if RING_LABEL[_n] in ('3V', 'GND') else u(3.4) / 2
        icon.append('Rectangle(lineColor = {25, 25, 25}, fillColor = {25, 25, 25}, fillPattern = FillPattern.Solid, extent = {{%g, %g}, {%g, %g}})' % (cx - bw, PAD_TOP + u(2.4), cx + bw, PAD_TOP))
        icon.append('Text(textColor = {255, 255, 255}, extent = {{%g, %g}, {%g, %g}}, textString = "%s", fontSize = 10)' % (cx - bw + 3, PAD_TOP + u(2.4) - 3, cx + bw - 3, PAD_TOP + 3, RING_LABEL[_n]))
    else:
        icon.append('Rectangle(lineColor = {200, 160, 40}, fillColor = {230, 190, 60}, fillPattern = FillPattern.Solid, extent = {{%g, %g}, {%g, %g}})' % (cx - u(0.55), PAD_TOP, cx + u(0.55), PAD_BOT))
        if _n:
            # numero de la broche au-dessus de son pad (les connecteurs de
            # l'icone se montent sur les pads, cf PAD_Y)
            icon.append('Text(textColor = {255, 255, 255}, extent = {{%g, %g}, {%g, %g}}, textString = "%s", fontSize = 9)' % (cx - 5, PAD_TOP + u(2.4) - 2, cx + 5, PAD_TOP + 2, _n[1:]))
    _step += _w
# USB micro-B (en haut a gauche) avec son ouverture, et eclair
usb_cx, usb_w, usb_d = -u(15), u(7.5) / 2, u(5.5)
icon.append('Rectangle(lineColor = {110, 110, 110}, fillColor = {200, 200, 200}, fillPattern = FillPattern.Solid, extent = {{%g, %g}, {%g, %g}})' % (usb_cx - usb_w, HALF_L - u(0.3), usb_cx + usb_w, HALF_L - u(0.3) - usb_d))
icon.append('Rectangle(lineColor = {60, 60, 60}, fillColor = {70, 70, 70}, fillPattern = FillPattern.Solid, extent = {{%g, %g}, {%g, %g}})' % (usb_cx - u(2), HALF_L - u(0.3), usb_cx + u(2), HALF_L - u(1.5)))
bolt = [(x * 0.65, y * 0.65) for x, y in [(6, 0), (-8, -22), (0, -22), (-6, -44), (10, -16), (2, -16), (8, 0)]]
by0 = HALF_L - u(1.8)
icon.append('Polygon(visible = usbConnected, lineColor = {200, 140, 0}, fillColor = {255, 210, 0}, fillPattern = FillPattern.Solid, points = {%s})' % ', '.join('{%g, %g}' % (usb_cx + x, by0 + y) for x, y in bolt))
# Matrice LED 5x5 (centree, entre les boutons) : pastille noire et LED rouge,
# points allumes par le courant reel
MX0, MY0, MST = -u(7.8), u(10.4), u(3.9)
for x in range(5):
    for y in range(5):
        cx, cy, r = MX0 + x * MST, MY0 - y * MST, u(1.3)
        icon.append('Rectangle(lineColor = {25, 25, 25}, fillColor = {25, 25, 25}, fillPattern = FillPattern.Solid, extent = {{%g, %g}, {%g, %g}}, radius = 2)' % (cx - r, cy + r, cx + r, cy - r))
        dyn = 'DynamicSelect({80, 10, 10}, {integer(80 + min(1, max(0, led_%d_%d.mean.y)/led_%d_%d.IMax)*175), integer(10 + min(1, max(0, led_%d_%d.mean.y)/led_%d_%d.IMax)*50), integer(10 + min(1, max(0, led_%d_%d.mean.y)/led_%d_%d.IMax)*40)})' % ((x, y) * 6)
        icon.append('Ellipse(lineColor = {60, 60, 60}, fillColor = %s, fillPattern = FillPattern.Solid, extent = {{%g, %g}, {%g, %g}})' % (dyn, cx - u(0.9), cy + u(0.9), cx + u(0.9), cy - u(0.9)))
# Boutons A et B : disques gris a liseré blanc sur les bords lateraux, alignes
# sur la matrice, legerement sortants comme sur la vraie carte
BTN_Y = u(1)
btn_cx, btn_r = HALF_W - u(2.5), u(3.5)
for sx, lbl in ((-1, 'A'), (1, 'B')):
    cx = sx * btn_cx
    icon.append('Ellipse(lineColor = {255, 255, 255}, fillColor = {255, 255, 255}, fillPattern = FillPattern.Solid, extent = {{%g, %g}, {%g, %g}})' % (cx - btn_r - u(0.5), BTN_Y + btn_r + u(0.5), cx + btn_r + u(0.5), BTN_Y - btn_r - u(0.5)))
    icon.append('Ellipse(lineColor = {30, 30, 30}, fillColor = {180, 180, 180}, fillPattern = FillPattern.Solid, extent = {{%g, %g}, {%g, %g}})' % (cx - btn_r, BTN_Y + btn_r, cx + btn_r, BTN_Y - btn_r))
    icon.append('Text(textColor = {0, 0, 0}, extent = {{%g, %g}, {%g, %g}}, textString = "%s", fontSize = 18)' % (cx - 10, BTN_Y + 10, cx + 10, BTN_Y - 10, lbl))
# nRF52833 (sous la matrice, assez bas pour ne couvrir aucune LED) et bouton
# reset (en haut a droite) ; reference en deux lignes, lisible dans la puce
chip_h = u(7) / 2
chip_cy = -u(10.7)
icon.append('Rectangle(lineColor = {20, 20, 20}, fillColor = {40, 40, 40}, fillPattern = FillPattern.Solid, extent = {{%g, %g}, {%g, %g}})' % (-chip_h, chip_cy + chip_h, chip_h, chip_cy - chip_h))
icon.append('Text(textColor = {220, 220, 220}, extent = {{%g, %g}, {%g, %g}}, textString = "nRF", fontSize = 11)' % (-chip_h + 4, chip_cy + chip_h - 4, chip_h - 4, chip_cy + 3))
icon.append('Text(textColor = {220, 220, 220}, extent = {{%g, %g}, {%g, %g}}, textString = "52833", fontSize = 9)' % (-chip_h + 4, chip_cy - 3, chip_h - 4, chip_cy - chip_h + 4))
icon.append('Ellipse(lineColor = {60, 60, 60}, fillColor = {200, 200, 200}, fillPattern = FillPattern.Solid, extent = {{%g, %g}, {%g, %g}})' % (u(19) - u(1.2), HALF_L - u(2.5) + u(1.2), u(19) + u(1.2), HALF_L - u(2.5) - u(1.2)))
icon.append('Text(textColor = {230, 190, 60}, extent = {{-95, %g}, {95, %g}}, textString = "micro:bit", fontSize = 24, textStyle = {TextStyle.Bold})' % (HALF_L - 28, HALF_L - 54))
icon.append('Text(textColor = {28, 108, 200}, extent = {{-30, %g}, {30, %g}}, textString = "v2")' % (HALF_L - 58, HALF_L - 72))
icon.append('Text(textColor = {0, 0, 255}, extent = {{-150, %g}, {150, %g}}, textString = "%%name")' % (-HALF_L - 4, -HALF_L - 22))

# ---------------------------------------------------------------- zones du schema
ZONES = [
    ((-334, 320), (-205, -340), '{235, 242, 255}', 'Edge connector (P0-P20, 3V, GND), touch-ring pulls'),
    ((-60, 215), (200, -20), '{242, 242, 242}', 'LED matrix (5x5, multiplexed)'),
    ((205, 325), (345, 160), '{255, 243, 228}', 'Power supply: USB, regulator, 3V rail'),
    ((270, 20), (350, -370), '{255, 242, 252}', 'Integrated sensors'),
    ((-200, -148), (60, -236), '{255, 242, 252}', 'I2C pull resistors'),
    ((-200, -244), (370, -264), '{238, 238, 238}', 'Ground'),
    ((-200, -270), (60, -335), '{255, 242, 252}', 'Buttons (A, B)'),
]
zone_g = []
for (x1, y1), (x2, y2), fill, label in ZONES:
    zone_g.append('Rectangle(lineColor = {200, 200, 200}, fillColor = %s, fillPattern = FillPattern.Solid, extent = {{%g, %g}, {%g, %g}}, radius = 4)' % (fill, x1, y1, x2, y2))
for (x1, y1), (x2, y2), fill, label in ZONES:
    zone_g.append('Text(textColor = {90, 90, 90}, extent = {{%g, %g}, {%g, %g}}, textString = "%s", horizontalAlignment = TextAlignment.Left)' % (x1 + 4, y1 - 2, x2 - 4, y1 - 10, label))

# ---------------------------------------------------------------- assemblage
doc = DOC.replace('"', '\\"')
# La carte n'apporte plus que sa specificite : le contrat carte-coeur vit dans
# Internal.PartialBoard ; ICore (0,004 A : nRF52833) surcharge le defaut du
# socle dans le modificateur du extends, le redeclare porte l'annotation de
# placement (le coeur reste au point calcule par le generateur)
core_mods = ', '.join(
    ['final nPins = 34',
     'final pinIds = {%s}' % ', '.join([n[1:] for n in EDGE] + [str(i) for i in ROW_IDS + list(range(26, 36))]),
     'final pinCaps = {%s}' % ', '.join(['7' if n in ADC_EDGE else '3' for n in EDGE] + ['1'] * 5 + ['4'] * 8 + ['1'] * 2),
     'final boardProfile = "microbit"'])

src = '''within MicroPythonMCU;

model MicroBit_v2 "BBC micro:bit v2 board: nRF52833 programmable in MicroPython, real pinout and dimensions, multiplexed 5x5 LED matrix, buttons A/B, integrated sensors and USB power supply"
  extends Internal.PartialUsbBoard(ICore = 0.004, redeclare Internal.McuCore core(%(core_mods)s) "The nRF52833: pin[1..19] = P0-P16, P19, P20 (edge), pin[20..24] = matrix rows ROW1-ROW5 (internal), pin[25..32] = accelerometer X/Y/Z, compass X/Y/Z, temperature, light (internal), pin[33..34] = TX/RX of the on-board radio (internal)" annotation(
    Placement(transformation(origin = {%(cx)g, %(cy)g}, extent = {{-70, -70}, {70, 70}}))));
  type InputSource = MicroPythonMCU.Interfaces.InputSource "Source of each button and integrated sensor value (alias of the shared type, so that existing models keep writing MicroBit_v2.InputSource.Connector)";
  parameter Modelica.Units.SI.Voltage VTgt = 3.0 "Voltage of the 3V rail (output of the on-board regulator, high level and ADC reference of the pins)" annotation(
    Dialog(tab = "Power supply", group = "Regulator"));
  parameter Boolean useGroundPin = true "Show the GND pin - unchecked: the board is referenced to the simulation ground (0 V), nothing to wire" annotation(
    Dialog(tab = "Pins", group = "Supply"),
    choices(checkBox = true));
%(sensor_params)s
%(button_params)s
%(conns)s
%(sensor_inputs_decl)s
  Internal.Rt6150 regulator(VOut = VTgt, eta = eta) "Buck-boost regulator USB -> 3V rail (RT6150)" annotation(
    Placement(transformation(origin = {%(rx)g, %(ry)g}, extent = {{-20, -20}, {20, 20}}, rotation = 270)));
  Modelica.Electrical.Analog.Sources.ConstantVoltage usbSupply(V = VUsb) if usbConnected "USB supply (5 V)" annotation(
    Placement(transformation(origin = {%(ux)g, %(uy)g}, extent = {{-10, -10}, {10, 10}}, rotation = 270)));
  Modelica.Electrical.Analog.Basic.Resistor usbCable(R = RUsb) if usbConnected "Resistance of the USB cable" annotation(
    Placement(transformation(origin = {%(wx)g, %(wy)g}, extent = {{-10, -10}, {10, 10}}, rotation = 270)));
  Modelica.Units.SI.Voltage vRail = P_3V.v - core.gnd.v "Voltage of the 3V rail";
%(public_decls)s
protected
%(decls)s
equation
%(wires)s
%(button_eqs)s
%(sensor_eqs)s
  annotation(
    Icon(coordinateSystem(preserveAspectRatio = true, extent = {{-230, -210}, {230, 210}}, initialScale = 0.2), graphics = {%(graphics)s}),
    Diagram(coordinateSystem(preserveAspectRatio = true, extent = {{-360, -380}, {380, 340}}), graphics = {%(zones)s}),
    Documentation(info = "%(doc)s"));
end MicroBit_v2;
'''

# Les entrees logiques de capteurs : publiques (cablables depuis le modele
# contenant), affichees sur l'icone seulement quand leur source vaut Connector
# (accelerometre sur le bord droit, magnetometre sur le bord gauche,
# temperature et lumiere sur le bord haut), tournees vers le centre de la
# carte, avec une etiquette au-dessus de chaque port ; placees hors schema
# dans le diagramme interne
SENSOR_PORT = {
    'accelX': (HALF_W + 8, 125, 180),
    'accelY': (HALF_W + 8, 90, 180),
    'accelZ': (HALF_W + 8, 55, 180),
    'magX': (-HALF_W - 8, 125, 0),
    'magY': (-HALF_W - 8, 90, 0),
    'magZ': (-HALF_W - 8, 55, 0),
    'temp': (-35, HALF_L + 14, 270),
    'light': (35, HALF_L + 14, 270),
}
sensor_inputs_decl = []
for k, (name, unit, default, formula, doc, group, tbl) in enumerate(SENSORS):
    px, py, rot = SENSOR_PORT[name]
    u_mod = '(unit = "%s")' % unit if unit != '1' else ''
    rot_s = ', rotation = %d' % rot if rot else ''
    sensor_inputs_decl.append('  Modelica.Blocks.Interfaces.RealInput %sIn%s if %sSource == InputSource.Connector "%s from the diagram" annotation('
                              '\n    Placement(transformation(origin = {330, %d}, extent = {{-6, -6}, {6, 6}}), iconTransformation(origin = {%g, %g}, extent = {{-10, -10}, {10, 10}}%s)));'
                              % (name, u_mod, name, doc, -60 - 40 * k, px, py, rot_s))
    icon.append('Text(textColor = {70, 70, 70}, extent = {{%g, %g}, {%g, %g}}, textString = "%s", fontSize = 8)' % (px - 17, py + 21, px + 17, py + 11.5, name))

# Etiquette de l'antenne radio (bord haut a droite, avec son port)
icon.append('Text(textColor = {70, 70, 70}, extent = {{123, 204.3}, {157, 194.8}}, textString = "ant", fontSize = 8)')

src = src % dict(sensor_params='\n'.join(sensor_params), button_params='\n'.join(button_params), conns='\n'.join(conns), core_mods=core_mods,
                 cx=CORE_O[0], cy=CORE_O[1], rx=P['regulator'][0][0], ry=P['regulator'][0][1],
                 ux=P['usbSupply'][0][0], uy=P['usbSupply'][0][1], wx=P['usbCable'][0][0], wy=P['usbCable'][0][1],
                 public_decls='\n'.join(public_decls),
                 sensor_inputs_decl='\n'.join(sensor_inputs_decl), decls='\n'.join(decls),
                 wires='\n'.join(wires), button_eqs='\n'.join(button_eqs), sensor_eqs='\n'.join(sensor_eqs),
                 graphics=', '.join(icon), zones=', '.join(zone_g), doc=doc)
open(os.path.join(ROOT, 'MicroBit_v2.mo'), 'w', encoding='utf-8').write(src)
print('ok', len(src))
