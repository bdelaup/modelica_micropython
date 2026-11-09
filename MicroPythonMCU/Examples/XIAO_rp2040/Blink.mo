within MicroPythonMCU.Examples.XIAO_rp2040;

model Blink "XIAO RP2040 supplied by USB: cycle through the on-board RGB LED and blink an external LED on D6"
  extends Modelica.Icons.Example;
  MicroPythonMCU.XIAO_rp2040 xiao(scriptPath = Modelica.Utilities.Files.loadResource("modelica://MicroPythonMCU/Resources/Scripts/MCU/xiao_blink.py")) annotation(
    Placement(transformation(origin = {0, 0}, extent = {{-40, -44}, {40, 44}})));
  Modelica.Electrical.Analog.Basic.Ground boardGround annotation(
    Placement(transformation(origin = {66, -86}, extent = {{-10, -10}, {10, 10}})));
  Modelica.Electrical.Analog.Basic.Ground ledGround annotation(
    Placement(transformation(origin = {-108, -86}, extent = {{-10, -10}, {10, 10}})));
  Modelica.Electrical.Analog.Basic.Resistor externalLedResistor(R = 330) "Current limiter for the external LED" annotation(
    Placement(transformation(origin = {-58, -24}, extent = {{10, -10}, {-10, 10}}, rotation = -0)));
  MicroPythonMCU.Peripherals.LED externalLed(colorOn = {255, 190, 30}, colorOff = {8, 5, 0}, IMax = 0.0015) "Bright external LED on D6 / GPIO0" annotation(
    Placement(transformation(origin = {-94, -24}, extent = {{10, -10}, {-10, 10}}, rotation = -0)));
equation
  connect(xiao.GND, boardGround.p) annotation(
    Line(points = {{32, 16}, {66, 16}, {66, -76}}, color = {0, 0, 255}));
  connect(externalLedResistor.n, externalLed.p) annotation(
    Line(points = {{-68, -24}, {-84, -24}}, color = {0, 0, 255}));
  connect(externalLed.n, ledGround.p) annotation(
    Line(points = {{-104, -24}, {-104, -25}, {-108, -25}, {-108, -76}}, color = {0, 0, 255}));
  connect(externalLedResistor.p, xiao.D6) annotation(
    Line(points = {{-48, -24}, {-32, -24}}, color = {0, 0, 255}));
  annotation(
    Diagram(coordinateSystem(extent = {{-120, -130}, {100, 100}})),
    experiment(StopTime = 1.5, Interval = 0.001, StartTime = 0, Tolerance = 1e-06),
    Documentation(info = "<html><p>The board is powered by USB-C by default. The script cycles red, green and blue on the single on-board RGB LED package (active-low GPIO17/16/25) and blinks a bright external LED wired to D6 / GPIO0. Plot <code>xiao.vRail</code>, <code>xiao.D6.v</code> and the channels' measured currents at <code>xiao.rgbLed.red.currentSensor.i</code>, <code>xiao.rgbLed.green.currentSensor.i</code> and <code>xiao.rgbLed.blue.currentSensor.i</code>.</p></html>"));
end Blink;
