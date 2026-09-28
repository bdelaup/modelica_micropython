within MicroPythonMCU.Examples.Weighing;

model KitchenScale "Balance de cuisine : écran I2C, microcontrôleur, HX711, pont de jauges, corps d'épreuve, poids ; bouton de tare"
  extends Modelica.Icons.Example;
  MCU mcu(scriptPath = Modelica.Utilities.Files.loadResource("modelica://MicroPythonMCU/Resources/Scripts/MCU/kitchen_scale.py")) "scriptPath = Resources/Scripts/MCU/kitchen_scale.py - importe les drivers hx711_gpio.py et driver_grove_lcd_rgb.py posés à côté" annotation(
    Placement(transformation(origin = {0, 0}, extent = {{-50, -50}, {50, 50}})));
  MicroPythonMCU.Peripherals.I2cGroveLcdRgb lcd "Écran 16x2 à rétroéclairage RGB, porteur des tirages du bus I2C" annotation(
    Placement(transformation(origin = {150, 100}, extent = {{-50, -50}, {50, 50}})));
  MicroPythonMCU.Peripherals.Weighing.Hx711 hx(noiseLsb = 25) "Convertisseur, avec un bruit réaliste (25 LSB, soit 0,06 g)" annotation(
    Placement(transformation(origin = {149, -19}, extent = {{-29, -29}, {29, 29}})));
  MicroPythonMCU.Peripherals.Weighing.WheatstoneBridge bridge "Quatre jauges collées sur le corps d'épreuve" annotation(
    Placement(transformation(origin = {262, -20}, extent = {{-28, -28}, {28, 28}})));
  MicroPythonMCU.Peripherals.Weighing.LoadCell loadCell "Corps d'épreuve de 5 kg" annotation(
    Placement(transformation(origin = {359, -17}, extent = {{-25, -25}, {25, 25}})));
  Modelica.Mechanics.Translational.Sources.Force weight "Le poids de ce qui est sur le plateau (plateau compris)" annotation(
    Placement(transformation(origin = {430, -20}, extent = {{10, -10}, {-10, 10}})));
  Modelica.Blocks.Math.Gain g(k = Modelica.Constants.g_n) "Poids = masse × g" annotation(
    Placement(transformation(origin = {470, -20}, extent = {{10, -10}, {-10, 10}})));
  Modelica.Blocks.Math.Add totalMass "Masse totale sur le corps d'épreuve" annotation(
    Placement(transformation(origin = {510, -20}, extent = {{10, -10}, {-10, 10}})));
  Modelica.Blocks.Sources.Constant plateau(k = 0.2) "Plateau : 200 g, toujours présents - la tare au démarrage les fait disparaître" annotation(
    Placement(transformation(origin = {550, 0}, extent = {{10, -10}, {-10, 10}})));
  Modelica.Blocks.Sources.TimeTable load(table = [0, 0; 2, 0; 2, 0.35; 4.5, 0.35; 5.5, 0.6; 7, 0.6]) "Ce qu'on pose (kg) : un bol de 350 g à t = 2 s, puis 250 g de farine versés entre 4,5 et 5,5 s" annotation(
    Placement(transformation(origin = {550, -40}, extent = {{10, -10}, {-10, 10}})));
  Modelica.Electrical.Analog.Sources.ConstantVoltage vcc(V = 3.3) "Alimentation 3,3 V du tirage du bouton" annotation(
    Placement(transformation(origin = {-130, 50}, extent = {{-10, -10}, {10, 10}}, rotation = -90)));
  Modelica.Electrical.Analog.Basic.Resistor rPull(R = 10e3) "Résistance de tirage : bouton relâché, GP0 lit 1" annotation(
    Placement(transformation(origin = {-90, 50}, extent = {{-10, -10}, {10, 10}}, rotation = 90)));
  Modelica.Electrical.Analog.Basic.VariableConductor button "Bouton TARE : contact vers la masse (conductance commandée, sans commutation idéale)" annotation(
    Placement(transformation(origin = {-90, 0}, extent = {{-10, -10}, {10, 10}}, rotation = 90)));
  Modelica.Blocks.Math.BooleanToReal contact(realTrue = 10, realFalse = 1e-9) "Appuyé : 0,1 Ω ; relâché : 1 GΩ" annotation(
    Placement(transformation(origin = {-125, 0}, extent = {{-10, -10}, {10, 10}})));
  Modelica.Blocks.Sources.BooleanTable press(table = {3.5, 3.7}) "Appui sur TARE de t = 3,5 s à 3,7 s, bol posé" annotation(
    Placement(transformation(origin = {-160, 0}, extent = {{-10, -10}, {10, 10}})));
  Modelica.Electrical.Analog.Basic.Ground ground annotation(
    Placement(transformation(origin = {60, -100}, extent = {{-10, -10}, {10, 10}})));
  Modelica.Electrical.Analog.Basic.Ground groundBtn annotation(
    Placement(transformation(origin = {-130, -40}, extent = {{-10, -10}, {10, 10}})));
  Modelica.Electrical.Analog.Basic.Ground groundLcd annotation(
    Placement(transformation(origin = {150, 35}, extent = {{-10, -10}, {10, 10}})));
