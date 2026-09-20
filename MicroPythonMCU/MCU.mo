within MicroPythonMCU;

model MCU "Microcontrôleur programmable simulé (v0), piloté par un script Python compatible MicroPython"
  parameter String scriptPath = Modelica.Utilities.Files.loadResource("modelica://MicroPythonMCU/Resources/Scripts/demo.py") "Chemin du script utilisateur (.py)" annotation(
    Dialog(loadSelector(filter = "Fichiers Python (*.py)", caption = "Sélectionner un script Python")));
  parameter Modelica.Units.SI.Time tickPeriod = 0.1 "Période du point de synchro minimal (fraîcheur des sorties si le script ne dort jamais)";
  parameter Modelica.Units.SI.Voltage VOH = Interfaces.VOH "Tension logique haute";
  parameter Modelica.Units.SI.Voltage VOL = Interfaces.VOL "Tension logique basse";
  parameter Modelica.Units.SI.Voltage VIH = Interfaces.VIH "Seuil de reconnaissance d'une entrée haute";
  parameter Modelica.Units.SI.Voltage VIL = Interfaces.VIL "Seuil de reconnaissance d'une entrée basse";
  parameter Modelica.Units.SI.Resistance ROut = Interfaces.ROut "Résistance série de sortie (drive strength)";
  parameter Modelica.Units.SI.Resistance ledSeriesR = 330 "Résistance série de la LED embarquée (interne, GP25)";
  Modelica.Electrical.Analog.Interfaces.PositivePin GP0 "GPIO 0 (machine.Pin(0), machine.ADC(0) ou machine.PWM(0))" annotation(
    Placement(transformation(origin = {-62, 50}, extent = {{-7, -7}, {7, 7}})));
  Modelica.Electrical.Analog.Interfaces.PositivePin GP1 "GPIO 1 (machine.Pin(1), machine.ADC(1) ou machine.PWM(1))" annotation(
    Placement(transformation(origin = {-62, 20}, extent = {{-7, -7}, {7, 7}})));
  Modelica.Electrical.Analog.Interfaces.PositivePin GP2 "GPIO 2 (machine.Pin(2), machine.ADC(2) ou machine.PWM(2))" annotation(
    Placement(transformation(origin = {-62, -20}, extent = {{-7, -7}, {7, 7}})));
  Modelica.Electrical.Analog.Interfaces.PositivePin GP3 "GPIO 3 (machine.Pin(3), machine.ADC(3) ou machine.PWM(3))" annotation(
    Placement(transformation(origin = {-62, -50}, extent = {{-7, -7}, {7, 7}})));
  Modelica.Electrical.Analog.Interfaces.PositivePin GP4 "GPIO 4 (machine.Pin(4), machine.ADC(4) ou machine.PWM(4))" annotation(
    Placement(transformation(origin = {62, 50}, extent = {{-7, -7}, {7, 7}})));
  Modelica.Electrical.Analog.Interfaces.PositivePin GP5 "GPIO 5 (machine.Pin(5), machine.ADC(5) ou machine.PWM(5))" annotation(
    Placement(transformation(origin = {62, 20}, extent = {{-7, -7}, {7, 7}})));
  Modelica.Electrical.Analog.Interfaces.PositivePin GP6 "GPIO 6 (machine.Pin(6), machine.ADC(6) ou machine.PWM(6))" annotation(
    Placement(transformation(origin = {62, -20}, extent = {{-7, -7}, {7, 7}})));
  Modelica.Electrical.Analog.Interfaces.PositivePin GP7 "GPIO 7 (machine.Pin(7), machine.ADC(7) ou machine.PWM(7))" annotation(
    Placement(transformation(origin = {62, -50}, extent = {{-7, -7}, {7, 7}})));
  Modelica.Electrical.Analog.Interfaces.NegativePin GND "Référence commune (masse) - à relier à la masse du circuit externe" annotation(
    Placement(transformation(origin = {0, -78}, extent = {{-6, -6}, {6, 6}})));
  MicroPythonMCU.Utils.LED builtinLed "LED embarquée du Raspberry Pi Pico (GP25 réel), câblée en interne à demeure (pas de connecteur externe). Publique (pas protected comme le reste de l'implémentation) : les variables protected n'apparaissent pas dans les résultats de simulation dans cette installation OpenModelica, ce qui casserait l'animation DynamicSelect de l'icône (vérifié empiriquement, cf. requirements.md) — on réutilise directement builtinLed.mean.y, déjà public via Utils.LED." annotation(
    Placement(transformation(extent = {{-150, -130}, {-130, -110}})));
