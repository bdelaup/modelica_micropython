within MicroPythonMCU.Examples.MicroBit;

model GpioEdge "The edge pins as on the board: P1 drives P0 through a wire loop, the display mirrors the level read on P0"
  extends Modelica.Icons.Example;
  MicroPythonMCU.MicroBit_v2 mb(scriptPath = Modelica.Utilities.Files.loadResource("modelica://MicroPythonMCU/Resources/Scripts/MCU/microbit_gpio.py")) "Program: Resources/Scripts/MCU/microbit_gpio.py" annotation(
    Placement(transformation(origin = {0, 0}, extent = {{-60, -60}, {60, 60}})));
  Modelica.Electrical.Analog.Basic.Ground ground annotation(
    Placement(transformation(origin = {39.13, -85}, extent = {{-10, -10}, {10, 10}})));
  Modelica.Electrical.Analog.Basic.Resistor loopR(R = 100) "Wire loop between P1 (output) and P0 (input)" annotation(
    Placement(transformation(origin = {-27.39, -70}, extent = {{-10, -10}, {10, 10}})));
  Modelica.Blocks.Sources.BooleanConstant btnA(k = false) "button A idle" annotation(
    Placement(transformation(origin = {-100, 0}, extent = {{-10, -10}, {10, 10}})));
  Modelica.Blocks.Sources.BooleanConstant btnB(k = false) "button B idle" annotation(
    Placement(transformation(origin = {100, 0}, extent = {{10, -10}, {-10, 10}}, rotation = -0)));
equation
  connect(mb.GND, ground.p) annotation(
    Line(points = {{39.13, -43.66}, {39.13, -75}}, color = {0, 0, 255}));
  connect(loopR.p, mb.P0) annotation(
    Line(points = {{-37.39, -70}, {-36.52, -70}, {-36.52, -43.66}}, color = {0, 0, 255}));
  connect(loopR.n, mb.P1) annotation(
    Line(points = {{-17.39, -70}, {-18.26, -70}, {-18.26, -43.66}}, color = {0, 0, 255}));
  connect(btnA.y, mb.buttonA) annotation(
    Line(points = {{-90, 0}, {-56.53, 0}}, color = {255, 0, 255}));
  connect(btnB.y, mb.buttonB) annotation(
    Line(points = {{89, 0}, {56.53, 0}}, color = {255, 0, 255}));
  annotation(
    Diagram(coordinateSystem(extent = {{-120, 60}, {120, -100}})),
    experiment(StopTime = 2, Interval = 0.001, StartTime = 0, Tolerance = 1e-06),
    Documentation(info = "<html>
<p>Expected result: <code>P1</code> is driven high by the script (<code>pin1.write_digital(1)</code>), <code>P0</code> reads it back through the wire loop: the plot of <code>mb.P0.v</code> stays at 3 V, and the matrix shows a dot at the bottom centre (level of <code>P0</code> read by <code>pin0.read_digital()</code>).</p>
<p>The edge pins (<code>pin0</code>...<code>pin20</code>) are used exactly as on the physical board - the same program runs unchanged on a real micro:bit.</p>
</html>"));
end GpioEdge;