equation
// Écran : I2C(scl=Pin(4), sda=Pin(5)), imposé par le driver
  connect(mcu.GP4, lcd.SCL) annotation(
    Line(points = {{31, 25}, {60, 25}, {60, 83}, {88, 83}}, color = {0, 0, 255}));
  connect(mcu.GP5, lcd.SDA) annotation(
    Line(points = {{31, 10}, {70, 10}, {70, 117}, {88, 117}}, color = {0, 0, 255}));
  connect(lcd.GND, groundLcd.p) annotation(
    Line(points = {{150, 64}, {150, 45}}, color = {0, 0, 255}));
// HX711 : PD_SCK sur GP6, DOUT sur GP7
  connect(mcu.GP6, hx.PD_SCK) annotation(
    Line(points = {{31, -10}, {113, -10}}, color = {0, 0, 255}));
  connect(mcu.GP7, hx.DOUT) annotation(
    Line(points = {{31, -25}, {66, -25}, {66, -28}, {113, -28}}, color = {0, 0, 255}));
  connect(hx.E_plus, bridge.E_plus) annotation(
    Line(points = {{185, -6}, {210.5, -6}, {210.5, -7}, {231, -7}}, color = {0, 0, 255}));
  connect(hx.A_plus, bridge.S_plus) annotation(
    Line(points = {{185, -15}, {210.5, -15}, {210.5, -16}, {231, -16}}, color = {0, 0, 255}));
  connect(hx.A_minus, bridge.S_minus) annotation(
    Line(points = {{185, -23}, {193.5, -23}, {193.5, -24}, {231, -24}}, color = {0, 0, 255}));
  connect(hx.E_minus, bridge.E_minus) annotation(
    Line(points = {{185, -32}, {193.5, -32}, {193.5, -33}, {231, -33}}, color = {0, 0, 255}));
  connect(loadCell.eps, bridge.eps) annotation(
    Line(points = {{331.5, -17}, {305.5, -17}, {305.5, -20}, {296, -20}}, color = {0, 0, 127}));
  connect(weight.flange, loadCell.flange) annotation(
    Line(points = {{420, -20}, {420, -7.5}, {384, -7.5}, {384, -17}}, color = {0, 127, 0}));
  connect(g.y, weight.f) annotation(
    Line(points = {{459, -20}, {442, -20}}, color = {0, 0, 127}));
  connect(totalMass.y, g.u) annotation(
    Line(points = {{499, -20}, {482, -20}}, color = {0, 0, 127}));
  connect(plateau.y, totalMass.u1) annotation(
    Line(points = {{539, 0}, {530, 0}, {530, -14}, {522, -14}}, color = {0, 0, 127}));
  connect(load.y, totalMass.u2) annotation(
    Line(points = {{539, -40}, {530, -40}, {530, -26}, {522, -26}}, color = {0, 0, 127}));
