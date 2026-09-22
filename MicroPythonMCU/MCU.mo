within MicroPythonMCU;

model MCU "Microcontrôleur programmable simulé (v0), piloté par un script Python compatible MicroPython"
  parameter String scriptPath = Modelica.Utilities.Files.loadResource("modelica://MicroPythonMCU/Resources/Scripts/demo.py") "Chemin du script utilisateur (.py)" annotation(
    Dialog(group = "Script Python", loadSelector(filter = "Fichiers Python (*.py)", caption = "Sélectionner un script Python")));
  parameter Boolean addScriptDirToPath = true "Rendre importables les fichiers .py situés à côté du script (ex. import mon_module) - reproduit le comportement du vrai Pico (dossier racine de la flash sur sys.path)" annotation(
    Dialog(group = "Script Python"));
  parameter String libraryPath = "" "Optionnel : fichier .py d'un dossier de bibliothèque partagée à rendre importable (le dossier contenant ce fichier est ajouté au chemin de recherche des modules) - laisser vide si non utilisé" annotation(
    Dialog(group = "Script Python", loadSelector(filter = "Fichiers Python (*.py)", caption = "Sélectionner un fichier de la bibliothèque à ajouter")));
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
    Placement(transformation(origin = {0, -78}, extent = {{-6, -6}, {6, 6}}), iconTransformation(origin = {0, -78}, extent = {{-6, -6}, {6, 6}})));
  Interfaces.DisplayLinkOutput Display0 "Liaison logique vers un périphérique d'affichage pédagogique (machine.Display(0).write()) - liaison causale simplifiée (message livré instantanément au point de synchro), pas de tension/courant réels ni de forme d'onde série bit-à-bit, cf. requirements.md décision « Périphérique d'affichage pédagogique »" annotation(
    Placement(transformation(origin = {62, 78}, extent = {{-7, -7}, {7, 7}}), iconTransformation(origin = {49, 75}, extent = {{-10, -10}, {10, 10}}, rotation = 90)));
  MicroPythonMCU.Peripherals.LED builtinLed "LED embarquée du Raspberry Pi Pico (GP25 réel), câblée en interne à demeure (pas de connecteur externe). Publique (pas protected comme le reste de l'implémentation) : les variables protected n'apparaissent pas dans les résultats de simulation dans cette installation OpenModelica, ce qui casserait l'animation DynamicSelect de l'icône (vérifié empiriquement, cf. requirements.md) — on réutilise directement builtinLed.mean.y, déjà public via Peripherals.LED." annotation(
    Placement(visible = false, transformation(extent = {{-150, -130}, {-130, -110}})));
