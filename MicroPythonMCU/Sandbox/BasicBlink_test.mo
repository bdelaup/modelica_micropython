within MicroPythonMCU.Sandbox;

model BasicBlink_test "Scénario de vérification v0 n°1 : le script de démo par défaut fait clignoter GP0 à 1 Hz"
  extends Modelica.Icons.Example;
  MCU mcu(scriptPath = "D:/benoit/OneDrive - LYCEE Jules Haag/modelica_micropython3/MicroPythonMCU/Sandbox/BasicBlink_test.py")  "scriptPath par défaut = Resources/Scripts/MCU/demo.py" annotation(
    Placement(transformation(extent = {{-250, -100}, {-50, 100}})));
  Modelica.Electrical.Analog.Basic.Ground ground annotation(
    Placement(transformation(extent = {{-160, -190}, {-140, -180}})));
  Modelica.Electrical.Analog.Basic.Resistor led(R = 1000) "Charge simulant une LED sur GP0" annotation(
    Placement(transformation(extent = {{-300, 40}, {-280, 60}})));
  Modelica.Electrical.Analog.Basic.Resistor pulldown1(R = 1000) "GP1" annotation(
    Placement(transformation(extent = {{-300, 10}, {-280, 30}})));
  Modelica.Electrical.Analog.Basic.Resistor pulldown2(R = 1000) "GP2" annotation(
    Placement(transformation(extent = {{-300, -30}, {-280, -10}})));
  Modelica.Electrical.Analog.Basic.Resistor pulldown3(R = 1000) "GP3" annotation(
    Placement(transformation(extent = {{-300, -60}, {-280, -40}})));
  Modelica.Electrical.Analog.Basic.Resistor pulldown4(R = 1000) "GP4" annotation(
    Placement(transformation(extent = {{-20, 40}, {0, 60}})));
  Modelica.Electrical.Analog.Basic.Resistor pulldown5(R = 1000) "GP5" annotation(
    Placement(transformation(extent = {{-20, 10}, {0, 30}})));
  Modelica.Electrical.Analog.Basic.Resistor pulldown6(R = 1000) "GP6" annotation(
    Placement(transformation(extent = {{-20, -30}, {0, -10}})));
  Modelica.Electrical.Analog.Basic.Resistor pulldown7(R = 220) "GP7" annotation(
    Placement(transformation(origin = {-24, 0}, extent = {{-20, -60}, {0, -40}})));
  Peripherals.LED led1 annotation(
    Placement(transformation(origin = {-58, -100}, extent = {{-10, -10}, {10, 10}})));
equation
  connect(mcu.GND, ground.p) annotation(
    Line(points = {{-150, -78}, {-150, -180}}, color = {0, 0, 255}));
  connect(mcu.GP0, led.n) annotation(
    Line(points = {{-212, 50}, {-280, 50}}, color = {0, 0, 255}));
  connect(led.p, ground.p) annotation(
    Line(points = {{-300, 50}, {-300, -200}, {-150, -200}, {-150, -180}}, color = {0, 0, 255}));
  connect(mcu.GP1, pulldown1.n) annotation(
    Line(points = {{-212, 20}, {-280, 20}}, color = {0, 0, 255}));
  connect(pulldown1.p, ground.p) annotation(
    Line(points = {{-300, 20}, {-300, -200}, {-150, -200}, {-150, -180}}, color = {0, 0, 255}));
  connect(mcu.GP2, pulldown2.n) annotation(
    Line(points = {{-212, -20}, {-280, -20}}, color = {0, 0, 255}));
  connect(pulldown2.p, ground.p) annotation(
    Line(points = {{-300, -20}, {-300, -200}, {-150, -200}, {-150, -180}}, color = {0, 0, 255}));
  connect(mcu.GP3, pulldown3.n) annotation(
    Line(points = {{-212, -50}, {-280, -50}}, color = {0, 0, 255}));
  connect(pulldown3.p, ground.p) annotation(
    Line(points = {{-300, -50}, {-300, -200}, {-150, -200}, {-150, -180}}, color = {0, 0, 255}));
  connect(mcu.GP4, pulldown4.p) annotation(
    Line(points = {{-88, 50}, {-20, 50}}, color = {0, 0, 255}));
  connect(pulldown4.n, ground.p) annotation(
    Line(points = {{0, 50}, {0, -200}, {-150, -200}, {-150, -180}}, color = {0, 0, 255}));
  connect(mcu.GP5, pulldown5.p) annotation(
    Line(points = {{-88, 20}, {-20, 20}}, color = {0, 0, 255}));
  connect(pulldown5.n, ground.p) annotation(
    Line(points = {{0, 20}, {0, -200}, {-150, -200}, {-150, -180}}, color = {0, 0, 255}));
  connect(mcu.GP6, pulldown6.p) annotation(
    Line(points = {{-88, -20}, {-20, -20}}, color = {0, 0, 255}));
  connect(pulldown6.n, ground.p) annotation(
    Line(points = {{0, -20}, {0, -200}, {-150, -200}, {-150, -180}}, color = {0, 0, 255}));
  connect(mcu.GP7, pulldown7.p) annotation(
    Line(points = {{-88, -50}, {-44, -50}}, color = {0, 0, 255}));
  connect(led1.p, pulldown7.n) annotation(
    Line(points = {{-68, -100}, {-72, -100}, {-72, -64}, {-18, -64}, {-18, -50}, {-24, -50}}, color = {0, 0, 255}));
  connect(led1.n, ground.p) annotation(
    Line(points = {{-48, -100}, {-36, -100}, {-36, -178}, {-150, -178}, {-150, -180}}, color = {0, 0, 255}));
  annotation(
    Diagram(coordinateSystem(extent = {{-340, -220}, {40, 120}})),
    experiment(StopTime = 4.5, Interval = 0.001),
    Documentation(info = "<html>
<p>Succès attendu : la trace de <code>mcu.GP0.v</code> montre un créneau périodique 0 V / ≈3 V de période 2 s (1 s allumé, 1 s éteint).</p>
</html>"));
end BasicBlink_test;
