within MicroPythonMCU.Sandbox;
model PinBridgeFullDemo "Banc d'essai de PinBridgeFull : tirages internes, drain ouvert, entrée en l'air"
  // 1 - entrée + PULL_UP interne, bouton vers la masse, sans résistance externe
  PinBridgeFull pin1 annotation(
    Placement(transformation(origin = {0, 120}, extent = {{-20, -20}, {20, 20}})));
  Modelica.Electrical.Analog.Basic.Ground ground1 annotation(
    Placement(transformation(origin = {0, 90}, extent = {{-6, -6}, {6, 6}})));
  Modelica.Blocks.Sources.BooleanConstant isOut1(k = false) annotation(
    Placement(transformation(origin = {-40, 136}, extent = {{-4, -4}, {4, 4}})));
  Modelica.Blocks.Sources.BooleanConstant level1(k = false) annotation(
    Placement(transformation(origin = {-60, 128}, extent = {{-4, -4}, {4, 4}})));
  Modelica.Blocks.Sources.BooleanConstant openDrain1(k = false) annotation(
    Placement(transformation(origin = {-40, 120}, extent = {{-4, -4}, {4, 4}})));
  Modelica.Blocks.Sources.BooleanConstant pullUp1(k = true) annotation(
    Placement(transformation(origin = {-60, 112}, extent = {{-4, -4}, {4, 4}})));
  Modelica.Blocks.Sources.BooleanConstant pullDown1(k = false) annotation(
    Placement(transformation(origin = {-40, 104}, extent = {{-4, -4}, {4, 4}})));
  Modelica.Electrical.Analog.Ideal.IdealClosingSwitch button1(Goff = 1e-12) "Bouton vers la masse" annotation(
    Placement(transformation(origin = {50, 108}, extent = {{-10, -10}, {10, 10}}, rotation = 270)));
  Modelica.Blocks.Sources.BooleanPulse press1(width = 25, period = 0.4, startTime = 0.1) "Appuis" annotation(
    Placement(transformation(origin = {85, 108}, extent = {{6, -6}, {-6, 6}})));
  // 2 - entrée + PULL_DOWN interne, bouton vers 3,3 V
  PinBridgeFull pin2 annotation(
    Placement(transformation(origin = {0, 40}, extent = {{-20, -20}, {20, 20}})));
  Modelica.Electrical.Analog.Basic.Ground ground2 annotation(
    Placement(transformation(origin = {0, 10}, extent = {{-6, -6}, {6, 6}})));
  Modelica.Blocks.Sources.BooleanConstant isOut2(k = false) annotation(
    Placement(transformation(origin = {-40, 56}, extent = {{-4, -4}, {4, 4}})));
  Modelica.Blocks.Sources.BooleanConstant level2(k = false) annotation(
    Placement(transformation(origin = {-60, 48}, extent = {{-4, -4}, {4, 4}})));
  Modelica.Blocks.Sources.BooleanConstant openDrain2(k = false) annotation(
    Placement(transformation(origin = {-40, 40}, extent = {{-4, -4}, {4, 4}})));
  Modelica.Blocks.Sources.BooleanConstant pullUp2(k = false) annotation(
    Placement(transformation(origin = {-60, 32}, extent = {{-4, -4}, {4, 4}})));
  Modelica.Blocks.Sources.BooleanConstant pullDown2(k = true) annotation(
    Placement(transformation(origin = {-40, 24}, extent = {{-4, -4}, {4, 4}})));
  Modelica.Electrical.Analog.Ideal.IdealClosingSwitch button2(Goff = 1e-12) "Bouton vers 3,3 V" annotation(
    Placement(transformation(origin = {50, 52}, extent = {{-10, -10}, {10, 10}}, rotation = 270)));
  Modelica.Blocks.Sources.BooleanPulse press2(width = 25, period = 0.4, startTime = 0.1) "Appuis" annotation(
    Placement(transformation(origin = {85, 52}, extent = {{6, -6}, {-6, 6}})));
  Modelica.Electrical.Analog.Sources.ConstantVoltage vcc2(V = 3.3) annotation(
    Placement(transformation(origin = {110, 40}, extent = {{-8, -8}, {8, 8}}, rotation = 270)));
  // 3 - OPEN_DRAIN, tirage externe 4,7 kΩ
  PinBridgeFull pin3 annotation(
    Placement(transformation(origin = {0, -40}, extent = {{-20, -20}, {20, 20}})));
  Modelica.Electrical.Analog.Basic.Ground ground3 annotation(
    Placement(transformation(origin = {0, -70}, extent = {{-6, -6}, {6, 6}})));
  Modelica.Blocks.Sources.BooleanConstant isOut3(k = true) annotation(
    Placement(transformation(origin = {-40, -24}, extent = {{-4, -4}, {4, 4}})));
  Modelica.Blocks.Sources.BooleanPulse level3(width = 40, period = 0.25, startTime = 0.05) "Niveau écrit : 1 = relâcher, 0 = tirer à la masse" annotation(
    Placement(transformation(origin = {-60, -32}, extent = {{-4, -4}, {4, 4}})));
  Modelica.Blocks.Sources.BooleanConstant openDrain3(k = true) annotation(
    Placement(transformation(origin = {-40, -40}, extent = {{-4, -4}, {4, 4}})));
  Modelica.Blocks.Sources.BooleanConstant pullUp3(k = false) annotation(
    Placement(transformation(origin = {-60, -48}, extent = {{-4, -4}, {4, 4}})));
  Modelica.Blocks.Sources.BooleanConstant pullDown3(k = false) annotation(
    Placement(transformation(origin = {-40, -56}, extent = {{-4, -4}, {4, 4}})));
  Modelica.Electrical.Analog.Basic.Resistor rPull3(R = 4.7e3) "Tirage externe du bus" annotation(
    Placement(transformation(origin = {50, -28}, extent = {{-8, -8}, {8, 8}}, rotation = 270)));
  Modelica.Electrical.Analog.Sources.ConstantVoltage vcc3(V = 3.3) annotation(
    Placement(transformation(origin = {110, -35}, extent = {{-8, -8}, {8, 8}}, rotation = 270)));
  // 4 - entrée en l'air (vraie haute impédance)
  PinBridgeFull pin4 annotation(
    Placement(transformation(origin = {0, -120}, extent = {{-20, -20}, {20, 20}})));
  Modelica.Electrical.Analog.Basic.Ground ground4 annotation(
    Placement(transformation(origin = {0, -150}, extent = {{-6, -6}, {6, 6}})));
  Modelica.Blocks.Sources.BooleanConstant isOut4(k = false) annotation(
    Placement(transformation(origin = {-40, -104}, extent = {{-4, -4}, {4, 4}})));
  Modelica.Blocks.Sources.BooleanConstant level4(k = false) annotation(
    Placement(transformation(origin = {-60, -112}, extent = {{-4, -4}, {4, 4}})));
  Modelica.Blocks.Sources.BooleanConstant openDrain4(k = false) annotation(
    Placement(transformation(origin = {-40, -120}, extent = {{-4, -4}, {4, 4}})));
  Modelica.Blocks.Sources.BooleanStep pullUp4(startTime = 0.5) "Pin.PULL_UP activé à t = 0,5 s" annotation(
    Placement(transformation(origin = {-60, -128}, extent = {{-4, -4}, {4, 4}})));
  Modelica.Blocks.Sources.BooleanConstant pullDown4(k = false) annotation(
    Placement(transformation(origin = {-40, -136}, extent = {{-4, -4}, {4, 4}})));
