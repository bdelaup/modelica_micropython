within MicroPythonMCU.Examples;
model DisplayDemo "Le script ecrit du texte sur machine.Display(0) a deux instants differents ; un Peripherals.Display recoit chaque message (connecteur logique Display0->displayLink) et l'affiche dans le journal (print) et sur son icone - prouve la liaison d'affichage pedagogique bout en bout"
  extends Modelica.Icons.Example;
  MCU mcu(scriptPath = Modelica.Utilities.Files.loadResource("modelica://MicroPythonMCU/Resources/Scripts/display_demo.py")) "scriptPath = Resources/Scripts/display_demo.py" annotation(
    Placement(transformation(origin = {-40, -10}, extent = {{-50, -50}, {50, 50}})));
  Modelica.Electrical.Analog.Basic.Ground ground annotation(
    Placement(transformation(origin = {-40, -90}, extent = {{-15, -15}, {15, 15}})));
  Peripherals.Display display "Recoit le texte via Display0" annotation(
    Placement(transformation(origin = {108, 64}, extent = {{-40, -40}, {40, 40}})));
equation
  connect(mcu.GND, ground.p) annotation(
    Line(points = {{-40, -49}, {-40, -75}}, color = {0, 0, 255}));
  connect(display.displayLink, mcu.Display0) annotation(
    Line(points = {{64, 64}, {-16, 64}, {-16, 28}}, color = {28, 108, 200}));
  annotation(
    Diagram(coordinateSystem(extent = {{-120, -120}, {160, 100}})),
    experiment(StopTime = 3, Interval = 0.005, StartTime = 0, Tolerance = 1e-06),
    Documentation(info = "<html>
<p>Scénario de vérification 12 (cf. <code>requirements.md</code>) : le script <code>Resources/Scripts/display_demo.py</code> appelle <code>machine.Display(0).write(...)</code> à deux reprises (séparées par un <code>sleep(1)</code>), vers t≈1 s et t≈2 s. Le <code>Peripherals.Display</code> reçoit chaque message via son connecteur <code>displayLink</code> (câblé sur <code>mcu.Display0</code>, connecteur logique causal - pas électrique, cf. <code>requirements.md</code> décision « Périphérique d'affichage pédagogique »), l'affiche dans le journal de simulation et son icône montre réellement le texte reçu (défilement 2 lignes). Succès attendu : <code>mcu.Display0.seq</code> vaut 0 avant le premier <code>write()</code>, 1 après le premier, 2 après le second - vérifié numériquement via <code>val()</code> dans <code>verify_12_display.mos</code>.</p>
</html>"));
end DisplayDemo;
