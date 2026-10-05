# Genere MicroPythonMCU/RPi_Pico.mo : brochage et cotes reelles de la carte
# (icone : 40 broches, pastilles, USB et eclair, RP2040, LED animee), schema
# interne lisible (coeur Internal.McuCore, USB, diode, diviseurs, regulateur,
# LED), connexions et documentation. A relancer apres toute modification ici ;
# ne pas editer RPi_Pico.mo a la main.
#
#   python make_pico.py
import os, sys
ROOT = os.path.join(os.path.dirname(os.path.abspath(__file__)), 'MicroPythonMCU')
MM = 2.54 / 20          # 1 unite d'icone = 0,127 mm : pas de 2,54 mm = 20 unites
def u(mm):
    return round(mm / MM, 1)

DOC = '''<html>
<p>Replica of the <b>Raspberry Pi Pico</b> board (RP2040): real pinout (40 pins, viewed from above, USB connector at the top) and real dimensions (21 x 51 mm, 2.54 mm pitch, rows 17.78 mm apart), and its <b>power supply</b>. It contains the same programmable core as <code>MCU</code> (<code>Internal.McuCore</code>: Python program, <code>machine</code> API, sync point), wired to the power components of the board — see the internal diagram. The pins are supplied by the 3.3 V rail of the board, and the program only runs while the board is supplied.</p>
<h4>Power supply</h4>
<ul>
<li><code>usbConnected</code> (true by default, lightning bolt on the USB connector of the icon): the USB cable supplies 5 V on <code>VBUS</code> — the board runs without wiring anything, like a Pico plugged into the computer.</li>
<li><code>VBUS</code> feeds <code>VSYS</code> through a Schottky diode (about 0.3 V). <code>VSYS</code> (1.8 to 5.5 V) can also be supplied directly, typically by a battery, with <code>usbConnected = false</code>.</li>
<li>The buck-boost regulator (<code>Internal.Rt6150</code>, averaged model: efficiency <code>eta</code>, undervoltage lockout) makes the 3.3 V rail from <code>VSYS</code>; <code>3V3_EN</code> (pulled up to <code>VSYS</code>) switches it off when grounded. The rail supplies the RP2040 and the flash (<code>ICore</code>), the pins (high level and pull-ups: the current of an LED on a pin is drawn from it) and the <code>3V3(OUT)</code> pin for external circuits.</li>
<li><code>ADC_VREF</code> = 3V3 filtered through 200 Ohm: it is the reference of <code>machine.ADC</code>.</li>
<li>Internal sensing, as on the board: <code>Pin(24)</code> reads the presence of <code>VBUS</code>, <code>ADC(3)</code> (GPIO29) reads <code>VSYS/3</code>, <code>ADC(4)</code> reads the temperature sensor (<code>dieTemperature</code>).</li>
</ul>
<p><b>Power-on and power loss</b>: the program (<code>boot.py</code>/<code>main.py</code> or the script) starts the first time the 3.3 V rail exceeds <code>VPowerOn</code> with <code>RUN</code> high, and <code>time.ticks_ms()</code> counts from this instant. If the rail falls below <code>VPowerOff</code> or <code>RUN</code> is grounded afterwards, the program is stopped for good (warning in the log) and the pins are released; a restart when the supply comes back is <b>not simulated</b>.</p>
<h4>Differences with <code>MCU</code></h4>
<ul>
<li>All the pins of the board: <code>GP0</code>-<code>GP22</code>, <code>GP26</code>-<code>GP28</code>; ADC only on <code>GP26</code>-<code>GP28</code> (<code>ADC(0)</code>-<code>ADC(2)</code>), as on the RP2040.</li>
<li>UART and I2C follow the pin multiplexing of the RP2040 (e.g. <code>UART(0)</code>: TX on GP0, 12, 16 or 28) and the default pins of the rp2 port; <code>UART(0)</code> and <code>UART(1)</code> (and <code>I2C(0)</code>/<code>I2C(1)</code>) are both accepted, but only one at a time (single engine in the simulation). <code>SoftI2C</code> accepts any pins.</li>
<li>The on-board LED (<code>Pin(25)</code> or <code>Pin("LED")</code>) is drawn at its real place on the icon.</li>
</ul>
<p>The <code>Display0</code> logical link to the educational displays is kept (top of the icon), although it does not exist on the real board. See <code>requirements.md</code>, decision "Carte Raspberry Pi Pico et alimentation".</p>
</html>'''

# ---------------------------------------------------------------- brochage
LEFT = ['GP0', 'GP1', 'GND_3', 'GP2', 'GP3', 'GP4', 'GP5', 'GND_8', 'GP6', 'GP7',
        'GP8', 'GP9', 'GND_13', 'GP10', 'GP11', 'GP12', 'GP13', 'GND_18', 'GP14', 'GP15']
