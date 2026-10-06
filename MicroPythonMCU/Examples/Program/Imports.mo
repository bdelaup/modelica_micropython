within MicroPythonMCU.Examples.Program;

model Imports "The main script imports a helper module placed next to it (addScriptDirToPath) and a module of a shared library in a separate folder (libraryPath)"
  extends Modelica.Icons.Example;
  MCU mcu(scriptPath = Modelica.Utilities.Files.loadResource("modelica://MicroPythonMCU/Resources/Scripts/MCU/import_demo.py"), libraryPath = Modelica.Utilities.Files.loadResource("modelica://MicroPythonMCU/Resources/Scripts/MCU/lib/shared_helper.py")) "scriptPath = Resources/Scripts/MCU/import_demo.py, libraryPath = Resources/Scripts/MCU/lib/shared_helper.py (addScriptDirToPath keeps its default value, true)" annotation(
    Placement(transformation(origin = {0, 0}, extent = {{-20, -20}, {20, 20}})));
  Modelica.Electrical.Analog.Basic.Ground ground annotation(
    Placement(transformation(origin = {0, -70}, extent = {{-10, -10}, {10, 10}})));
  Modelica.Electrical.Analog.Basic.Resistor r0(R = 330) "limits the current of led0 (GP0: import companion, same folder as the script)" annotation(
    Placement(transformation(origin = {-62, 28}, extent = {{-10, -10}, {10, 10}})));
  MicroPythonMCU.Peripherals.LED led0 "GP0: import companion (addScriptDirToPath)" annotation(
    Placement(transformation(origin = {-98, 28}, extent = {{-10, 10}, {10, -10}}, rotation = -180)));
  Modelica.Electrical.Analog.Basic.Resistor r1(R = 330) "limits the current of led1 (GP1: import shared_helper, shared library)" annotation(
    Placement(transformation(origin = {-62, -8}, extent = {{-10, -10}, {10, 10}})));
  MicroPythonMCU.Peripherals.LED led1 "GP1: import shared_helper (libraryPath)" annotation(
    Placement(transformation(origin = {-98, -8}, extent = {{-10, 10}, {10, -10}}, rotation = -180)));
equation
  connect(mcu.GND, ground.p) annotation(
    Line(points = {{0, -14}, {0, -60}}, color = {0, 0, 255}));
  connect(mcu.GP0, r0.n) annotation(
    Line(points = {{-12, 10}, {-22, 10}, {-22, 28}, {-52, 28}}, color = {0, 0, 255}));
  connect(r0.p, led0.p) annotation(
    Line(points = {{-72, 28}, {-88, 28}}, color = {0, 0, 255}));
  connect(led0.n, ground.p) annotation(
    Line(points = {{-108, 28}, {-112, 28}, {-112, -56}, {0, -56}, {0, -60}}, color = {0, 0, 255}));
  connect(mcu.GP1, r1.n) annotation(
    Line(points = {{-12, 4}, {-22, 4}, {-22, -8}, {-52, -8}}, color = {0, 0, 255}));
  connect(r1.p, led1.p) annotation(
    Line(points = {{-72, -8}, {-88, -8}}, color = {0, 0, 255}));
  connect(led1.n, ground.p) annotation(
    Line(points = {{-108, -8}, {-112, -8}, {-112, -56}, {0, -56}, {0, -60}}, color = {0, 0, 255}));
  annotation(
    Diagram(coordinateSystem(extent = {{-140, -98}, {56, 70}})),
    experiment(StopTime = 0.5, Interval = 0.001, StartTime = 0, Tolerance = 1e-06),
    Documentation(info = "<html>
<p>Verification scenario 10 (see <code>requirements.md</code>): the main script <code>import_demo.py</code> imports two helper modules — <code>companion.py</code>, placed next to it in <code>Resources/Scripts/MCU/</code> (made importable by <code>addScriptDirToPath</code>, enabled by default on <code>MCU</code>), and <code>shared_helper.py</code>, in the separate subfolder <code>Resources/Scripts/MCU/lib/</code> (made importable through the <code>libraryPath</code> parameter of <code>mcu</code>, which points to it explicitly). If either import failed, the script would raise an uncaught <code>ImportError</code> and the simulation would stop with an error. <code>led0</code>/<code>led1</code> confirm visually that both imports succeeded. Pins <code>GP2</code>-<code>GP7</code>, unused by this scenario, are left unconnected.</p>
</html>"));
end Imports;
