within MicroPythonMCU.Examples.Weighing;

model KitchenScale "Kitchen scale: I2C screen, microcontroller, HX711, gauge bridge, load cell body, weight; tare button"
  extends Modelica.Icons.Example;
  MCU mcu(scriptPath = Modelica.Utilities.Files.loadResource("modelica://MicroPythonMCU/Resources/Scripts/MCU/kitchen_scale.py")) "scriptPath = Resources/Scripts/MCU/kitchen_scale.py - imports the drivers hx711_gpio.py and driver_grove_lcd_rgb.py placed next to it" annotation(
    Placement(transformation(origin = {0, 0}, extent = {{-50, -50}, {50, 50}})));
  MicroPythonMCU.Peripherals.I2cGroveLcdRgb lcd "16x2 screen with RGB backlight, carrying the pull-ups of the I2C bus" annotation(
    Placement(transformation(origin = {150, 100}, extent = {{-50, -50}, {50, 50}})));
  MicroPythonMCU.Peripherals.Weighing.Hx711 hx(noiseLsb = 25) "Converter, with realistic noise (25 LSB, i.e. 0.06 g)" annotation(
    Placement(transformation(origin = {149, -19}, extent = {{-29, -29}, {29, 29}})));
  MicroPythonMCU.Peripherals.Weighing.WheatstoneBridge bridge "Four gauges bonded to the load cell body" annotation(
    Placement(transformation(origin = {262, -20}, extent = {{-28, -28}, {28, 28}})));
  MicroPythonMCU.Peripherals.Weighing.LoadCell loadCell "5 kg load cell body" annotation(
    Placement(transformation(origin = {359, -17}, extent = {{-25, -25}, {25, 25}})));
  Modelica.Mechanics.Translational.Sources.Force weight "The weight of what is on the pan (pan included)" annotation(
    Placement(transformation(origin = {430, -20}, extent = {{10, -10}, {-10, 10}})));
  Modelica.Blocks.Math.Gain g(k = Modelica.Constants.g_n) "Weight = mass × g" annotation(
    Placement(transformation(origin = {470, -20}, extent = {{10, -10}, {-10, 10}})));
  Modelica.Blocks.Math.Add totalMass "Total mass on the load cell body" annotation(
    Placement(transformation(origin = {510, -20}, extent = {{10, -10}, {-10, 10}})));
  Modelica.Blocks.Sources.Constant pan(k = 0.2) "Pan: 200 g, always present - the tare at start-up makes them disappear" annotation(
    Placement(transformation(origin = {550, 0}, extent = {{10, -10}, {-10, 10}})));
  Modelica.Blocks.Sources.TimeTable load(table = [0, 0; 2, 0; 2, 0.35; 4.5, 0.35; 5.5, 0.6; 7, 0.6]) "What is placed (kg): a 350 g bowl at t = 2 s, then 250 g of flour poured between 4.5 and 5.5 s" annotation(
    Placement(transformation(origin = {550, -40}, extent = {{10, -10}, {-10, 10}})));
  Modelica.Electrical.Analog.Sources.ConstantVoltage vcc(V = 3.3) "3.3 V supply of the button pull-up" annotation(
    Placement(transformation(origin = {-130, 50}, extent = {{-10, -10}, {10, 10}}, rotation = -90)));
  Modelica.Electrical.Analog.Basic.Resistor rPull(R = 10e3) "Pull-up resistor: button released, GP0 reads 1" annotation(
    Placement(transformation(origin = {-90, 50}, extent = {{-10, -10}, {10, 10}}, rotation = 90)));
  Modelica.Electrical.Analog.Basic.VariableConductor button "TARE button: contact to ground (controlled conductance, no ideal switching)" annotation(
    Placement(transformation(origin = {-90, 0}, extent = {{-10, -10}, {10, 10}}, rotation = 90)));
  Modelica.Blocks.Math.BooleanToReal contact(realTrue = 10, realFalse = 1e-9) "Pressed: 0.1 Ω; released: 1 GΩ" annotation(
    Placement(transformation(origin = {-125, 0}, extent = {{-10, -10}, {10, 10}})));
  Modelica.Blocks.Sources.BooleanTable press(table = {3.5, 3.7}) "TARE pressed from t = 3.5 s to 3.7 s, bowl in place" annotation(
    Placement(transformation(origin = {-160, 0}, extent = {{-10, -10}, {10, 10}})));
  Modelica.Electrical.Analog.Basic.Ground ground annotation(
    Placement(transformation(origin = {60, -100}, extent = {{-10, -10}, {10, 10}})));
  Modelica.Electrical.Analog.Basic.Ground groundBtn annotation(
    Placement(transformation(origin = {-130, -40}, extent = {{-10, -10}, {10, 10}})));
  Modelica.Electrical.Analog.Basic.Ground groundLcd annotation(
    Placement(transformation(origin = {150, 35}, extent = {{-10, -10}, {10, 10}})));
