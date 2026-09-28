within MicroPythonMCU.Examples;

model BasicBlink "v0 verification scenario no. 1: the default demo script blinks GP0 (external LED) and the on-board LED at 1 Hz"
  extends Modelica.Icons.Example;
  MCU mcu "default scriptPath = Resources/Scripts/MCU/demo.py" annotation(
    Placement(transformation(origin = {0, 0}, extent = {{-50, -50}, {50, 50}})));
  Modelica.Electrical.Analog.Basic.Ground ground annotation(
    Placement(transformation(origin = {0, -90}, extent = {{-15, -15}, {15, 15}})));
  Modelica.Electrical.Analog.Basic.Resistor r0(R = 330) "limits the current of led0 (GP0)" annotation(
    Placement(transformation(origin = {-90, 25}, extent = {{-15, -15}, {15, 15}})));
  MicroPythonMCU.Peripherals.LED led0 "GP0: blinks together with the on-board LED" annotation(
    Placement(transformation(origin = {-128, 25}, extent = {{-15, 15}, {15, -15}}, rotation = -180)));
equation
  connect(mcu.GND, ground.p) annotation(
    Line(points = {{0, -39}, {0, -75}}, color = {0, 0, 255}));
  connect(mcu.GP0, r0.n) annotation(
    Line(points = {{-31, 25}, {-75, 25}}, color = {0, 0, 255}));
  connect(r0.p, led0.p) annotation(
    Line(points = {{-105, 25}, {-113, 25}}, color = {0, 0, 255}));
  connect(led0.n, ground.p) annotation(
    Line(points = {{-143, 25}, {-149.5, 25}, {-149.5, -75}, {0, -75}}, color = {0, 0, 255}));
  annotation(
    Diagram(coordinateSystem(extent = {{-200, -120}, {80, 80}})),
    experiment(StopTime = 4.5, Interval = 0.001, StartTime = 0, Tolerance = 1e-06),
    Documentation(info = "<html>
<p>Expected result: the plot of <code>mcu.GP0.v</code> shows a periodic 0 V / ≈3 V square wave with a 2 s period (1 s on, 1 s off); the on-board LED (icon of <code>mcu</code>) blinks in phase with <code>led0</code> (the <code>demo.py</code> script drives both together).</p>
</html>"));
end BasicBlink;