RIGHT = ['VBUS', 'VSYS', 'GND_38', 'V3V3_EN', 'V3V3', 'ADC_VREF', 'GP28', 'AGND', 'GP27', 'GP26',
         'RUN', 'GP22', 'GND_28', 'GP21', 'GP20', 'GP19', 'GP18', 'GND_23', 'GP17', 'GP16']
SILK = {'V3V3_EN': '3V3_EN', 'V3V3': '3V3(OUT)', 'AGND': 'AGND'}
PHYS = {n: i + 1 for i, n in enumerate(LEFT)}
PHYS.update({n: 40 - i for i, n in enumerate(RIGHT)})

# Cotes de la carte (datasheet Raspberry Pi Pico) : 21 x 51 mm, rangees de
# broches a 17,78 mm d'entraxe, pas de 2,54 mm, centrees sur la carte.
HALF_W = u(21 / 2)              # 82,7
HALF_L = u(51 / 2)              # 200,8
ROW = u(17.78 / 2)              # 70
PITCH = 20
Y0 = PITCH * 19 / 2             # 190 : broche 1 en haut
XCONN = 92                      # connecteurs juste au-dela du bord de la carte

def ypin(row):
    return Y0 - PITCH * row

def descr(name):
    p = PHYS[name]
    if name.startswith('GP'):
        n = int(name[2:])
        extra = ', machine.ADC(%d)' % (n - 26) if 26 <= n <= 28 else ''
        return 'GPIO %d, physical pin %d (machine.Pin(%d)%s)' % (n, p, n, extra)
    if name.startswith('GND'):
        return 'Ground, physical pin %d (all the GND pins and AGND are connected together)' % p
    return {
        'VBUS': 'Micro-USB input voltage, physical pin 40: 5 V from the USB connector when usbConnected, otherwise free (an external 5 V supply can be connected here)',
        'VSYS': 'Main system input, physical pin 39: 1.8 to 5.5 V, supplied from VBUS through a Schottky diode, or directly from a battery',
        'V3V3_EN': 'Enable of the 3.3 V regulator (3V3_EN), physical pin 37: pulled up to VSYS by 100 kOhm, to ground to switch the regulator off',
        'V3V3': '3.3 V output of the regulator (3V3(OUT)), physical pin 36: supplies external circuits (keep the load under 300 mA)',
        'ADC_VREF': 'ADC reference voltage, physical pin 35: 3V3 filtered through 200 Ohm on the board; can be driven by an external reference',
        'AGND': 'Analog ground of the ADC, physical pin 33 (connected to GND)',
        'RUN': 'RP2040 enable, physical pin 30: internal pull-up to 3V3; to ground, the RP2040 is held in reset (the program stops for good, a restart is not simulated)',
    }[name]

# ---------------------------------------------------------------- schema
# Points des connecteurs dans le schema (diagram)
D = {}
gp_names = ['GP%d' % n for n in list(range(23)) + [26, 27, 28]]
for k, n in enumerate(gp_names):
    D[n] = (-300, 230 - 18 * k)
gnds = [n for n in LEFT + RIGHT if n.startswith('GND')] + ['AGND']
for k, n in enumerate(gnds):
    D[n] = (-140 + 50 * k, -250)
D.update({'VBUS': (300, 220), 'VSYS': (300, 170), 'V3V3_EN': (300, 120), 'V3V3': (300, 60),
          'ADC_VREF': (300, 10), 'RUN': (300, -60), 'Display0': (300, -120)})
GND_RAIL = -230

def route(a, b, first='h'):
    (ax, ay), (bx, by) = a, b
    if ax == bx or ay == by:
        pts = [a, b]
    elif first == 'h':
        pts = [a, (bx, ay), b]
    else:
        pts = [a, (ax, by), b]
    return '{' + ', '.join('{%g, %g}' % pt for pt in pts) + '}'

# Couleur des fils du schema, par reseau (l'ordre des tests compte)
NET_COLORS = [
    ('{90, 90, 90}', ('core.gnd',)),                                          # masse
    ('{28, 108, 200}', ('Display0',)),                                        # liaison d'affichage
    ('{150, 0, 200}', ('V3V3_EN', 'enPullUp.n', 'regulator.en', 'RUN', 'core.run')),  # commandes
    ('{0, 150, 0}', ('vbusSenseTop.n', 'vsysSenseTop.n', 'vrefFilter.n', 'ADC_VREF', 'core.vref')),  # mesures
    ('{230, 120, 0}', ('usb', 'VBUS', 'schottky.p')),                          # USB / VBUS
    ('{160, 80, 0}', ('VSYS', 'schottky.n', 'regulator.vin')),                 # VSYS
    ('{220, 0, 0}', ('V3V3', 'regulator.vout', 'core.vdd')),                   # rail 3,3 V
]