protected
  Modelica.Units.SI.Voltage pinNodeVoltage[9] "Tension effective de chaque broche (index 9 = noeud interne de la LED embarquée)";
  Boolean pinBoolIn[9] "Valeur logique lue par broche (tension comparée aux seuils VIL/VIH), y compris index 9 (LED embarquée) qui relit ainsi son propre état comme une broche normale";
  discrete Boolean pinBoolOut[9](each start = false, each fixed = true) "Valeur pilotée par broche (sortie du dernier point de synchro) ; index 9 = LED embarquée (GP25 réel)";
  discrete Boolean pinIsOutputD[9](each start = false, each fixed = true) "Direction par broche (sortie du dernier point de synchro)";
  discrete Modelica.Units.SI.Frequency pwmFreq[9](each start = 0, each fixed = true) "Fréquence PWM par broche (Hz) ; 0 = pas en mode PWM (sortie numérique classique via pinBoolOut), cf. machine.PWM";
  discrete Real pwmDuty[9](each start = 0, each fixed = true) "Rapport cyclique PWM par broche (0-1), pertinent seulement si pwmFreq > 0";
  Modelica.Units.SI.Time pwmPeriod[9] "1/pwmFreq, avec plancher pour éviter une division par zéro quand pwmFreq = 0 (broche pas en PWM)";
  discrete Integer uartTxPin(start = 0, fixed = true) "Broche affectée à l'émission série (0 = aucune) ; une fois affectée elle le reste, même hors trame, car la ligne au repos doit être HAUTE - cf. machine.UART";
  discrete Boolean uartTxActive(start = false, fixed = true) "Une trame est en cours d'émission";
  discrete Modelica.Units.SI.Time uartTxStart(start = 0, fixed = true) "Instant du front de start de la trame en cours";
  discrete Modelica.Units.SI.Time uartBitDur(start = 1, fixed = true) "Durée d'un bit (1/baudrate)";
  discrete Integer uartTxNumBits(start = 10, fixed = true) "Nombre de bits utiles de la trame (10 en 8N1)";
  discrete Real uartTxBits[Interfaces.UART_MAX_FRAME_BITS](each start = 1, each fixed = true) "Motif de bits de la trame, déjà sérialisé côté C (start + data LSB first + stop) : Modelica ne fait que le rejouer dans le temps";
  Real uartTxPhase[9] "Position temporelle dans la trame, en nombre de bits. Vaut -1 (constante) sur toute broche qui n'émet pas : floor() ne croise alors jamais rien, donc aucun événement parasite - même principe que le plancher de pwmPeriod";
  Real uartTxBitIdx[9] "Index du bit en cours d'émission (-1 hors trame)";
  Boolean uartTxLevel[9] "Niveau logique à émettre sur la broche (repos = haut)";
  discrete Modelica.Units.SI.Time nextWakeTime(start = 0, fixed = true) "Prochain réveil demandé par le script (sleep) ou +inf si terminé";
  Internal.PyRuntime rt = Internal.PyRuntime(scriptPath, Modelica.Utilities.Files.loadResource("modelica://MicroPythonMCU/Resources/PythonRuntime"), addScriptDirToPath, libraryPath, Modelica.Utilities.Files.loadResource("modelica://MicroPythonMCU/Resources/Scripts/_shim/machine_time_shim.py")) "Interpréteur Python embarqué exécutant le script utilisateur" annotation(
    Placement(visible = false, transformation(extent = {{-20, 75}, {20, 95}})));
  Modelica.Electrical.Analog.Sources.SignalVoltage src[9] "Source de tension pilotée par le script (VOH/VOL) quand la broche est en sortie ; index 9 = LED embarquée" annotation(
    Placement(visible = false, transformation(extent = {{-190, -90}, {-150, -50}})));
  Modelica.Electrical.Analog.Basic.Resistor rOut[9](each R = ROut) "Résistance série (drive strength) ; index 9 = LED embarquée" annotation(
    Placement(visible = false, transformation(extent = {{-130, -90}, {-90, -50}})));
  Modelica.Electrical.Analog.Ideal.IdealOpeningSwitch sw[9] "Ouvert (haute impédance) quand la broche est en entrée ; index 9 = LED embarquée" annotation(
    Placement(visible = false, transformation(extent = {{-70, -90}, {-30, -50}})));
  Modelica.Electrical.Analog.Sensors.VoltageSensor sns[9] "Mesure la tension réellement présente sur la broche, quelle que soit sa direction ; index 9 = LED embarquée" annotation(
    Placement(visible = false, transformation(extent = {{-10, -90}, {30, -50}})));
  Modelica.Electrical.Analog.Basic.Resistor ledResistor(R = ledSeriesR) "Résistance série de la LED embarquée, entre le pont GPIO interne (index 9) et builtinLed" annotation(
    Placement(visible = false, transformation(extent = {{-190, -125}, {-170, -115}})));
