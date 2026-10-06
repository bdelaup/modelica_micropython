within MicroPythonMCU.Examples.Adc;

model Sleep "ADC input (GP0) crossing the logic threshold during sleep(): neither early wake-up nor IRQ, since the ADC disconnects the digital input of the pin; GP1 (LED) confirms"
  extends Modelica.Icons.Example;
  MCU mcu(scriptPath = Modelica.Utilities.Files.loadResource("modelica://MicroPythonMCU/Resources/Scripts/MCU/adc_sleep.py")) "scriptPath = Resources/Scripts/MCU/adc_sleep.py" annotation(
    Placement(transformation(origin = {0, 0}, extent = {{-20, -20}, {20, 20}})));
  Modelica.Electrical.Analog.Basic.Ground ground annotation(
    Placement(transformation(origin = {0, -62}, extent = {{-10, -10}, {10, 10}})));
  Modelica.Electrical.Analog.Sources.SineVoltage sine(V = 1.65, f = 5, offset = 1.65) "voltage read by the ADC (GP0): 0-3.3 V sine wave at 5 Hz, which crosses the logic threshold (~1.4 V) 10 times per second" annotation(
    Placement(transformation(origin = {-76, -20}, extent = {{-10, -10}, {10, 10}}, rotation = -90)));
  Modelica.Electrical.Analog.Basic.Resistor r1(R = 330) "limits the current of led1 (GP1)" annotation(
    Placement(transformation(origin = {-62, 8}, extent = {{-10, -10}, {10, 10}})));
  MicroPythonMCU.Peripherals.LED led1 "GP1: the five sleep(0.2) lasted 200 ms and the IRQ saw no edge" annotation(
    Placement(transformation(origin = {-98, 8}, extent = {{-10, 10}, {10, -10}}, rotation = -180)));
equation
  connect(mcu.GND, ground.p) annotation(
    Line(points = {{0, -14}, {0, -52}}, color = {0, 0, 255}));
  connect(sine.p, mcu.GP0) annotation(
    Line(points = {{-76, -10}, {-76, -6}, {-16, -6}, {-16, 10}, {-12, 10}}, color = {0, 0, 255}));
  connect(sine.n, ground.p) annotation(
    Line(points = {{-76, -30}, {-76, -48}, {0, -48}, {0, -52}}, color = {0, 0, 255}));
  connect(mcu.GP1, r1.n) annotation(
    Line(points = {{-12, 4}, {-32, 4}, {-32, 8}, {-52, 8}}, color = {0, 0, 255}));
  connect(r1.p, led1.p) annotation(
    Line(points = {{-72, 8}, {-88, 8}}, color = {0, 0, 255}));
  connect(led1.n, ground.p) annotation(
    Line(points = {{-108, 8}, {-116, 8}, {-116, -48}, {0, -48}, {0, -52}}, color = {0, 0, 255}));
  annotation(
    Diagram(coordinateSystem(extent = {{-126, -84}, {56, 56}})),
    experiment(StopTime = 1.5, Interval = 0.001),
    Documentation(info = "<html>
<p>Verification scenario 26 (see <code>requirements.md</code>, decision \"ADC (entrées analogiques)\"): <code>GP0</code>, read by <code>machine.ADC(0)</code>, receives a 0 to 3.3 V sine wave at 5 Hz, which crosses the logic threshold of the pin 10 times per second. The script <code>adc_sleep.py</code> first arms an IRQ on both edges of <code>Pin(0)</code>, creates <code>ADC(0)</code>, then chains five <code>sleep(0.2)</code> while measuring their duration.</p>
<p>As on the RP2040, switching the pin to ADC disconnects its digital input: the threshold crossings must neither shorten the <code>sleep()</code> calls nor trigger the IRQ. <code>led1</code> (<code>GP1</code>) lights up if the five waits did last 200 ms and if the IRQ saw no edge. Before the fix, each crossing woke the script up like a real input transition.</p>
</html>"));
end Sleep;