def net_color(c1, c2):
    for color, keys in NET_COLORS:
        if any(k in c for k in keys for c in (c1, c2)):
            return color
    return '{0, 0, 255}'                                                       # GPIO, LED

POWER_COLORS = ('{230, 120, 0}', '{160, 80, 0}', '{220, 0, 0}')   # USB/VBUS, VSYS, rail : traits epais

def wire(c1, c2, pts, color=None):
    color = color or net_color(c1, c2)
    if color in POWER_COLORS:
        color += ', thickness = 0.75'
    elif color != '{0, 0, 255}':
        color += ', thickness = 0.5'
    return '  connect(%s, %s) annotation(\n    Line(points = %s, color = %s));' % (c1, c2, pts, color)

# Composants : origine, rotation ; broches calculees
# rotation 0 : p a gauche, n a droite ; rotation 270 : p en haut, n en bas
def two_pin(origin, rot, half=10):
    x, y = origin
    if rot == 0:
        return (x - half, y), (x + half, y)
    return (x, y + half), (x, y - half)

comp = {}
def place(name, origin, rot, half=10):
    comp[name] = two_pin(origin, rot, half)
    return origin, rot

CORE_O, CORE_S = (-120, -20), 0.7   # coeur : extent {{-70,-70},{70,70}}
def core_pt(lx, ly):
    return (CORE_O[0] + lx * CORE_S, CORE_O[1] + ly * CORE_S)
CORE = {'pin': core_pt(-110, 0), 'vdd': core_pt(0, 110), 'gnd': core_pt(0, -110),
        'vref': core_pt(-60, 110), 'run': core_pt(110, -60), 'Display0': core_pt(110, 60)}
REG_O = (150, 120)                   # regulateur : extent {{-20,-20},{20,20}}, rotation 0
REG = {'vin': (REG_O[0] - 20, REG_O[1]), 'vout': (REG_O[0] + 20, REG_O[1]),
       'en': (REG_O[0] - 12, REG_O[1] - 20), 'gnd': (REG_O[0], REG_O[1] - 20)}

P = {}
P['usbSupply'] = place('usbSupply', (40, 200), 270)
P['usbCable'] = place('usbCable', (70, 220), 0)
P['schottky'] = place('schottky', (200, 200), 270)
P['vbusSenseTop'] = place('vbusSenseTop', (120, 190), 270)
P['vbusSenseBottom'] = place('vbusSenseBottom', (120, 150), 270)
P['vsysSenseTop'] = place('vsysSenseTop', (240, 150), 270)
P['vsysSenseBottom'] = place('vsysSenseBottom', (240, 110), 270)
P['enPullUp'] = place('enPullUp', (270, 150), 270)
P['vrefFilter'] = place('vrefFilter', (240, 30), 270)
P['ledResistor'] = place('ledResistor', (-150, -170), 0)
P['builtinLed'] = place('builtinLed', (-110, -170), 0)

wires = []
# GPIO -> coeur
for k, n in enumerate(gp_names):
    idx = int(n[2:]) + 1
    x, y = D[n]
    wires.append(wire(n, 'core.pin[%d]' % idx, '{{%g, %g}, {-230, %g}, {-230, %g}, {%g, %g}}' % (x, y, y, CORE['pin'][1], CORE['pin'][0], CORE['pin'][1])))
# masses
for n in gnds:
    x, y = D[n]
    wires.append(wire(n, 'core.gnd', '{{%g, %g}, {%g, %g}, {%g, %g}, {%g, %g}}' % (x, y, x, GND_RAIL, CORE['gnd'][0], GND_RAIL, CORE['gnd'][0], CORE['gnd'][1])))
