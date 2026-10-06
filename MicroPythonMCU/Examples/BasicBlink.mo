within MicroPythonMCU.Examples;

model BasicBlink "Verification scenario no. 1: the default demo script blinks GP0 (external LED) and the on-board LED at 1 Hz"
  extends Modelica.Icons.Example;
  MCU mcu "default scriptPath = Resources/Scripts/MCU/demo.py" annotation(
    Placement(transformation(origin = {0, 0}, extent = {{-20, -20}, {20, 20}})));
  Modelica.Electrical.Analog.Basic.Ground ground annotation(
    Placement(transformation(origin = {0, -62}, extent = {{-10, -10}, {10, 10}})));
  Modelica.Electrical.Analog.Basic.Resistor r0(R = 330) "limits the current of led0 (GP0)" annotation(
    Placement(transformation(origin = {-62, 18}, extent = {{-10, -10}, {10, 10}})));
  MicroPythonMCU.Peripherals.LED led0 "GP0: blinks together with the on-board LED" annotation(
    Placement(transformation(origin = {-90, 18}, extent = {{-10, 10}, {10, -10}}, rotation = -180)));
equation
  connect(mcu.GND, ground.p) annotation(
    Line(points = {{0, -14}, {0, -52}}, color = {0, 0, 255}));
  connect(mcu.GP0, r0.n) annotation(
    Line(points = {{-12, 10}, {-32, 10}, {-32, 18}, {-52, 18}}, color = {0, 0, 255}));
  connect(r0.p, led0.p) annotation(
    Line(points = {{-72, 18}, {-80, 18}}, color = {0, 0, 255}));
  connect(led0.n, ground.p) annotation(
    Line(points = {{-100, 18}, {-104, 18}, {-104, -48}, {0, -48}, {0, -52}}, color = {0, 0, 255}));
  annotation(
    Diagram(coordinateSystem(extent = {{-140, -84}, {56, 56}})),
    experiment(StopTime = 4.5, Interval = 0.001, StartTime = 0, Tolerance = 1e-06),
    Documentation(info = "<html>
<p>Expected result: the plot of <code>mcu.GP0.v</code> shows a periodic 0 V / ≈3 V square wave with a 2 s period (1 s on, 1 s off); the on-board LED (icon of <code>mcu</code>) blinks in phase with <code>led0</code> (the <code>demo.py</code> script drives both together).</p>
</html>"));
end BasicBlink;
