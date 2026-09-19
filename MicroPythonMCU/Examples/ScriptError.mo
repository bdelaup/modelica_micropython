within MicroPythonMCU.Examples;
model ScriptError "Scénario de vérification v0 n°4 : une exception non gérée doit arrêter la simulation avec la trace visible dans le journal"
  extends Modelica.Icons.Example;
  MCU mcu(scriptPath = Modelica.Utilities.Files.loadResource("modelica://MicroPythonMCU/Resources/Verification/script_error.py")) "scriptPath = Verification/script_error.py" annotation(Placement(transformation(origin = {-150, 0}, extent = {{-100, -100}, {100, 100}})));
  Modelica.Electrical.Analog.Basic.Ground ground annotation(Placement(transformation(extent = {{-160, -190}, {-140, -180}})));
  Modelica.Electrical.Analog.Basic.Resistor led(R = 1000) "Charge simulant une LED sur GP0" annotation(Placement(transformation(extent = {{-300, 40}, {-280, 60}})));
  Modelica.Electrical.Analog.Basic.Resistor pulldown1(R = 1000) "GP1" annotation(Placement(transformation(extent = {{-300, 10}, {-280, 30}})));
  Modelica.Electrical.Analog.Basic.Resistor pulldown2(R = 1000) "GP2" annotation(Placement(transformation(extent = {{-300, -30}, {-280, -10}})));
  Modelica.Electrical.Analog.Basic.Resistor pulldown3(R = 1000) "GP3" annotation(Placement(transformation(extent = {{-300, -60}, {-280, -40}})));
  Modelica.Electrical.Analog.Basic.Resistor pulldown4(R = 1000) "GP4" annotation(Placement(transformation(extent = {{-20, 40}, {0, 60}})));
  Modelica.Electrical.Analog.Basic.Resistor pulldown5(R = 1000) "GP5" annotation(Placement(transformation(extent = {{-20, 10}, {0, 30}})));
  Modelica.Electrical.Analog.Basic.Resistor pulldown6(R = 1000) "GP6" annotation(Placement(transformation(extent = {{-20, -30}, {0, -10}})));
  Modelica.Electrical.Analog.Basic.Resistor pulldown7(R = 1000) "GP7" annotation(Placement(transformation(extent = {{-20, -60}, {0, -40}})));
equation
  connect(mcu.GND, ground.p) annotation(Line(points = {{-150, -78}, {-150, -180}}, color = {0, 0, 255}));

  connect(mcu.GP0, led.n) annotation(Line(points = {{-212, 50}, {-280, 50}}, color = {0, 0, 255}));
  connect(led.p, ground.p) annotation(Line(points = {{-300, 50}, {-300, -200}, {-150, -200}, {-150, -180}}, color = {0, 0, 255}));
  connect(mcu.GP1, pulldown1.n) annotation(Line(points = {{-212, 20}, {-280, 20}}, color = {0, 0, 255}));
  connect(pulldown1.p, ground.p) annotation(Line(points = {{-300, 20}, {-300, -200}, {-150, -200}, {-150, -180}}, color = {0, 0, 255}));
  connect(mcu.GP2, pulldown2.n) annotation(Line(points = {{-212, -20}, {-280, -20}}, color = {0, 0, 255}));
  connect(pulldown2.p, ground.p) annotation(Line(points = {{-300, -20}, {-300, -200}, {-150, -200}, {-150, -180}}, color = {0, 0, 255}));
  connect(mcu.GP3, pulldown3.n) annotation(Line(points = {{-212, -50}, {-280, -50}}, color = {0, 0, 255}));
  connect(pulldown3.p, ground.p) annotation(Line(points = {{-300, -50}, {-300, -200}, {-150, -200}, {-150, -180}}, color = {0, 0, 255}));

  connect(mcu.GP4, pulldown4.p) annotation(Line(points = {{-88, 50}, {-20, 50}}, color = {0, 0, 255}));
  connect(pulldown4.n, ground.p) annotation(Line(points = {{0, 50}, {0, -200}, {-150, -200}, {-150, -180}}, color = {0, 0, 255}));
  connect(mcu.GP5, pulldown5.p) annotation(Line(points = {{-88, 20}, {-20, 20}}, color = {0, 0, 255}));
  connect(pulldown5.n, ground.p) annotation(Line(points = {{0, 20}, {0, -200}, {-150, -200}, {-150, -180}}, color = {0, 0, 255}));
  connect(mcu.GP6, pulldown6.p) annotation(Line(points = {{-88, -20}, {-20, -20}}, color = {0, 0, 255}));
  connect(pulldown6.n, ground.p) annotation(Line(points = {{0, -20}, {0, -200}, {-150, -200}, {-150, -180}}, color = {0, 0, 255}));
  connect(mcu.GP7, pulldown7.p) annotation(Line(points = {{-88, -50}, {-20, -50}}, color = {0, 0, 255}));
  connect(pulldown7.n, ground.p) annotation(Line(points = {{0, -50}, {0, -200}, {-150, -200}, {-150, -180}}, color = {0, 0, 255}));
  annotation(
    Diagram(coordinateSystem(extent = {{-340, -220}, {40, 120}})),
    experiment(StopTime = 5),
    Documentation(info = "<html>
<p>Succès attendu : la simulation s'arrête en erreur après ≈1 s (après le <code>sleep(1)</code>), la trace Python (ZeroDivisionError) est visible dans le journal de simulation.</p>
</html>"));
end ScriptError;
