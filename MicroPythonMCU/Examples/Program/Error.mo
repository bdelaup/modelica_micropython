within MicroPythonMCU.Examples.Program;

model Error "v0 verification scenario no. 4: an unhandled exception must stop the simulation with the traceback visible in the log"
  extends Modelica.Icons.Example;
  MCU mcu(scriptPath = Modelica.Utilities.Files.loadResource("modelica://MicroPythonMCU/Resources/Verification/script_error.py")) "scriptPath = Verification/script_error.py" annotation(
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
    experiment(StopTime = 5),
    Documentation(info = "<html>
<p>Expected result: the simulation stops with an error after ≈1 s (after the <code>sleep(1)</code>), the Python traceback (ZeroDivisionError) is visible in the simulation log.</p>
</html>"));
end Error;
