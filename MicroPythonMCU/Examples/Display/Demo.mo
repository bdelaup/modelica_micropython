within MicroPythonMCU.Examples.Display;
model Demo "The script writes text to machine.Display(0) at two different instants; a Peripherals.Display receives each message (logical connector Display0->displayLink) and shows it in the log (print) and on its icon - proves the educational display link end to end"
  extends Modelica.Icons.Example;
  MCU mcu(scriptPath = Modelica.Utilities.Files.loadResource("modelica://MicroPythonMCU/Resources/Scripts/MCU/display_demo.py")) "scriptPath = Resources/Scripts/MCU/display_demo.py" annotation(
    Placement(transformation(origin = {-40, -10}, extent = {{-50, -50}, {50, 50}})));
  Modelica.Electrical.Analog.Basic.Ground ground annotation(
    Placement(transformation(origin = {-40, -90}, extent = {{-15, -15}, {15, 15}})));
  MicroPythonMCU.Peripherals.Display display "Receives the text through Display0" annotation(
    Placement(transformation(origin = {108, 64}, extent = {{-40, -40}, {40, 40}})));
equation
  connect(mcu.GND, ground.p) annotation(
    Line(points = {{-40, -49}, {-40, -75}}, color = {0, 0, 255}));
  connect(display.displayLink, mcu.Display0) annotation(
    Line(points = {{64, 64}, {-16, 64}, {-16, 28}}, color = {28, 108, 200}));
  annotation(
    Diagram(coordinateSystem(extent = {{-120, -120}, {160, 100}})),
    experiment(StopTime = 3, Interval = 0.005, StartTime = 0, Tolerance = 1e-06),
    Documentation(info = "<html>
<p>Verification scenario 12 (see <code>requirements.md</code>): the script <code>Resources/Scripts/MCU/display_demo.py</code> calls <code>machine.Display(0).write(...)</code> twice (separated by a <code>sleep(1)</code>), around t≈1 s and t≈2 s. The <code>Peripherals.Display</code> receives each message through its <code>displayLink</code> connector (connected to <code>mcu.Display0</code>, a causal logical connector - not electrical, see <code>requirements.md</code> decision \"Périphérique d'affichage pédagogique\"), shows it in the simulation log, and its icon really shows the received text (2-line scrolling). Expected result: <code>mcu.Display0.seq</code> is 0 before the first <code>write()</code>, 1 after the first, 2 after the second - checked numerically through <code>val()</code> in <code>verify_12_display.mos</code>.</p>
</html>"));
end Demo;