# USB
up, un = comp['usbSupply']; cp, cn = comp['usbCable']
wires.append(wire('usbSupply.p', 'usbCable.p', route(up, cp, 'v')))
wires.append(wire('usbCable.n', 'VBUS', route(cn, D['VBUS'])))
wires.append(wire('usbSupply.n', 'core.gnd', '{{%g, %g}, {%g, %g}, {%g, %g}}' % (un[0], un[1], un[0], GND_RAIL, CORE['gnd'][0], GND_RAIL)))
# VBUS -> Schottky -> VSYS
sp, sn = comp['schottky']
wires.append(wire('VBUS', 'schottky.p', '{{%g, %g}, {%g, %g}, {%g, %g}}' % (D['VBUS'][0], D['VBUS'][1], sp[0], D['VBUS'][1], sp[0], sp[1])))
wires.append(wire('schottky.n', 'VSYS', route(sn, D['VSYS'], 'v')))
# diviseur VBUS -> GPIO24
tp, tn = comp['vbusSenseTop']; bp, bn = comp['vbusSenseBottom']
wires.append(wire('VBUS', 'vbusSenseTop.p', '{{%g, %g}, {%g, %g}, {%g, %g}}' % (D['VBUS'][0], D['VBUS'][1], tp[0], D['VBUS'][1], tp[0], tp[1])))
wires.append(wire('vbusSenseTop.n', 'vbusSenseBottom.p', route(tn, bp)))
wires.append(wire('vbusSenseBottom.n', 'core.gnd', '{{%g, %g}, {%g, %g}, {%g, %g}}' % (bn[0], bn[1], bn[0], GND_RAIL, CORE['gnd'][0], GND_RAIL)))
wires.append(wire('vbusSenseTop.n', 'core.pin[25]', '{{%g, %g}, {%g, %g}, {-215, %g}, {-215, %g}, {%g, %g}}' % (tn[0], tn[1], tn[0] - 30, tn[1], tn[1], CORE['pin'][1], CORE['pin'][0], CORE['pin'][1])))
# diviseur VSYS/3 -> GPIO29
tp, tn = comp['vsysSenseTop']; bp, bn = comp['vsysSenseBottom']
wires.append(wire('VSYS', 'vsysSenseTop.p', '{{%g, %g}, {%g, %g}, {%g, %g}}' % (D['VSYS'][0], D['VSYS'][1], tp[0], D['VSYS'][1], tp[0], tp[1])))
wires.append(wire('vsysSenseTop.n', 'vsysSenseBottom.p', route(tn, bp)))
wires.append(wire('vsysSenseBottom.n', 'core.gnd', '{{%g, %g}, {%g, %g}, {%g, %g}}' % (bn[0], bn[1], bn[0], GND_RAIL, CORE['gnd'][0], GND_RAIL)))
wires.append(wire('vsysSenseTop.n', 'core.pin[30]', '{{%g, %g}, {%g, %g}, {%g, 80}, {-215, 80}, {-215, %g}, {%g, %g}}' % (tn[0], tn[1], tn[0] + 15, tn[1], tn[0] + 15, CORE['pin'][1], CORE['pin'][0], CORE['pin'][1])))
# 3V3_EN
ep, en = comp['enPullUp']
wires.append(wire('VSYS', 'enPullUp.p', '{{%g, %g}, {%g, %g}, {%g, %g}}' % (D['VSYS'][0], D['VSYS'][1], ep[0], D['VSYS'][1], ep[0], ep[1])))
wires.append(wire('enPullUp.n', 'V3V3_EN', route(en, D['V3V3_EN'], 'v')))
wires.append(wire('V3V3_EN', 'regulator.en', '{{%g, %g}, {%g, %g}, {%g, %g}}' % (D['V3V3_EN'][0], D['V3V3_EN'][1], 280, D['V3V3_EN'][1], 280, REG['en'][1] - 10) + '' ))
# corrige : trace EN jusqu'a la broche en du regulateur
wires[-1] = wire('V3V3_EN', 'regulator.en', '{{%g, %g}, {280, %g}, {280, %g}, {%g, %g}, {%g, %g}}' % (D['V3V3_EN'][0], D['V3V3_EN'][1], D['V3V3_EN'][1], REG['en'][1] - 10, REG['en'][0], REG['en'][1] - 10, REG['en'][0], REG['en'][1]))
# regulateur
wires.append(wire('VSYS', 'regulator.vin', '{{%g, %g}, {%g, %g}, {%g, %g}, {%g, %g}}' % (D['VSYS'][0], D['VSYS'][1], 110, D['VSYS'][1], 110, REG['vin'][1], REG['vin'][0], REG['vin'][1])))
wires.append(wire('regulator.gnd', 'core.gnd', '{{%g, %g}, {%g, %g}, {%g, %g}}' % (REG['gnd'][0], REG['gnd'][1], REG['gnd'][0], GND_RAIL, CORE['gnd'][0], GND_RAIL)))
RAIL_Y = 60
wires.append(wire('regulator.vout', 'V3V3', '{{%g, %g}, {%g, %g}, {%g, %g}, {%g, %g}}' % (REG['vout'][0], REG['vout'][1], 185, REG['vout'][1], 185, RAIL_Y, D['V3V3'][0], D['V3V3'][1])))
wires.append(wire('V3V3', 'core.vdd', '{{%g, %g}, {%g, %g}, {%g, %g}}' % (D['V3V3'][0], D['V3V3'][1], CORE['vdd'][0], RAIL_Y, CORE['vdd'][0], CORE['vdd'][1])))
# ADC_VREF
vp, vn = comp['vrefFilter']
wires.append(wire('V3V3', 'vrefFilter.p', '{{%g, %g}, {%g, %g}, {%g, %g}}' % (D['V3V3'][0], D['V3V3'][1], vp[0], RAIL_Y, vp[0], vp[1])))
wires.append(wire('vrefFilter.n', 'ADC_VREF', route(vn, D['ADC_VREF'], 'v')))
wires.append(wire('ADC_VREF', 'core.vref', '{{%g, %g}, {285, %g}, {285, 70}, {%g, 70}, {%g, %g}}' % (D['ADC_VREF'][0], D['ADC_VREF'][1], D['ADC_VREF'][1], CORE['vref'][0], CORE['vref'][0], CORE['vref'][1])))
# RUN, Display0
wires.append(wire('RUN', 'core.run', route(D['RUN'], CORE['run'])))
wires.append(wire('core.Display0', 'Display0', '{{%g, %g}, {%g, %g}, {%g, %g}, {%g, %g}}' % (CORE['Display0'][0], CORE['Display0'][1], 20, CORE['Display0'][1], 20, D['Display0'][1], D['Display0'][0], D['Display0'][1])))
# LED embarquee
lp, ln = comp['ledResistor']; dp, dn = comp['builtinLed']
wires.append(wire('core.pin[26]', 'ledResistor.p', '{{%g, %g}, {-215, %g}, {-215, %g}, {%g, %g}}' % (CORE['pin'][0], CORE['pin'][1], CORE['pin'][1], lp[1], lp[0], lp[1])))
wires.append(wire('ledResistor.n', 'builtinLed.p', route(ln, dp)))
wires.append(wire('builtinLed.n', 'core.gnd', '{{%g, %g}, {%g, %g}, {%g, %g}}' % (dn[0], dn[1], dn[0], GND_RAIL, CORE['gnd'][0], GND_RAIL)))

