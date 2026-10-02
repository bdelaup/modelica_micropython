within MicroPythonMCU.Examples.Gpio;

model Pull "Internal pull resistors: two push buttons without any external resistor (Pin.PULL_UP, Pin.PULL_DOWN), and a pin whose pull is switched against a weak external resistor"
  extends Modelica.Icons.Example;
  MCU mcu(scriptPath = Modelica.Utilities.Files.loadResource("modelica://MicroPythonMCU/Resources/Scripts/MCU/gpio_pull.py")) "scriptPath = Scripts/MCU/gpio_pull.py" annotation(
    Placement(transformation(origin = {0, 0}, extent = {{-50, -50}, {50, 50}})));
  Modelica.Electrical.Analog.Basic.Ground ground annotation(
    Placement(transformation(origin = {0, -100}, extent = {{-15, -15}, {15, 15}})));
  // GP0: button to GND, internal pull-up
  Modelica.Electrical.Analog.Basic.VariableConductor buttonGnd "Push button from GP0 to GND (controlled conductance, no ideal switching)" annotation(
    Placement(transformation(origin = {-80, 25}, extent = {{-10, -10}, {10, 10}})));
  Modelica.Blocks.Math.BooleanToReal contactGnd(realTrue = 10, realFalse = 1e-9) "Pressed: 0.1 Ω; released: 1 GΩ" annotation(
    Placement(transformation(origin = {-80, 55}, extent = {{-10, -10}, {10, 10}}, rotation = 270)));
  Modelica.Blocks.Sources.BooleanTable pressGnd(table = {0.1, 0.2}) "GP0 button pressed from t = 0.1 s to 0.2 s" annotation(
    Placement(transformation(origin = {-80, 85}, extent = {{-10, -10}, {10, 10}}, rotation = 270)));
  Modelica.Electrical.Analog.Basic.Ground groundGnd annotation(
    Placement(transformation(origin = {-100, 12}, extent = {{-6, -6}, {6, 6}})));
  // GP3: button to 3.3 V, internal pull-down
  Modelica.Electrical.Analog.Basic.VariableConductor buttonVcc "Push button from GP3 to 3.3 V" annotation(
    Placement(transformation(origin = {-80, -25}, extent = {{-10, 10}, {10, -10}})));
  Modelica.Blocks.Math.BooleanToReal contactVcc(realTrue = 10, realFalse = 1e-9) "Pressed: 0.1 Ω; released: 1 GΩ" annotation(
    Placement(transformation(origin = {-80, -55}, extent = {{-10, -10}, {10, 10}}, rotation = 90)));
  Modelica.Blocks.Sources.BooleanTable pressVcc(table = {0.4, 0.5}) "GP3 button pressed from t = 0.4 s to 0.5 s" annotation(
    Placement(transformation(origin = {-80, -85}, extent = {{-10, -10}, {10, 10}}, rotation = 90)));
  Modelica.Electrical.Analog.Sources.ConstantVoltage vccButton(V = 3.3) "3.3 V supply of the GP3 button" annotation(
    Placement(transformation(origin = {-110, -45}, extent = {{-10, -10}, {10, 10}}, rotation = 270)));
  Modelica.Electrical.Analog.Basic.Ground groundVcc annotation(
    Placement(transformation(origin = {-110, -68}, extent = {{-6, -6}, {6, 6}})));
  // GP4: weak external pull-up, internal pull switched by the program
  Modelica.Electrical.Analog.Basic.Resistor rWeak(R = 1e6) "Weak resistor (1 MΩ) from GP4 to 3.3 V: wins when the pin has no pull, loses against the internal pull-down" annotation(
    Placement(transformation(origin = {60, 40}, extent = {{-10, -10}, {10, 10}}, rotation = 270)));
  Modelica.Electrical.Analog.Sources.ConstantVoltage vccWeak(V = 3.3) annotation(
    Placement(transformation(origin = {90, 40}, extent = {{-10, -10}, {10, 10}}, rotation = 270)));
  Modelica.Electrical.Analog.Basic.Ground groundWeak annotation(
    Placement(transformation(origin = {90, 17}, extent = {{-6, -6}, {6, 6}})));
  // GP6, GP7: loads standing for LEDs
  Modelica.Electrical.Analog.Basic.Resistor ledGnd(R = 1000) "Load standing for an LED: lit while the GP0 button is pressed" annotation(
    Placement(transformation(origin = {60, -10}, extent = {{-10, -10}, {10, 10}})));
  Modelica.Electrical.Analog.Basic.Resistor ledVcc(R = 1000) "Load standing for an LED: lit while the GP3 button is pressed" annotation(
    Placement(transformation(origin = {60, -25}, extent = {{-10, -10}, {10, 10}})));
  Modelica.Electrical.Analog.Basic.Ground groundLed annotation(
    Placement(transformation(origin = {85, -45}, extent = {{-6, -6}, {6, 6}})));
