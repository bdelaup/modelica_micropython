within MicroPythonMCU.Examples.Program;

model Error "Verification scenario no. 4: an unhandled exception must stop the simulation with the traceback visible in the log"
  extends Modelica.Icons.Example;
  MCU mcu(scriptPath = Modelica.Utilities.Files.loadResource("modelica://MicroPythonMCU/Resources/Verification/script_error.py")) "scriptPath = Verification/script_error.py" annotation(
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
    experiment(StopTime = 5),
    Documentation(info = "<html>
<p>Expected result: the simulation stops with an error after ≈1 s (after the <code>sleep(1)</code>), the Python traceback (ZeroDivisionError) is visible in the simulation log.</p>
</html>"));
end Error;