# ---------------------------------------------------------------- declarations
conns = []
for row, name in enumerate(LEFT):
    kind = 'NegativePin' if name.startswith('GND') else 'PositivePin'
    x, y = D[name]
    conns.append('  Modelica.Electrical.Analog.Interfaces.%s %s "%s" annotation(\n    Placement(transformation(origin = {%g, %g}, extent = {{-6, -6}, {6, 6}}), iconTransformation(origin = {%g, %g}, extent = {{-6, -6}, {6, 6}})));'
                 % (kind, name, descr(name), x, y, -XCONN, ypin(row)))
for row, name in enumerate(RIGHT):
    kind = 'NegativePin' if name.startswith('GND') or name == 'AGND' else 'PositivePin'
    x, y = D[name]
    conns.append('  Modelica.Electrical.Analog.Interfaces.%s %s "%s" annotation(\n    Placement(transformation(origin = {%g, %g}, extent = {{-6, -6}, {6, 6}}), iconTransformation(origin = {%g, %g}, extent = {{-6, -6}, {6, 6}})));'
                 % (kind, name, descr(name), x, y, XCONN, ypin(row)))

def comp_decl(cls, name, mods, doc, extra=''):
    o, r = P[name]
    rot = ', rotation = %d' % r if r else ''
    return '  %s %s%s%s "%s" annotation(\n    Placement(transformation(origin = {%g, %g}, extent = {{-10, -10}, {10, 10}}%s)));' % (cls, name, mods, extra, doc, o[0], o[1], rot)

