within MicroPythonMCU.Examples.FileSystem;

model Boot "File system: with no script, the microcontroller runs boot.py then main.py of a flash image copied at each simulation; main.py logs the ADC measurements (GP0) to /data/measurements.csv"
  extends Modelica.Icons.Example;
  MCU mcu(scriptPath = "", fsEnabled = true, fsSource = "modelica://MicroPythonMCU/Resources/FileSystems/datalogger") "empty scriptPath: boot.py then main.py of the image Resources/FileSystems/datalogger; copy created in the simulation folder (fsWorkspace = \".\" by default), opened in Explorer at the end of the simulation" annotation(
    Placement(transformation(origin = {0, 0}, extent = {{-20, -20}, {20, 20}})));
  Modelica.Electrical.Analog.Basic.Ground ground annotation(
    Placement(transformation(origin = {0, -62}, extent = {{-10, -10}, {10, 10}})));
  Modelica.Electrical.Analog.Sources.RampVoltage ramp(V = 3.3, duration = 1) "voltage measured by the ADC (GP0): ramp from 0 to 3.3 V in 1 s" annotation(
    Placement(transformation(origin = {-76, -20}, extent = {{-10, -10}, {10, 10}}, rotation = -90)));
  Modelica.Electrical.Analog.Basic.Resistor r1(R = 330) "limits the current of led1 (GP1)" annotation(
    Placement(transformation(origin = {-62, 8}, extent = {{-10, -10}, {10, 10}})));
  MicroPythonMCU.Peripherals.LED led1 "GP1: self-check of main.py passed" annotation(
    Placement(transformation(origin = {-98, 8}, extent = {{-10, 10}, {10, -10}}, rotation = -180)));
equation
  connect(mcu.GND, ground.p) annotation(
    Line(points = {{0, -14}, {0, -52}}, color = {0, 0, 255}));
  connect(ramp.p, mcu.GP0) annotation(
    Line(points = {{-76, -10}, {-76, -6}, {-16, -6}, {-16, 10}, {-12, 10}}, color = {0, 0, 255}));
  connect(ramp.n, ground.p) annotation(
    Line(points = {{-76, -30}, {-76, -48}, {0, -48}, {0, -52}}, color = {0, 0, 255}));
  connect(mcu.GP1, r1.n) annotation(
    Line(points = {{-12, 4}, {-32, 4}, {-32, 8}, {-52, 8}}, color = {0, 0, 255}));
  connect(r1.p, led1.p) annotation(
    Line(points = {{-72, 8}, {-88, 8}}, color = {0, 0, 255}));
  connect(led1.n, ground.p) annotation(
    Line(points = {{-108, 8}, {-116, 8}, {-116, -48}, {0, -48}, {0, -52}}, color = {0, 0, 255}));
  annotation(
    Diagram(coordinateSystem(extent = {{-126, -84}, {56, 56}})),
    experiment(StopTime = 1.5, Interval = 0.001, StartTime = 0, Tolerance = 1e-06),
    Documentation(info = "<html>
<p>Verification scenario 25 (see <code>requirements.md</code>, decision \"Système de fichiers\"): the file system is enabled (<code>fsEnabled</code>) and <code>scriptPath</code> is empty, so the microcontroller starts like a real board — <code>boot.py</code> then <code>main.py</code>, read at the root of the flash.</p>
<p>At each simulation, the image <code>Resources/FileSystems/datalogger</code> (<code>fsSource</code>) is copied into a new folder of the workspace (<code>fsWorkspace = \".\"</code> by default: the simulation folder), named <code>mcu_datalogger_&lt;date&gt;_&lt;time&gt;</code> — its exact path is announced in the simulation log, at the start and at the end, and Windows Explorer opens on it at the end of the simulation (<code>fsOpenExplorer</code>). The original image is never modified: each simulation starts again from the same state and produces the same files.</p>
<ul>
<li><code>boot.py</code> creates the <code>/data</code> folder;</li>
<li><code>main.py</code> reads its settings from <code>/config.txt</code>, imports the <code>DataLog</code> module from <code>/lib</code>, then logs every 100 ms the voltage read by the ADC on <code>GP0</code> (ramp from 0 to 3.3 V) to <code>/data/measurements.csv</code>;</li>
<li>it finally checks itself (file read-back, <code>os.listdir</code>, <code>os.stat</code>, attempt to escape the flash through <code>../..</code>) and lights <code>led1</code> (<code>GP1</code>) if everything is as expected.</li>
</ul>
<p>To run it on your own files: point <code>fsSource</code> to a folder containing <code>boot.py</code>/<code>main.py</code>, and possibly <code>fsWorkspace</code> to the folder where the copies should go. Variant with a script instead of <code>main.py</code>: <code>Examples.FileSystem.Script</code>.</p>
</html>"));
end Boot;
