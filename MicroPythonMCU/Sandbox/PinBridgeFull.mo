within MicroPythonMCU.Sandbox;
model PinBridgeFull "Pont de broche avec tirages internes (PULL_UP/PULL_DOWN, faits dans MCU) et prototype du mode drain ouvert (OPEN_DRAIN, pas encore dans MCU), en blocs standard"
  parameter Modelica.Units.SI.Voltage VDD = 3.3 "Alimentation interne des tirages";
  parameter Modelica.Units.SI.Voltage VOH = 3.3 "Niveau haut de sortie";
  parameter Modelica.Units.SI.Voltage VOL = 0 "Niveau bas de sortie";
  parameter Modelica.Units.SI.Resistance ROut = 100 "Résistance série de sortie";
  parameter Modelica.Units.SI.Resistance RPullUp = 50e3 "Tirage interne au niveau haut (RP2040 : 50 à 80 kOhm)";
  parameter Modelica.Units.SI.Resistance RPullDown = 50e3 "Tirage interne au niveau bas (RP2040 : 50 à 80 kOhm)";
  parameter Modelica.Units.SI.Conductance GOff = 1e-9 "Fuite des interrupteurs ouverts : 1 GOhm, une vraie haute impédance (la valeur par défaut de la MSL, 1e-5 S, fait 100 kOhm)";
  parameter Modelica.Units.SI.Voltage vThreshold = (0.8 + 2.0)/2 "Seuil logique unique, comme MCU.mo";
  Modelica.Blocks.Interfaces.BooleanInput isOutput "Direction : true = sortie" annotation(
    Placement(transformation(origin = {-200, 90}, extent = {{-10, -10}, {10, 10}}), iconTransformation(extent = {{-140, 60}, {-100, 100}})));
  Modelica.Blocks.Interfaces.BooleanInput level "Niveau logique écrit (on/off, créneau PWM, bit de trame UART)" annotation(
    Placement(transformation(origin = {-200, 24}, extent = {{-10, -10}, {10, 10}}), iconTransformation(extent = {{-140, 20}, {-100, 60}})));
  Modelica.Blocks.Interfaces.BooleanInput openDrain "Pin.OPEN_DRAIN : en sortie, un niveau haut relâche la ligne au lieu de la piloter" annotation(
    Placement(transformation(origin = {-200, 52}, extent = {{-10, -10}, {10, 10}}), iconTransformation(extent = {{-140, -20}, {-100, 20}})));
  Modelica.Blocks.Interfaces.BooleanInput pullUp "Pin.PULL_UP : tirage interne vers VDD" annotation(
    Placement(transformation(origin = {110, -50}, extent = {{10, -10}, {-10, 10}}), iconTransformation(extent = {{-140, -60}, {-100, -20}})));
  Modelica.Blocks.Interfaces.BooleanInput pullDown "Pin.PULL_DOWN : tirage interne vers la masse" annotation(
    Placement(transformation(origin = {160, -50}, extent = {{10, -10}, {-10, 10}}), iconTransformation(extent = {{-140, -100}, {-100, -60}})));
  Modelica.Electrical.Analog.Interfaces.PositivePin pin "La broche GPx" annotation(
    Placement(transformation(origin = {260, 0}, extent = {{-10, -10}, {10, 10}}), iconTransformation(extent = {{90, -10}, {110, 10}})));
  Modelica.Electrical.Analog.Interfaces.NegativePin gnd "Masse commune (MCU.GND)" annotation(
    Placement(transformation(origin = {0, -130}, extent = {{-10, -10}, {10, 10}}), iconTransformation(extent = {{-10, -110}, {10, -90}})));
  Modelica.Blocks.Interfaces.BooleanOutput boolIn "Valeur logique lue : Pin.value(), IRQ" annotation(
    Placement(transformation(origin = {270, -30}, extent = {{-10, -10}, {10, 10}}), iconTransformation(extent = {{100, -50}, {120, -30}})));
  Modelica.Blocks.Interfaces.RealOutput v(unit = "V") "Tension de la broche : ADC.read_u16()" annotation(
    Placement(transformation(origin = {270, -70}, extent = {{-10, -10}, {10, 10}}), iconTransformation(extent = {{100, -90}, {120, -70}})));
  Modelica.Blocks.Logical.And release "Drain ouvert et niveau haut : relâcher la ligne" annotation(
    Placement(transformation(origin = {-150, 52}, extent = {{-10, -10}, {10, 10}})));
  Modelica.Blocks.Logical.Not notRelease annotation(
    Placement(transformation(origin = {-115, 52}, extent = {{-10, -10}, {10, 10}})));
  Modelica.Blocks.Logical.And drive "L'étage de sortie est branché : en sortie, sauf ligne relâchée" annotation(
    Placement(transformation(origin = {-70, 60}, extent = {{-10, -10}, {10, 10}})));
  Modelica.Blocks.Math.BooleanToReal srcLevel(realTrue = VOH, realFalse = VOL) "VOH / VOL" annotation(
    Placement(transformation(origin = {-90, 24}, extent = {{-10, -10}, {10, 10}})));
  Modelica.Electrical.Analog.Sources.SignalVoltage src "Source de l'étage de sortie" annotation(
    Placement(transformation(origin = {-60, 0}, extent = {{10, -10}, {-10, 10}})));
  Modelica.Electrical.Analog.Basic.Resistor rOut(R = ROut) annotation(
    Placement(transformation(origin = {-25, 0}, extent = {{-10, -10}, {10, 10}})));
  Modelica.Electrical.Analog.Ideal.IdealClosingSwitch sw(Goff = GOff) "Étage de sortie branché ou non" annotation(
    Placement(transformation(origin = {10, 0}, extent = {{-10, -10}, {10, 10}})));
  Modelica.Electrical.Analog.Basic.Resistor rPullUp(R = RPullUp) annotation(
    Placement(transformation(origin = {80, -20}, extent = {{-10, -10}, {10, 10}}, rotation = 270)));
  Modelica.Electrical.Analog.Ideal.IdealClosingSwitch swUp(Goff = GOff) annotation(
    Placement(transformation(origin = {80, -50}, extent = {{-10, -10}, {10, 10}}, rotation = 270)));
  Modelica.Electrical.Analog.Sources.ConstantVoltage vdd(V = VDD) "Alimentation interne" annotation(
    Placement(transformation(origin = {80, -80}, extent = {{-8, -8}, {8, 8}}, rotation = 270)));
  Modelica.Electrical.Analog.Basic.Resistor rPullDown(R = RPullDown) annotation(
    Placement(transformation(origin = {130, -20}, extent = {{-10, -10}, {10, 10}}, rotation = 270)));
  Modelica.Electrical.Analog.Ideal.IdealClosingSwitch swDown(Goff = GOff) annotation(
    Placement(transformation(origin = {130, -50}, extent = {{-10, -10}, {10, 10}}, rotation = 270)));
  Modelica.Electrical.Analog.Sensors.VoltageSensor sns annotation(
    Placement(transformation(origin = {200, -30}, extent = {{10, -10}, {-10, 10}}, rotation = 90)));
  Modelica.Blocks.Logical.GreaterThreshold threshold(threshold = vThreshold) annotation(
    Placement(transformation(origin = {235, -30}, extent = {{-10, -10}, {10, 10}})));