# ---------------------------------------------------------------- icone
icon = []
icon.append('Rectangle(lineColor = {0, 90, 40}, fillColor = {0, 120, 60}, fillPattern = FillPattern.Solid, extent = {{%g, %g}, {%g, %g}}, radius = 6)' % (-HALF_W, HALF_L, HALF_W, -HALF_L))
# connecteur micro-USB : 8 mm de large, depasse de 1,3 mm en haut
usb_w, usb_d = u(8) / 2, u(5.6)
icon.append('Rectangle(lineColor = {110, 110, 110}, fillColor = {200, 200, 200}, fillPattern = FillPattern.Solid, extent = {{%g, %g}, {%g, %g}})' % (-usb_w, HALF_L + u(1.3), usb_w, HALF_L + u(1.3) - usb_d))
# eclair : alimente par l'USB
bolt = [(x * 0.75, y * 0.75) for x, y in [(6, 0), (-8, -22), (0, -22), (-6, -44), (10, -16), (2, -16), (8, 0)]]
by0 = HALF_L + u(1.3) - 5
icon.append('Polygon(visible = usbConnected, lineColor = {200, 140, 0}, fillColor = {255, 210, 0}, fillPattern = FillPattern.Solid, points = {%s})' % ', '.join('{%g, %g}' % (x, by0 + y) for x, y in bolt))
# trous de fixation (4 trous de 2,1 mm, a 11,4 mm d'entraxe, a 2 mm des bords courts)
for sx in (-1, 1):
    for sy in (-1, 1):
        cx, cy, r = sx * u(11.4 / 2), sy * (HALF_L - u(2)), u(2.1 / 2)
        icon.append('Ellipse(lineColor = {230, 190, 60}, lineThickness = 0.75, fillColor = {0, 80, 35}, fillPattern = FillPattern.Solid, extent = {{%g, %g}, {%g, %g}})' % (cx - r, cy + r, cx + r, cy - r))
# pastilles des broches
for row in range(20):
    y = ypin(row)
    for x in (-ROW, ROW):
        icon.append('Ellipse(lineColor = {200, 160, 40}, fillColor = {230, 190, 60}, fillPattern = FillPattern.Solid, extent = {{%g, %g}, {%g, %g}})' % (x - 7, y + 7, x + 7, y - 7))
# RP2040 (7 x 7 mm) et flash
chip = u(7) / 2
icon.append('Rectangle(lineColor = {20, 20, 20}, fillColor = {40, 40, 40}, fillPattern = FillPattern.Solid, extent = {{%g, %g}, {%g, %g}})' % (-chip, 30 + chip, chip, 30 - chip))
icon.append('Text(textColor = {220, 220, 220}, extent = {{%g, %g}, {%g, %g}}, textString = "RP2040")' % (-chip + 4, 40, chip - 4, 20))
icon.append('Rectangle(lineColor = {20, 20, 20}, fillColor = {40, 40, 40}, fillPattern = FillPattern.Solid, extent = {{-18, -40}, {18, -70}})')
# BOOTSEL et LED (a cote du connecteur USB)
icon.append('Ellipse(lineColor = {180, 180, 180}, fillColor = {245, 245, 245}, fillPattern = FillPattern.Solid, extent = {{-14, 130}, {14, 102}})')
icon.append('Ellipse(fillColor = DynamicSelect({40, 90, 40}, {integer(40 + min(1, max(0, builtinLed.mean.y)/builtinLed.IMax)*(-40)), integer(90 + min(1, max(0, builtinLed.mean.y)/builtinLed.IMax)*130), integer(40 + min(1, max(0, builtinLed.mean.y)/builtinLed.IMax)*(-40))}), fillPattern = FillPattern.Solid, extent = {{-38, 160}, {-26, 148}})')
icon.append('Text(textColor = {255, 255, 255}, extent = {{-42, 146}, {-22, 138}}, textString = "LED")')
icon.append('Text(textColor = {255, 255, 255}, extent = {{-40, -100}, {40, -130}}, textString = "Pico", textStyle = {TextStyle.Bold})')
icon.append('Text(textColor = {255, 255, 255}, extent = {{-40, -132}, {40, -146}}, textString = "Raspberry Pi")')
# libelles des broches, entre les pastilles et le centre
for row, name in enumerate(LEFT):
    y = ypin(row)
    icon.append('Text(textColor = {255, 255, 255}, extent = {{%g, %g}, {%g, %g}}, textString = "%s", horizontalAlignment = TextAlignment.Left)' % (-ROW + 10, y + 6, -14, y - 6, SILK.get(name, 'GND' if name.startswith('GND') else name)))
for row, name in enumerate(RIGHT):
    y = ypin(row)
    icon.append('Text(textColor = {255, 255, 255}, extent = {{%g, %g}, {%g, %g}}, textString = "%s", horizontalAlignment = TextAlignment.Right)' % (14, y + 6, ROW - 10, y - 6, SILK.get(name, 'GND' if name.startswith('GND') else name)))
icon.append('Text(textColor = {28, 108, 200}, extent = {{38, 236}, {90, 226}}, textString = "DISPLAY")')
icon.append('Text(textColor = {0, 0, 255}, extent = {{-150, 268}, {150, 246}}, textString = "%name")')

doc = DOC.replace('"', '\\"')

