within MicroPythonMCU.Examples.MultiMcu;

model FileSystem "Two data loggers start from the same flash image: each gets its own copy and writes its own measurements"
  extends Modelica.Icons.Example;
  MCU mcu1(scriptPath = "", fsEnabled = true, fsSource = "modelica://MicroPythonMCU/Resources/FileSystems/datalogger", fsOpenExplorer = false) "boot.py then main.py of its own copy of Resources/FileSystems/datalogger (folder mcu1_datalogger_<date>)" annotation(
    Placement(transformation(origin = {-42, 0}, extent = {{-20, -20}, {20, 20}})));
  MCU mcu2(scriptPath = "", fsEnabled = true, fsSource = "modelica://MicroPythonMCU/Resources/FileSystems/datalogger", fsOpenExplorer = false) "same image, its own copy (folder mcu2_datalogger_<date>)" annotation(
    Placement(transformation(origin = {84, 0}, extent = {{-20, -20}, {20, 20}})));
  Modelica.Electrical.Analog.Basic.Ground ground annotation(
    Placement(transformation(origin = {20, -70}, extent = {{-10, -10}, {10, 10}})));
  Modelica.Electrical.Analog.Sources.RampVoltage ramp(V = 3.3, duration = 1) "voltage measured by mcu1 (GP0): ramp from 0 to 3.3 V in 1 s" annotation(
    Placement(transformation(origin = {-92, -20}, extent = {{-10, -10}, {10, 10}}, rotation = -90)));
  Modelica.Electrical.Analog.Sources.ConstantVoltage steady(V = 1) "voltage measured by mcu2 (GP0): constant 1 V" annotation(
    Placement(transformation(origin = {36, -20}, extent = {{-10, -10}, {10, 10}}, rotation = -90)));
equation
  connect(mcu1.GND, ground.p) annotation(
    Line(points = {{-42, -14}, {-42, -56}, {20, -56}, {20, -60}}, color = {0, 0, 255}));
  connect(mcu2.GND, ground.p) annotation(
    Line(points = {{84, -14}, {84, -56}, {20, -56}, {20, -60}}, color = {0, 0, 255}));
  connect(ramp.p, mcu1.GP0) annotation(
    Line(points = {{-92, -10}, {-92, 10}, {-54, 10}}, color = {0, 0, 255}));
  connect(ramp.n, ground.p) annotation(
    Line(points = {{-92, -30}, {-92, -56}, {20, -56}, {20, -60}}, color = {0, 0, 255}));
  connect(steady.p, mcu2.GP0) annotation(
    Line(points = {{36, -10}, {36, 10}, {72, 10}}, color = {0, 0, 255}));
  connect(steady.n, ground.p) annotation(
    Line(points = {{36, -30}, {36, -56}, {20, -56}, {20, -60}}, color = {0, 0, 255}));
  annotation(
    Diagram(coordinateSystem(extent = {{-112, -98}, {126, 42}})),
    experiment(StopTime = 1.5, Interval = 0.001, StartTime = 0, Tolerance = 1e-06),
    Documentation(info = "<html>
<p>Two <code>MCU</code> blocks start from the same flash image, <code>Resources/FileSystems/datalogger</code> (the one of <code>Examples.FileSystem.Boot</code>). Each one gets <strong>its own</strong> timestamped copy, named after its instance (<code>mcu1_datalogger_&lt;date&gt;</code>, <code>mcu2_datalogger_&lt;date&gt;</code>), with its own current folder and its own <code>/lib</code> on the import path: nothing written by one board appears on the other, as with two real boards.</p>
<p><code>mcu1</code> logs a ramp from 0 to 3.3 V, <code>mcu2</code> a constant 1 V, each in its own <code>/data/measurements.csv</code>. The self-check of <code>main.py</code> (exact content of <code>/</code>, read-back, attempt to escape the flash) passes on both boards and sets their <code>GP1</code> high.</p>
</html>"));
end FileSystem;
