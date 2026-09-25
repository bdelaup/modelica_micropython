within MicroPythonMCU.Examples;

model AdcRead "GP1 utilisée en entrée analogique (machine.ADC), pilotée par un pont diviseur externe ; le script recopie un seuil sur GP0 (LED) pour rendre la lecture observable"
  extends Modelica.Icons.Example;
  MCU mcu(scriptPath = Modelica.Utilities.Files.loadResource("modelica://MicroPythonMCU/Resources/Scripts/MCU/adc_read.py")) "scriptPath = Resources/Scripts/MCU/adc_read.py" annotation(
    Placement(transformation(origin = {0, 0}, extent = {{-50, -50}, {50, 50}})));
  Modelica.Electrical.Analog.Basic.Ground ground annotation(
    Placement(transformation(origin = {0, -90}, extent = {{-15, -15}, {15, 15}})));
  Modelica.Electrical.Analog.Basic.Resistor r0(R = 330) "limite le courant de led0 (GP0)" annotation(
    Placement(transformation(origin = {-90, 25}, extent = {{-15, -15}, {15, 15}})));
  MicroPythonMCU.Peripherals.LED led0 "GP0 : recopie (v > moitie de l'echelle ADC) ?" annotation(
    Placement(transformation(origin = {-140, 25}, extent = {{-15, 15}, {15, -15}}, rotation = -180)));
  Modelica.Electrical.Analog.Sources.ConstantVoltage supply(V = 3.3) "alimentation du pont diviseur (independante de MCU)" annotation(
    Placement(transformation(origin = {-126, -36}, extent = {{-15, -15}, {15, 15}}, rotation = -90)));
  Modelica.Electrical.Analog.Basic.Resistor rTop(R = 1000) "haut du pont diviseur" annotation(
    Placement(transformation(origin = {-90, -10}, extent = {{-15, -15}, {15, 15}})));
  Modelica.Electrical.Analog.Basic.Resistor rBot(R = 2000) "bas du pont diviseur : GP1 lit ~3.3*2/3 = 2.2 V" annotation(
    Placement(transformation(origin = {-74, -50}, extent = {{-15, -15}, {15, 15}}, rotation = -90)));
equation
  connect(mcu.GND, ground.p) annotation(
    Line(points = {{0, -39}, {0, -75}}, color = {0, 0, 255}));
  connect(mcu.GP0, r0.n) annotation(
    Line(points = {{-31, 25}, {-75, 25}}, color = {0, 0, 255}));
  connect(r0.p, led0.p) annotation(
    Line(points = {{-105, 25}, {-125, 25}}, color = {0, 0, 255}));
  connect(led0.n, ground.p) annotation(
    Line(points = {{-155, 25}, {-155, -75}, {0, -75}}, color = {0, 0, 255}));
  connect(supply.n, ground.p) annotation(
    Line(points = {{-126, -51}, {-126, -75}, {0, -75}}, color = {0, 0, 255}));
  connect(supply.p, rTop.p) annotation(
    Line(points = {{-126, -21}, {-126, -10}, {-105, -10}}, color = {0, 0, 255}));
  connect(rTop.n, rBot.p) annotation(
    Line(points = {{-75, -10}, {-75, -35}, {-74, -35}}, color = {0, 0, 255}));
  connect(rTop.n, mcu.GP1) annotation(
    Line(points = {{-75, -10}, {-75, 10}, {-31, 10}}, color = {0, 0, 255}));
  connect(rBot.n, ground.p) annotation(
    Line(points = {{-74, -65}, {-74, -75}, {0, -75}}, color = {0, 0, 255}));
  annotation(
    Diagram(coordinateSystem(extent = {{-220, -120}, {80, 80}})),
    experiment(StopTime = 1, Interval = 0.001),
    Documentation(info = "<html>
<p>Scénario de vérification 8 (cf. <code>requirements.md</code>) : <code>GP1</code> est utilisée en entrée analogique (<code>machine.ADC(1)</code>) plutôt qu'en broche numérique — un pont diviseur externe (<code>supply</code>/<code>rTop</code>/<code>rBot</code>, indépendant de <code>MCU</code>) l'alimente à ~2,2 V (3,3 V × 2000/3000). Le script <code>adc_read.py</code> lit <code>ADC(1).read_u16()</code> et pilote <code>Pin(0, Pin.OUT)</code> selon un seuil (moitié de l'échelle 16 bits) — <code>led0</code> rend ce seuil observable, servant de sonde pour valider tout le pipeline (division de tension → ADC → seuil → sortie) sans dépendre d'une lecture directe d'un flottant. Les broches <code>GP2</code>-<code>GP7</code>, non utilisées par ce scénario, sont laissées non connectées.</p>
</html>"));
end AdcRead;