core_mods = ', '.join(['final nPins = 30', 'final pinIds = {i for i in 0:29}',
    'final pinCaps = {%s}' % ', '.join(['3'] * 23 + ['1', '1', '1', '7', '7', '7', '5']),
    'final boardProfile = "pico"', 'final instanceName = boardName', 'final hasTempSensor = true', 'final dieTemperature = dieTemperature',
    'final ICore = ICore', 'final VPowerOn = VPowerOn', 'final VPowerOff = VPowerOff'] +
    ['final %s = %s' % (n, n) for n in ['scriptPath', 'addScriptDirToPath', 'libraryPath', 'fsEnabled', 'fsSource', 'fsWorkspace', 'fsOpenExplorer', 'tickPeriod', 'gpioOpTime', 'hangWarningTime', 'debugEnabled', 'debugPort', 'VOL', 'VIH', 'VIL', 'ROut', 'ledSeriesR', 'RPullUp', 'RPullDown', 'GOff']])

src = '''within MicroPythonMCU;

model RPi_Pico "Raspberry Pi Pico board: RP2040 programmable in MicroPython, real pinout and dimensions, power supply through USB, VBUS or VSYS and the on-board 3.3 V regulator"
  extends Internal.PartialMcuSettings;
  parameter Boolean usbConnected = true "USB cable plugged in: 5 V on VBUS (the board runs without any wiring) - false to supply the board through VBUS or VSYS" annotation(
    Dialog(tab = "Power supply", group = "USB"),
    choices(checkBox = true));
  parameter Modelica.Units.SI.Voltage VUsb = 5 "Voltage of the USB supply" annotation(
    Dialog(tab = "Power supply", group = "USB", enable = usbConnected));
  parameter Modelica.Units.SI.Resistance RUsb = 0.2 "Resistance of the USB cable and connector" annotation(
    Dialog(tab = "Power supply", group = "USB", enable = usbConnected));
  parameter Real eta(min = 0.1, max = 1) = 0.9 "Efficiency of the 3.3 V regulator" annotation(
    Dialog(tab = "Power supply", group = "Regulator"));
  parameter Modelica.Units.SI.Current ICore = 0.02 "Current drawn from the 3.3 V rail by the RP2040 and the flash while supplied (program running, pins excluded)" annotation(
    Dialog(tab = "Power supply", group = "Consumption"));
  parameter Modelica.Units.SI.Voltage VPowerOn = 1.8 "3.3 V rail voltage above which the RP2040 starts (power-on reset)" annotation(
    Dialog(tab = "Power supply", group = "Power-on"));
  parameter Modelica.Units.SI.Voltage VPowerOff = 1.6 "3.3 V rail voltage below which a running RP2040 stops for good (brown-out)" annotation(
    Dialog(tab = "Power supply", group = "Power-on"));
  parameter Modelica.Units.NonSI.Temperature_degC dieTemperature = 27 "Temperature of the RP2040, read by machine.ADC(4)" annotation(
    Dialog(tab = "Power supply", group = "Temperature sensor"));
%(conns)s
  Interfaces.DisplayLinkOutput Display0 "Logical link to an educational display peripheral (machine.Display(0).write()) - not on the real board: simplified causal link, see requirements.md decision \\"P\u00e9riph\u00e9rique d'affichage p\u00e9dagogique\\"" annotation(
    Placement(transformation(origin = {%(dx)g, %(dy)g}, extent = {{-6, -6}, {6, 6}}), iconTransformation(origin = {64, 214}, extent = {{-6, -6}, {6, 6}}, rotation = 90)));
  Internal.McuCore core(%(core_mods)s) "The RP2040: pin[i] = GPIO i-1 (GP0-GP22, GP23 power-save, GP24 VBUS sense, GP25 LED, GP26-GP28, GP29 VSYS/3)" annotation(
    Placement(transformation(origin = {%(cx)g, %(cy)g}, extent = {{-70, -70}, {70, 70}})));
  Internal.Rt6150 regulator(eta = eta) "Buck-boost regulator VSYS -> 3.3 V (RT6150B)" annotation(
    Placement(transformation(origin = {%(rx)g, %(ry)g}, extent = {{-20, -20}, {20, 20}})));
  MicroPythonMCU.Peripherals.LED builtinLed "On-board LED (GPIO25)" annotation(
    Placement(transformation(origin = {%(lx)g, %(ly)g}, extent = {{-10, -10}, {10, 10}})));
  Modelica.Units.SI.Voltage vRail = V3V3.v - core.gnd.v "Voltage of the 3.3 V rail (3V3(OUT))";
  Modelica.Units.SI.Voltage vSys = VSYS.v - core.gnd.v "Voltage of VSYS";
  Modelica.Units.SI.Current iSys = regulator.iIn "Current drawn from VSYS by the regulator";
protected
  final parameter String boardName = getInstanceName() "Instance name of the board, given to the core (log prefix, name of the copy of the flash): getInstanceName() written in the modifier of core would return the name of the core";
%(decls)s
equation
%(wires)s
  // GPIO23 (core.pin[24]): power-save mode of the regulator, no electrical effect in the averaged model (Internal.Rt6150)
  annotation(
    Icon(coordinateSystem(preserveAspectRatio = true, extent = {{-100, -210}, {100, 270}}), graphics = {%(graphics)s}),
    Diagram(coordinateSystem(preserveAspectRatio = true, extent = {{-320, -270}, {320, 260}}), graphics = {%(zones)s}),
    Documentation(info = "%(doc)s"));
end RPi_Pico;
'''
# Zones de fond du schema, sous les composants : GPIO, coeur, alimentation, masse
ZONES = [
    ((-314, 250), (-206, -234), '{235, 242, 255}', 'GPIO'),
    ((-200, 62), (-40, -104), '{242, 242, 242}', 'RP2040 core'),
    ((22, 250), (316, -2), '{255, 243, 228}', 'Power supply: USB, VBUS, VSYS, regulator, 3V3'),
    ((-200, -238), (280, -266), '{238, 238, 238}', 'Ground (GND pins, AGND)'),
]
zone_g = []
for (x1, y1), (x2, y2), fill, label in ZONES:
    zone_g.append('Rectangle(lineColor = {200, 200, 200}, fillColor = %s, fillPattern = FillPattern.Solid, extent = {{%g, %g}, {%g, %g}}, radius = 4)' % (fill, x1, y1, x2, y2))
