within MicroPythonMCU.Examples.XIAO_rp2040;

model Adc "Read 1.65 V on XIAO pad D0 (RP2040 GPIO26, ADC0)"
  extends Modelica.Icons.Example;
  MicroPythonMCU.XIAO_rp2040 xiao(scriptPath = Modelica.Utilities.Files.loadResource("modelica://MicroPythonMCU/Resources/Scripts/MCU/xiao_adc.py")) annotation(
    Placement(transformation(origin = {0, 0}, extent = {{-40, -44}, {40, 44}})));
  Modelica.Electrical.Analog.Basic.Ground ground annotation(
    Placement(transformation(origin = {52, -28}, extent = {{-10, -10}, {10, 10}})));
  Modelica.Electrical.Analog.Basic.Ground inputGround annotation(
    Placement(transformation(origin = {-74, -26}, extent = {{-10, -10}, {10, 10}})));
  Modelica.Electrical.Analog.Sources.ConstantVoltage analogInput(V = 1.65) "Half of the 3.3 V ADC range" annotation(
    Placement(transformation(origin = {-74, 14}, extent = {{-10, -10}, {10, 10}}, rotation = 270)));
equation
  connect(xiao.GND, ground.p) annotation(
    Line(points = {{32, 16}, {52, 16}, {52, -18}}, color = {0, 0, 255}));
  connect(analogInput.p, xiao.D0) annotation(
    Line(points = {{-74, 24}, {-32, 24}}, color = {0, 0, 255}));
  connect(analogInput.n, inputGround.p) annotation(
    Line(points = {{-74, 4}, {-74, -16}}, color = {0, 0, 255}));
  annotation(
    Diagram(coordinateSystem(extent = {{-130, -100}, {100, 80}})),
    experiment(StopTime = 0.6, Interval = 0.001, StartTime = 0, Tolerance = 1e-06),
    Documentation(info = "<html><p>D0 maps to GPIO26 and ADC channel 0. The analog input is 1.65 V; the script should report an ADC reading close to half scale (about 32768 from <code>read_u16()</code>). D1, D2 and D3 similarly map to ADC channels 1, 2 and 3.</p></html>"));
end Adc;