equation
  connect(pin1.gnd, ground1.p) annotation(
    Line(points = {{0, 100}, {0, 96}}, color = {0, 0, 255}));
  connect(isOut1.y, pin1.isOutput) annotation(
    Line(points = {{-35.6, 136}, {-24, 136}}, color = {255, 0, 255}));
  connect(level1.y, pin1.level) annotation(
    Line(points = {{-55.6, 128}, {-24, 128}}, color = {255, 0, 255}));
  connect(openDrain1.y, pin1.openDrain) annotation(
    Line(points = {{-35.6, 120}, {-24, 120}}, color = {255, 0, 255}));
  connect(pullUp1.y, pin1.pullUp) annotation(
    Line(points = {{-55.6, 112}, {-24, 112}}, color = {255, 0, 255}));
  connect(pullDown1.y, pin1.pullDown) annotation(
    Line(points = {{-35.6, 104}, {-24, 104}}, color = {255, 0, 255}));
  connect(pin1.pin, button1.p) annotation(
    Line(points = {{20, 120}, {50, 120}, {50, 118}}, color = {0, 0, 255}));
  connect(button1.n, ground1.p) annotation(
    Line(points = {{50, 98}, {50, 96}, {0, 96}}, color = {0, 0, 255}));
  connect(press1.y, button1.control) annotation(
    Line(points = {{78.4, 108}, {62, 108}}, color = {255, 0, 255}));
  connect(pin2.gnd, ground2.p) annotation(
    Line(points = {{0, 20}, {0, 16}}, color = {0, 0, 255}));
  connect(isOut2.y, pin2.isOutput) annotation(
    Line(points = {{-35.6, 56}, {-24, 56}}, color = {255, 0, 255}));
  connect(level2.y, pin2.level) annotation(
    Line(points = {{-55.6, 48}, {-24, 48}}, color = {255, 0, 255}));
  connect(openDrain2.y, pin2.openDrain) annotation(
    Line(points = {{-35.6, 40}, {-24, 40}}, color = {255, 0, 255}));
  connect(pullUp2.y, pin2.pullUp) annotation(
    Line(points = {{-55.6, 32}, {-24, 32}}, color = {255, 0, 255}));
  connect(pullDown2.y, pin2.pullDown) annotation(
    Line(points = {{-35.6, 24}, {-24, 24}}, color = {255, 0, 255}));
  connect(button2.n, pin2.pin) annotation(
    Line(points = {{50, 42}, {50, 40}, {20, 40}}, color = {0, 0, 255}));
  connect(button2.p, vcc2.p) annotation(
    Line(points = {{50, 62}, {110, 62}, {110, 48}}, color = {0, 0, 255}));
  connect(vcc2.n, ground2.p) annotation(
    Line(points = {{110, 32}, {110, 16}, {0, 16}}, color = {0, 0, 255}));
  connect(press2.y, button2.control) annotation(
    Line(points = {{78.4, 52}, {62, 52}}, color = {255, 0, 255}));
  connect(pin3.gnd, ground3.p) annotation(
    Line(points = {{0, -60}, {0, -64}}, color = {0, 0, 255}));
  connect(isOut3.y, pin3.isOutput) annotation(
    Line(points = {{-35.6, -24}, {-24, -24}}, color = {255, 0, 255}));
  connect(level3.y, pin3.level) annotation(
    Line(points = {{-55.6, -32}, {-24, -32}}, color = {255, 0, 255}));
  connect(openDrain3.y, pin3.openDrain) annotation(
    Line(points = {{-35.6, -40}, {-24, -40}}, color = {255, 0, 255}));
  connect(pullUp3.y, pin3.pullUp) annotation(
    Line(points = {{-55.6, -48}, {-24, -48}}, color = {255, 0, 255}));
  connect(pullDown3.y, pin3.pullDown) annotation(
    Line(points = {{-35.6, -56}, {-24, -56}}, color = {255, 0, 255}));
  connect(rPull3.n, pin3.pin) annotation(
    Line(points = {{50, -36}, {50, -40}, {20, -40}}, color = {0, 0, 255}));
  connect(vcc3.p, rPull3.p) annotation(
    Line(points = {{110, -27}, {110, -20}, {50, -20}}, color = {0, 0, 255}));
  connect(vcc3.n, ground3.p) annotation(
    Line(points = {{110, -43}, {110, -64}, {0, -64}}, color = {0, 0, 255}));
  connect(pin4.gnd, ground4.p) annotation(
    Line(points = {{0, -140}, {0, -144}}, color = {0, 0, 255}));
  connect(isOut4.y, pin4.isOutput) annotation(
    Line(points = {{-35.6, -104}, {-24, -104}}, color = {255, 0, 255}));
  connect(level4.y, pin4.level) annotation(
    Line(points = {{-55.6, -112}, {-24, -112}}, color = {255, 0, 255}));
  connect(openDrain4.y, pin4.openDrain) annotation(
    Line(points = {{-35.6, -120}, {-24, -120}}, color = {255, 0, 255}));
  connect(pullUp4.y, pin4.pullUp) annotation(
    Line(points = {{-55.6, -128}, {-24, -128}}, color = {255, 0, 255}));
  connect(pullDown4.y, pin4.pullDown) annotation(
    Line(points = {{-35.6, -136}, {-24, -136}}, color = {255, 0, 255}));
  annotation(
    Diagram(coordinateSystem(extent = {{-140, -165}, {140, 165}}), graphics = {Text(extent = {{-136, 158}, {136, 152}}, textString = "1 - entrée + PULL_UP interne, bouton vers la masse, sans résistance externe : relâché 3,3 V, appuyé 0 V", horizontalAlignment = TextAlignment.Left), Text(extent = {{-136, 78}, {136, 72}}, textString = "2 - entrée + PULL_DOWN interne, bouton vers 3,3 V : relâché 0 V, appuyé 3,3 V", horizontalAlignment = TextAlignment.Left), Text(extent = {{-136, -2}, {136, -8}}, textString = "3 - OPEN_DRAIN, tirage externe 4,7 kΩ : level = 1 relâche (3,3 V), level = 0 tire (≈ 0,07 V)", horizontalAlignment = TextAlignment.Left), Text(extent = {{-136, -82}, {136, -88}}, textString = "4 - entrée en l'air (vraie haute impédance) : niveau indéfini, puis PULL_UP activé à t = 0,5 s", horizontalAlignment = TextAlignment.Left)}),
    experiment(StartTime = 0, StopTime = 1, Tolerance = 1e-6, Interval = 0.001),
    Documentation(info = "<html>
<p>Banc d'essai de <code>PinBridgeFull</code>. Courbes à tracer : <code>pinK.v</code> et <code>pinK.boolIn</code>. Aucune des rangées 1, 2 et 4 n'a de résistance externe : les tirages sont ceux de la broche.</p>
</html>"));
end PinBridgeFullDemo;