public
equation
  connect(sw[1].n, GP0);
  connect(sns[1].p, GP0);
  connect(sw[2].n, GP1);
  connect(sns[2].p, GP1);
  connect(sw[3].n, GP2);
  connect(sns[3].p, GP2);
  connect(sw[4].n, GP3);
  connect(sns[4].p, GP3);
  connect(sw[5].n, GP4);
  connect(sns[5].p, GP4);
  connect(sw[6].n, GP5);
  connect(sns[6].p, GP5);
  connect(sw[7].n, GP6);
  connect(sns[7].p, GP6);
  connect(sw[8].n, GP7);
  connect(sns[8].p, GP7);
  for i in 1:9 loop
    connect(src[i].n, GND);
    connect(src[i].p, rOut[i].p);
    connect(rOut[i].n, sw[i].p);
    connect(sns[i].n, GND);
    pinNodeVoltage[i] = sns[i].v;
    pinBoolIn[i] = pinNodeVoltage[i] > (VIL + VIH)/2 "seuil logique médian, approximation v0";
    pwmPeriod[i] = 1/max(pwmFreq[i], 1e-6);
    uartTxPhase[i] = if uartTxPin == i and uartTxActive then (time - uartTxStart)/uartBitDur else -1.0;
    uartTxBitIdx[i] = floor(uartTxPhase[i]);
    uartTxLevel[i] = if uartTxBitIdx[i] < -0.5 or uartTxBitIdx[i] > uartTxNumBits - 0.5 then true elseif uartTxBitIdx[i] < 0.5 then uartTxBits[1] > 0.5 elseif uartTxBitIdx[i] < 1.5 then uartTxBits[2] > 0.5 elseif uartTxBitIdx[i] < 2.5 then uartTxBits[3] > 0.5 elseif uartTxBitIdx[i] < 3.5 then uartTxBits[4] > 0.5 elseif uartTxBitIdx[i] < 4.5 then uartTxBits[5] > 0.5 elseif uartTxBitIdx[i] < 5.5 then uartTxBits[6] > 0.5 elseif uartTxBitIdx[i] < 6.5 then uartTxBits[7] > 0.5 elseif uartTxBitIdx[i] < 7.5 then uartTxBits[8] > 0.5 elseif uartTxBitIdx[i] < 8.5 then uartTxBits[9] > 0.5 elseif uartTxBitIdx[i] < 9.5 then uartTxBits[10] > 0.5 elseif uartTxBitIdx[i] < 10.5 then uartTxBits[11] > 0.5 elseif uartTxBitIdx[i] < 11.5 then uartTxBits[12] > 0.5 elseif uartTxBitIdx[i] < 12.5 then uartTxBits[13] > 0.5 else true "sélection du bit courant par if/elseif explicite plutôt qu'indexation par variable ; hors trame et au-delà du dernier bit utile : niveau de repos (haut)";
    src[i].v = if pinIsOutputD[i] then (if uartTxPin == i then (if uartTxLevel[i] then VOH else VOL) elseif pwmFreq[i] > 0 then (if mod(time, pwmPeriod[i]) < pwmDuty[i]*pwmPeriod[i] then VOH else VOL) else (if pinBoolOut[i] then VOH else VOL)) else 0 "trame série (générée en continu par Modelica à partir du motif de bits fourni par le C) si la broche est affectée à l'UART, sinon créneau PWM si pwmFreq > 0, sinon sortie numérique classique - cf. requirements.md";
    sw[i].control = not pinIsOutputD[i] "ouvert (haute impédance) si la broche est en entrée";
  end for;
  connect(sw[9].n, ledResistor.p);
  connect(sns[9].p, ledResistor.p);
  connect(ledResistor.n, builtinLed.p);
  connect(builtinLed.n, GND);
  when {initial(), time >= pre(nextWakeTime), sample(0, tickPeriod), change(pinBoolIn[1]) and not pre(pinIsOutputD[1]), change(pinBoolIn[2]) and not pre(pinIsOutputD[2]), change(pinBoolIn[3]) and not pre(pinIsOutputD[3]), change(pinBoolIn[4]) and not pre(pinIsOutputD[4]), change(pinBoolIn[5]) and not pre(pinIsOutputD[5]), change(pinBoolIn[6]) and not pre(pinIsOutputD[6]), change(pinBoolIn[7]) and not pre(pinIsOutputD[7]), change(pinBoolIn[8]) and not pre(pinIsOutputD[8]), change(pinBoolIn[9]) and not pre(pinIsOutputD[9])} then
    (pinBoolOut, pinIsOutputD, pwmFreq, pwmDuty, Display0.seq, Display0.payload, uartTxPin, uartTxActive, uartTxStart, uartBitDur, uartTxNumBits, uartTxBits, nextWakeTime) = Internal.PyRuntime_sync(rt, time, pinBoolIn, pinNodeVoltage);
    Display0.charCode = Internal.StringToCharCodes(Display0.payload, Interfaces.DISPLAY_COLS) "codes ASCII derives de Display0.payload (String, non stockable dans les resultats), pour permettre au périphérique d'affichage connecté d'animer le texte reellement recu sur son icone - cf. Internal.StringToCharCodes";
  end when;
  annotation(
    Icon(coordinateSystem(preserveAspectRatio = true, extent = {{-100, -100}, {100, 100}}), graphics = {Rectangle(fillColor = {60, 60, 60}, fillPattern = FillPattern.Solid, extent = {{-55, 65}, {55, -65}}), Ellipse(fillColor = DynamicSelect({40, 90, 40}, {integer(40 + min(1, max(0, builtinLed.mean.y)/builtinLed.IMax)*(-40)), integer(90 + min(1, max(0, builtinLed.mean.y)/builtinLed.IMax)*130), integer(40 + min(1, max(0, builtinLed.mean.y)/builtinLed.IMax)*(-40))}), fillPattern = FillPattern.Solid, extent = {{-6, 46}, {6, 34}}), Text(textColor = {255, 255, 255}, extent = {{-40, 18}, {40, -2}}, textString = "MCU", textStyle = {TextStyle.Bold}), Text(textColor = {200, 200, 200}, extent = {{-40, -4}, {40, -18}}, textString = "(v0)"), Text(textColor = {255, 255, 255}, extent = {{-46, 57}, {-8, 43}}, textString = "GP0", horizontalAlignment = TextAlignment.Left), Text(textColor = {255, 255, 255}, extent = {{-46, 27}, {-8, 13}}, textString = "GP1", horizontalAlignment = TextAlignment.Left), Text(textColor = {255, 255, 255}, extent = {{-46, -13}, {-8, -27}}, textString = "GP2", horizontalAlignment = TextAlignment.Left), Text(textColor = {255, 255, 255}, extent = {{-46, -43}, {-8, -57}}, textString = "GP3", horizontalAlignment = TextAlignment.Left), Text(textColor = {255, 255, 255}, extent = {{8, 57}, {46, 43}}, textString = "GP4", horizontalAlignment = TextAlignment.Right), Text(textColor = {255, 255, 255}, extent = {{8, 27}, {46, 13}}, textString = "GP5", horizontalAlignment = TextAlignment.Right), Text(textColor = {255, 255, 255}, extent = {{8, -13}, {46, -27}}, textString = "GP6", horizontalAlignment = TextAlignment.Right), Text(textColor = {255, 255, 255}, extent = {{8, -43}, {46, -57}}, textString = "GP7", horizontalAlignment = TextAlignment.Right), Text(extent = {{-25, -83}, {25, -90}}, textString = "GND"), Text(origin = {-54, -51}, textColor = {255, 255, 255}, extent = {{55, 106}, {108, 115}}, textString = "DISPLAY", horizontalAlignment = TextAlignment.Right), Text(origin = {0, -34}, textColor = {0, 0, 255}, extent = {{-150, 140}, {150, 100}}, textString = "%name")}),
    Diagram(coordinateSystem(preserveAspectRatio = true, extent = {{-100, -100}, {100, 100}}), graphics),
    Documentation(info = "<html>
<p>Modèle v0 complet : pont électrique GPIO (source de tension pilotée, résistance série, interrupteur idéal, capteur de tension) piloté par <code>PyRuntime</code>, qui exécute le script Python de l'utilisateur (compatible MicroPython, API <code>machine.Pin</code>/<code>machine.ADC</code>/<code>machine.PWM</code>/<code>time</code>) dans un thread avec interception de <code>sleep()</code>. Référence d'API : Raspberry Pi Pico (RP2040), cf. <code>requirements.md</code> — non affichée sur l'icône pour rester générique. Chaque broche <code>GP0</code>-<code>GP7</code> est utilisable au choix du script en numérique (<code>machine.Pin</code>), en analogique (<code>machine.ADC</code>, lecture 16 bits de la tension mesurée par le capteur déjà présent dans le pont) ou en PWM (<code>machine.PWM</code>, créneau généré en continu côté Modelica une fois fréquence/rapport cyclique configurés — pas de va-et-vient avec le thread Python à chaque front, cf. <code>requirements.md</code>) — contrairement au vrai Pico où seules certaines broches sont ADC-capables, cf. restrictions dans <code>requirements.md</code>.</p>
<p>Le script peut importer un module auxiliaire (<code>import mon_module</code>) : par défaut (<code>addScriptDirToPath</code>), le dossier du script est ajouté au chemin de recherche Python, et <code>libraryPath</code> permet de désigner en plus un fichier <code>.py</code> d'une bibliothèque partagée (son dossier est alors ajouté aussi) — cf. <code>requirements.md</code>, décision « Import de modules auxiliaires ».</p>
<p>Le connecteur <code>Display0</code> expose une liaison logique vers un périphérique d'affichage pédagogique (<code>machine.Display(0).write(texte)</code>) : contrairement aux broches <code>GPx</code>, ce n'est pas un connecteur électrique (<code>Modelica.Electrical.Analog</code>) mais un connecteur logique causal (<code>Interfaces.DisplayLinkOutput</code>, message livré instantanément au point de synchro, pas de forme d'onde série ni de bauds simulés) — à câbler sur le <code>displayLink</code> (<code>Interfaces.DisplayLinkInput</code>) d'un <code>Peripherals.Display</code>, composant optionnel (brancher ou non selon le circuit). Cf. <code>requirements.md</code>, décision « Périphérique d'affichage pédagogique ».</p>
<p>La pastille sur l'icône représente la LED embarquée du Raspberry Pi Pico (câblée sur <code>GP25</code> sur la vraie carte). Elle est traitée comme une broche normale, avec le même pont électrique interne que <code>GP0</code>-<code>GP7</code> (<code>SignalVoltage</code>/<code>Resistor</code>/<code>IdealOpeningSwitch</code>/<code>VoltageSensor</code>, indice 9 des mêmes tableaux) — simplement sans connecteur externe : la sortie de ce pont interne alimente directement, à demeure, une résistance série (<code>ledResistor</code>) et une vraie <code>Peripherals.LED</code> (<code>builtinLed</code>) reliée à <code>GND</code>, fidèle au câblage réel du Pico. Pilotable depuis le script exactement comme les 8 broches GPIO (<code>machine.Pin(25, machine.Pin.OUT).on()</code>/<code>.off()</code>) ; ce n'est pas l'une des 8 broches GPIO exposées en v0 (cf. restrictions dans <code>requirements.md</code>), donc aucun circuit externe ne peut s'y connecter. Vert vif quand allumée, vert éteint sinon — visible pendant la lecture animée d'un résultat de simulation dans OMEdit (<code>DynamicSelect</code> sur <code>builtinLed.mean.y</code>), pas sur un rendu statique.</p>
<p><em>Schéma interne (Diagram) volontairement vide en v0 : les blocs du pont électrique sont masqués (<code>visible = false</code>) plutôt que routés proprement — un schéma lisible sera redessiné plus tard, cf. requirements.md.</em></p>
</html>"));
end MCU;