equation
// Screen: I2C(scl=Pin(4), sda=Pin(5)), imposed by the driver
  connect(mcu.GP4, lcd.SCL) annotation(
    Line(points = {{31, 25}, {60, 25}, {60, 83}, {88, 83}}, color = {0, 0, 255}));
  connect(mcu.GP5, lcd.SDA) annotation(
    Line(points = {{31, 10}, {70, 10}, {70, 117}, {88, 117}}, color = {0, 0, 255}));
  connect(lcd.GND, groundLcd.p) annotation(
    Line(points = {{150, 64}, {150, 45}}, color = {0, 0, 255}));
// HX711: PD_SCK on GP6, DOUT on GP7
  connect(mcu.GP6, hx.PD_SCK) annotation(
    Line(points = {{31, -10}, {113, -10}}, color = {0, 0, 255}));
  connect(mcu.GP7, hx.DOUT) annotation(
    Line(points = {{31, -25}, {66, -25}, {66, -28}, {113, -28}}, color = {0, 0, 255}));
  connect(hx.E_plus, bridge.E_plus) annotation(
    Line(points = {{185, -6}, {210.5, -6}, {210.5, -7}, {231, -7}}, color = {0, 0, 255}));
  connect(hx.A_plus, bridge.S_plus) annotation(
    Line(points = {{185, -15}, {210.5, -15}, {210.5, -16}, {231, -16}}, color = {0, 0, 255}));
  connect(hx.A_minus, bridge.S_minus) annotation(
    Line(points = {{185, -23}, {193.5, -23}, {193.5, -24}, {231, -24}}, color = {0, 0, 255}));
  connect(hx.E_minus, bridge.E_minus) annotation(
    Line(points = {{185, -32}, {193.5, -32}, {193.5, -33}, {231, -33}}, color = {0, 0, 255}));
  connect(loadCell.eps, bridge.eps) annotation(
    Line(points = {{331.5, -17}, {305.5, -17}, {305.5, -20}, {296, -20}}, color = {0, 0, 127}));
  connect(weight.flange, loadCell.flange) annotation(
    Line(points = {{420, -20}, {420, -7.5}, {384, -7.5}, {384, -17}}, color = {0, 127, 0}));
  connect(g.y, weight.f) annotation(
    Line(points = {{459, -20}, {442, -20}}, color = {0, 0, 127}));
  connect(totalMass.y, g.u) annotation(
    Line(points = {{499, -20}, {482, -20}}, color = {0, 0, 127}));
  connect(pan.y, totalMass.u1) annotation(
    Line(points = {{539, 0}, {530, 0}, {530, -14}, {522, -14}}, color = {0, 0, 127}));
  connect(load.y, totalMass.u2) annotation(
    Line(points = {{539, -40}, {530, -40}, {530, -26}, {522, -26}}, color = {0, 0, 127}));
// TARE button on GP0: pull-up to 3.3 V, press = contact to ground
  connect(mcu.GP0, rPull.p) annotation(
    Line(points = {{-31, 25}, {-90, 25}, {-90, 40}}, color = {0, 0, 255}));
  connect(button.n, rPull.p) annotation(
    Line(points = {{-90, 10}, {-90, 40}}, color = {0, 0, 255}));
  connect(vcc.p, rPull.n) annotation(
    Line(points = {{-130, 60}, {-130, 75}, {-90, 75}, {-90, 60}}, color = {0, 0, 255}));
  connect(vcc.n, groundBtn.p) annotation(
    Line(points = {{-130, 40}, {-130, -30}}, color = {0, 0, 255}));
  connect(button.p, groundBtn.p) annotation(
    Line(points = {{-90, -10}, {-90, -30}, {-130, -30}}, color = {0, 0, 255}));
  connect(contact.y, button.G) annotation(
    Line(points = {{-114, 0}, {-102, 0}}, color = {0, 0, 127}));
  connect(press.y, contact.u) annotation(
    Line(points = {{-149, 0}, {-137, 0}}, color = {255, 0, 255}));
  connect(mcu.GND, ground.p) annotation(
    Line(points = {{0, -39}, {0, -90}, {60, -90}}, color = {0, 0, 255}));
  connect(hx.GND, ground.p) annotation(
    Line(points = {{149, -40}, {149, -90}, {60, -90}}, color = {0, 0, 255}));
  annotation(
    Diagram(coordinateSystem(extent = {{-180, -120}, {570, 160}})),
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
