within MicroPythonMCU.Examples.Weighing;

model Hx711Read "Lectures brutes d'un HX711 par le driver MicroPython de robert-hh : gain 128, gain 64, veille et réveil"
  extends Modelica.Icons.Example;
  MCU mcu(scriptPath = Modelica.Utilities.Files.loadResource("modelica://MicroPythonMCU/Resources/Scripts/MCU/hx711_read.py")) "scriptPath = Resources/Scripts/MCU/hx711_read.py - importe le driver hx711_gpio.py posé à côté (robert-hh, tel quel)" annotation(
    Placement(transformation(origin = {0, 0}, extent = {{-50, -50}, {50, 50}})));
  MicroPythonMCU.Peripherals.Display display "Codes lus par le microcontrôleur" annotation(
    Placement(transformation(origin = {80, 90}, extent = {{-30, -15}, {30, 15}})));
  MicroPythonMCU.Peripherals.Weighing.Hx711 hx "Convertisseur, sans bruit : les codes lus sont exactement prévisibles" annotation(
    Placement(transformation(origin = {130, -20}, extent = {{-50, -50}, {50, 50}})));
  MicroPythonMCU.Peripherals.Weighing.WheatstoneBridge bridge annotation(
    Placement(transformation(origin = {250, -20}, extent = {{-50, -50}, {50, 50}})));
  MicroPythonMCU.Peripherals.Weighing.LoadCell loadCell "Corps d'épreuve de 5 kg" annotation(
    Placement(transformation(origin = {370, -20}, extent = {{-50, -50}, {50, 50}})));
  Modelica.Mechanics.Translational.Sources.Force weight "Le poids de la masse posée" annotation(
    Placement(transformation(origin = {430, -20}, extent = {{10, -10}, {-10, 10}})));
  Modelica.Blocks.Math.Gain g(k = Modelica.Constants.g_n) "Poids = masse × g" annotation(
    Placement(transformation(origin = {470, -20}, extent = {{10, -10}, {-10, 10}})));
  Modelica.Blocks.Sources.Constant mass(k = 1) "Masse posée : 1 kg" annotation(
    Placement(transformation(origin = {510, -20}, extent = {{10, -10}, {-10, 10}})));
  Modelica.Electrical.Analog.Basic.Ground ground annotation(
    Placement(transformation(origin = {60, -100}, extent = {{-10, -10}, {10, 10}})));
equation
  connect(mcu.Display0, display.displayLink) annotation(
    Line(points = {{25, 38}, {25, 90}, {48, 90}}));
// Brochage du programme : PD_SCK sur GP6, DOUT sur GP7
  connect(mcu.GP6, hx.PD_SCK) annotation(
    Line(points = {{31, -10}, {50, -10}, {50, -5}, {68, -5}}, color = {0, 0, 255}));
  connect(mcu.GP7, hx.DOUT) annotation(
    Line(points = {{31, -25}, {50, -25}, {50, -35}, {68, -35}}, color = {0, 0, 255}));
  connect(hx.E_plus, bridge.E_plus) annotation(
    Line(points = {{192, 2.5}, {195, 2.5}}, color = {0, 0, 255}));
  connect(hx.A_plus, bridge.S_plus) annotation(
    Line(points = {{192, -12.5}, {195, -12.5}}, color = {0, 0, 255}));
  connect(hx.A_minus, bridge.S_minus) annotation(
    Line(points = {{192, -27.5}, {195, -27.5}}, color = {0, 0, 255}));
  connect(hx.E_minus, bridge.E_minus) annotation(
    Line(points = {{192, -42.5}, {195, -42.5}}, color = {0, 0, 255}));
  connect(loadCell.eps, bridge.eps) annotation(
    Line(points = {{315, -20}, {310, -20}}, color = {0, 0, 127}));
  connect(weight.flange, loadCell.flange) annotation(
    Line(points = {{420, -20}, {420, -20}}, color = {0, 127, 0}));
  connect(g.y, weight.f) annotation(
    Line(points = {{459, -20}, {442, -20}}, color = {0, 0, 127}));
  connect(mass.y, g.u) annotation(
    Line(points = {{499, -20}, {482, -20}}, color = {0, 0, 127}));
  connect(mcu.GND, ground.p) annotation(
    Line(points = {{0, -39}, {0, -90}, {60, -90}}, color = {0, 0, 255}));
  connect(hx.GND, ground.p) annotation(
    Line(points = {{130, -56}, {130, -90}, {60, -90}}, color = {0, 0, 255}));
  annotation(
    Diagram(coordinateSystem(extent = {{-60, -120}, {530, 120}})),
    experiment(StopTime = 2, Interval = 0.001, StartTime = 0, Tolerance = 1e-06),
    Documentation(info = "<html>
<p>Le microcontrôleur lit un <strong>HX711</strong> avec le driver MicroPython de Robert Hammelrath (<a href=\"https://github.com/robert-hh/hx711\">robert-hh/hx711</a>, <code>hx711_gpio.py</code>, posé sans modification à côté du programme <code>hx711_read.py</code>). Le driver pilote <code>PD_SCK</code> bit par bit et attend chaque nouvelle donnée par une interruption sur le front descendant de <code>DOUT</code> : c'est possible parce que chaque accès aux broches prend 5 µs de temps simulé (<code>mcu.gpioOpTime</code>).</p>
<p>La chaîne de mesure est complète : une masse de 1 kg (<code>mass</code>), son poids (<code>g</code>, <code>weight</code>), le corps d'épreuve de 5 kg (<code>loadCell</code>), le pont de jauges (<code>bridge</code>, 1 mV/V à pleine charge) et le convertisseur (<code>hx</code>, sans bruit).</p>
<p>Codes attendus : la sortie du pont vaut 1/5 de 1 mV/V, soit 0,2 mV/V ; à gain 128, <code>code = 0,2e-3 × 128 × 2<sup>24</sup> ≈ 429 497</code>, et à gain 64, la moitié (214 748). Le programme :</p>
<ol>
<li>lit une mesure à gain 128 (après les 400 ms d'établissement du HX711) ;</li>
<li>passe à gain 64 (<code>set_gain(64)</code> : 27 impulsions, le gain s'applique à la conversion suivante) et relit ;</li>
<li>affiche <code>128:429497 64:214748</code> ;</li>
<li>met le HX711 en veille (<code>power_down()</code> : <code>PD_SCK</code> haute plus de 60 µs), le réveille 200 ms plus tard, et relit : le circuit est reparti à gain 128, d'où <code>reveil:429497</code>.</li>
</ol>
<p>À observer : l'icône de <code>hx</code> (gain, dernier code, voyants « donnée prête » et « veille »), <code>mcu.GP6.v</code> (les trains de 25 ou 27 impulsions de 5 µs), <code>mcu.GP7.v</code> (les bits de la donnée), et le journal (les <code>print()</code> du programme).</p>
</html>"));
end Hx711Read;