protected
  Modelica.Units.SI.Voltage pinNodeVoltage[9] "Tension effective de chaque broche (index 9 = noeud interne de la LED embarquée)";
  Boolean pinBoolIn[9] "Valeur logique lue par broche (tension comparée aux seuils VIL/VIH), y compris index 9 (LED embarquée) qui relit ainsi son propre état comme une broche normale";
  discrete Boolean pinBoolOut[9](each start = false, each fixed = true) "Valeur pilotée par broche (sortie du dernier point de synchro) ; index 9 = LED embarquée (GP25 réel)";
  discrete Boolean pinIsOutputD[9](each start = false, each fixed = true) "Direction par broche (sortie du dernier point de synchro)";
  discrete Modelica.Units.SI.Frequency pwmFreq[9](each start = 0, each fixed = true) "Fréquence PWM par broche (Hz) ; 0 = pas en mode PWM (sortie numérique classique via pinBoolOut), cf. machine.PWM";
  discrete Real pwmDuty[9](each start = 0, each fixed = true) "Rapport cyclique PWM par broche (0-1), pertinent seulement si pwmFreq > 0";
  Modelica.Units.SI.Time pwmPeriod[9] "1/pwmFreq, avec plancher pour éviter une division par zéro quand pwmFreq = 0 (broche pas en PWM)";
  discrete Modelica.Units.SI.Time nextWakeTime(start = 0, fixed = true) "Prochain réveil demandé par le script (sleep) ou +inf si terminé";
  Internal.PyRuntime rt = Internal.PyRuntime(scriptPath, Modelica.Utilities.Files.loadResource("modelica://MicroPythonMCU/Resources/PythonRuntime")) "Interpréteur Python embarqué exécutant le script utilisateur" annotation(
    Placement(transformation(extent = {{-20, 75}, {20, 95}})));
  Modelica.Electrical.Analog.Sources.SignalVoltage src[9] "Source de tension pilotée par le script (VOH/VOL) quand la broche est en sortie ; index 9 = LED embarquée" annotation(
    Placement(transformation(extent = {{-190, -90}, {-150, -50}})));
  Modelica.Electrical.Analog.Basic.Resistor rOut[9](each R = ROut) "Résistance série (drive strength) ; index 9 = LED embarquée" annotation(
    Placement(transformation(extent = {{-130, -90}, {-90, -50}})));
  Modelica.Electrical.Analog.Ideal.IdealOpeningSwitch sw[9] "Ouvert (haute impédance) quand la broche est en entrée ; index 9 = LED embarquée" annotation(
    Placement(transformation(extent = {{-70, -90}, {-30, -50}})));
  Modelica.Electrical.Analog.Sensors.VoltageSensor sns[9] "Mesure la tension réellement présente sur la broche, quelle que soit sa direction ; index 9 = LED embarquée" annotation(
    Placement(transformation(extent = {{-10, -90}, {30, -50}})));
  Modelica.Electrical.Analog.Basic.Resistor ledResistor(R = ledSeriesR) "Résistance série de la LED embarquée, entre le pont GPIO interne (index 9) et builtinLed" annotation(
    Placement(transformation(extent = {{-190, -125}, {-170, -115}})));
