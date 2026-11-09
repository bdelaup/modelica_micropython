# Genere MicroPythonMCU/XIAO_rp2040.mo : icone et schema de la carte Seeed
# Studio XIAO RP2040 standard. Le modele et son diagramme sont regeneres ici ;
# ne pas editer XIAO_rp2040.mo a la main.
#
#   python tools/make_xiao.py
import os

ROOT = os.path.join(os.path.dirname(os.path.dirname(os.path.abspath(__file__))), 'MicroPythonMCU')
MM = 2.54 / 20


def u(mm):
    return round(mm / MM, 1)


GPIO = {'D0': 26, 'D1': 27, 'D2': 28, 'D3': 29,
        'D4': 6, 'D5': 7, 'D6': 0, 'D7': 1,
        'D8': 2, 'D9': 4, 'D10': 3}
LEFT = ['D0', 'D1', 'D2', 'D3', 'D4', 'D5', 'D6']
RIGHT = ['V5', 'GND', 'V3V3', 'D10', 'D9', 'D8', 'D7']
PIN_Y = {name: 60 - 20 * row for row, name in enumerate(LEFT)}
PIN_Y.update({name: 60 - 20 * row for row, name in enumerate(RIGHT)})

DOC = '''<html>
<p>Replica of the <b>Seeed Studio XIAO RP2040</b> standard board (not the XIAO RP2040 Plus): 21 x 17.8 mm, USB-C and 14 edge pads. The board contains the shared RP2040 programmable core, a 3.3 V regulator, its power LED and the active-low RGB user LED. The BOOT and RESET buttons are drawn but not simulated.</p>
<h4>Pinout</h4>
<p>The schematic and icon show both the XIAO pad names (<code>D0</code>...<code>D10</code>) and the RP2040 GPIO numbers. In a script, keep using the real GPIO identifiers: <code>D0 = machine.Pin(26)</code>, <code>D1 = Pin(27)</code>, <code>D2 = Pin(28)</code>, <code>D3 = Pin(29)</code>, <code>D4 = Pin(6)</code>, <code>D5 = Pin(7)</code>, <code>D6 = Pin(0)</code>, <code>D7 = Pin(1)</code>, <code>D8 = Pin(2)</code>, <code>D9 = Pin(4)</code>, <code>D10 = Pin(3)</code>. D0-D3 are the four ADC inputs (<code>ADC(0)</code>...<code>ADC(3)</code>).</p>
<p>UART and I2C use the RP2040 <code>rp2</code> pin multiplexing. For example, the default <code>UART(0)</code> uses GPIO0/GPIO1 (D6/D7), and <code>I2C(1)</code> uses SCL GPIO7/SDA GPIO6 (D5/D4). GPIOs not exposed on the standard XIAO are rejected, even though they exist in the RP2040 silicon.</p>
<h4>Power</h4>
<p><code>usbConnected</code> (true by default) powers the 5 V input from USB-C. With USB disconnected, an external 5 V supply can be connected to <code>V5</code>. The averaged regulator supplies the RP2040, the pins and the <code>V3V3</code> output at 3.3 V. This is a simplified electrical model, not a component-level replica of the regulator. Do not connect an external 5 V supply while the USB source is enabled.</p>
<p>One on-board RGB LED package is driven by GPIO17 (red), GPIO16 (green) and GPIO25 (blue); all three channels are <b>active low</b>, as on the board. The power LED is connected to the 3.3 V rail and lights when the board is powered. The core starts on power-up and stops permanently below <code>VPowerOff</code>; a restart after power loss is not simulated.</p>
<p><code>Display0</code> is the educational logical display link also found on the other boards; it is not a physical XIAO connector. See <code>requirements.md</code>, decision "Seeed Studio XIAO RP2040".</p>
</html>'''


def pin_description(name):
    if name in GPIO:
        return 'XIAO %s, RP2040 GPIO%d (machine.Pin(%d)%s)' % (
            name, GPIO[name], GPIO[name],
            ', ADC(%d)' % (GPIO[name] - 26) if name in ('D0', 'D1', 'D2', 'D3') else '')
    if name == 'V5':
        return '5 V USB-C input/output (do not drive externally while usbConnected is true)'
    if name == 'V3V3':
        return '3.3 V regulated output for external circuits'
    return 'Ground'


def connector(name, side, row):
    diagram = {
        **{pin: (-300, 140 - 28 * index) for index, pin in enumerate(GPIO)},
        'V5': (300, 78),
        'GND': (300, 46),
        'V3V3': (300, 110),
        'Display0': (300, 140),
    }
    x, y = diagram[name]
    ix = -80 if side == 'left' else 80
    kind = 'NegativePin' if name == 'GND' else 'PositivePin'
    return ('  Modelica.Electrical.Analog.Interfaces.%s %s "%s" annotation(\n'
            '    Placement(transformation(origin = {%d, %d}, extent = {{-6, -6}, {6, 6}}), '
            'iconTransformation(origin = {%d, %d}, extent = {{-5, -5}, {5, 5}})));'
            % (kind, name, pin_description(name), x, y, ix, PIN_Y[name]))


