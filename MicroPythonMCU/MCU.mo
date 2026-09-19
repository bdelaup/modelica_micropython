within MicroPythonMCU;
model MCU "Microcontrôleur programmable simulé (v0), piloté par un script Python compatible MicroPython"
  parameter String scriptPath = Modelica.Utilities.Files.loadResource("modelica://MicroPythonMCU/Resources/Scripts/demo.py") "Chemin du script utilisateur (.py)";
  parameter Modelica.Units.SI.Time tickPeriod = 0.1 "Période du point de synchro minimal (fraîcheur des sorties si le script ne dort jamais)";
  parameter Modelica.Units.SI.Voltage VOH = Interfaces.VOH "Tension logique haute";
  parameter Modelica.Units.SI.Voltage VOL = Interfaces.VOL "Tension logique basse";
  parameter Modelica.Units.SI.Voltage VIH = Interfaces.VIH "Seuil de reconnaissance d'une entrée haute";
  parameter Modelica.Units.SI.Voltage VIL = Interfaces.VIL "Seuil de reconnaissance d'une entrée basse";
  parameter Modelica.Units.SI.Resistance ROut = Interfaces.ROut "Résistance série de sortie (drive strength)";

  Modelica.Electrical.Analog.Interfaces.PositivePin GP0 "GPIO 0 (machine.Pin(0))" annotation(Placement(transformation(origin = {-62, 50}, extent = {{-7, -7}, {7, 7}})));
  Modelica.Electrical.Analog.Interfaces.PositivePin GP1 "GPIO 1 (machine.Pin(1))" annotation(Placement(transformation(origin = {-62, 20}, extent = {{-7, -7}, {7, 7}})));
  Modelica.Electrical.Analog.Interfaces.PositivePin GP2 "GPIO 2 (machine.Pin(2))" annotation(Placement(transformation(origin = {-62, -20}, extent = {{-7, -7}, {7, 7}})));
  Modelica.Electrical.Analog.Interfaces.PositivePin GP3 "GPIO 3 (machine.Pin(3))" annotation(Placement(transformation(origin = {-62, -50}, extent = {{-7, -7}, {7, 7}})));
  Modelica.Electrical.Analog.Interfaces.PositivePin GP4 "GPIO 4 (machine.Pin(4))" annotation(Placement(transformation(origin = {62, 50}, extent = {{-7, -7}, {7, 7}})));
  Modelica.Electrical.Analog.Interfaces.PositivePin GP5 "GPIO 5 (machine.Pin(5))" annotation(Placement(transformation(origin = {62, 20}, extent = {{-7, -7}, {7, 7}})));
  Modelica.Electrical.Analog.Interfaces.PositivePin GP6 "GPIO 6 (machine.Pin(6))" annotation(Placement(transformation(origin = {62, -20}, extent = {{-7, -7}, {7, 7}})));
  Modelica.Electrical.Analog.Interfaces.PositivePin GP7 "GPIO 7 (machine.Pin(7))" annotation(Placement(transformation(origin = {62, -50}, extent = {{-7, -7}, {7, 7}})));
  Modelica.Electrical.Analog.Interfaces.NegativePin GND "Référence commune (masse) - à relier à la masse du circuit externe" annotation(Placement(transformation(origin = {0, -78}, extent = {{-6, -6}, {6, 6}})));

protected
  Modelica.Units.SI.Voltage pinNodeVoltage[8] "Tension effective de chaque broche GPn (n = index-1)";
  Boolean pinBoolIn[8] "Valeur logique lue par broche (tension comparée aux seuils VIL/VIH)";
  discrete Boolean pinBoolOut[8](each start = false, each fixed = true) "Valeur pilotée par broche (sortie du dernier point de synchro)";
  discrete Boolean pinIsOutputD[8](each start = false, each fixed = true) "Direction par broche (sortie du dernier point de synchro)";
  discrete Modelica.Units.SI.Time nextWakeTime(start = 0, fixed = true) "Prochain réveil demandé par le script (sleep) ou +inf si terminé";

  Internal.PyRuntime rt = Internal.PyRuntime(scriptPath, Modelica.Utilities.Files.loadResource("modelica://MicroPythonMCU/Resources/PythonRuntime")) "Interpréteur Python embarqué exécutant le script utilisateur" annotation(Placement(transformation(extent = {{-20, 75}, {20, 95}})));

  Modelica.Electrical.Analog.Sources.SignalVoltage src[8] "Source de tension pilotée par le script (VOH/VOL) quand la broche est en sortie" annotation(Placement(transformation(extent = {{-190, -90}, {-150, -50}})));
  Modelica.Electrical.Analog.Basic.Resistor rOut[8](each R = ROut) "Résistance série (drive strength)" annotation(Placement(transformation(extent = {{-130, -90}, {-90, -50}})));
  Modelica.Electrical.Analog.Ideal.IdealOpeningSwitch sw[8] "Ouvert (haute impédance) quand la broche est en entrée" annotation(Placement(transformation(extent = {{-70, -90}, {-30, -50}})));
  Modelica.Electrical.Analog.Sensors.VoltageSensor sns[8] "Mesure la tension réellement présente sur la broche, quelle que soit sa direction" annotation(Placement(transformation(extent = {{-10, -90}, {30, -50}})));
