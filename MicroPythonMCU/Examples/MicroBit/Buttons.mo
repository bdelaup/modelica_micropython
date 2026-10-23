within MicroPythonMCU.Examples.MicroBit;

model Buttons "Button A counts its presses (scrolled on the display), button B resets the counter - the presses are driven from the diagram (BooleanPulse)"
  extends Modelica.Icons.Example;
  MicroPythonMCU.MicroBit_v2 mb(scriptPath = Modelica.Utilities.Files.loadResource("modelica://MicroPythonMCU/Resources/Scripts/MCU/microbit_buttons.py")) "Program: Resources/Scripts/MCU/microbit_buttons.py" annotation(
    Placement(transformation(origin = {0, 0}, extent = {{-60, -60}, {60, 60}})));
  Modelica.Electrical.Analog.Basic.Ground ground annotation(
    Placement(transformation(origin = {39.13, -85}, extent = {{-10, -10}, {10, 10}})));
  Modelica.Blocks.Sources.BooleanPulse pressA(width = 10, period = 1, startTime = 1.5) "Button A pressed during 100 ms, every second" annotation(
    Placement(transformation(origin = {-100, 0}, extent = {{-10, -10}, {10, 10}})));
  Modelica.Blocks.Sources.BooleanConstant btnB(k = false) "button B idle" annotation(
    Placement(transformation(origin = {100, 0}, extent = {{10, -10}, {-10, 10}}, rotation = -0)));
equation
  connect(mb.GND, ground.p) annotation(
    Line(points = {{39.13, -43.66}, {39.13, -75}}, color = {0, 0, 255}));
  connect(pressA.y, mb.buttonA) annotation(
    Line(points = {{-90, 0}, {-56.53, 0}}, color = {255, 0, 255}));
  connect(btnB.y, mb.buttonB) annotation(
    Line(points = {{89, 0}, {56.53, 0}}, color = {255, 0, 255}));
  annotation(
    Diagram(coordinateSystem(extent = {{-120, 60}, {120, -100}})),
    experiment(StopTime = 5, Interval = 0.001, StartTime = 0, Tolerance = 1e-06),
    Documentation(info = "<html>
<p>Expected result: the script scrolls <code>A=+1 B=0</code> at start, then <code>1</code>, <code>2</code>, <code>3</code>... each time <code>pressA</code> fires (presses at 1.5 s, 2.5 s, 3.5 s, 4.5 s - <code>button_a.was_pressed()</code> never misses one). The pin <code>P5</code> falls to 0 V during each press and returns to 3 V through its 10 kOhm pull-up.</p>
<p>The presses come from the diagram (<code>buttonA</code> input of the board), like a finger on the real board; the program itself runs unchanged on a physical micro:bit.</p>
</html>"));
end Buttons;
