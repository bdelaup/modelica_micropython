within MicroPythonMCU.Examples;
model AdcRead "GP1 utilisée en entrée analogique (machine.ADC), pilotée par un pont diviseur externe ; le script recopie un seuil sur GP0 (LED) pour rendre la lecture observable"
  extends Modelica.Icons.Example;
  MCU mcu(scriptPath = Modelica.Utilities.Files.loadResource("modelica://MicroPythonMCU/Resources/Scripts/adc_read.py")) "scriptPath = Resources/Scripts/adc_read.py" annotation(
    Placement(transformation(extent = {{-100, -100}, {100, 100}})));
  Modelica.Electrical.Analog.Basic.Ground ground annotation(
    Placement(transformation(extent = {{-10, -230}, {10, -220}})));

  Modelica.Electrical.Analog.Basic.Resistor r0(R = 330) "limite le courant de led0 (GP0)" annotation(
    Placement(transformation(extent = {{-110, 45}, {-90, 55}})));
  MicroPythonMCU.Utils.LED led0 "GP0 : recopie (v > moitie de l'echelle ADC) ?" annotation(
    Placement(transformation(extent = {{-160, 40}, {-180, 60}})));

  Modelica.Electrical.Analog.Sources.ConstantVoltage supply(V = 3.3) "alimentation du pont diviseur (independante de MCU)" annotation(
    Placement(transformation(extent = {{-230, -100}, {-210, -80}})));
  Modelica.Electrical.Analog.Basic.Resistor rTop(R = 1000) "haut du pont diviseur" annotation(
    Placement(transformation(extent = {{-190, -80}, {-170, -60}})));
  Modelica.Electrical.Analog.Basic.Resistor rBot(R = 2000) "bas du pont diviseur : GP1 lit ~3.3*2/3 = 2.2 V" annotation(
    Placement(transformation(extent = {{-190, -130}, {-170, -110}})));

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
    Line(points = {{0, -78}, {0, -220}}, color = {0, 0, 255}));
  connect(mcu.GP0, r0.n) annotation(
    Line(points = {{-62, 50}, {-90, 50}}, color = {0, 0, 255}));
  connect(r0.p, led0.p) annotation(
    Line(points = {{-110, 50}, {-160, 50}}, color = {0, 0, 255}));
  connect(led0.n, ground.p) annotation(
    Line(points = {{-180, 50}, {-180, -210}, {0, -210}, {0, -220}}, color = {0, 0, 255}));
  connect(supply.n, ground.p) annotation(
    Line(points = {{-210, -90}, {-200, -90}, {-200, -210}, {0, -210}, {0, -220}}, color = {0, 0, 255}));
  connect(supply.p, rTop.p) annotation(
    Line(points = {{-230, -90}, {-240, -90}, {-240, -70}, {-190, -70}}, color = {0, 0, 255}));
  connect(rTop.n, rBot.p) annotation(
    Line(points = {{-170, -70}, {-160, -70}, {-160, -120}, {-190, -120}}, color = {0, 0, 255}));
  connect(rTop.n, mcu.GP1) annotation(
    Line(points = {{-170, -70}, {-62, -70}, {-62, 20}}, color = {0, 0, 255}));
  connect(rBot.n, ground.p) annotation(
    Line(points = {{-170, -120}, {-160, -120}, {-160, -210}, {0, -210}, {0, -220}}, color = {0, 0, 255}));
  connect(mcu.GP2, pulldown2.n) annotation(
    Line(points = {{-62, -20}, {-90, -20}}, color = {0, 0, 255}));
  connect(pulldown2.p, ground.p) annotation(
    Line(points = {{-110, -20}, {-130, -20}, {-130, -210}, {0, -210}, {0, -220}}, color = {0, 0, 255}));
  connect(mcu.GP3, pulldown3.n) annotation(
    Line(points = {{-62, -50}, {-90, -50}}, color = {0, 0, 255}));
  connect(pulldown3.p, ground.p) annotation(
    Line(points = {{-110, -50}, {-130, -50}, {-130, -210}, {0, -210}, {0, -220}}, color = {0, 0, 255}));
  connect(mcu.GP4, pulldown4.p) annotation(
    Line(points = {{62, 50}, {90, 50}}, color = {0, 0, 255}));
  connect(pulldown4.n, ground.p) annotation(
    Line(points = {{110, 50}, {130, 50}, {130, -210}, {0, -210}, {0, -220}}, color = {0, 0, 255}));
  connect(mcu.GP5, pulldown5.p) annotation(
    Line(points = {{62, 20}, {90, 20}}, color = {0, 0, 255}));
  connect(pulldown5.n, ground.p) annotation(
    Line(points = {{110, 20}, {130, 20}, {130, -210}, {0, -210}, {0, -220}}, color = {0, 0, 255}));
  connect(mcu.GP6, pulldown6.p) annotation(
    Line(points = {{62, -20}, {90, -20}}, color = {0, 0, 255}));
  connect(pulldown6.n, ground.p) annotation(
    Line(points = {{110, -20}, {130, -20}, {130, -210}, {0, -210}, {0, -220}}, color = {0, 0, 255}));
  connect(mcu.GP7, pulldown7.p) annotation(
    Line(points = {{62, -50}, {90, -50}}, color = {0, 0, 255}));
  connect(pulldown7.n, ground.p) annotation(
    Line(points = {{110, -50}, {130, -50}, {130, -210}, {0, -210}, {0, -220}}, color = {0, 0, 255}));
  annotation(
    Diagram(coordinateSystem(extent = {{-260, -240}, {150, 110}})),
    experiment(StopTime = 1, Interval = 0.001),
    Documentation(info = "<html>
<p>Scénario de vérification 8 (cf. <code>requirements.md</code>) : <code>GP1</code> est utilisée en entrée analogique (<code>machine.ADC(1)</code>) plutôt qu'en broche numérique — un pont diviseur externe (<code>supply</code>/<code>rTop</code>/<code>rBot</code>, indépendant de <code>MCU</code>) l'alimente à ~2,2 V (3,3 V × 2000/3000). Le script <code>adc_read.py</code> lit <code>ADC(1).read_u16()</code> et pilote <code>Pin(0, Pin.OUT)</code> selon un seuil (moitié de l'échelle 16 bits) — <code>led0</code> rend ce seuil observable, servant de sonde pour valider tout le pipeline (division de tension → ADC → seuil → sortie) sans dépendre d'une lecture directe d'un flottant. Les broches inutilisées (<code>GP2</code>-<code>GP7</code>) sont tirées à la masse par une résistance, comme dans <code>BasicBlink.mo</code>/<code>PinEcho.mo</code>.</p>
</html>"));
end AdcRead;
