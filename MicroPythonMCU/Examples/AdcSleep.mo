within MicroPythonMCU.Examples;

model AdcSleep "Entrée ADC (GP0) traversant le seuil logique pendant des sleep() : ni réveil anticipé ni IRQ, l'ADC coupant l'entrée numérique de la broche ; GP1 (LED) confirme"
  extends Modelica.Icons.Example;
  MCU mcu(scriptPath = Modelica.Utilities.Files.loadResource("modelica://MicroPythonMCU/Resources/Scripts/MCU/adc_sleep.py")) "scriptPath = Resources/Scripts/MCU/adc_sleep.py" annotation(
    Placement(transformation(origin = {0, 0}, extent = {{-50, -50}, {50, 50}})));
  Modelica.Electrical.Analog.Basic.Ground ground annotation(
    Placement(transformation(origin = {0, -90}, extent = {{-15, -15}, {15, 15}})));
  Modelica.Electrical.Analog.Sources.SineVoltage sine(V = 1.65, f = 5, offset = 1.65) "tension lue par l'ADC (GP0) : sinusoïde 0-3,3 V à 5 Hz, qui traverse le seuil logique (~1,4 V) 10 fois par seconde" annotation(
    Placement(transformation(origin = {-110, -30}, extent = {{-15, -15}, {15, 15}}, rotation = -90)));
  Modelica.Electrical.Analog.Basic.Resistor r1(R = 330) "limite le courant de led1 (GP1)" annotation(
    Placement(transformation(origin = {-90, 10}, extent = {{-15, -15}, {15, 15}})));
  MicroPythonMCU.Peripherals.LED led1 "GP1 : les cinq sleep(0.2) ont duré 200 ms et l'IRQ n'a vu aucun front" annotation(
    Placement(transformation(origin = {-140, 10}, extent = {{-15, 15}, {15, -15}}, rotation = -180)));
equation
  connect(mcu.GND, ground.p) annotation(
    Line(points = {{0, -39}, {0, -75}}, color = {0, 0, 255}));
  connect(sine.p, mcu.GP0) annotation(
    Line(points = {{-110, -15}, {-110, 25}, {-31, 25}}, color = {0, 0, 255}));
  connect(sine.n, ground.p) annotation(
    Line(points = {{-110, -45}, {-110, -75}, {0, -75}}, color = {0, 0, 255}));
  connect(mcu.GP1, r1.n) annotation(
    Line(points = {{-31, 10}, {-75, 10}}, color = {0, 0, 255}));
  connect(r1.p, led1.p) annotation(
    Line(points = {{-105, 10}, {-125, 10}}, color = {0, 0, 255}));
  connect(led1.n, ground.p) annotation(
    Line(points = {{-155, 10}, {-165, 10}, {-165, -75}, {0, -75}}, color = {0, 0, 255}));
  annotation(
    Diagram(coordinateSystem(extent = {{-180, -120}, {80, 80}})),
    experiment(StopTime = 1.5, Interval = 0.001),
    Documentation(info = "<html>
<p>Scénario de vérification 26 (cf. <code>requirements.md</code>, décision « ADC (entrées analogiques) ») : <code>GP0</code>, lue par <code>machine.ADC(0)</code>, reçoit une sinusoïde de 0 à 3,3 V à 5 Hz, qui traverse le seuil logique de la broche 10 fois par seconde. Le script <code>adc_sleep.py</code> arme d'abord une IRQ sur les deux fronts de <code>Pin(0)</code>, crée <code>ADC(0)</code>, puis enchaîne cinq <code>sleep(0.2)</code> en mesurant leur durée.</p>
<p>Comme sur le RP2040, passer la broche en ADC coupe son entrée numérique : les franchissements du seuil ne doivent ni écourter les <code>sleep()</code>, ni déclencher l'IRQ. <code>led1</code> (<code>GP1</code>) s'allume si les cinq attentes ont bien duré 200 ms et si l'IRQ n'a vu aucun front. Avant la correction, chaque franchissement réveillait le script comme une vraie transition d'entrée.</p>
</html>"));
end AdcSleep;