equation
  connect(sw[1].n, GP0) annotation(
    Line(points = {{-34, -70}, {-34, 50}, {-62, 50}}, color = {0, 0, 255}));
  connect(sns[1].p, GP0) annotation(
    Line(points = {{-6, -70}, {-6, 44}, {-62, 44}}, color = {0, 0, 255}));
  connect(sw[2].n, GP1) annotation(
    Line(points = {{-34, -70}, {-34, 20}, {-62, 20}}, color = {0, 0, 255}));
  connect(sns[2].p, GP1) annotation(
    Line(points = {{-6, -70}, {-6, 14}, {-62, 14}}, color = {0, 0, 255}));
  connect(sw[3].n, GP2) annotation(
    Line(points = {{-34, -70}, {-34, -20}, {-62, -20}}, color = {0, 0, 255}));
  connect(sns[3].p, GP2) annotation(
    Line(points = {{-6, -70}, {-6, -26}, {-62, -26}}, color = {0, 0, 255}));
  connect(sw[4].n, GP3) annotation(
    Line(points = {{-34, -70}, {-34, -50}, {-62, -50}}, color = {0, 0, 255}));
  connect(sns[4].p, GP3) annotation(
    Line(points = {{-6, -70}, {-6, -56}, {-62, -56}}, color = {0, 0, 255}));
  connect(sw[5].n, GP4) annotation(
    Line(points = {{-34, -70}, {40, -70}, {40, 50}, {62, 50}}, color = {0, 0, 255}));
  connect(sns[5].p, GP4) annotation(
    Line(points = {{-6, -70}, {45, -70}, {45, 44}, {62, 44}}, color = {0, 0, 255}));
  connect(sw[6].n, GP5) annotation(
    Line(points = {{-34, -70}, {40, -70}, {40, 20}, {62, 20}}, color = {0, 0, 255}));
  connect(sns[6].p, GP5) annotation(
    Line(points = {{-6, -70}, {45, -70}, {45, 14}, {62, 14}}, color = {0, 0, 255}));
  connect(sw[7].n, GP6) annotation(
    Line(points = {{-34, -70}, {40, -70}, {40, -20}, {62, -20}}, color = {0, 0, 255}));
  connect(sns[7].p, GP6) annotation(
    Line(points = {{-6, -70}, {45, -70}, {45, -26}, {62, -26}}, color = {0, 0, 255}));
  connect(sw[8].n, GP7) annotation(
    Line(points = {{-34, -70}, {40, -70}, {40, -50}, {62, -50}}, color = {0, 0, 255}));
  connect(sns[8].p, GP7) annotation(
    Line(points = {{-6, -70}, {45, -70}, {45, -56}, {62, -56}}, color = {0, 0, 255}));
  for i in 1:9 loop
    connect(src[i].n, GND) annotation(
      Line(points = {{-154, -70}, {-154, -100}, {0, -100}, {0, -78}}, color = {0, 0, 255}));
    connect(src[i].p, rOut[i].p) annotation(
      Line(points = {{-186, -70}, {-186, -97}, {-126, -97}, {-126, -70}}, color = {0, 0, 255}));
    connect(rOut[i].n, sw[i].p) annotation(
      Line(points = {{-94, -70}, {-66, -70}}, color = {0, 0, 255}));
    connect(sns[i].n, GND) annotation(
      Line(points = {{26, -70}, {26, -103}, {0, -103}, {0, -78}}, color = {0, 0, 255}));
    pinNodeVoltage[i] = sns[i].v;
    pinBoolIn[i] = pinNodeVoltage[i] > (VIL + VIH)/2 "seuil logique médian, approximation v0";
    pwmPeriod[i] = 1 / max(pwmFreq[i], 1e-6);
    src[i].v = if pinIsOutputD[i] then
      (if pwmFreq[i] > 0 then (if mod(time, pwmPeriod[i]) < pwmDuty[i]*pwmPeriod[i] then VOH else VOL)
       else (if pinBoolOut[i] then VOH else VOL))
      else 0 "sortie PWM (créneau généré en continu par Modelica, cf. requirements.md) si pwmFreq > 0, sinon sortie numérique classique";
    sw[i].control = not pinIsOutputD[i] "ouvert (haute impédance) si la broche est en entrée";
  end for;
  connect(sw[9].n, ledResistor.p) annotation(
    Line(points = {{-30, -70}, {-30, -115}, {-190, -115}, {-190, -120}}, color = {0, 0, 255}));
  connect(sns[9].p, ledResistor.p) annotation(
    Line(points = {{-10, -70}, {-10, -118}, {-190, -118}}, color = {0, 0, 255}));
  connect(ledResistor.n, builtinLed.p) annotation(
    Line(points = {{-170, -120}, {-150, -120}}, color = {0, 0, 255}));
  connect(builtinLed.n, GND) annotation(
    Line(points = {{-130, -120}, {-130, -108}, {0, -108}, {0, -78}}, color = {0, 0, 255}));
  when {initial(), time >= pre(nextWakeTime), sample(0, tickPeriod), change(pinBoolIn[1]) and not pre(pinIsOutputD[1]), change(pinBoolIn[2]) and not pre(pinIsOutputD[2]), change(pinBoolIn[3]) and not pre(pinIsOutputD[3]), change(pinBoolIn[4]) and not pre(pinIsOutputD[4]), change(pinBoolIn[5]) and not pre(pinIsOutputD[5]), change(pinBoolIn[6]) and not pre(pinIsOutputD[6]), change(pinBoolIn[7]) and not pre(pinIsOutputD[7]), change(pinBoolIn[8]) and not pre(pinIsOutputD[8]), change(pinBoolIn[9]) and not pre(pinIsOutputD[9])} then
    (pinBoolOut, pinIsOutputD, pwmFreq, pwmDuty, nextWakeTime) = Internal.PyRuntime_sync(rt, time, pinBoolIn, pinNodeVoltage);
  end when;
  annotation(
    Icon(coordinateSystem(preserveAspectRatio = true, extent = {{-100, -100}, {100, 100}}), graphics = {Rectangle(extent = {{-55, 65}, {55, -65}}, lineColor = {0, 0, 0}, fillColor = {60, 60, 60}, fillPattern = FillPattern.Solid), Ellipse(extent = {{-6, 46}, {6, 34}}, lineColor = {0, 0, 0}, fillPattern = FillPattern.Solid, fillColor = DynamicSelect({40, 90, 40}, {integer(40 + min(1, max(0, builtinLed.mean.y)/builtinLed.IMax)*(0 - 40)), integer(90 + min(1, max(0, builtinLed.mean.y)/builtinLed.IMax)*(220 - 90)), integer(40 + min(1, max(0, builtinLed.mean.y)/builtinLed.IMax)*(0 - 40))})), Text(extent = {{-40, 18}, {40, -2}}, textString = "MCU", textColor = {255, 255, 255}, textStyle = {TextStyle.Bold}), Text(extent = {{-40, -4}, {40, -18}}, textString = "(v0)", textColor = {200, 200, 200}), Text(extent = {{-46, 57}, {-8, 43}}, textString = "GP0", textColor = {255, 255, 255}, horizontalAlignment = TextAlignment.Left), Text(extent = {{-46, 27}, {-8, 13}}, textString = "GP1", textColor = {255, 255, 255}, horizontalAlignment = TextAlignment.Left), Text(extent = {{-46, -13}, {-8, -27}}, textString = "GP2", textColor = {255, 255, 255}, horizontalAlignment = TextAlignment.Left), Text(extent = {{-46, -43}, {-8, -57}}, textString = "GP3", textColor = {255, 255, 255}, horizontalAlignment = TextAlignment.Left), Text(extent = {{8, 57}, {46, 43}}, textString = "GP4", textColor = {255, 255, 255}, horizontalAlignment = TextAlignment.Right), Text(extent = {{8, 27}, {46, 13}}, textString = "GP5", textColor = {255, 255, 255}, horizontalAlignment = TextAlignment.Right), Text(extent = {{8, -13}, {46, -27}}, textString = "GP6", textColor = {255, 255, 255}, horizontalAlignment = TextAlignment.Right), Text(extent = {{8, -43}, {46, -57}}, textString = "GP7", textColor = {255, 255, 255}, horizontalAlignment = TextAlignment.Right), Text(extent = {{-25, -83}, {25, -90}}, textString = "GND", textColor = {0, 0, 0}), Text(extent = {{-150, 140}, {150, 100}}, textString = "%name", textColor = {0, 0, 255})}),
    Diagram(coordinateSystem(preserveAspectRatio = true, extent = {{-200, -150}, {100, 110}})),
    Documentation(info = "<html>
<p>Modèle v0 complet : pont électrique GPIO (source de tension pilotée, résistance série, interrupteur idéal, capteur de tension) piloté par <code>PyRuntime</code>, qui exécute le script Python de l'utilisateur (compatible MicroPython, API <code>machine.Pin</code>/<code>machine.ADC</code>/<code>machine.PWM</code>/<code>time</code>) dans un thread avec interception de <code>sleep()</code>. Référence d'API : Raspberry Pi Pico (RP2040), cf. <code>requirements.md</code> — non affichée sur l'icône pour rester générique. Chaque broche <code>GP0</code>-<code>GP7</code> est utilisable au choix du script en numérique (<code>machine.Pin</code>), en analogique (<code>machine.ADC</code>, lecture 16 bits de la tension mesurée par le capteur déjà présent dans le pont) ou en PWM (<code>machine.PWM</code>, créneau généré en continu côté Modelica une fois fréquence/rapport cyclique configurés — pas de va-et-vient avec le thread Python à chaque front, cf. <code>requirements.md</code>) — contrairement au vrai Pico où seules certaines broches sont ADC-capables, cf. restrictions dans <code>requirements.md</code>.</p>
<p>La pastille sur l'icône représente la LED embarquée du Raspberry Pi Pico (câblée sur <code>GP25</code> sur la vraie carte). Elle est traitée comme une broche normale, avec le même pont électrique interne que <code>GP0</code>-<code>GP7</code> (<code>SignalVoltage</code>/<code>Resistor</code>/<code>IdealOpeningSwitch</code>/<code>VoltageSensor</code>, indice 9 des mêmes tableaux) — simplement sans connecteur externe : la sortie de ce pont interne alimente directement, à demeure, une résistance série (<code>ledResistor</code>) et une vraie <code>Utils.LED</code> (<code>builtinLed</code>) reliée à <code>GND</code>, fidèle au câblage réel du Pico. Pilotable depuis le script exactement comme les 8 broches GPIO (<code>machine.Pin(25, machine.Pin.OUT).on()</code>/<code>.off()</code>) ; ce n'est pas l'une des 8 broches GPIO exposées en v0 (cf. restrictions dans <code>requirements.md</code>), donc aucun circuit externe ne peut s'y connecter. Vert vif quand allumée, vert éteint sinon — visible pendant la lecture animée d'un résultat de simulation dans OMEdit (<code>DynamicSelect</code> sur <code>builtinLed.mean.y</code>), pas sur un rendu statique.</p>
</html>"));
end MCU;
