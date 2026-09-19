within MicroPythonMCU.Examples;
model SleepCompression "Scénario de vérification v0 n°2 : deux sleep(3600) simulés ne doivent pas prendre une heure de temps réel chacun"
  extends Modelica.Icons.Example;
  Pico pico(scriptPath = Modelica.Utilities.Files.loadResource("modelica://MicroPythonMCU/Resources/Verification/sleep_long.py"), tickPeriod = 60) annotation(
    Placement(transformation(extent = {{-95, -80}, {-25, 80}})));
  Modelica.Electrical.Analog.Basic.Ground ground annotation(Placement(transformation(extent = {{-60, -98}, {-40, -88}})));
  Modelica.Electrical.Analog.Basic.Resistor led(R = 1000) "Charge simulant une LED sur GP0" annotation(Placement(transformation(extent = {{0, 60}, {20, 80}})));
  Modelica.Electrical.Analog.Basic.Resistor pulldown1(R = 1000)"GP1" annotation(
    Placement(transformation(extent = {{0, 40}, {20, 60}})));
  Modelica.Electrical.Analog.Basic.Resistor pulldown2(R = 1000) "GP2" annotation(
    Placement(transformation(extent = {{0, 20}, {20, 40}})));
  Modelica.Electrical.Analog.Basic.Resistor pulldown3(R = 1000) "GP3" annotation(
    Placement(transformation(extent = {{0, 0}, {20, 20}})));
  Modelica.Electrical.Analog.Basic.Resistor pulldown4(R = 1000) "GP4" annotation(
    Placement(transformation(extent = {{0, -20}, {20, 0}})));
  Modelica.Electrical.Analog.Basic.Resistor pulldown5(R = 1000) "GP5" annotation(
    Placement(transformation(extent = {{0, -40}, {20, -20}})));
  Modelica.Electrical.Analog.Basic.Resistor pulldown6(R = 1000) "GP6" annotation(
    Placement(transformation(extent = {{0, -60}, {20, -40}})));
  Modelica.Electrical.Analog.Basic.Resistor pulldown7(R = 1000) "GP7" annotation(
    Placement(transformation(extent = {{0, -80}, {20, -60}})));
equation
  connect(pico.GND, ground.p) annotation(
    Line(points = {{-60, -70}, {-60, -88}, {-50, -88}}, color = {0, 0, 255}));
  connect(pico.GP0, led.p) annotation(
    Line(points = {{-25, 56}, {0, 56}, {0, 70}}, color = {0, 0, 255})); connect(led.n, ground.p) annotation(
    Line(points = {{20, 70}, {30, 70}, {30, -88}, {-50, -88}}, color = {0, 0, 255}));
  connect(pico.GP1, pulldown1.p) annotation(
    Line(points = {{-25, 40}, {0, 40}, {0, 50}}, color = {0, 0, 255})); connect(pulldown1.n, ground.p) annotation(
    Line(points = {{20, 50}, {32, 50}, {32, -88}, {-50, -88}}, color = {0, 0, 255}));
  connect(pico.GP2, pulldown2.p) annotation(
    Line(points = {{-25, 24}, {0, 24}, {0, 30}}, color = {0, 0, 255})); connect(pulldown2.n, ground.p) annotation(
    Line(points = {{20, 30}, {34, 30}, {34, -88}, {-50, -88}}, color = {0, 0, 255}));
  connect(pico.GP3, pulldown3.p) annotation(
    Line(points = {{-25, 8}, {0, 8}, {0, 10}}, color = {0, 0, 255})); connect(pulldown3.n, ground.p) annotation(
    Line(points = {{20, 10}, {36, 10}, {36, -88}, {-50, -88}}, color = {0, 0, 255}));
  connect(pico.GP4, pulldown4.p) annotation(
    Line(points = {{-25, -8}, {0, -8}, {0, -10}}, color = {0, 0, 255})); connect(pulldown4.n, ground.p) annotation(
    Line(points = {{20, -10}, {38, -10}, {38, -88}, {-50, -88}}, color = {0, 0, 255}));
  connect(pico.GP5, pulldown5.p) annotation(
    Line(points = {{-25, -24}, {0, -24}, {0, -30}}, color = {0, 0, 255})); connect(pulldown5.n, ground.p) annotation(
    Line(points = {{20, -30}, {40, -30}, {40, -88}, {-50, -88}}, color = {0, 0, 255}));
  connect(pico.GP6, pulldown6.p) annotation(
    Line(points = {{-25, -40}, {0, -40}, {0, -50}}, color = {0, 0, 255})); connect(pulldown6.n, ground.p) annotation(
    Line(points = {{20, -50}, {42, -50}, {42, -88}, {-50, -88}}, color = {0, 0, 255}));
  connect(pico.GP7, pulldown7.p) annotation(
    Line(points = {{-25, -56}, {0, -56}, {0, -70}}, color = {0, 0, 255})); connect(pulldown7.n, ground.p) annotation(
    Line(points = {{20, -70}, {44, -70}, {44, -88}, {-50, -88}}, color = {0, 0, 255}));
  annotation(
    experiment(StopTime = 7250, Interval = 10),
    Documentation(info = "<html>
<p>Succès attendu : la simulation de 7250 s de temps simulé (deux sleep d'1 h) se termine en quelques secondes de temps réel, pas en ~2 h. <code>pico.GP0.v</code> bascule à t=3600 s et t=7200 s.</p>
</html>"));
end SleepCompression;
