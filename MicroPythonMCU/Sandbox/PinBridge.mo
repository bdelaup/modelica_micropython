within MicroPythonMCU.Sandbox;
model PinBridge "Pont électrique d'une broche GPIO du MCU tel qu'il était avant les tirages internes (2026-10-01), refait en blocs standard"
  parameter Modelica.Units.SI.Resistance ROut = 100 "Résistance série de sortie (MCU.ROut)";
  parameter Modelica.Units.SI.Voltage vThreshold = (0.8 + 2.0)/2 "Seuil logique unique, sans hystérésis : (VIL + VIH)/2 dans MCU.mo";
  Modelica.Blocks.Interfaces.BooleanInput isOutput "Direction : true = sortie (pinIsOutputD dans MCU.mo)" annotation(
    Placement(transformation(extent = {{-140, 40}, {-100, 80}})));
  Modelica.Blocks.Interfaces.RealInput vDrive(unit = "V") "Tension demandée en sortie : VOH/VOL, créneau PWM ou niveau de trame UART, choisie par MCU.mo" annotation(
    Placement(transformation(extent = {{-140, 0}, {-100, 40}})));
  Modelica.Electrical.Analog.Interfaces.PositivePin pin "La broche GPx" annotation(
    Placement(transformation(extent = {{90, -20}, {110, 0}})));
  Modelica.Electrical.Analog.Interfaces.NegativePin gnd "Masse commune (MCU.GND)" annotation(
    Placement(transformation(extent = {{-10, -110}, {10, -90}})));
  Modelica.Blocks.Interfaces.BooleanOutput boolIn "Valeur logique lue (pinBoolIn) : Pin.value(), IRQ, réveil du script" annotation(
    Placement(transformation(extent = {{100, -50}, {120, -30}})));
  Modelica.Blocks.Interfaces.RealOutput v(unit = "V") "Tension de la broche (pinNodeVoltage) : ADC.read_u16() = round(v/3.3*65535)" annotation(
    Placement(transformation(extent = {{100, -90}, {120, -70}})));
  Modelica.Blocks.Math.BooleanToReal enable "1 en sortie, 0 en entrée" annotation(
    Placement(transformation(origin = {-80, 60}, extent = {{-10, -10}, {10, 10}})));
  Modelica.Blocks.Math.Product gate "Consigne de la source : vDrive en sortie, 0 V en entrée" annotation(
    Placement(transformation(origin = {-50, 40}, extent = {{-10, -10}, {10, 10}})));
  Modelica.Electrical.Analog.Sources.SignalVoltage src "Source pilotée (src[i])" annotation(
    Placement(transformation(origin = {-30, -10}, extent = {{10, -10}, {-10, 10}})));
  Modelica.Electrical.Analog.Basic.Resistor rOut(R = ROut) "Résistance série (rOut[i])" annotation(
    Placement(transformation(origin = {-5, -10}, extent = {{-10, -10}, {10, 10}})));
  Modelica.Electrical.Analog.Ideal.IdealClosingSwitch sw "Fermé en sortie (Ron = 10 µΩ) ; ouvert en entrée, il reste sa fuite Goff = 1e-5 S, soit ≈ 100 kΩ vers la source à 0 V. MCU.mo utilise IdealOpeningSwitch commandé par not isOutput : même circuit" annotation(
    Placement(transformation(origin = {25, -10}, extent = {{-10, -10}, {10, 10}})));
  Modelica.Electrical.Analog.Sensors.VoltageSensor sns "Capteur de tension idéal (sns[i]), quelle que soit la direction" annotation(
    Placement(transformation(origin = {45, -40}, extent = {{10, -10}, {-10, 10}}, rotation = 90)));
  Modelica.Blocks.Logical.GreaterThreshold threshold(threshold = vThreshold) "Lecture logique : un seul seuil, pas d'hystérésis" annotation(
    Placement(transformation(origin = {70, -40}, extent = {{-10, -10}, {10, 10}})));