equation
  connect(openDrain, release.u1) annotation(
    Line(points = {{-200, 52}, {-162, 52}}, color = {255, 0, 255}));
  connect(level, release.u2) annotation(
    Line(points = {{-200, 24}, {-170, 24}, {-170, 44}, {-162, 44}}, color = {255, 0, 255}));
  connect(release.y, notRelease.u) annotation(
    Line(points = {{-139, 52}, {-127, 52}}, color = {255, 0, 255}));
  connect(notRelease.y, drive.u2) annotation(
    Line(points = {{-104, 52}, {-82, 52}}, color = {255, 0, 255}));
  connect(isOutput, drive.u1) annotation(
    Line(points = {{-200, 90}, {-90, 90}, {-90, 60}, {-82, 60}}, color = {255, 0, 255}));
  connect(level, srcLevel.u) annotation(
    Line(points = {{-200, 24}, {-102, 24}}, color = {255, 0, 255}));
  connect(srcLevel.y, src.v) annotation(
    Line(points = {{-79, 24}, {-60, 24}, {-60, 12}}, color = {0, 0, 127}));
  connect(drive.y, sw.control) annotation(
    Line(points = {{-59, 60}, {10, 60}, {10, 12}}, color = {255, 0, 255}));
  connect(src.p, rOut.p) annotation(
    Line(points = {{-50, 0}, {-35, 0}}, color = {0, 0, 255}));
  connect(rOut.n, sw.p) annotation(
    Line(points = {{-15, 0}, {0, 0}}, color = {0, 0, 255}));
  connect(sw.n, pin) annotation(
    Line(points = {{20, 0}, {260, 0}}, color = {0, 0, 255}));
  connect(src.n, gnd) annotation(
    Line(points = {{-70, 0}, {-80, 0}, {-80, -110}, {0, -110}, {0, -130}}, color = {0, 0, 255}));
  connect(rPullUp.p, pin) annotation(
    Line(points = {{80, -10}, {80, 0}}, color = {0, 0, 255}));
  connect(rPullUp.n, swUp.p) annotation(
    Line(points = {{80, -30}, {80, -40}}, color = {0, 0, 255}));
  connect(swUp.n, vdd.p) annotation(
    Line(points = {{80, -60}, {80, -72}}, color = {0, 0, 255}));
  connect(vdd.n, gnd) annotation(
    Line(points = {{80, -88}, {80, -110}, {0, -110}, {0, -130}}, color = {0, 0, 255}));
  connect(pullUp, swUp.control) annotation(
    Line(points = {{110, -50}, {92, -50}}, color = {255, 0, 255}));
  connect(rPullDown.p, pin) annotation(
    Line(points = {{130, -10}, {130, 0}}, color = {0, 0, 255}));
  connect(rPullDown.n, swDown.p) annotation(
    Line(points = {{130, -30}, {130, -40}}, color = {0, 0, 255}));
  connect(swDown.n, gnd) annotation(
    Line(points = {{130, -60}, {130, -110}, {0, -110}, {0, -130}}, color = {0, 0, 255}));
  connect(pullDown, swDown.control) annotation(
    Line(points = {{160, -50}, {142, -50}}, color = {255, 0, 255}));
  connect(sns.p, pin) annotation(
    Line(points = {{200, -20}, {200, 0}}, color = {0, 0, 255}));
  connect(sns.n, gnd) annotation(
    Line(points = {{200, -40}, {200, -110}, {0, -110}, {0, -130}}, color = {0, 0, 255}));
  connect(sns.v, threshold.u) annotation(
    Line(points = {{211, -30}, {223, -30}}, color = {0, 0, 127}));
  connect(threshold.y, boolIn) annotation(
    Line(points = {{246, -30}, {270, -30}}, color = {255, 0, 255}));
  connect(sns.v, v) annotation(
    Line(points = {{211, -30}, {214, -30}, {214, -70}, {270, -70}}, color = {0, 0, 127}));
  annotation(
    Icon(coordinateSystem(extent = {{-100, -100}, {100, 100}}), graphics = {Rectangle(lineColor = {0, 0, 127}, fillColor = {255, 255, 255}, fillPattern = FillPattern.Solid, extent = {{-100, 100}, {100, -100}}), Text(extent = {{-20, 30}, {90, -10}}, textString = "GPIO+"), Text(extent = {{-96, 90}, {-30, 70}}, textString = "isOutput", horizontalAlignment = TextAlignment.Left), Text(extent = {{-96, 50}, {-30, 30}}, textString = "level", horizontalAlignment = TextAlignment.Left), Text(extent = {{-96, 10}, {-30, -10}}, textString = "openDrain", horizontalAlignment = TextAlignment.Left), Text(extent = {{-96, -30}, {-30, -50}}, textString = "pullUp", horizontalAlignment = TextAlignment.Left), Text(extent = {{-96, -70}, {-30, -90}}, textString = "pullDown", horizontalAlignment = TextAlignment.Left), Text(extent = {{30, -30}, {96, -50}}, textString = "boolIn", horizontalAlignment = TextAlignment.Right), Text(extent = {{30, -70}, {96, -90}}, textString = "v", horizontalAlignment = TextAlignment.Right), Text(textColor = {0, 0, 255}, extent = {{-150, 140}, {150, 105}}, textString = "%name")}),
    Diagram(coordinateSystem(extent = {{-220, -150}, {280, 110}}), graphics = {Text(extent = {{-180, 104}, {20, 96}}, textString = "Étage de sortie : branché si isOutput et pas (openDrain et level)", horizontalAlignment = TextAlignment.Left), Text(extent = {{56, 36}, {104, 28}}, textString = "PULL_UP"), Text(extent = {{106, 36}, {154, 28}}, textString = "PULL_DOWN"), Text(extent = {{56, -94}, {104, -102}}, textString = "VDD")}),
    Documentation(info = "<html>
<p>Prototype, non utilisé par <code>MCU</code> : le pont de <code>PinBridge</code> complété de ce que l'API <code>machine.Pin</code> du RP2040 offre. Depuis le 2026-10-01, <code>MCU.mo</code> réalise les tirages internes et la fuite de 1 GOhm, avec des conductances commandées plutôt que des interrupteurs (décision « Tirages internes » de <code>requirements.md</code>) ; le drain ouvert reste à faire (TODO).</p>
<ul>
<li><b>Tirages internes</b> : <code>pullUp</code> branche <code>RPullUp</code> vers une alimentation interne <code>VDD</code>, <code>pullDown</code> branche <code>RPullDown</code> vers la masse. Ils agissent quelle que soit la direction, comme sur le RP2040.</li>
<li><b>Drain ouvert</b> : avec <code>openDrain</code>, un niveau bas tire la ligne à <code>VOL</code>, un niveau haut débranche l'étage de sortie (haute impédance). C'est ce que le maître I2C du <code>MCU</code> obtient aujourd'hui en basculant la direction.</li>
<li><b>Vraie haute impédance</b> : fuite des interrupteurs <code>GOff</code> = 1 nS (1 GOhm) au lieu des 100 kOhm de l'ancien <code>MCU</code>, comme le <code>MCU</code> actuel. Une entrée en l'air n'a donc plus de niveau défini ; il faut un tirage, interne ou externe.</li>
<li>L'étage de sortie prend un niveau logique <code>level</code> au lieu d'une tension : dans <code>MCU.mo</code>, la sortie vaut toujours <code>VOH</code> ou <code>VOL</code> (numérique, PWM, UART).</li>
</ul>
<p>Banc d'essai : <code>PinBridgeFullDemo</code>.</p>
</html>"));
end PinBridgeFull;
