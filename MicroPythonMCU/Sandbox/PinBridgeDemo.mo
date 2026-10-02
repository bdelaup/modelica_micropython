within MicroPythonMCU.Sandbox;
model PinBridgeDemo "Quatre broches PinBridge, une par mode : sortie, entrée avec bouton, drain ouvert (I2C), entrée analogique"
  // A - sortie push-pull sur une charge de 330 Ohm
  PinBridge pinA annotation(
    Placement(transformation(origin = {0, 120}, extent = {{-20, -20}, {20, 20}})));
  Modelica.Blocks.Sources.BooleanConstant isOutA(k = true) annotation(
    Placement(transformation(origin = {-40, 142}, extent = {{-6, -6}, {6, 6}})));
  Modelica.Blocks.Sources.BooleanPulse levelA(width = 50, period = 0.2) "Ce que le script écrirait : on()/off()" annotation(
    Placement(transformation(origin = {-80, 124}, extent = {{-6, -6}, {6, 6}})));
  Modelica.Blocks.Math.BooleanToReal vohA(realTrue = 3.3, realFalse = 0) "VOH / VOL" annotation(
    Placement(transformation(origin = {-50, 124}, extent = {{-6, -6}, {6, 6}})));
  Modelica.Electrical.Analog.Basic.Resistor rLoadA(R = 330) annotation(
    Placement(transformation(origin = {50, 106}, extent = {{-10, -10}, {10, 10}}, rotation = 270)));
  Modelica.Electrical.Analog.Basic.Ground groundA annotation(
    Placement(transformation(origin = {0, 90}, extent = {{-6, -6}, {6, 6}})));
  // B - entrée, tirage de 10 kOhm vers 3,3 V et bouton vers la masse
  PinBridge pinB annotation(
    Placement(transformation(origin = {0, 40}, extent = {{-20, -20}, {20, 20}})));
  Modelica.Blocks.Sources.BooleanConstant isOutB(k = false) annotation(
    Placement(transformation(origin = {-40, 62}, extent = {{-6, -6}, {6, 6}})));
  Modelica.Blocks.Sources.Constant vB(k = 0) annotation(
    Placement(transformation(origin = {-50, 44}, extent = {{-6, -6}, {6, 6}})));
  Modelica.Electrical.Analog.Basic.Resistor rPullB(R = 10e3) annotation(
    Placement(transformation(origin = {50, 52}, extent = {{-8, -8}, {8, 8}}, rotation = 270)));
  Modelica.Electrical.Analog.Ideal.IdealClosingSwitch buttonB(Goff = 1e-12) "Bouton poussoir (fuite à l'état ouvert rendue négligeable : par défaut 1e-5 S, elle ferait un second 100 kΩ en parallèle)" annotation(
    Placement(transformation(origin = {50, 26}, extent = {{-10, -10}, {10, 10}}, rotation = 270)));
  Modelica.Blocks.Sources.BooleanPulse pressB(width = 25, period = 0.4, startTime = 0.1) "Appuis sur le bouton" annotation(
    Placement(transformation(origin = {85, 26}, extent = {{6, -6}, {-6, 6}})));
  Modelica.Electrical.Analog.Sources.ConstantVoltage vccB(V = 3.3) annotation(
    Placement(transformation(origin = {110, 45}, extent = {{-8, -8}, {8, 8}}, rotation = 270)));
  Modelica.Electrical.Analog.Basic.Ground groundB annotation(
    Placement(transformation(origin = {0, 10}, extent = {{-6, -6}, {6, 6}})));
  // C - drain ouvert (comme SDA/SCL du maître I2C) : tirage de 4,7 kOhm, la broche tire à 0 ou se relâche
  PinBridge pinC annotation(
    Placement(transformation(origin = {0, -40}, extent = {{-20, -20}, {20, 20}})));
  Modelica.Blocks.Sources.BooleanPulse pullLowC(width = 40, period = 0.25, startTime = 0.05) "true = tirer la ligne à la masse, false = relâcher" annotation(
    Placement(transformation(origin = {-40, -18}, extent = {{-6, -6}, {6, 6}})));
  Modelica.Blocks.Sources.Constant vC(k = 0) "Drain ouvert : la sortie n'écrit jamais que 0" annotation(
    Placement(transformation(origin = {-50, -36}, extent = {{-6, -6}, {6, 6}})));
  Modelica.Electrical.Analog.Basic.Resistor rPullC(R = 4.7e3) annotation(
    Placement(transformation(origin = {50, -28}, extent = {{-8, -8}, {8, 8}}, rotation = 270)));
  Modelica.Electrical.Analog.Sources.ConstantVoltage vccC(V = 3.3) annotation(
    Placement(transformation(origin = {110, -35}, extent = {{-8, -8}, {8, 8}}, rotation = 270)));
  Modelica.Electrical.Analog.Basic.Ground groundC annotation(
    Placement(transformation(origin = {0, -70}, extent = {{-6, -6}, {6, 6}})));
  // D - entrée analogique : sinusoïde 0-3 V à travers 1 kOhm
  PinBridge pinD annotation(
    Placement(transformation(origin = {0, -120}, extent = {{-20, -20}, {20, 20}})));
  Modelica.Blocks.Sources.BooleanConstant isOutD(k = false) annotation(
    Placement(transformation(origin = {-40, -98}, extent = {{-6, -6}, {6, 6}})));
  Modelica.Blocks.Sources.Constant vD(k = 0) annotation(
    Placement(transformation(origin = {-50, -116}, extent = {{-6, -6}, {6, 6}})));
  Modelica.Electrical.Analog.Basic.Resistor rSerD(R = 1e3) annotation(
    Placement(transformation(origin = {60, -122}, extent = {{-8, -8}, {8, 8}})));
  Modelica.Electrical.Analog.Sources.SineVoltage sineD(V = 1.5, f = 2, offset = 1.5) annotation(
    Placement(transformation(origin = {90, -132}, extent = {{-8, -8}, {8, 8}}, rotation = 270)));
  Modelica.Electrical.Analog.Basic.Ground groundD annotation(
    Placement(transformation(origin = {0, -150}, extent = {{-6, -6}, {6, 6}})));