equation
  connect(isOutput, enable.u) annotation(
    Line(points = {{-120, 60}, {-92, 60}}, color = {255, 0, 255}));
  connect(isOutput, sw.control) annotation(
    Line(points = {{-120, 60}, {-105, 60}, {-105, 80}, {25, 80}, {25, 2}}, color = {255, 0, 255}));
  connect(enable.y, gate.u1) annotation(
    Line(points = {{-69, 60}, {-66, 60}, {-66, 46}, {-62, 46}}, color = {0, 0, 127}));
  connect(vDrive, gate.u2) annotation(
    Line(points = {{-120, 20}, {-70, 20}, {-70, 34}, {-62, 34}}, color = {0, 0, 127}));
  connect(gate.y, src.v) annotation(
    Line(points = {{-39, 40}, {-30, 40}, {-30, 2}}, color = {0, 0, 127}));
  connect(src.p, rOut.p) annotation(
    Line(points = {{-20, -10}, {-15, -10}}, color = {0, 0, 255}));
  connect(rOut.n, sw.p) annotation(
    Line(points = {{5, -10}, {15, -10}}, color = {0, 0, 255}));
  connect(sw.n, pin) annotation(
    Line(points = {{35, -10}, {100, -10}}, color = {0, 0, 255}));
  connect(sns.p, pin) annotation(
    Line(points = {{45, -30}, {45, -10}, {100, -10}}, color = {0, 0, 255}));
  connect(src.n, gnd) annotation(
    Line(points = {{-40, -10}, {-50, -10}, {-50, -70}, {0, -70}, {0, -100}}, color = {0, 0, 255}));
  connect(sns.n, gnd) annotation(
    Line(points = {{45, -50}, {45, -70}, {0, -70}, {0, -100}}, color = {0, 0, 255}));
  connect(sns.v, threshold.u) annotation(
    Line(points = {{56, -40}, {58, -40}}, color = {0, 0, 127}));
  connect(threshold.y, boolIn) annotation(
    Line(points = {{81, -40}, {110, -40}}, color = {255, 0, 255}));
  connect(sns.v, v) annotation(
    Line(points = {{56, -40}, {57, -40}, {57, -80}, {110, -80}}, color = {0, 0, 127}));
  annotation(
    Icon(coordinateSystem(extent = {{-100, -100}, {100, 100}}), graphics = {Rectangle(lineColor = {0, 0, 127}, fillColor = {255, 255, 255}, fillPattern = FillPattern.Solid, extent = {{-100, 100}, {100, -100}}), Text(extent = {{-90, 40}, {90, -20}}, textString = "GPIO"), Text(extent = {{-96, 70}, {-30, 50}}, textString = "isOutput", horizontalAlignment = TextAlignment.Left), Text(extent = {{-96, 30}, {-30, 10}}, textString = "vDrive", horizontalAlignment = TextAlignment.Left), Text(extent = {{30, -30}, {96, -50}}, textString = "boolIn", horizontalAlignment = TextAlignment.Right), Text(extent = {{30, -70}, {96, -90}}, textString = "v", horizontalAlignment = TextAlignment.Right), Text(textColor = {0, 0, 255}, extent = {{-150, 140}, {150, 105}}, textString = "%name")}),
    Diagram(coordinateSystem(extent = {{-140, -100}, {120, 100}}), graphics = {Text(extent = {{-100, -82}, {-40, -92}}, textString = "en entrée : src = 0 V, sw ouvert = 100 kΩ", fontSize = 6, horizontalAlignment = TextAlignment.Left)}),
    Documentation(info = "<html>
<p>Le pont électrique d'une broche du <code>MCU</code>, extrait de la boucle <code>for i in 1:9</code> de <code>MCU.mo</code> et redessiné avec des blocs standard, pour le voir et l'essayer seul. Non utilisé par <code>MCU</code>. C'est l'état d'<b>avant le 2026-10-01</b> : depuis, <code>MCU.mo</code> a des tirages internes et une fuite de 1 GOhm (voir <code>PinBridgeFull</code> et la décision « Tirages internes » de <code>requirements.md</code>).</p>
<ul>
<li>En sortie (<code>isOutput = true</code>) : source <code>vDrive</code> derrière <code>ROut</code>.</li>
<li>En entrée : la source tombe à 0 V et l'interrupteur s'ouvre ; reste sa fuite <code>Goff</code> = 1e-5 S, soit ≈ 100 kΩ vers la masse.</li>
<li>Lecture : <code>v</code> (ADC) brute, <code>boolIn</code> = <code>v &gt; vThreshold</code>, sans hystérésis.</li>
</ul>
<p>Le choix de <code>vDrive</code> (VOH/VOL, PWM, trame UART) reste dans <code>MCU.mo</code> ; le maître I2C fait du drain ouvert en basculant <code>isOutput</code> avec <code>vDrive</code> = 0. Banc d'essai : <code>PinBridgeDemo</code>.</p>
</html>"));
end PinBridge;
