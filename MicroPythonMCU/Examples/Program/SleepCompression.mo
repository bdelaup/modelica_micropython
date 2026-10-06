within MicroPythonMCU.Examples.Program;

model SleepCompression "Verification scenario no. 2: two simulated sleep(3600) must not each take an hour of real time"
  extends Modelica.Icons.Example;
  MCU mcu(scriptPath = Modelica.Utilities.Files.loadResource("modelica://MicroPythonMCU/Resources/Verification/sleep_long.py"), tickPeriod = 60) "scriptPath = Verification/sleep_long.py" annotation(
    Placement(transformation(origin = {0, 0}, extent = {{-20, -20}, {20, 20}})));
  Modelica.Electrical.Analog.Basic.Ground ground annotation(
    Placement(transformation(origin = {0, -62}, extent = {{-10, -10}, {10, 10}})));
  Modelica.Electrical.Analog.Basic.Resistor led(R = 1000) "Load simulating an LED on GP0" annotation(
    Placement(transformation(origin = {-62, 18}, extent = {{-10, -10}, {10, 10}})));
equation
  connect(mcu.GND, ground.p) annotation(
    Line(points = {{0, -14}, {0, -52}}, color = {0, 0, 255}));
  connect(mcu.GP0, led.n) annotation(
    Line(points = {{-12, 10}, {-32, 10}, {-32, 18}, {-52, 18}}, color = {0, 0, 255}));
  connect(led.p, ground.p) annotation(
    Line(points = {{-72, 18}, {-74, 18}, {-74, -48}, {0, -48}, {0, -52}}, color = {0, 0, 255}));
  annotation(
    Diagram(coordinateSystem(extent = {{-112, -84}, {56, 56}})),
    experiment(StopTime = 7250, Interval = 10),
    Documentation(info = "<html>
<p>Expected result: the simulation of 7250 s of simulated time (two 1 h sleeps) finishes in a few seconds of real time, not in ~2 h. <code>mcu.GP0.v</code> toggles at t=3600 s and t=7200 s.</p>
</html>"));
end SleepCompression;