def wire(c1, c2, points, color='{0, 0, 255}'):
    return ('  connect(%s, %s) annotation(\n'
            '    Line(points = {%s}, color = %s));'
            % (c1, c2, ', '.join('{%g, %g}' % point for point in points), color))


def comp_decl(cls, name, modifiers, description, x, y, conditional='', rotation=0):
    rotation = ', rotation = %d' % rotation if rotation else ''
    return ('  %s %s%s "%s" annotation(\n'
            '    Placement(transformation(origin = {%d, %d}, extent = {{-10, -10}, {10, 10}}%s)));'
            % (cls, name, modifiers + conditional, description, x, y, rotation))


core_ids = [GPIO[name] for name in GPIO] + [16, 17, 25]
core_caps = [7 if name in ('D0', 'D1', 'D2', 'D3') else 3 for name in GPIO] + [1, 1, 1]
core_modifiers = ', '.join([
    'final nPins = %d' % len(core_ids),
    'final pinIds = {%s}' % ', '.join(map(str, core_ids)),
    'final pinCaps = {%s}' % ', '.join(map(str, core_caps)),
    'final boardProfile = "pico"',
    'final hasTempSensor = true',
    'final dieTemperature = dieTemperature',
])

connectors = [connector(name, 'left', row) for row, name in enumerate(LEFT)]
connectors.extend(connector(name, 'right', row) for row, name in enumerate(RIGHT))
connectors.append(
    '  Interfaces.DisplayLinkOutput Display0 "Educational logical display link, not on the real board" annotation(\n'
    '    Placement(transformation(origin = {300, 140}, extent = {{-6, -6}, {6, 6}}), '
    'iconTransformation(origin = {58, 84}, extent = {{-5, -5}, {5, 5}}, rotation = 90)));')

components = [
    comp_decl('Modelica.Electrical.Analog.Sources.ConstantVoltage', 'usbSupply',
              '(V = VUsb)', 'USB-C 5 V supply', 230, 0, ' if usbConnected', 270),
    comp_decl('Modelica.Electrical.Analog.Basic.Resistor', 'usbCable',
              '(R = RUsb)', 'USB cable and connector resistance', 260, 10, ' if usbConnected'),
    comp_decl('Modelica.Electrical.Analog.Basic.Resistor', 'powerLedResistor',
              '(R = powerLedSeriesR)', 'Power LED current limiter', 30, 85),
    comp_decl('MicroPythonMCU.Peripherals.LED', 'powerLed',
              '(colorOn = {0, 255, 0}, colorOff = {0, 35, 0}, IMax = 0.002)',
              'On-board green power LED', 60, 85),
    comp_decl('Internal.Boards.XiaoRgbLed', 'rgbLed',
              '(RSeries = ledSeriesR)', 'Single on-board RGB LED package', -150, 70),
]

core_ids_by_gpio = {gpio: index for index, gpio in enumerate(core_ids, start=1)}
core_scale = 0.45
core_origin = (-45, 0)
core_pin = (core_origin[0] - 110 * core_scale, core_origin[1])
core_vdd = (core_origin[0], core_origin[1] + 110 * core_scale)
core_gnd = (core_origin[0], core_origin[1] - 110 * core_scale)
core_vref = (core_origin[0] - 60 * core_scale, core_origin[1] + 110 * core_scale)
core_display = (core_origin[0] + 110 * core_scale, core_origin[1] + 60 * core_scale)
equations = []
GND_Y = -75
RED, BROWN, GRAY, ORANGE, PURPLE = '{220, 0, 0}', '{160, 80, 0}', '{90, 90, 90}', '{230, 120, 0}', '{150, 0, 200}'


def to_gnd(connector_name, pin):
    equations.append(wire(connector_name, 'core.gnd', [pin, (pin[0], GND_Y),
                                                     (core_gnd[0], GND_Y), core_gnd], GRAY))


for index, name in enumerate(GPIO, start=1):
    pin_y = 140 - 28 * (index - 1)
    lane_x = -250 + 6 * round(abs(pin_y) / 28)
    equations.append(wire(name, 'core.pin[%d]' % index, [
        (-300, pin_y), (lane_x, pin_y), (lane_x, core_pin[1]), core_pin]))
to_gnd('GND', (300, 46))
equations[-1] = wire('GND', 'core.gnd', [(300, 46), (280, 46), (280, GND_Y),
                                         (core_gnd[0], GND_Y), core_gnd], GRAY)
