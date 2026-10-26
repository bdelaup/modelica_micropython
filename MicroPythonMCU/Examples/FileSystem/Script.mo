within MicroPythonMCU.Examples.FileSystem;

model Script "File system and script: boot.py of the flash, then the script fs_script.py instead of main.py"
  extends Modelica.Icons.Example;
  MCU mcu(scriptPath = Modelica.Utilities.Files.loadResource("modelica://MicroPythonMCU/Resources/Scripts/MCU/fs_script.py"), fsEnabled = true, fsSource = "modelica://MicroPythonMCU/Resources/FileSystems/datalogger") "boot.py of the flash image, then the script fs_script.py instead of main.py; copy created in the simulation folder (fsWorkspace = \".\" by default), opened in Explorer at the end of the simulation" annotation(
    Placement(transformation(origin = {0, 0}, extent = {{-20, -20}, {20, 20}})));
  Modelica.Electrical.Analog.Basic.Ground ground annotation(
    Placement(transformation(origin = {0, -62}, extent = {{-10, -10}, {10, 10}})));
  Modelica.Electrical.Analog.Sources.RampVoltage ramp(V = 3.3, duration = 1) "voltage measured by the ADC (GP0): ramp from 0 to 3.3 V in 1 s" annotation(
    Placement(transformation(origin = {-76, -20}, extent = {{-10, -10}, {10, 10}}, rotation = -90)));
  Modelica.Electrical.Analog.Basic.Resistor r1(R = 330) "limits the current of led1 (GP1)" annotation(
    Placement(transformation(origin = {-62, 8}, extent = {{-10, -10}, {10, 10}})));
  MicroPythonMCU.Peripherals.LED led1 "GP1: self-check passed" annotation(
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
    experiment(StopTime = 0.5, Interval = 0.001, StartTime = 0, Tolerance = 1e-06),
    Documentation(info = "<html>
<p>Verification scenario 27 (see <code>requirements.md</code>, decision \"Système de fichiers\"): same circuit and same flash image as <code>Examples.FileSystem.Boot</code>, but <code>scriptPath</code> is set. The microcontroller then runs <code>boot.py</code> from the flash, then the script <code>fs_script.py</code> <strong>instead of</strong> <code>main.py</code> — like Thonny running the open script on an already booted board.</p>
<p>The script checks that <code>boot.py</code> did create <code>/data</code> and that <code>main.py</code> did not run (<code>/data</code> empty), writes then reads back <code>/data/notes.txt</code>, and lights <code>led1</code> (<code>GP1</code>) if everything is as expected.</p>
</html>"));
end Script;
