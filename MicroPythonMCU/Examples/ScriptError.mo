within MicroPythonMCU.Examples;

model ScriptError "Scénario de vérification v0 n°4 : une exception non gérée doit arrêter la simulation avec la trace visible dans le journal"
  extends Modelica.Icons.Example;
  MCU mcu(scriptPath = Modelica.Utilities.Files.loadResource("modelica://MicroPythonMCU/Resources/Verification/script_error.py")) "scriptPath = Verification/script_error.py" annotation(
    Placement(transformation(origin = {0, 0}, extent = {{-50, -50}, {50, 50}})));
  Modelica.Electrical.Analog.Basic.Ground ground annotation(
    Placement(transformation(origin = {0, -90}, extent = {{-15, -15}, {15, 15}})));
  Modelica.Electrical.Analog.Basic.Resistor led(R = 1000) "Charge simulant une LED sur GP0" annotation(
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
<p>Succès attendu : la simulation s'arrête en erreur après ≈1 s (après le <code>sleep(1)</code>), la trace Python (ZeroDivisionError) est visible dans le journal de simulation.</p>
</html>"));
end ScriptError;