equation
  // A
  connect(isOutA.y, pinA.isOutput) annotation(
    Line(points = {{-33.4, 142}, {-30, 142}, {-30, 132}, {-24, 132}}, color = {255, 0, 255}));
  connect(levelA.y, vohA.u) annotation(
    Line(points = {{-73.4, 124}, {-57.2, 124}}, color = {255, 0, 255}));
  connect(vohA.y, pinA.vDrive) annotation(
    Line(points = {{-43.4, 124}, {-24, 124}}, color = {0, 0, 127}));
  connect(pinA.pin, rLoadA.p) annotation(
    Line(points = {{20, 118}, {50, 118}, {50, 116}}, color = {0, 0, 255}));
  connect(rLoadA.n, groundA.p) annotation(
    Line(points = {{50, 96}, {0, 96}}, color = {0, 0, 255}));
  connect(pinA.gnd, groundA.p) annotation(
    Line(points = {{0, 100}, {0, 96}}, color = {0, 0, 255}));
  // B
  connect(isOutB.y, pinB.isOutput) annotation(
    Line(points = {{-33.4, 62}, {-30, 62}, {-30, 52}, {-24, 52}}, color = {255, 0, 255}));
  connect(vB.y, pinB.vDrive) annotation(
    Line(points = {{-43.4, 44}, {-24, 44}}, color = {0, 0, 127}));
  connect(rPullB.n, pinB.pin) annotation(
    Line(points = {{50, 44}, {50, 38}, {20, 38}}, color = {0, 0, 255}));
  connect(buttonB.p, pinB.pin) annotation(
    Line(points = {{50, 36}, {50, 38}, {20, 38}}, color = {0, 0, 255}));
  connect(pressB.y, buttonB.control) annotation(
    Line(points = {{78.4, 26}, {62, 26}}, color = {255, 0, 255}));
  connect(vccB.p, rPullB.p) annotation(
    Line(points = {{110, 53}, {110, 60}, {50, 60}}, color = {0, 0, 255}));
  connect(vccB.n, groundB.p) annotation(
    Line(points = {{110, 37}, {110, 16}, {0, 16}}, color = {0, 0, 255}));
  connect(buttonB.n, groundB.p) annotation(
    Line(points = {{50, 16}, {0, 16}}, color = {0, 0, 255}));
  connect(pinB.gnd, groundB.p) annotation(
    Line(points = {{0, 20}, {0, 16}}, color = {0, 0, 255}));
  // C
  connect(pullLowC.y, pinC.isOutput) annotation(
    Line(points = {{-33.4, -18}, {-30, -18}, {-30, -28}, {-24, -28}}, color = {255, 0, 255}));
  connect(vC.y, pinC.vDrive) annotation(
    Line(points = {{-43.4, -36}, {-24, -36}}, color = {0, 0, 127}));
  connect(rPullC.n, pinC.pin) annotation(
    Line(points = {{50, -36}, {50, -42}, {20, -42}}, color = {0, 0, 255}));
  connect(vccC.p, rPullC.p) annotation(
    Line(points = {{110, -27}, {110, -20}, {50, -20}}, color = {0, 0, 255}));
  connect(vccC.n, groundC.p) annotation(
    Line(points = {{110, -43}, {110, -64}, {0, -64}}, color = {0, 0, 255}));
  connect(pinC.gnd, groundC.p) annotation(
    Line(points = {{0, -60}, {0, -64}}, color = {0, 0, 255}));
  // D
  connect(isOutD.y, pinD.isOutput) annotation(
    Line(points = {{-33.4, -98}, {-30, -98}, {-30, -108}, {-24, -108}}, color = {255, 0, 255}));
  connect(vD.y, pinD.vDrive) annotation(
    Line(points = {{-43.4, -116}, {-24, -116}}, color = {0, 0, 127}));
  connect(pinD.pin, rSerD.p) annotation(
    Line(points = {{20, -122}, {52, -122}}, color = {0, 0, 255}));
  connect(rSerD.n, sineD.p) annotation(
    Line(points = {{68, -122}, {90, -122}, {90, -124}}, color = {0, 0, 255}));
  connect(sineD.n, groundD.p) annotation(
    Line(points = {{90, -140}, {90, -144}, {0, -144}}, color = {0, 0, 255}));
  connect(pinD.gnd, groundD.p) annotation(
    Line(points = {{0, -140}, {0, -144}}, color = {0, 0, 255}));
  annotation(
    Diagram(coordinateSystem(extent = {{-140, -165}, {140, 165}}), graphics = {Text(extent = {{-136, 158}, {136, 152}}, textString = "A - sortie sur charge 330 Ω : niveau haut 3,3·330/430 ≈ 2,53 V (chute dans ROut)", horizontalAlignment = TextAlignment.Left), Text(extent = {{-136, 78}, {136, 72}}, textString = "B - entrée, tirage 10 kΩ + bouton : relâché 3,3·100k/110k ≈ 3,0 V, appuyé ≈ 0 V", horizontalAlignment = TextAlignment.Left), Text(extent = {{-136, -2}, {136, -8}}, textString = "C - drain ouvert (I2C), tirage 4,7 kΩ : relâché ≈ 3,15 V, tiré bas ≈ 0,07 V", horizontalAlignment = TextAlignment.Left), Text(extent = {{-136, -82}, {136, -88}}, textString = "D - entrée analogique : v ≈ 0,99·sinus, boolIn bascule à 1,4 V pile", horizontalAlignment = TextAlignment.Left)}),
    experiment(StartTime = 0, StopTime = 1, Tolerance = 1e-6, Interval = 0.001),
    Documentation(info = "<html>
<p>Banc d'essai de <code>PinBridge</code> : une broche par mode. Courbes à tracer : <code>pinX.v</code> et <code>pinX.boolIn</code>, avec <code>pinX.isOutput</code>. Une broche en entrée laissée en l'air lirait 0 V (fuite de 100 kΩ vers la masse).</p>
</html>"));
end PinBridgeDemo;
