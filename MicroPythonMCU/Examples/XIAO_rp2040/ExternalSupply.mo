within MicroPythonMCU.Examples.XIAO_rp2040;

model ExternalSupply "XIAO RP2040 supplied through its 5V pad instead of USB-C"
  extends Modelica.Icons.Example;
  MicroPythonMCU.XIAO_rp2040 xiao(usbConnected = false, scriptPath = Modelica.Utilities.Files.loadResource("modelica://MicroPythonMCU/Resources/Scripts/MCU/xiao_blink.py")) annotation(
    Placement(transformation(origin = {0, 0}, extent = {{-40, -44}, {40, 44}})));
  Modelica.Electrical.Analog.Sources.ConstantVoltage supply(V = 5) "External 5 V source on the XIAO V5 pad" annotation(
    Placement(transformation(origin = {96, 14}, extent = {{-10, -10}, {10, 10}}, rotation = 270)));
  Modelica.Electrical.Analog.Basic.Ground sourceGround annotation(
    Placement(transformation(origin = {96, -30}, extent = {{-10, -10}, {10, 10}})));
  Modelica.Electrical.Analog.Basic.Ground boardGround annotation(
    Placement(transformation(origin = {68, -30}, extent = {{-10, -10}, {10, 10}})));
equation
  connect(supply.p, xiao.V5) annotation(
    Line(points = {{96, 24}, {32, 24}}, color = {0, 0, 255}));
  connect(supply.n, sourceGround.p) annotation(
    Line(points = {{96, 4}, {96, -20}}, color = {0, 0, 255}));
  connect(xiao.GND, boardGround.p) annotation(
    Line(points = {{32, 16}, {68, 16}, {68, -20}}, color = {0, 0, 255}));
  annotation(
    Diagram(coordinateSystem(extent = {{-80, -70}, {180, 80}})),
    experiment(StopTime = 0.6, Interval = 0.001, StartTime = 0, Tolerance = 1e-06),
    Documentation(info = "<html><p>This example disconnects the USB source and applies 5 V externally to <code>V5</code>. Tie the source ground to <code>GND</code>. Do not connect this source while <code>usbConnected</code> is true.</p></html>"));
end ExternalSupply;
