within MicroPythonMCU.Examples.Program;

model SleepCompression "Verification scenario no. 2: two simulated sleep(3600) must not each take an hour of real time"
  extends Modelica.Icons.Example;
  MCU mcu(scriptPath = Modelica.Utilities.Files.loadResource("modelica://MicroPythonMCU/Resources/Verification/sleep_long.py"), tickPeriod = 60) "scriptPath = Verification/sleep_long.py" annotation(
    Placement(transformation(origin = {0, 0}, extent = {{-50, -50}, {50, 50}})));
  Modelica.Electrical.Analog.Basic.Ground ground annotation(
    Placement(transformation(origin = {0, -90}, extent = {{-15, -15}, {15, 15}})));
  Modelica.Electrical.Analog.Basic.Resistor led(R = 1000) "Load simulating an LED on GP0" annotation(
    Placement(transformation(origin = {-90, 25}, extent = {{-15, -15}, {15, 15}})));
equation
  connect(mcu.GND, ground.p) annotation(
    Line(points = {{0, -39}, {0, -75}}, color = {0, 0, 255}));
  connect(mcu.GP0, led.n) annotation(
    Line(points = {{-31, 25}, {-75, 25}}, color = {0, 0, 255}));
  connect(led.p, ground.p) annotation(
    Line(points = {{-105, 25}, {-105, -75}, {0, -75}}, color = {0, 0, 255}));
  annotation(
    Diagram(coordinateSystem(extent = {{-160, -120}, {80, 80}})),
    experiment(StopTime = 7250, Interval = 10),
    Documentation(info = "<html>
<p>Expected result: the simulation of 7250 s of simulated time (two 1 h sleeps) finishes in a few seconds of real time, not in ~2 h. <code>mcu.GP0.v</code> toggles at t=3600 s and t=7200 s.</p>
</html>"));
end SleepCompression;