// Bouton TARE sur GP0 : tirage vers 3,3 V, appui = contact à la masse
  connect(mcu.GP0, rPull.p) annotation(
    Line(points = {{-31, 25}, {-90, 25}, {-90, 40}}, color = {0, 0, 255}));
  connect(button.n, rPull.p) annotation(
    Line(points = {{-90, 10}, {-90, 40}}, color = {0, 0, 255}));
  connect(vcc.p, rPull.n) annotation(
    Line(points = {{-130, 60}, {-130, 75}, {-90, 75}, {-90, 60}}, color = {0, 0, 255}));
  connect(vcc.n, groundBtn.p) annotation(
    Line(points = {{-130, 40}, {-130, -30}}, color = {0, 0, 255}));
  connect(button.p, groundBtn.p) annotation(
    Line(points = {{-90, -10}, {-90, -30}, {-130, -30}}, color = {0, 0, 255}));
  connect(contact.y, button.G) annotation(
    Line(points = {{-114, 0}, {-102, 0}}, color = {0, 0, 127}));
  connect(press.y, contact.u) annotation(
    Line(points = {{-149, 0}, {-137, 0}}, color = {255, 0, 255}));
  connect(mcu.GND, ground.p) annotation(
    Line(points = {{0, -39}, {0, -90}, {60, -90}}, color = {0, 0, 255}));
  connect(hx.GND, ground.p) annotation(
    Line(points = {{149, -40}, {149, -90}, {60, -90}}, color = {0, 0, 255}));
  annotation(
    Diagram(coordinateSystem(extent = {{-180, -120}, {570, 160}})),
    experiment(StopTime = 7, Interval = 0.001, StartTime = 0, Tolerance = 1e-06),
    Documentation(info = "<html>
<p>Une <strong>balance de cuisine</strong> complète, de la masse posée sur le plateau jusqu'à l'affichage :</p>
<p><code>load</code> + <code>plateau</code> (masses) → <code>g</code>, <code>weight</code> (poids : une force) → <code>loadCell</code> (corps d'épreuve, qui se déforme) → <code>bridge</code> (jauges : la déformation déséquilibre le pont, 1 mV/V à pleine charge) → <code>hx</code> (HX711 : amplification × 128 et conversion 24 bits) → <code>mcu</code> (programme <code>kitchen_scale.py</code>) → <code>lcd</code> (écran Grove LCD RGB, bus I2C).</p>
<p>Le programme utilise deux drivers MicroPython du commerce, sans modification : <code>hx711_gpio.py</code> (<a href=\"https://github.com/robert-hh/hx711\">robert-hh/hx711</a>) et <code>driver_grove_lcd_rgb.py</code>. Il fait la tare au démarrage (le plateau de 200 g devient le zéro), convertit les points du HX711 en grammes par une constante d'étalonnage (429,497 points par gramme) et affiche le résultat au gramme près. Seuls les caractères qui changent sont envoyés à l'écran : chacun coûte une transaction I2C. Un appui sur le bouton <strong>TARE</strong> (<code>GP0</code>, interruption sur front descendant) remet l'affichage à zéro, bol compris.</p>
<p>Scénario :</p>
<ul>
<li>t = 0 à 1,1 s : démarrage, tare du plateau vide (« Tare... ») ;</li>
<li>t = 2 s : on pose un bol de 350 g → « 350 g » ;</li>
<li>t = 3,5 s : appui sur TARE → « Tare... », puis « 0 g » vers 4,2 s ;</li>
<li>t = 4,5 à 5,5 s : on verse 250 g de farine → l'affichage monte jusqu'à « 250 g ».</li>
</ul>
<p>À observer : l'icône de <code>lcd</code> pendant la relecture animée ; <code>hx.code</code> (les points bruts, bruit compris) ; <code>mcu.GP6.v</code> et <code>mcu.GP7.v</code> (les trames du HX711) ; <code>mcu.GP4.v</code>/<code>mcu.GP5.v</code> (le bus I2C, actif seulement quand l'affichage change).</p>
<p>Pistes de TP : étalonner la balance (retrouver 429,497 points par gramme à partir d'une masse connue) ; régler le filtre du driver (<code>set_time_constant</code>) et observer le compromis entre stabilité et rapidité ; augmenter <code>hx.noiseLsb</code> ; passer <code>hx.rate</code> à 80 échantillons par seconde.</p>
</html>"));
end KitchenScale;
