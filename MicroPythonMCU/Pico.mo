within MicroPythonMCU;
model Pico "Microcontrôleur simulé (v0, style Raspberry Pi Pico / RP2040), piloté par un script Python compatible MicroPython"
  parameter String scriptPath = Modelica.Utilities.Files.loadResource("modelica://MicroPythonMCU/Resources/Scripts/demo.py") "Chemin du script utilisateur (.py)";
  parameter Modelica.Units.SI.Time tickPeriod = 0.1 "Période du point de synchro minimal (fraîcheur des sorties si le script ne dort jamais)";
  parameter Modelica.Units.SI.Voltage VOH = Interfaces.VOH "Tension logique haute";
  parameter Modelica.Units.SI.Voltage VOL = Interfaces.VOL "Tension logique basse";
  parameter Modelica.Units.SI.Voltage VIH = Interfaces.VIH "Seuil de reconnaissance d'une entrée haute";
  parameter Modelica.Units.SI.Voltage VIL = Interfaces.VIL "Seuil de reconnaissance d'une entrée basse";
  parameter Modelica.Units.SI.Resistance ROut = Interfaces.ROut "Résistance série de sortie (drive strength)";

  Modelica.Electrical.Analog.Interfaces.PositivePin GP0 "GPIO 0 (machine.Pin(0))" annotation(Placement(transformation(origin = {100, 70}, extent = {{-7, -7}, {7, 7}})));
  Modelica.Electrical.Analog.Interfaces.PositivePin GP1 "GPIO 1 (machine.Pin(1))" annotation(Placement(transformation(origin = {100, 50}, extent = {{-7, -7}, {7, 7}})));
  Modelica.Electrical.Analog.Interfaces.PositivePin GP2 "GPIO 2 (machine.Pin(2))" annotation(Placement(transformation(origin = {100, 30}, extent = {{-7, -7}, {7, 7}})));
  Modelica.Electrical.Analog.Interfaces.PositivePin GP3 "GPIO 3 (machine.Pin(3))" annotation(Placement(transformation(origin = {100, 10}, extent = {{-7, -7}, {7, 7}})));
  Modelica.Electrical.Analog.Interfaces.PositivePin GP4 "GPIO 4 (machine.Pin(4))" annotation(Placement(transformation(origin = {100, -10}, extent = {{-7, -7}, {7, 7}})));
  Modelica.Electrical.Analog.Interfaces.PositivePin GP5 "GPIO 5 (machine.Pin(5))" annotation(Placement(transformation(origin = {100, -30}, extent = {{-7, -7}, {7, 7}})));
  Modelica.Electrical.Analog.Interfaces.PositivePin GP6 "GPIO 6 (machine.Pin(6))" annotation(Placement(transformation(origin = {100, -50}, extent = {{-7, -7}, {7, 7}})));
  Modelica.Electrical.Analog.Interfaces.PositivePin GP7 "GPIO 7 (machine.Pin(7))" annotation(Placement(transformation(origin = {100, -70}, extent = {{-7, -7}, {7, 7}})));
  Modelica.Electrical.Analog.Interfaces.NegativePin GND "Référence commune (masse) - à relier à la masse du circuit externe" annotation(Placement(transformation(origin = {0, -87}, extent = {{-5, -5}, {5, 5}})));

protected
  Modelica.Units.SI.Voltage pinNodeVoltage[8] "Tension effective de chaque broche GPn (n = index-1)";
  Boolean pinBoolIn[8] "Valeur logique lue par broche (tension comparée aux seuils VIL/VIH)";
  discrete Boolean pinBoolOut[8](each start = false, each fixed = true) "Valeur pilotée par broche (sortie du dernier point de synchro)";
  discrete Boolean pinIsOutputD[8](each start = false, each fixed = true) "Direction par broche (sortie du dernier point de synchro)";
  discrete Modelica.Units.SI.Time nextWakeTime(start = 0, fixed = true) "Prochain réveil demandé par le script (sleep) ou +inf si terminé";

  Internal.PyRuntime rt = Internal.PyRuntime(scriptPath, Modelica.Utilities.Files.loadResource("modelica://MicroPythonMCU/Resources/PythonRuntime")) "Interpréteur Python embarqué exécutant le script utilisateur";

  Modelica.Electrical.Analog.Sources.SignalVoltage src[8] "Source de tension pilotée par le script (VOH/VOL) quand la broche est en sortie";
  Modelica.Electrical.Analog.Basic.Resistor rOut[8](each R = ROut) "Résistance série (drive strength)";
  Modelica.Electrical.Analog.Ideal.IdealOpeningSwitch sw[8] "Ouvert (haute impédance) quand la broche est en entrée";
  Modelica.Electrical.Analog.Sensors.VoltageSensor sns[8] "Mesure la tension réellement présente sur la broche, quelle que soit sa direction";
