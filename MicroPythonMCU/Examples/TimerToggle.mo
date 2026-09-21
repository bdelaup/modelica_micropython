within MicroPythonMCU.Examples;
model TimerToggle "GP0 pilote une LED basculee par un machine.Timer periodique (500 ms) pendant que le script principal dort une seule fois, longtemps - prouve que le Timer continue de se declencher sans faire retourner ce sleep() en avance"
  extends Modelica.Icons.Example;
  MCU mcu(scriptPath = Modelica.Utilities.Files.loadResource("modelica://MicroPythonMCU/Resources/Verification/timer_toggle.py")) "scriptPath = Verification/timer_toggle.py" annotation(
    Placement(transformation(origin = {0, 0}, extent = {{-50, -50}, {50, 50}})));
  Modelica.Electrical.Analog.Basic.Ground ground annotation(
    Placement(transformation(origin = {0, -90}, extent = {{-15, -15}, {15, 15}})));

  Modelica.Electrical.Analog.Basic.Resistor r0(R = 330) "limite le courant de led0 (GP0)" annotation(
    Placement(transformation(origin = {-90, 25}, extent = {{-15, -15}, {15, 15}})));
  MicroPythonMCU.Utils.LED led0 "GP0 : bascule toutes les 500 ms, pilotee par machine.Timer" annotation(
    Placement(transformation(origin = {-142, 25}, extent = {{15, -15}, {-15, 15}}, rotation = -0)));
equation
  connect(mcu.GND, ground.p) annotation(
    Line(points = {{0, -39}, {0, -75}}, color = {0, 0, 255}));
  connect(mcu.GP0, r0.n) annotation(
    Line(points = {{-31, 25}, {-75, 25}}, color = {0, 0, 255}));
  connect(r0.p, led0.p) annotation(
    Line(points = {{-105, 25}, {-127, 25}}, color = {0, 0, 255}));
  connect(led0.n, ground.p) annotation(
    Line(points = {{-157, 25}, {-157, -75}, {0, -75}}, color = {0, 0, 255}));
  annotation(
    Diagram(coordinateSystem(extent = {{-200, -120}, {80, 80}})),
    experiment(StopTime = 2.5, Interval = 0.0005, StartTime = 0, Tolerance = 1e-06),
    Documentation(info = "<html>
<p>Scénario de vérification 12 (cf. <code>requirements.md</code>) : le script <code>timer_toggle.py</code> arme un <code>Timer(period=500, mode=Timer.PERIODIC)</code> qui bascule <code>led0</code> (GP0) toutes les 500 ms, puis fait un seul <code>time.sleep(3600)</code> — sans jamais relire/écrire de broche lui-même en dehors du callback du Timer. Succès attendu : <code>GP0</code> bascule à chaque échéance de 500 ms (t≈0,5/1,0/1,5/2,0 s) alors que rien ne change sur aucune entrée du modèle, preuve que le mécanisme de « pitstop » du Timer se déclenche indépendamment du <code>sleep()</code> en cours, sans le faire retourner en avance (contrairement à une vraie transition d'entrée, cf. <code>Examples.InputReactivity</code>). Les broches <code>GP1</code>-<code>GP7</code>, non utilisées par ce scénario, sont laissées non connectées.</p>
</html>"));
end TimerToggle;