equation
  connect(sw[1].n, GP0) annotation(Line(points = {{-34, -70}, {-34, 50}, {-62, 50}}, color = {0, 0, 255}));
  connect(sns[1].p, GP0) annotation(Line(points = {{-6, -70}, {-6, 44}, {-62, 44}}, color = {0, 0, 255}));
  connect(sw[2].n, GP1) annotation(Line(points = {{-34, -70}, {-34, 20}, {-62, 20}}, color = {0, 0, 255}));
  connect(sns[2].p, GP1) annotation(Line(points = {{-6, -70}, {-6, 14}, {-62, 14}}, color = {0, 0, 255}));
  connect(sw[3].n, GP2) annotation(Line(points = {{-34, -70}, {-34, -20}, {-62, -20}}, color = {0, 0, 255}));
  connect(sns[3].p, GP2) annotation(Line(points = {{-6, -70}, {-6, -26}, {-62, -26}}, color = {0, 0, 255}));
  connect(sw[4].n, GP3) annotation(Line(points = {{-34, -70}, {-34, -50}, {-62, -50}}, color = {0, 0, 255}));
  connect(sns[4].p, GP3) annotation(Line(points = {{-6, -70}, {-6, -56}, {-62, -56}}, color = {0, 0, 255}));
  connect(sw[5].n, GP4) annotation(Line(points = {{-34, -70}, {40, -70}, {40, 50}, {62, 50}}, color = {0, 0, 255}));
  connect(sns[5].p, GP4) annotation(Line(points = {{-6, -70}, {45, -70}, {45, 44}, {62, 44}}, color = {0, 0, 255}));
  connect(sw[6].n, GP5) annotation(Line(points = {{-34, -70}, {40, -70}, {40, 20}, {62, 20}}, color = {0, 0, 255}));
  connect(sns[6].p, GP5) annotation(Line(points = {{-6, -70}, {45, -70}, {45, 14}, {62, 14}}, color = {0, 0, 255}));
  connect(sw[7].n, GP6) annotation(Line(points = {{-34, -70}, {40, -70}, {40, -20}, {62, -20}}, color = {0, 0, 255}));
  connect(sns[7].p, GP6) annotation(Line(points = {{-6, -70}, {45, -70}, {45, -26}, {62, -26}}, color = {0, 0, 255}));
  connect(sw[8].n, GP7) annotation(Line(points = {{-34, -70}, {40, -70}, {40, -50}, {62, -50}}, color = {0, 0, 255}));
  connect(sns[8].p, GP7) annotation(Line(points = {{-6, -70}, {45, -70}, {45, -56}, {62, -56}}, color = {0, 0, 255}));

  for i in 1:8 loop
    connect(src[i].n, GND) annotation(Line(points = {{-154, -70}, {-154, -100}, {0, -100}, {0, -78}}, color = {0, 0, 255}));
    connect(src[i].p, rOut[i].p) annotation(Line(points = {{-186, -70}, {-186, -97}, {-126, -97}, {-126, -70}}, color = {0, 0, 255}));
    connect(rOut[i].n, sw[i].p) annotation(Line(points = {{-94, -70}, {-66, -70}}, color = {0, 0, 255}));
    connect(sns[i].n, GND) annotation(Line(points = {{26, -70}, {26, -103}, {0, -103}, {0, -78}}, color = {0, 0, 255}));

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
      Rectangle(extent = {{-55, 65}, {55, -65}}, lineColor = {0, 0, 0}, fillColor = {60, 60, 60}, fillPattern = FillPattern.Solid),
      Text(extent = {{-40, 18}, {40, -2}}, textString = "MCU", textColor = {255, 255, 255}, textStyle = {TextStyle.Bold}),
      Text(extent = {{-40, -4}, {40, -18}}, textString = "(v0)", textColor = {200, 200, 200}),
      Text(extent = {{-46, 57}, {-8, 43}}, textString = "GP0", textColor = {255, 255, 255}, horizontalAlignment = TextAlignment.Left),
      Text(extent = {{-46, 27}, {-8, 13}}, textString = "GP1", textColor = {255, 255, 255}, horizontalAlignment = TextAlignment.Left),
      Text(extent = {{-46, -13}, {-8, -27}}, textString = "GP2", textColor = {255, 255, 255}, horizontalAlignment = TextAlignment.Left),
      Text(extent = {{-46, -43}, {-8, -57}}, textString = "GP3", textColor = {255, 255, 255}, horizontalAlignment = TextAlignment.Left),
      Text(extent = {{8, 57}, {46, 43}}, textString = "GP4", textColor = {255, 255, 255}, horizontalAlignment = TextAlignment.Right),
      Text(extent = {{8, 27}, {46, 13}}, textString = "GP5", textColor = {255, 255, 255}, horizontalAlignment = TextAlignment.Right),
      Text(extent = {{8, -13}, {46, -27}}, textString = "GP6", textColor = {255, 255, 255}, horizontalAlignment = TextAlignment.Right),
      Text(extent = {{8, -43}, {46, -57}}, textString = "GP7", textColor = {255, 255, 255}, horizontalAlignment = TextAlignment.Right),
      Text(extent = {{-25, -83}, {25, -90}}, textString = "GND", textColor = {0, 0, 0}),
      Text(extent = {{-150, 140}, {150, 100}}, textString = "%name", textColor = {0, 0, 255})}),
    Diagram(coordinateSystem(preserveAspectRatio = true, extent = {{-200, -150}, {100, 110}})),
    Documentation(info = "<html>
<p>Modèle v0 complet : pont électrique GPIO (source de tension pilotée, résistance série, interrupteur idéal, capteur de tension) piloté par <code>PyRuntime</code>, qui exécute le script Python de l'utilisateur (compatible MicroPython, API <code>machine.Pin</code>/<code>time</code>) dans un thread avec interception de <code>sleep()</code>. Référence d'API : Raspberry Pi Pico (RP2040), cf. <code>requirements.md</code> — non affichée sur l'icône pour rester générique.</p>
</html>"));
end MCU;
