within MicroPythonMCU.Examples;
model PwmLed "GP0 pilote une LED en PWM (machine.PWM), 200 Hz / ~30% de rapport cyclique, configuré une fois puis généré en continu côté Modelica"
  extends Modelica.Icons.Example;
  MCU mcu(scriptPath = Modelica.Utilities.Files.loadResource("modelica://MicroPythonMCU/Resources/Scripts/pwm_led.py")) "scriptPath = Resources/Scripts/pwm_led.py" annotation(
    Placement(transformation(extent = {{-100, -100}, {100, 100}})));
  Modelica.Electrical.Analog.Basic.Ground ground annotation(
    Placement(transformation(extent = {{-10, -210}, {10, -200}})));

  Modelica.Electrical.Analog.Basic.Resistor r0(R = 330) "limite le courant de led0 (GP0)" annotation(
    Placement(transformation(extent = {{-110, 45}, {-90, 55}})));
  MicroPythonMCU.Utils.LED led0 "GP0 : créneau PWM (200 Hz, ~30%)" annotation(
    Placement(transformation(extent = {{-160, 40}, {-180, 60}})));

  Modelica.Electrical.Analog.Basic.Resistor pulldown1(R = 1000) "GP1 (inutilisee), tirée à la masse" annotation(
    Placement(transformation(extent = {{-110, 15}, {-90, 25}})));
  Modelica.Electrical.Analog.Basic.Resistor pulldown2(R = 1000) "GP2 (inutilisee), tirée à la masse" annotation(
    Placement(transformation(extent = {{-110, -25}, {-90, -15}})));
  Modelica.Electrical.Analog.Basic.Resistor pulldown3(R = 1000) "GP3 (inutilisee), tirée à la masse" annotation(
    Placement(transformation(extent = {{-110, -55}, {-90, -45}})));
  Modelica.Electrical.Analog.Basic.Resistor pulldown4(R = 1000) "GP4 (inutilisee), tirée à la masse" annotation(
    Placement(transformation(extent = {{90, 45}, {110, 55}})));
  Modelica.Electrical.Analog.Basic.Resistor pulldown5(R = 1000) "GP5 (inutilisee), tirée à la masse" annotation(
    Placement(transformation(extent = {{90, 15}, {110, 25}})));
  Modelica.Electrical.Analog.Basic.Resistor pulldown6(R = 1000) "GP6 (inutilisee), tirée à la masse" annotation(
    Placement(transformation(extent = {{90, -25}, {110, -15}})));
  Modelica.Electrical.Analog.Basic.Resistor pulldown7(R = 1000) "GP7 (inutilisee), tirée à la masse" annotation(
    Placement(transformation(extent = {{90, -55}, {110, -45}})));
equation
  connect(mcu.GND, ground.p) annotation(
    Line(points = {{0, -78}, {0, -200}}, color = {0, 0, 255}));
  connect(mcu.GP0, r0.n) annotation(
    Line(points = {{-62, 50}, {-90, 50}}, color = {0, 0, 255}));
  connect(r0.p, led0.p) annotation(
    Line(points = {{-110, 50}, {-160, 50}}, color = {0, 0, 255}));
  connect(led0.n, ground.p) annotation(
    Line(points = {{-180, 50}, {-180, -190}, {0, -190}, {0, -200}}, color = {0, 0, 255}));
  connect(mcu.GP1, pulldown1.n) annotation(
    Line(points = {{-62, 20}, {-90, 20}}, color = {0, 0, 255}));
  connect(pulldown1.p, ground.p) annotation(
    Line(points = {{-110, 20}, {-130, 20}, {-130, -190}, {0, -190}, {0, -200}}, color = {0, 0, 255}));
  connect(mcu.GP2, pulldown2.n) annotation(
    Line(points = {{-62, -20}, {-90, -20}}, color = {0, 0, 255}));
  connect(pulldown2.p, ground.p) annotation(
    Line(points = {{-110, -20}, {-130, -20}, {-130, -190}, {0, -190}, {0, -200}}, color = {0, 0, 255}));
  connect(mcu.GP3, pulldown3.n) annotation(
    Line(points = {{-62, -50}, {-90, -50}}, color = {0, 0, 255}));
  connect(pulldown3.p, ground.p) annotation(
    Line(points = {{-110, -50}, {-130, -50}, {-130, -190}, {0, -190}, {0, -200}}, color = {0, 0, 255}));
  connect(mcu.GP4, pulldown4.p) annotation(
    Line(points = {{62, 50}, {90, 50}}, color = {0, 0, 255}));
  connect(pulldown4.n, ground.p) annotation(
    Line(points = {{110, 50}, {130, 50}, {130, -190}, {0, -190}, {0, -200}}, color = {0, 0, 255}));
  connect(mcu.GP5, pulldown5.p) annotation(
    Line(points = {{62, 20}, {90, 20}}, color = {0, 0, 255}));
  connect(pulldown5.n, ground.p) annotation(
    Line(points = {{110, 20}, {130, 20}, {130, -190}, {0, -190}, {0, -200}}, color = {0, 0, 255}));
  connect(mcu.GP6, pulldown6.p) annotation(
    Line(points = {{62, -20}, {90, -20}}, color = {0, 0, 255}));
  connect(pulldown6.n, ground.p) annotation(
    Line(points = {{110, -20}, {130, -20}, {130, -190}, {0, -190}, {0, -200}}, color = {0, 0, 255}));
  connect(mcu.GP7, pulldown7.p) annotation(
    Line(points = {{62, -50}, {90, -50}}, color = {0, 0, 255}));
  connect(pulldown7.n, ground.p) annotation(
    Line(points = {{110, -50}, {130, -50}, {130, -190}, {0, -190}, {0, -200}}, color = {0, 0, 255}));
  annotation(
    Diagram(coordinateSystem(extent = {{-200, -220}, {150, 110}})),
    experiment(StopTime = 0.5, Interval = 0.00002),
    Documentation(info = "<html>
<p>Scénario de vérification 9 (cf. <code>requirements.md</code>) : <code>GP0</code> est configurée en sortie PWM (<code>machine.PWM</code>) plutôt qu'en broche numérique classique — le script <code>pwm_led.py</code> appelle <code>PWM(Pin(0))</code>, <code>freq(200)</code> et <code>duty_u16(19661)</code> (~30%) une seule fois puis se termine : le créneau est ensuite généré en continu côté Modelica (expression <code>mod(time, période)</code> dans <code>MCU.mo</code>), sans qu'aucun aller-retour supplémentaire avec le thread Python ne soit nécessaire — fidèle au vrai périphérique matériel PWM du RP2040, qui tourne indépendamment du CPU une fois configuré. <code>led0</code> rend le rapport cyclique observable visuellement (luminosité réduite par rapport à un GPIO numérique allumé en continu). Les broches inutilisées (<code>GP1</code>-<code>GP7</code>) sont tirées à la masse.</p>
</html>"));
end PwmLed;
