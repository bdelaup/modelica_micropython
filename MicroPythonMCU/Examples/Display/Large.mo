within MicroPythonMCU.Examples.Display;
model Large "Ten messages written to machine.Display(0), received at the same time by a 20x2 Display and by the two large screens Display4x32 and Display8x32, which fill line after line then scroll"
  extends Modelica.Icons.Example;
  MCU mcu(scriptPath = Modelica.Utilities.Files.loadResource("modelica://MicroPythonMCU/Resources/Scripts/MCU/display_large.py")) "scriptPath = Resources/Scripts/MCU/display_large.py" annotation(
    Placement(transformation(origin = {-42, -8}, extent = {{-20, -20}, {20, 20}})));
  Modelica.Electrical.Analog.Basic.Ground ground annotation(
    Placement(transformation(origin = {-42, -62}, extent = {{-10, -10}, {10, 10}})));
  MicroPythonMCU.Peripherals.Display display "20x2: the last two messages" annotation(
    Placement(transformation(origin = {56, 62}, extent = {{-20, -20}, {20, 20}})));
  MicroPythonMCU.Peripherals.Display4x32 screen4(logReceived = false) "4x32: the last four messages" annotation(
    Placement(transformation(origin = {56, 20}, extent = {{-20, -20}, {20, 20}})));
  MicroPythonMCU.Peripherals.Display8x32 screen8(logReceived = false) "8x32: the last eight messages" annotation(
    Placement(transformation(origin = {56, -36}, extent = {{-20, -20}, {20, 20}})));
equation
  connect(mcu.GND, ground.p) annotation(
    Line(points = {{-42, -22}, {-42, -52}}, color = {0, 0, 255}));
  connect(display.displayLink, mcu.Display0) annotation(
    Line(points = {{34, 62}, {-32, 62}, {-32, 6}}, color = {28, 108, 200}));
  connect(screen4.displayLink, mcu.Display0) annotation(
    Line(points = {{34, 20}, {-32, 20}, {-32, 6}}, color = {28, 108, 200}));
  connect(screen8.displayLink, mcu.Display0) annotation(
    Line(points = {{34, -36}, {0, -36}, {0, 10}, {-32, 10}, {-32, 6}}, color = {28, 108, 200}));
  annotation(
    Diagram(coordinateSystem(extent = {{-84, -76}, {92, 98}})),
    experiment(StopTime = 1.2, Interval = 0.001, StartTime = 0, Tolerance = 1e-06),
    Documentation(info = "<html>
<p>The script <code>Resources/Scripts/MCU/display_large.py</code> sends ten numbered messages to <code>machine.Display(0)</code>, one every 100 ms (t = 0.1 s to 1.0 s). The three displays share <code>mcu.Display0</code>:</p>
<ul>
<li><code>display</code> (<code>Peripherals.Display</code>, 20x2) shows the last message on its first line and the previous one on the second;</li>
<li><code>screen4</code> (<code>Peripherals.Display4x32</code>) fills its four lines from top to bottom, then scrolls: at the end, messages 7 to 10;</li>
<li><code>screen8</code> (<code>Peripherals.Display8x32</code>) does the same over eight lines: at the end, messages 3 to 10.</li>
</ul>
<p>Message 5 is longer than 32 characters: it is truncated on the icons, and appears in full in the log (written once, by <code>display</code>: the two large screens have <code>logReceived = false</code>). Replay the result in OMEdit and move the time cursor to watch the screens fill. Verification scenario 40 (<code>verify_40_display_large.mos</code>).</p>
</html>"));
end Large;
