within MicroPythonMCU.Examples.Weighing;

model KitchenScale "Kitchen scale: I2C screen, microcontroller, HX711, gauge bridge, load cell body, weight; tare button"
  extends Modelica.Icons.Example;
  MCU mcu(scriptPath = Modelica.Utilities.Files.loadResource("modelica://MicroPythonMCU/Resources/Scripts/MCU/kitchen_scale.py")) "scriptPath = Resources/Scripts/MCU/kitchen_scale.py - imports the drivers hx711_gpio.py and driver_grove_lcd_rgb.py placed next to it" annotation(
    Placement(transformation(origin = {0, 0}, extent = {{-20, -20}, {20, 20}})));
  MicroPythonMCU.Peripherals.I2cGroveLcdRgb lcd "16x2 screen with RGB backlight, carrying the pull-ups of the I2C bus" annotation(
    Placement(transformation(origin = {60, 40}, extent = {{-20, -20}, {20, 20}})));
  MicroPythonMCU.Peripherals.Weighing.Hx711 hx(noiseLsb = 25) "Converter, with realistic noise (25 LSB, i.e. 0.06 g)" annotation(
    Placement(transformation(origin = {60, -20}, extent = {{-20, -20}, {20, 20}})));
  MicroPythonMCU.Peripherals.Weighing.WheatstoneBridge bridge "Four gauges bonded to the load cell body" annotation(
    Placement(transformation(origin = {130, -20}, extent = {{-20, -20}, {20, 20}})));
  MicroPythonMCU.Peripherals.Weighing.LoadCell loadCell "5 kg load cell body" annotation(
    Placement(transformation(origin = {190, -20}, extent = {{-20, -20}, {20, 20}})));
  Modelica.Mechanics.Translational.Sources.Force weight "The weight of what is on the pan (pan included)" annotation(
    Placement(transformation(origin = {230, -20}, extent = {{10, -10}, {-10, 10}})));
  Modelica.Blocks.Math.Gain g(k = Modelica.Constants.g_n) "Weight = mass × g" annotation(
    Placement(transformation(origin = {270, -20}, extent = {{10, -10}, {-10, 10}})));
  Modelica.Blocks.Math.Add totalMass "Total mass on the load cell body" annotation(
    Placement(transformation(origin = {310, -20}, extent = {{10, -10}, {-10, 10}})));
  Modelica.Blocks.Sources.Constant pan(k = 0.2) "Pan: 200 g, always present - the tare at start-up makes them disappear" annotation(
    Placement(transformation(origin = {350, 0}, extent = {{10, -10}, {-10, 10}})));
  Modelica.Blocks.Sources.TimeTable load(table = [0, 0; 2, 0; 2, 0.35; 4.5, 0.35; 5.5, 0.6; 7, 0.6]) "What is placed (kg): a 350 g bowl at t = 2 s, then 250 g of flour poured between 4.5 and 5.5 s" annotation(
    Placement(transformation(origin = {350, -40}, extent = {{10, -10}, {-10, 10}})));
  Modelica.Electrical.Analog.Sources.ConstantVoltage vcc(V = 3.3) "3.3 V supply of the button pull-up" annotation(
    Placement(transformation(origin = {-130, 50}, extent = {{-10, -10}, {10, 10}}, rotation = -90)));
  Modelica.Electrical.Analog.Basic.Resistor rPull(R = 10e3) "Pull-up resistor: button released, GP0 reads 1" annotation(
    Placement(transformation(origin = {-90, 50}, extent = {{-10, -10}, {10, 10}}, rotation = 90)));
  Modelica.Electrical.Analog.Basic.VariableConductor button "TARE button: contact to ground (controlled conductance, no ideal switching)" annotation(
    Placement(transformation(origin = {-90, 0}, extent = {{-10, -10}, {10, 10}}, rotation = 90)));
  Modelica.Blocks.Math.BooleanToReal contact(realTrue = 10, realFalse = 1e-9) "Pressed: 0.1 Ω; released: 1 GΩ" annotation(
    Placement(transformation(origin = {-152, 0}, extent = {{-10, -10}, {10, 10}})));
  Modelica.Blocks.Sources.BooleanTable press(table = {3.5, 3.7}) "TARE pressed from t = 3.5 s to 3.7 s, bowl in place" annotation(
    Placement(transformation(origin = {-182, 0}, extent = {{-10, -10}, {10, 10}})));
  Modelica.Electrical.Analog.Basic.Ground ground annotation(
    Placement(transformation(origin = {-20, -70}, extent = {{-10, -10}, {10, 10}})));
  Modelica.Electrical.Analog.Basic.Ground groundBtn annotation(
    Placement(transformation(origin = {-130, -40}, extent = {{-10, -10}, {10, 10}})));
  Modelica.Electrical.Analog.Basic.Ground groundLcd annotation(
    Placement(transformation(origin = {60, 14}, extent = {{-10, -10}, {10, 10}})));
