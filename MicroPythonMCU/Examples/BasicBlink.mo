within MicroPythonMCU.Examples;

model BasicBlink "Scénario de vérification v0 n°1 : le script de démo par défaut fait clignoter GP0 (LED externe) et la LED embarquée à 1 Hz"
  extends Modelica.Icons.Example;
  MCU mcu "scriptPath par défaut = Resources/Scripts/demo.py" annotation(
    Placement(transformation(origin = {0, 0}, extent = {{-50, -50}, {50, 50}})));
  Modelica.Electrical.Analog.Basic.Ground ground annotation(
    Placement(transformation(origin = {0, -90}, extent = {{-15, -15}, {15, 15}})));
  Modelica.Electrical.Analog.Basic.Resistor r0(R = 330) "limite le courant de led0 (GP0)" annotation(
    Placement(transformation(origin = {-90, 25}, extent = {{-15, -15}, {15, 15}})));
  MicroPythonMCU.Utils.LED led0 "GP0 : clignote en même temps que la LED embarquée" annotation(
    Placement(transformation(origin = {-128, 25}, extent = {{-15, 15}, {15, -15}}, rotation = -180)));
equation
  connect(mcu.GND, ground.p) annotation(
    Line(points = {{0, -39}, {0, -75}}, color = {0, 0, 255}));
  connect(mcu.GP0, r0.n) annotation(
    Line(points = {{-31, 25}, {-75, 25}}, color = {0, 0, 255}));
  connect(r0.p, led0.p) annotation(
    Line(points = {{-105, 25}, {-113, 25}}, color = {0, 0, 255}));
  connect(led0.n, ground.p) annotation(
    Line(points = {{-143, 25}, {-149.5, 25}, {-149.5, -75}, {0, -75}}, color = {0, 0, 255}));
  annotation(
    Diagram(coordinateSystem(extent = {{-200, -120}, {80, 80}})),
    experiment(StopTime = 4.5, Interval = 0.001, StartTime = 0, Tolerance = 1e-06),
    Documentation(info = "<html>
<p>Succès attendu : la trace de <code>mcu.GP0.v</code> montre un créneau périodique 0 V / ≈3 V de période 2 s (1 s allumé, 1 s éteint) ; la LED embarquée (icône de <code>mcu</code>) clignote en phase avec <code>led0</code> (le script <code>demo.py</code> pilote les deux ensemble).</p>
</html>"));
end BasicBlink;