equation
  connect(mcu.GND, ground.p) annotation(
    Line(points = {{0, -39}, {0, -85}}, color = {0, 0, 255}));
  // GP0
  connect(mcu.GP0, buttonGnd.n) annotation(
    Line(points = {{-31, 25}, {-70, 25}}, color = {0, 0, 255}));
  connect(buttonGnd.p, groundGnd.p) annotation(
    Line(points = {{-90, 25}, {-100, 25}, {-100, 18}}, color = {0, 0, 255}));
  connect(contactGnd.y, buttonGnd.G) annotation(
    Line(points = {{-80, 44}, {-80, 37}}, color = {0, 0, 127}));
  connect(pressGnd.y, contactGnd.u) annotation(
    Line(points = {{-80, 74}, {-80, 67}}, color = {255, 0, 255}));
  // GP3
  connect(mcu.GP3, buttonVcc.n) annotation(
    Line(points = {{-31, -25}, {-70, -25}}, color = {0, 0, 255}));
  connect(buttonVcc.p, vccButton.p) annotation(
    Line(points = {{-90, -25}, {-110, -25}, {-110, -35}}, color = {0, 0, 255}));
  connect(vccButton.n, groundVcc.p) annotation(
    Line(points = {{-110, -55}, {-110, -62}}, color = {0, 0, 255}));
  connect(contactVcc.y, buttonVcc.G) annotation(
    Line(points = {{-80, -44}, {-80, -37}}, color = {0, 0, 127}));
  connect(pressVcc.y, contactVcc.u) annotation(
    Line(points = {{-80, -74}, {-80, -67}}, color = {255, 0, 255}));
  // GP4
  connect(mcu.GP4, rWeak.n) annotation(
    Line(points = {{31, 25}, {60, 25}, {60, 30}}, color = {0, 0, 255}));
  connect(vccWeak.p, rWeak.p) annotation(
    Line(points = {{90, 50}, {90, 55}, {60, 55}, {60, 50}}, color = {0, 0, 255}));
  connect(vccWeak.n, groundWeak.p) annotation(
    Line(points = {{90, 30}, {90, 23}}, color = {0, 0, 255}));
  // GP6, GP7
  connect(mcu.GP6, ledGnd.p) annotation(
    Line(points = {{31, -10}, {50, -10}}, color = {0, 0, 255}));
  connect(mcu.GP7, ledVcc.p) annotation(
    Line(points = {{31, -25}, {50, -25}}, color = {0, 0, 255}));
  connect(ledGnd.n, groundLed.p) annotation(
    Line(points = {{70, -10}, {85, -10}, {85, -39}}, color = {0, 0, 255}));
  connect(ledVcc.n, groundLed.p) annotation(
    Line(points = {{70, -25}, {85, -25}, {85, -39}}, color = {0, 0, 255}));
  annotation(
    Diagram(coordinateSystem(extent = {{-130, 100}, {110, -120}})),
    experiment(StopTime = 1, Interval = 0.001),
    Documentation(info = "<html>
<p>The internal pull resistors of the microcontroller (<code>mcu.RPullUp</code>, <code>mcu.RPullDown</code>, 50 kΩ), switched on by <code>Pin(n, mode, pull)</code>. Program: <code>Scripts/MCU/gpio_pull.py</code>.</p>
<ul>
<li><code>GP0</code>: push button to GND, <strong>no external resistor</strong>, <code>Pin.PULL_UP</code>. Released, the pull-up holds the pin at 3.3 V; pressed from t = 0.1 s to 0.2 s, it falls to 0 V. <code>GP6</code> lights up meanwhile.</li>
<li><code>GP3</code>: push button to 3.3 V, <code>Pin.PULL_DOWN</code>: 0 V released, 3.3 V pressed from t = 0.4 s to 0.5 s. <code>GP7</code> lights up meanwhile.</li>
<li><code>GP4</code>: only a weak 1 MΩ resistor to 3.3 V. Without pull (0-0.3 s), the input is a real high impedance and the 1 MΩ alone brings it to 3.3 V; with the internal pull-down (0.3-0.6 s), the divider gives 0.16 V; with the pull-up (from 0.6 s), 3.3 V again.</li>
</ul>
<p>Plot <code>mcu.GP0.v</code>, <code>mcu.GP3.v</code>, <code>mcu.GP4.v</code>, <code>mcu.GP6.v</code> and <code>mcu.GP7.v</code>. The simulation log shows what the program reads on <code>GP4</code> in each phase.</p>
</html>"));
end Pull;
