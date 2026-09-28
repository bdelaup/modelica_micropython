within MicroPythonMCU.Examples.Adc;

model Sleep "ADC input (GP0) crossing the logic threshold during sleep(): neither early wake-up nor IRQ, since the ADC disconnects the digital input of the pin; GP1 (LED) confirms"
  extends Modelica.Icons.Example;
  MCU mcu(scriptPath = Modelica.Utilities.Files.loadResource("modelica://MicroPythonMCU/Resources/Scripts/MCU/adc_sleep.py")) "scriptPath = Resources/Scripts/MCU/adc_sleep.py" annotation(
    Placement(transformation(origin = {0, 0}, extent = {{-50, -50}, {50, 50}})));
  Modelica.Electrical.Analog.Basic.Ground ground annotation(
    Placement(transformation(origin = {0, -90}, extent = {{-15, -15}, {15, 15}})));
  Modelica.Electrical.Analog.Sources.SineVoltage sine(V = 1.65, f = 5, offset = 1.65) "voltage read by the ADC (GP0): 0-3.3 V sine wave at 5 Hz, which crosses the logic threshold (~1.4 V) 10 times per second" annotation(
    Placement(transformation(origin = {-110, -30}, extent = {{-15, -15}, {15, 15}}, rotation = -90)));
  Modelica.Electrical.Analog.Basic.Resistor r1(R = 330) "limits the current of led1 (GP1)" annotation(
    Placement(transformation(origin = {-90, 10}, extent = {{-15, -15}, {15, 15}})));
  MicroPythonMCU.Peripherals.LED led1 "GP1: the five sleep(0.2) lasted 200 ms and the IRQ saw no edge" annotation(
    Placement(transformation(origin = {-140, 10}, extent = {{-15, 15}, {15, -15}}, rotation = -180)));
equation
  connect(mcu.GND, ground.p) annotation(
    Line(points = {{0, -39}, {0, -75}}, color = {0, 0, 255}));
  connect(sine.p, mcu.GP0) annotation(
    Line(points = {{-110, -15}, {-110, 25}, {-31, 25}}, color = {0, 0, 255}));
  connect(sine.n, ground.p) annotation(
    Line(points = {{-110, -45}, {-110, -75}, {0, -75}}, color = {0, 0, 255}));
  connect(mcu.GP1, r1.n) annotation(
    Line(points = {{-31, 10}, {-75, 10}}, color = {0, 0, 255}));
  connect(r1.p, led1.p) annotation(
    Line(points = {{-105, 10}, {-125, 10}}, color = {0, 0, 255}));
  connect(led1.n, ground.p) annotation(
    Line(points = {{-155, 10}, {-165, 10}, {-165, -75}, {0, -75}}, color = {0, 0, 255}));
  annotation(
    Diagram(coordinateSystem(extent = {{-180, -120}, {80, 80}})),
    experiment(StopTime = 1.5, Interval = 0.001),
    Documentation(info = "<html>
<p>Verification scenario 26 (see <code>requirements.md</code>, decision \"ADC (entrées analogiques)\"): <code>GP0</code>, read by <code>machine.ADC(0)</code>, receives a 0 to 3.3 V sine wave at 5 Hz, which crosses the logic threshold of the pin 10 times per second. The script <code>adc_sleep.py</code> first arms an IRQ on both edges of <code>Pin(0)</code>, creates <code>ADC(0)</code>, then chains five <code>sleep(0.2)</code> while measuring their duration.</p>
<p>As on the RP2040, switching the pin to ADC disconnects its digital input: the threshold crossings must neither shorten the <code>sleep()</code> calls nor trigger the IRQ. <code>led1</code> (<code>GP1</code>) lights up if the five waits did last 200 ms and if the IRQ saw no edge. Before the fix, each crossing woke the script up like a real input transition.</p>
</html>"));
end Sleep;