equations.extend([
    wire('V3V3', 'core.vdd', [(300, 110), (core_vdd[0], 110), core_vdd], RED),
    wire('V3V3', 'core.vref', [(300, 110), (core_vref[0], 110), core_vref], '{0, 150, 0}'),
    wire('V3V3', 'regulator.vout', [(300, 110), (160, 110), (160, 20), (140, 20)], RED),
    wire('V3V3', 'powerLedResistor.p', [(300, 110), (20, 110), (20, 85)], RED),
    wire('V3V3', 'rgbLed.vcc', [(300, 110), (-153, 110), (-153, 79)], RED),
    wire('V5', 'regulator.vin', [(300, 78), (100, 78), (100, 20)], BROWN),
    wire('V5', 'regulator.en', [(300, 78), (90, 78), (90, -10), (108, -10), (108, 0)], PURPLE),
    wire('usbSupply.p', 'usbCable.p', [(230, 10), (250, 10)], ORANGE),
    wire('usbCable.n', 'V5', [(270, 10), (270, 78), (300, 78)], ORANGE),
    wire('powerLedResistor.n', 'powerLed.p', [(40, 85), (50, 85)], RED),
])
to_gnd('usbSupply.n', (230, -10))
to_gnd('powerLed.n', (70, 85))
to_gnd('regulator.gnd', (120, 0))
for color, gpio, lane_x in (('Red', 17, -102), ('Green', 16, -112), ('Blue', 25, -122)):
    pin_index = core_ids_by_gpio[gpio]
    local_y = {'Red': 73.5, 'Green': 70, 'Blue': 66.5}[color]
    equations.append(wire('rgbLed.%sPin' % color.lower(), 'core.pin[%d]' % pin_index,
                          [(-141, local_y), (lane_x, local_y), (lane_x, core_pin[1]), core_pin]))
equations.append(wire('core.Display0', 'Display0', [core_display, (10, core_display[1]),
                                                     (10, 140), (300, 140)], '{28, 108, 200}'))

icon = [
    'Rectangle(lineColor = {20, 40, 35}, fillColor = {0, 115, 70}, fillPattern = FillPattern.Solid, extent = {{-70, 83}, {70, -83}}, radius = 4)',
    'Rectangle(lineColor = {110, 110, 110}, fillColor = {190, 190, 190}, fillPattern = FillPattern.Solid, extent = {{-33, 100}, {33, 72}}, radius = 3)',
    'Polygon(visible = usbConnected, lineColor = {200, 140, 0}, fillColor = {255, 210, 0}, fillPattern = FillPattern.Solid, points = {{4, 92}, {-6, 82}, {0, 82}, {-4, 77}, {7, 86}, {1, 86}})',
    'Rectangle(lineColor = {20, 20, 20}, fillColor = {45, 45, 45}, fillPattern = FillPattern.Solid, extent = {{-24, 30}, {24, -18}})',
    'Text(textColor = {230, 230, 230}, extent = {{-21, 12}, {21, -2}}, textString = "RP2040", fontSize = 7)',
    'Ellipse(lineColor = {80, 80, 80}, fillColor = DynamicSelect({0, 35, 0}, {0, integer(35 + 220*min(1, max(0, powerLed.mean.y)/powerLed.IMax)), 0}), fillPattern = FillPattern.Solid, extent = {{42, 63}, {52, 53}})',
    'Text(textColor = {255, 255, 255}, extent = {{34, 50}, {60, 42}}, textString = "PWR", fontSize = 7)',
    'Ellipse(lineColor = {120, 120, 120}, fillColor = {85, 85, 85}, fillPattern = FillPattern.Solid, extent = {{-52, -47}, {-36, -63}})',
    'Text(textColor = {230, 230, 230}, extent = {{-59, -39}, {-29, -45}}, textString = "RESET", fontSize = 6)',
    'Ellipse(lineColor = {120, 120, 120}, fillColor = {85, 85, 85}, fillPattern = FillPattern.Solid, extent = {{36, -47}, {52, -63}})',
    'Text(textColor = {230, 230, 230}, extent = {{29, -39}, {59, -45}}, textString = "BOOT", fontSize = 6)',
    'Ellipse(lineColor = {80, 80, 80}, fillColor = DynamicSelect({30, 30, 30}, {integer(12 + 243*min(1, max(0, rgbLed.red.mean.y)/rgbLed.IMax)), integer(12 + 243*min(1, max(0, rgbLed.green.mean.y)/rgbLed.IMax)), integer(12 + 243*min(1, max(0, rgbLed.blue.mean.y)/rgbLed.IMax))}), fillPattern = FillPattern.Solid, extent = {{-12, -20}, {12, -44}})',
    'Text(textColor = {255, 255, 255}, extent = {{-35, -66}, {35, -77}}, textString = "XIAO RP2040", textStyle = {TextStyle.Bold}, fontSize = 7)',
    'Text(textColor = {0, 0, 255}, extent = {{-120, 137}, {120, 120}}, textString = "%name")',
]
for name in LEFT:
    label = '%s / GPIO%d' % (name, GPIO[name]) if name in GPIO else {'V3V3': '3V3', 'V5': '5V', 'GND': 'GND'}[name]
    icon.append('Text(textColor = {255, 255, 255}, extent = {{-65, %d}, {-6, %d}}, textString = "%s", horizontalAlignment = TextAlignment.Left, fontSize = 8)' %
                (PIN_Y[name] + 7, PIN_Y[name] - 7, label))
