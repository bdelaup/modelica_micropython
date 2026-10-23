within MicroPythonMCU.Examples.MicroBit;

model Heart "The LED matrix shows a beating heart: Image.HEART and Image.HEART_SMALL alternate every 500 ms"
  extends Modelica.Icons.Example;
  MicroPythonMCU.MicroBit_v2 mb(scriptPath = Modelica.Utilities.Files.loadResource("modelica://MicroPythonMCU/Resources/Scripts/MCU/microbit_heart.py")) "Program: Resources/Scripts/MCU/microbit_heart.py" annotation(
    Placement(transformation(extent = {{-60, -60}, {60, 60}})));
  Modelica.Electrical.Analog.Basic.Ground ground annotation(
    Placement(transformation(origin = {39.13, -85}, extent = {{-10, -10}, {10, 10}})));
  Modelica.Blocks.Sources.BooleanConstant btnA(k = false) "button A idle" annotation(
    Placement(transformation(origin = {-100, 0}, extent = {{-10, -10}, {10, 10}})));
  Modelica.Blocks.Sources.BooleanConstant btnB(k = false) "button B idle" annotation(
    Placement(transformation(origin = {100, 0}, extent = {{10, -10}, {-10, 10}}, rotation = -0)));
equation
  connect(mb.GND, ground.p) annotation(
    Line(points = {{39.13, -43.66}, {39.13, -75}}, color = {0, 0, 255}));
  connect(btnA.y, mb.buttonA) annotation(
    Line(points = {{-90, 0}, {-56.53, 0}}, color = {255, 0, 255}));
  connect(btnB.y, mb.buttonB) annotation(
    Line(points = {{89, 0}, {56.53, 0}}, color = {255, 0, 255}));
  annotation(
    Diagram(coordinateSystem(extent = {{-120, 60}, {120, -100}})),
    experiment(StopTime = 3, Interval = 0.001, StartTime = 0, Tolerance = 1e-06),
    Documentation(info = "<html>
<p>Expected result: the dots of the 5x5 matrix on the icon of <code>mb</code> light up in a heart shape (brighter while <code>Image.HEART</code> is shown than during <code>Image.HEART_SMALL</code>), and the LED currents in the plot (<code>mb.led_x_y.mean.y</code>) show the 60 Hz multiplexed scan of the rows.</p>
<p>The program is written for the official micro:bit MicroPython API (<code>from microbit import *</code>) and runs unchanged on a physical micro:bit.</p>
</html>"));
end Heart;