equation
  connect(sw[1].n, GP0); connect(sns[1].p, GP0);
  connect(sw[2].n, GP1); connect(sns[2].p, GP1);
  connect(sw[3].n, GP2); connect(sns[3].p, GP2);
  connect(sw[4].n, GP3); connect(sns[4].p, GP3);
  connect(sw[5].n, GP4); connect(sns[5].p, GP4);
  connect(sw[6].n, GP5); connect(sns[6].p, GP5);
  connect(sw[7].n, GP6); connect(sns[7].p, GP6);
  connect(sw[8].n, GP7); connect(sns[8].p, GP7);

  for i in 1:8 loop
    connect(src[i].n, GND);
    connect(src[i].p, rOut[i].p);
    connect(rOut[i].n, sw[i].p);
    connect(sns[i].n, GND);

    pinNodeVoltage[i] = sns[i].v;
    pinBoolIn[i] = pinNodeVoltage[i] > (VIL + VIH)/2 "seuil logique médian, approximation v0";

    src[i].v = if pinIsOutputD[i] then (if pinBoolOut[i] then VOH else VOL) else 0;
    sw[i].control = not pinIsOutputD[i] "ouvert (haute impédance) si la broche est en entrée";
  end for;

  when {initial(), time >= pre(nextWakeTime), sample(0, tickPeriod),
        change(pinBoolIn[1]) and not pre(pinIsOutputD[1]), change(pinBoolIn[2]) and not pre(pinIsOutputD[2]),
        change(pinBoolIn[3]) and not pre(pinIsOutputD[3]), change(pinBoolIn[4]) and not pre(pinIsOutputD[4]),
        change(pinBoolIn[5]) and not pre(pinIsOutputD[5]), change(pinBoolIn[6]) and not pre(pinIsOutputD[6]),
        change(pinBoolIn[7]) and not pre(pinIsOutputD[7]), change(pinBoolIn[8]) and not pre(pinIsOutputD[8])} then
    (pinBoolOut, pinIsOutputD, nextWakeTime) = Internal.PyRuntime_sync(rt, time, pinBoolIn);
  end when;

  annotation(
    Icon(coordinateSystem(preserveAspectRatio = true, extent = {{-100, -100}, {100, 100}}), graphics = {
      Rectangle(extent = {{-70, 90}, {70, -78}}, lineColor = {0, 0, 0}, fillColor = {60, 60, 60}, fillPattern = FillPattern.Solid),
      Text(extent = {{-60, 10}, {60, -10}}, textString = "Pico", textColor = {255, 255, 255}),
      Text(extent = {{-60, -20}, {60, -35}}, textString = "RP2040 (v0)", textColor = {200, 200, 200}),
      Text(extent = {{40, 80}, {65, 60}}, textString = "GP0", textColor = {0, 0, 0}, horizontalAlignment = TextAlignment.Right),
      Text(extent = {{40, 60}, {65, 40}}, textString = "GP1", textColor = {0, 0, 0}, horizontalAlignment = TextAlignment.Right),
      Text(extent = {{40, 40}, {65, 20}}, textString = "GP2", textColor = {0, 0, 0}, horizontalAlignment = TextAlignment.Right),
      Text(extent = {{40, 20}, {65, 0}}, textString = "GP3", textColor = {0, 0, 0}, horizontalAlignment = TextAlignment.Right),
      Text(extent = {{40, 0}, {65, -20}}, textString = "GP4", textColor = {0, 0, 0}, horizontalAlignment = TextAlignment.Right),
      Text(extent = {{40, -20}, {65, -40}}, textString = "GP5", textColor = {0, 0, 0}, horizontalAlignment = TextAlignment.Right),
      Text(extent = {{40, -40}, {65, -60}}, textString = "GP6", textColor = {0, 0, 0}, horizontalAlignment = TextAlignment.Right),
      Text(extent = {{40, -60}, {65, -80}}, textString = "GP7", textColor = {0, 0, 0}, horizontalAlignment = TextAlignment.Right),
      Text(extent = {{-25, -93}, {25, -100}}, textString = "GND", textColor = {0, 0, 0}),
      Text(extent = {{-150, 140}, {150, 100}}, textString = "%name", textColor = {0, 0, 255})}),
    Documentation(info = "<html>
<p>Modèle v0 complet : pont électrique GPIO (source de tension pilotée, résistance série, interrupteur idéal, capteur de tension) piloté par <code>PyRuntime</code>, qui exécute le script Python de l'utilisateur (compatible MicroPython, API <code>machine.Pin</code>/<code>time</code>) dans un thread avec interception de <code>sleep()</code>. Voir <code>requirements.md</code>.</p>
</html>"));
end Pico;