for (x1, y1), (x2, y2), fill, label in ZONES:
    if label.startswith('Ground'):
        zone_g.append('Text(textColor = {90, 90, 90}, extent = {{%g, %g}, {%g, %g}}, textString = "%s", horizontalAlignment = TextAlignment.Right)' % (x2 - 200, y2 + 9, x2 - 4, y2 + 1, label))
    else:
        zone_g.append('Text(textColor = {90, 90, 90}, extent = {{%g, %g}, {%g, %g}}, textString = "%s", horizontalAlignment = TextAlignment.Left)' % (x1 + 4, y1 - 2, x2 - 4, y1 - 10, label))

decls = [
    comp_decl('Modelica.Electrical.Analog.Sources.ConstantVoltage', 'usbSupply', '(V = VUsb)', 'USB supply (5 V)', ' if usbConnected'),
    comp_decl('Modelica.Electrical.Analog.Basic.Resistor', 'usbCable', '(R = RUsb)', 'Resistance of the USB cable', ' if usbConnected'),
    comp_decl('Modelica.Electrical.Analog.Ideal.IdealDiode', 'schottky', '(Vknee = 0.3, Ron = 0.2, Goff = 1e-7)', 'Schottky diode from VBUS to VSYS (MBR120)'),
    comp_decl('Modelica.Electrical.Analog.Basic.Resistor', 'vbusSenseTop', '(R = 5.6e3)', 'VBUS sense divider, top (to GPIO24)'),
    comp_decl('Modelica.Electrical.Analog.Basic.Resistor', 'vbusSenseBottom', '(R = 10e3)', 'VBUS sense divider, bottom'),
    comp_decl('Modelica.Electrical.Analog.Basic.Resistor', 'vsysSenseTop', '(R = 200e3)', 'VSYS/3 divider, top (to GPIO29, ADC(3))'),
    comp_decl('Modelica.Electrical.Analog.Basic.Resistor', 'vsysSenseBottom', '(R = 100e3)', 'VSYS/3 divider, bottom'),
    comp_decl('Modelica.Electrical.Analog.Basic.Resistor', 'enPullUp', '(R = 100e3)', 'Pull-up of 3V3_EN to VSYS'),
    comp_decl('Modelica.Electrical.Analog.Basic.Resistor', 'vrefFilter', '(R = 200)', 'ADC_VREF filter from 3V3'),
    comp_decl('Modelica.Electrical.Analog.Basic.Resistor', 'ledResistor', '(R = ledSeriesR)', 'Series resistance of the on-board LED'),
]
src = src % dict(conns='\n'.join(conns), dx=D['Display0'][0], dy=D['Display0'][1], core_mods=core_mods,
                 cx=CORE_O[0], cy=CORE_O[1], rx=REG_O[0], ry=REG_O[1], lx=P['builtinLed'][0][0], ly=P['builtinLed'][0][1],
                 decls='\n'.join(decls), wires='\n'.join(wires), graphics=', '.join(icon), zones=', '.join(zone_g), doc=doc)
open(os.path.join(ROOT, 'RPi_Pico.mo'), 'w', encoding='utf-8').write(src)
print('ok', len(src))