for name in RIGHT:
    label = '%s / GPIO%d' % (name, GPIO[name]) if name in GPIO else {
        'V3V3': '3V3', 'V5': '5V', 'GND': 'GND'}[name]
    icon.append('Text(textColor = {255, 255, 255}, extent = {{6, %d}, {65, %d}}, textString = "%s", horizontalAlignment = TextAlignment.Right, fontSize = 8)' %
                (PIN_Y[name] + 7, PIN_Y[name] - 7, label))

zones = [
    'Rectangle(lineColor = {205, 205, 205}, fillColor = {235, 242, 255}, fillPattern = FillPattern.Solid, extent = {{-320, 165}, {-190, -165}}, radius = 4)',
    'Rectangle(lineColor = {205, 205, 205}, fillColor = {242, 242, 242}, fillPattern = FillPattern.Solid, extent = {{-170, 125}, {5, -60}}, radius = 4)',
    'Rectangle(lineColor = {205, 205, 205}, fillColor = {255, 243, 228}, fillPattern = FillPattern.Solid, extent = {{15, 125}, {285, -90}}, radius = 4)',
    'Text(textColor = {90, 90, 90}, extent = {{-315, 160}, {-195, 146}}, textString = "XIAO pads")',
    'Text(textColor = {90, 90, 90}, extent = {{-165, -40}, {0, -54}}, textString = "RP2040 core and RGB LED")',
    'Text(textColor = {90, 90, 90}, extent = {{20, -78}, {170, -89}}, textString = "USB / 3.3 V supply and LEDs")',
]

src = '''within MicroPythonMCU;

model XIAO_rp2040 "Seeed Studio XIAO RP2040 standard board with real pad-to-GPIO mapping, USB/5 V supply and active-low RGB LED"
  extends Internal.Boards.PartialUsbBoard(redeclare Internal.Boards.McuCore core(%(core_modifiers)s) "RP2040 core: external D0-D10 pads plus internal RGB LED GPIOs" annotation(
    Placement(transformation(origin = {-45, 0}, extent = {{-45, -45}, {45, 45}}))));
  parameter Modelica.Units.NonSI.Temperature_degC dieTemperature = 27 "RP2040 die temperature, read by machine.ADC(4)" annotation(
    Dialog(tab = "Power supply", group = "Temperature sensor"));
  parameter Modelica.Units.SI.Resistance ledSeriesR = 330 "Series resistance of each active-low RGB LED channel" annotation(
    Dialog(tab = "Electrical", group = "On-board LEDs"));
  parameter Modelica.Units.SI.Resistance powerLedSeriesR = 1000 "Series resistance of the green power LED" annotation(
    Dialog(tab = "Electrical", group = "On-board LEDs"));
%(connectors)s
  Internal.Boards.Rt6150 regulator(eta = eta) "Averaged 5 V to 3.3 V buck-boost regulator" annotation(
    Placement(transformation(origin = {120, 20}, extent = {{-20, -20}, {20, 20}})));
%(components)s
  Modelica.Units.SI.Voltage vRail = V3V3.v - core.gnd.v "Regulated 3.3 V rail";
  Modelica.Units.SI.Voltage vInput = V5.v - core.gnd.v "5 V input rail";
  Modelica.Units.SI.Current iInput = regulator.iIn "Current drawn by the regulator from the 5 V input";
equation
%(equations)s
  annotation(
    Icon(coordinateSystem(preserveAspectRatio = true, extent = {{-100, -110}, {100, 110}}, initialScale = 0.2), graphics = {%(icon)s}),
    Diagram(coordinateSystem(preserveAspectRatio = true, extent = {{-330, -175}, {330, 190}}), graphics = {%(zones)s}),
    Documentation(info = "%(doc)s"));
end XIAO_rp2040;
''' % {
    'core_modifiers': core_modifiers,
    'connectors': '\n'.join(connectors),
    'components': '\n'.join(components),
    'equations': '\n'.join(equations),
    'icon': ', '.join(icon),
    'zones': ', '.join(zones),
    'doc': DOC.replace('"', '\\"'),
}

with open(os.path.join(ROOT, 'XIAO_rp2040.mo'), 'w', encoding='utf-8', newline='\n') as model_file:
    model_file.write(src)
