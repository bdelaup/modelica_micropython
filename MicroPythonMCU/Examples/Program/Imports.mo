within MicroPythonMCU.Examples.Program;

model Imports "The main script imports a helper module placed next to it (addScriptDirToPath) and a module of a shared library in a separate folder (libraryPath)"
  extends Modelica.Icons.Example;
  MCU mcu(scriptPath = Modelica.Utilities.Files.loadResource("modelica://MicroPythonMCU/Resources/Scripts/MCU/import_demo.py"), libraryPath = Modelica.Utilities.Files.loadResource("modelica://MicroPythonMCU/Resources/Scripts/MCU/lib/shared_helper.py")) "scriptPath = Resources/Scripts/MCU/import_demo.py, libraryPath = Resources/Scripts/MCU/lib/shared_helper.py (addScriptDirToPath keeps its default value, true)" annotation(
    Placement(transformation(origin = {0, 0}, extent = {{-50, -50}, {50, 50}})));
  Modelica.Electrical.Analog.Basic.Ground ground annotation(
    Placement(transformation(origin = {0, -100}, extent = {{-15, -15}, {15, 15}})));
  Modelica.Electrical.Analog.Basic.Resistor r0(R = 330) "limits the current of led0 (GP0: import companion, same folder as the script)" annotation(
    Placement(transformation(origin = {-90, 40}, extent = {{-15, -15}, {15, 15}})));
  MicroPythonMCU.Peripherals.LED led0 "GP0: import companion (addScriptDirToPath)" annotation(
    Placement(transformation(origin = {-140, 40}, extent = {{-15, 15}, {15, -15}}, rotation = -180)));
  Modelica.Electrical.Analog.Basic.Resistor r1(R = 330) "limits the current of led1 (GP1: import shared_helper, shared library)" annotation(
    Placement(transformation(origin = {-90, -10}, extent = {{-15, -15}, {15, 15}})));
  MicroPythonMCU.Peripherals.LED led1 "GP1: import shared_helper (libraryPath)" annotation(
    Placement(transformation(origin = {-140, -10}, extent = {{-15, 15}, {15, -15}}, rotation = -180)));
equation
  connect(mcu.GND, ground.p) annotation(
    Line(points = {{0, -39}, {0, -85}}, color = {0, 0, 255}));
  connect(mcu.GP0, r0.n) annotation(
    Line(points = {{-31, 25}, {-31, 40}, {-75, 40}}, color = {0, 0, 255}));
  connect(r0.p, led0.p) annotation(
    Line(points = {{-105, 40}, {-125, 40}}, color = {0, 0, 255}));
  connect(led0.n, ground.p) annotation(
    Line(points = {{-155, 40}, {-155, -85}, {0, -85}}, color = {0, 0, 255}));
  connect(mcu.GP1, r1.n) annotation(
    Line(points = {{-31, 10}, {-31, -10}, {-75, -10}}, color = {0, 0, 255}));
  connect(r1.p, led1.p) annotation(
    Line(points = {{-105, -10}, {-125, -10}}, color = {0, 0, 255}));
  connect(led1.n, ground.p) annotation(
    Line(points = {{-155, -10}, {-155, -85}, {0, -85}}, color = {0, 0, 255}));
  annotation(
    Diagram(coordinateSystem(extent = {{-200, -140}, {80, 100}})),
    experiment(StopTime = 0.5, Interval = 0.001, StartTime = 0, Tolerance = 1e-06),
    Documentation(info = "<html>
<p>Verification scenario 10 (see <code>requirements.md</code>): the main script <code>import_demo.py</code> imports two helper modules — <code>companion.py</code>, placed next to it in <code>Resources/Scripts/MCU/</code> (made importable by <code>addScriptDirToPath</code>, enabled by default on <code>MCU</code>), and <code>shared_helper.py</code>, in the separate subfolder <code>Resources/Scripts/MCU/lib/</code> (made importable through the <code>libraryPath</code> parameter of <code>mcu</code>, which points to it explicitly). If either import failed, the script would raise an uncaught <code>ImportError</code> and the simulation would stop with an error. <code>led0</code>/<code>led1</code> confirm visually that both imports succeeded. Pins <code>GP2</code>-<code>GP7</code>, unused by this scenario, are left unconnected.</p>
</html>"));
end Imports;
