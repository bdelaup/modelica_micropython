within MicroPythonMCU.Examples.Weighing;

model Hx711Read "Raw readings of an HX711 by the robert-hh MicroPython driver: gain 128, gain 64, power-down and wake-up"
  extends Modelica.Icons.Example;
  MCU mcu(scriptPath = Modelica.Utilities.Files.loadResource("modelica://MicroPythonMCU/Resources/Scripts/MCU/hx711_read.py")) "scriptPath = Resources/Scripts/MCU/hx711_read.py - imports the driver hx711_gpio.py placed next to it (robert-hh, unchanged)" annotation(
    Placement(transformation(origin = {0, 0}, extent = {{-20, -20}, {20, 20}})));
  MicroPythonMCU.Peripherals.Display display "Codes read by the microcontroller" annotation(
    Placement(transformation(origin = {60, 40}, extent = {{-20, -20}, {20, 20}})));
  MicroPythonMCU.Peripherals.Weighing.Hx711 hx "Converter, without noise: the codes read are exactly predictable" annotation(
    Placement(transformation(origin = {60, -20}, extent = {{-20, -20}, {20, 20}})));
  MicroPythonMCU.Peripherals.Weighing.WheatstoneBridge bridge annotation(
    Placement(transformation(origin = {130, -20}, extent = {{-20, -20}, {20, 20}})));
  MicroPythonMCU.Peripherals.Weighing.LoadCell loadCell "5 kg load cell body" annotation(
    Placement(transformation(origin = {190, -20}, extent = {{-20, -20}, {20, 20}})));
  Modelica.Mechanics.Translational.Sources.Force weight "The weight of the mass placed" annotation(
    Placement(transformation(origin = {230, -20}, extent = {{10, -10}, {-10, 10}})));
  Modelica.Blocks.Math.Gain g(k = Modelica.Constants.g_n) "Weight = mass × g" annotation(
    Placement(transformation(origin = {270, -20}, extent = {{10, -10}, {-10, 10}})));
  Modelica.Blocks.Sources.Constant mass(k = 1) "Mass placed: 1 kg" annotation(
    Placement(transformation(origin = {310, -20}, extent = {{10, -10}, {-10, 10}})));
  Modelica.Electrical.Analog.Basic.Ground ground annotation(
    Placement(transformation(origin = {-20, -70}, extent = {{-10, -10}, {10, 10}})));
equation
  connect(mcu.Display0, display.displayLink) annotation(
    Line(points = {{10, 14}, {10, 40}, {38, 40}}));
// Program pinout: PD_SCK on GP6, DOUT on GP7
  connect(mcu.GP6, hx.PD_SCK) annotation(
    Line(points = {{12, -4}, {24, -4}, {24, -14}, {38, -14}}, color = {0, 0, 255}));
  connect(mcu.GP7, hx.DOUT) annotation(
    Line(points = {{12, -10}, {20, -10}, {20, -26}, {38, -26}}, color = {0, 0, 255}));
  connect(hx.E_plus, bridge.E_plus) annotation(
    Line(points = {{82, -14}, {108, -14}}, color = {0, 0, 255}));
  connect(hx.A_plus, bridge.S_plus) annotation(
    Line(points = {{82, -18}, {108, -18}}, color = {0, 0, 255}));
  connect(hx.A_minus, bridge.S_minus) annotation(
    Line(points = {{82, -22}, {108, -22}}, color = {0, 0, 255}));
  connect(hx.E_minus, bridge.E_minus) annotation(
    Line(points = {{82, -26}, {108, -26}}, color = {0, 0, 255}));
  connect(loadCell.eps, bridge.eps) annotation(
    Line(points = {{168, -20}, {152, -20}}, color = {0, 0, 127}));
  connect(weight.flange, loadCell.flange) annotation(
    Line(points = {{220, -20}, {210, -20}}, color = {0, 127, 0}));
  connect(g.y, weight.f) annotation(
    Line(points = {{259, -20}, {242, -20}}, color = {0, 0, 127}));
  connect(mass.y, g.u) annotation(
    Line(points = {{299, -20}, {282, -20}}, color = {0, 0, 127}));
  connect(mcu.GND, ground.p) annotation(
    Line(points = {{0, -14}, {0, -56}, {-20, -56}, {-20, -60}}, color = {0, 0, 255}));
  connect(hx.GND, ground.p) annotation(
    Line(points = {{60, -32}, {60, -56}, {-20, -56}, {-20, -60}}, color = {0, 0, 255}));
  annotation(
    Diagram(coordinateSystem(extent = {{-40, -130}, {330, 60}})),
    experiment(StopTime = 2, Interval = 0.001, StartTime = 0, Tolerance = 1e-06),
    Documentation(info = "<html>
<p>The microcontroller reads an <strong>HX711</strong> with the MicroPython driver by Robert Hammelrath (<a href=\"https://github.com/robert-hh/hx711\">robert-hh/hx711</a>, <code>hx711_gpio.py</code>, placed unmodified next to the program <code>hx711_read.py</code>). The driver drives <code>PD_SCK</code> bit by bit and waits for each new data through an interrupt on the falling edge of <code>DOUT</code>: this is possible because each pin access takes 5 µs of simulated time (<code>mcu.gpioOpTime</code>).</p>
<p>The measurement chain is complete: a 1 kg mass (<code>mass</code>), its weight (<code>g</code>, <code>weight</code>), the 5 kg load cell body (<code>loadCell</code>), the gauge bridge (<code>bridge</code>, 1 mV/V at full load) and the converter (<code>hx</code>, without noise).</p>
<p>Expected codes: the bridge output is 1/5 of 1 mV/V, i.e. 0.2 mV/V; at gain 128, <code>code = 0.2e-3 × 128 × 2<sup>24</sup> ≈ 429,497</code>, and at gain 64, half of it (214,748). The program:</p>
<ol>
<li>reads a measurement at gain 128 (after the 400 ms settling time of the HX711);</li>
<li>switches to gain 64 (<code>set_gain(64)</code>: 27 pulses, the gain applies to the next conversion) and reads again;</li>
<li>shows <code>128:429497 64:214748</code>;</li>
<li>powers the HX711 down (<code>power_down()</code>: <code>PD_SCK</code> high for more than 60 µs), wakes it up 200 ms later, and reads again: the chip has restarted at gain 128, hence <code>wakeup:429497</code>.</li>
</ol>
<p>To watch: the icon of <code>hx</code> (gain, last code, \"data ready\" and \"power-down\" lights), <code>mcu.GP6.v</code> (the trains of 25 or 27 pulses of 5 µs), <code>mcu.GP7.v</code> (the bits of the data), and the log (the <code>print()</code> output of the program).</p>
</html>"));
end Hx711Read;
