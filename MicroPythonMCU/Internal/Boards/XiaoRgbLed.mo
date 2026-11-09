within MicroPythonMCU.Internal.Boards;

model XiaoRgbLed "One on-board RGB LED package with three active-low RP2040 channels"
  parameter Modelica.Units.SI.Resistance RSeries = 330 "Series resistance of each LED channel";
  parameter Modelica.Units.SI.Current IMax = 0.005 "Current at full icon brightness for each channel";
  Modelica.Electrical.Analog.Interfaces.PositivePin vcc "Common anode supply" annotation(
    Placement(transformation(origin = {-30, 90}, extent = {{-6, -6}, {6, 6}})));
  Modelica.Electrical.Analog.Interfaces.NegativePin redPin "Active-low red channel, GPIO17" annotation(
    Placement(transformation(origin = {90, 35}, extent = {{-6, -6}, {6, 6}})));
  Modelica.Electrical.Analog.Interfaces.NegativePin greenPin "Active-low green channel, GPIO16" annotation(
    Placement(transformation(origin = {90, 0}, extent = {{-6, -6}, {6, 6}})));
  Modelica.Electrical.Analog.Interfaces.NegativePin bluePin "Active-low blue channel, GPIO25" annotation(
    Placement(transformation(origin = {90, -35}, extent = {{-6, -6}, {6, 6}})));
  Modelica.Electrical.Analog.Basic.Resistor redResistor(R = RSeries) annotation(
    Placement(transformation(origin = {0, 35}, extent = {{-10, -10}, {10, 10}})));
  Modelica.Electrical.Analog.Basic.Resistor greenResistor(R = RSeries) annotation(
    Placement(transformation(origin = {0, 0}, extent = {{-10, -10}, {10, 10}})));
  Modelica.Electrical.Analog.Basic.Resistor blueResistor(R = RSeries) annotation(
    Placement(transformation(origin = {0, -35}, extent = {{-10, -10}, {10, 10}})));
  MicroPythonMCU.Peripherals.LED red(colorOn = {255, 0, 0}, colorOff = {0, 0, 0}, IMax = IMax) annotation(
    Placement(transformation(origin = {50, 35}, extent = {{-10, -10}, {10, 10}})));
  MicroPythonMCU.Peripherals.LED green(colorOn = {0, 255, 0}, colorOff = {0, 0, 0}, IMax = IMax) annotation(
    Placement(transformation(origin = {50, 0}, extent = {{-10, -10}, {10, 10}})));
  MicroPythonMCU.Peripherals.LED blue(colorOn = {0, 0, 255}, colorOff = {0, 0, 0}, IMax = IMax) annotation(
    Placement(transformation(origin = {50, -35}, extent = {{-10, -10}, {10, 10}})));
equation
  connect(vcc, redResistor.p) annotation(
    Line(points = {{-30, 90}, {-45, 90}, {-45, 35}, {-10, 35}}, color = {220, 0, 0}));
  connect(vcc, greenResistor.p) annotation(
    Line(points = {{-30, 90}, {-55, 90}, {-55, 0}, {-10, 0}}, color = {0, 150, 0}));
  connect(vcc, blueResistor.p) annotation(
    Line(points = {{-30, 90}, {-65, 90}, {-65, -35}, {-10, -35}}, color = {0, 0, 220}));
  connect(redResistor.n, red.p) annotation(
    Line(points = {{10, 35}, {40, 35}}, color = {220, 0, 0}));
  connect(red.n, redPin) annotation(
    Line(points = {{60, 35}, {90, 35}}, color = {220, 0, 0}));
  connect(greenResistor.n, green.p) annotation(
    Line(points = {{10, 0}, {40, 0}}, color = {0, 150, 0}));
  connect(green.n, greenPin) annotation(
    Line(points = {{60, 0}, {90, 0}}, color = {0, 150, 0}));
  connect(blueResistor.n, blue.p) annotation(
    Line(points = {{10, -35}, {40, -35}}, color = {0, 0, 220}));
  connect(blue.n, bluePin) annotation(
    Line(points = {{60, -35}, {90, -35}}, color = {0, 0, 220}));
  annotation(
    Icon(coordinateSystem(preserveAspectRatio = true, extent = {{-100, -100}, {100, 100}}), graphics = {
      Ellipse(lineColor = {35, 35, 35}, fillPattern = FillPattern.Solid, extent = {{-70, 70}, {70, -70}},
        fillColor = DynamicSelect({30, 30, 30}, {
          integer(12 + 243*min(1, max(0, red.mean.y)/IMax)),
          integer(12 + 243*min(1, max(0, green.mean.y)/IMax)),
          integer(12 + 243*min(1, max(0, blue.mean.y)/IMax))})),
      Ellipse(lineColor = {255, 255, 255}, fillColor = {230, 230, 230}, fillPattern = FillPattern.Solid,
        extent = {{-42, 42}, {-22, 22}}),
      Text(textColor = {0, 0, 255}, extent = {{-100, -76}, {100, -100}}, textString = "%name")}),
    Diagram(coordinateSystem(preserveAspectRatio = true, extent = {{-100, -100}, {100, 100}})),
    Documentation(info = "<html><p>The XIAO RP2040 has one integrated RGB LED package. Its red, green and blue dies are connected to GPIO17, GPIO16 and GPIO25 respectively and are active low. Each electrical channel has its own series resistor; the icon combines their measured currents into one animated RGB package.</p></html>"));
end XiaoRgbLed;
