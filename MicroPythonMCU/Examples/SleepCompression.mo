within MicroPythonMCU.Examples;

model SleepCompression "Scénario de vérification v0 n°2 : deux sleep(3600) simulés ne doivent pas prendre une heure de temps réel chacun"
  extends Modelica.Icons.Example;
  MCU mcu(scriptPath = Modelica.Utilities.Files.loadResource("modelica://MicroPythonMCU/Resources/Verification/sleep_long.py"), tickPeriod = 60) "scriptPath = Verification/sleep_long.py" annotation(
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
    experiment(StopTime = 7250, Interval = 10),
    Documentation(info = "<html>
<p>Succès attendu : la simulation de 7250 s de temps simulé (deux sleep d'1 h) se termine en quelques secondes de temps réel, pas en ~2 h. <code>mcu.GP0.v</code> bascule à t=3600 s et t=7200 s.</p>
</html>"));
end SleepCompression;