equation
// Screen: I2C(scl=Pin(4), sda=Pin(5)), imposed by the driver
  connect(mcu.GP4, lcd.SCL) annotation(
    Line(points = {{12, 10}, {30, 10}, {30, 34}, {38, 34}}, color = {0, 0, 255}));
  connect(mcu.GP5, lcd.SDA) annotation(
    Line(points = {{12, 4}, {26, 4}, {26, 46}, {38, 46}}, color = {0, 0, 255}));
  connect(lcd.GND, groundLcd.p) annotation(
    Line(points = {{60, 28}, {60, 24}}, color = {0, 0, 255}));
// HX711: PD_SCK on GP6, DOUT on GP7
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
  connect(totalMass.y, g.u) annotation(
    Line(points = {{299, -20}, {282, -20}}, color = {0, 0, 127}));
  connect(pan.y, totalMass.u1) annotation(
    Line(points = {{339, 0}, {330, 0}, {330, -14}, {322, -14}}, color = {0, 0, 127}));
  connect(load.y, totalMass.u2) annotation(
    Line(points = {{339, -40}, {330, -40}, {330, -26}, {322, -26}}, color = {0, 0, 127}));
// TARE button on GP0: pull-up to 3.3 V, press = contact to ground
  connect(mcu.GP0, rPull.p) annotation(
    Line(points = {{-12, 10}, {-16, 10}, {-16, 36}, {-90, 36}, {-90, 40}}, color = {0, 0, 255}));
  connect(button.n, rPull.p) annotation(
    Line(points = {{-90, 10}, {-90, 40}}, color = {0, 0, 255}));
  connect(vcc.p, rPull.n) annotation(
    Line(points = {{-130, 60}, {-130, 76}, {-90, 76}, {-90, 60}}, color = {0, 0, 255}));
  connect(vcc.n, groundBtn.p) annotation(
    Line(points = {{-130, 40}, {-130, -30}}, color = {0, 0, 255}));
  connect(button.p, groundBtn.p) annotation(
    Line(points = {{-90, -10}, {-90, -26}, {-130, -26}, {-130, -30}}, color = {0, 0, 255}));
  connect(contact.y, button.G) annotation(
    Line(points = {{-141, 0}, {-102, 0}}, color = {0, 0, 127}));
  connect(press.y, contact.u) annotation(
    Line(points = {{-171, 0}, {-164, 0}}, color = {255, 0, 255}));
  connect(mcu.GND, ground.p) annotation(
    Line(points = {{0, -14}, {0, -56}, {-20, -56}, {-20, -60}}, color = {0, 0, 255}));
  connect(hx.GND, ground.p) annotation(
    Line(points = {{60, -32}, {60, -56}, {-20, -56}, {-20, -60}}, color = {0, 0, 255}));
  annotation(
    Diagram(coordinateSystem(extent = {{-200, -90}, {370, 120}})),
    experiment(StopTime = 7, Interval = 0.001, StartTime = 0, Tolerance = 1e-06),
    Documentation(info = "<html>
<p>A complete <strong>kitchen scale</strong>, from the mass placed on the pan to the display:</p>
<p><code>load</code> + <code>pan</code> (masses) → <code>g</code>, <code>weight</code> (weight: a force) → <code>loadCell</code> (load cell body, which deforms) → <code>bridge</code> (gauges: the strain unbalances the bridge, 1 mV/V at full load) → <code>hx</code> (HX711: amplification × 128 and 24-bit conversion) → <code>mcu</code> (program <code>kitchen_scale.py</code>) → <code>lcd</code> (Grove LCD RGB screen, I2C bus).</p>
<p>The program uses two off-the-shelf MicroPython drivers, unmodified: <code>hx711_gpio.py</code> (<a href=\"https://github.com/robert-hh/hx711\">robert-hh/hx711</a>) and <code>driver_grove_lcd_rgb.py</code>. It tares at start-up (the 200 g pan becomes the zero), converts the HX711 points into grams with a calibration constant (429.497 points per gram) and shows the result to the nearest gram. Only the characters that change are sent to the screen: each one costs an I2C transaction. Pressing the <strong>TARE</strong> button (<code>GP0</code>, interrupt on falling edge) resets the display to zero, bowl included.</p>
<p>Scenario:</p>
<ul>
<li>t = 0 to 1.1 s: start-up, tare of the empty pan (\"Tare...\");</li>
<li>t = 2 s: a 350 g bowl is placed → \"350 g\";</li>
<li>t = 3.5 s: TARE pressed → \"Tare...\", then \"0 g\" around 4.2 s;</li>
<li>t = 4.5 to 5.5 s: 250 g of flour are poured → the display rises up to \"250 g\".</li>
</ul>
<p>To watch: the icon of <code>lcd</code> during the animated replay; <code>hx.code</code> (the raw points, noise included); <code>mcu.GP6.v</code> and <code>mcu.GP7.v</code> (the HX711 frames); <code>mcu.GP4.v</code>/<code>mcu.GP5.v</code> (the I2C bus, active only when the display changes).</p>
<p>Lab ideas: calibrate the scale (find 429.497 points per gram again from a known mass); tune the filter of the driver (<code>set_time_constant</code>) and observe the trade-off between stability and speed; increase <code>hx.noiseLsb</code>; set <code>hx.rate</code> to 80 samples per second.</p>
</html>"));
end KitchenScale;
