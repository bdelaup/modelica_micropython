within MicroPythonMCU.Examples.MultiMcu;

model Independent "Two microcontrollers run the same program and import the same module: each keeps its own state"
  extends Modelica.Icons.Example;
  MCU mcu1(scriptPath = Modelica.Utilities.Files.loadResource("modelica://MicroPythonMCU/Resources/Scripts/MCU/multi_counter.py")) "First board: Resources/Scripts/MCU/multi_counter.py" annotation(
    Placement(transformation(origin = {-42, 0}, extent = {{-20, -20}, {20, 20}})));
  MCU mcu2(scriptPath = Modelica.Utilities.Files.loadResource("modelica://MicroPythonMCU/Resources/Scripts/MCU/multi_counter.py")) "Second board: the same program" annotation(
    Placement(transformation(origin = {84, 0}, extent = {{-20, -20}, {20, 20}})));
  Modelica.Electrical.Analog.Basic.Ground ground annotation(
    Placement(transformation(origin = {20, -70}, extent = {{-10, -10}, {10, 10}})));
  Modelica.Electrical.Analog.Basic.Resistor r10(R = 330) "limits the current of led10" annotation(
    Placement(transformation(origin = {-98, 20}, extent = {{-10, -10}, {10, 10}})));
  MicroPythonMCU.Peripherals.LED led10 "mcu1 GP0: blinks with the ticks of mcu1" annotation(
    Placement(transformation(origin = {-126, 20}, extent = {{-10, 10}, {10, -10}}, rotation = -180)));
  Modelica.Electrical.Analog.Basic.Resistor r11(R = 330) "limits the current of led11" annotation(
    Placement(transformation(origin = {-98, -8}, extent = {{-10, -10}, {10, 10}})));
  MicroPythonMCU.Peripherals.LED led11 "mcu1 GP1: lit at the end if mcu1 counted only its own 5 ticks" annotation(
    Placement(transformation(origin = {-126, -8}, extent = {{-10, 10}, {10, -10}}, rotation = -180)));
  Modelica.Electrical.Analog.Basic.Resistor r20(R = 330) "limits the current of led20" annotation(
    Placement(transformation(origin = {28, 20}, extent = {{-10, -10}, {10, 10}})));
  MicroPythonMCU.Peripherals.LED led20 "mcu2 GP0: blinks with the ticks of mcu2" annotation(
    Placement(transformation(origin = {0, 20}, extent = {{-10, 10}, {10, -10}}, rotation = -180)));
  Modelica.Electrical.Analog.Basic.Resistor r21(R = 330) "limits the current of led21" annotation(
    Placement(transformation(origin = {28, -8}, extent = {{-10, -10}, {10, 10}})));
  MicroPythonMCU.Peripherals.LED led21 "mcu2 GP1: lit at the end if mcu2 counted only its own 5 ticks" annotation(
    Placement(transformation(origin = {0, -8}, extent = {{-10, 10}, {10, -10}}, rotation = -180)));
equation
  connect(mcu1.GND, ground.p) annotation(
    Line(points = {{-42, -14}, {-42, -56}, {20, -56}, {20, -60}}, color = {0, 0, 255}));
  connect(mcu2.GND, ground.p) annotation(
    Line(points = {{84, -14}, {84, -56}, {20, -56}, {20, -60}}, color = {0, 0, 255}));
  connect(mcu1.GP0, r10.n) annotation(
    Line(points = {{-54, 10}, {-76, 10}, {-76, 20}, {-88, 20}}, color = {0, 0, 255}));
  connect(r10.p, led10.p) annotation(
    Line(points = {{-108, 20}, {-116, 20}}, color = {0, 0, 255}));
  connect(led10.n, ground.p) annotation(
    Line(points = {{-136, 20}, {-140, 20}, {-140, -56}, {20, -56}, {20, -60}}, color = {0, 0, 255}));
  connect(mcu1.GP1, r11.n) annotation(
    Line(points = {{-54, 4}, {-76, 4}, {-76, -8}, {-88, -8}}, color = {0, 0, 255}));
  connect(r11.p, led11.p) annotation(
    Line(points = {{-108, -8}, {-116, -8}}, color = {0, 0, 255}));
  connect(led11.n, ground.p) annotation(
    Line(points = {{-136, -8}, {-140, -8}, {-140, -56}, {20, -56}, {20, -60}}, color = {0, 0, 255}));
  connect(mcu2.GP0, r20.n) annotation(
    Line(points = {{72, 10}, {48, 10}, {48, 20}, {38, 20}}, color = {0, 0, 255}));
  connect(r20.p, led20.p) annotation(
    Line(points = {{18, 20}, {10, 20}}, color = {0, 0, 255}));
  connect(led20.n, ground.p) annotation(
    Line(points = {{-10, 20}, {-14, 20}, {-14, -56}, {20, -56}, {20, -60}}, color = {0, 0, 255}));
  connect(mcu2.GP1, r21.n) annotation(
    Line(points = {{72, 4}, {48, 4}, {48, -8}, {38, -8}}, color = {0, 0, 255}));
  connect(r21.p, led21.p) annotation(
    Line(points = {{18, -8}, {10, -8}}, color = {0, 0, 255}));
  connect(led21.n, ground.p) annotation(
    Line(points = {{-10, -8}, {-14, -8}, {-14, -56}, {20, -56}, {20, -60}}, color = {0, 0, 255}));
  annotation(
    Diagram(coordinateSystem(extent = {{-154, -98}, {126, 56}})),
    experiment(StopTime = 0.8, Interval = 0.001, StartTime = 0, Tolerance = 1e-06),
    Documentation(info = "<html>
<p>Two <code>MCU</code> blocks run the same program, <code>multi_counter.py</code>, which imports the module <code>multi_counter_lib.py</code> (placed next to it) and increments its module-level counter every 100 ms, five times. Each microcontroller runs in its own Python sub-interpreter: its program globals, its imported modules (here the counter), <code>machine</code>, <code>time</code>, <code>sys.path</code> and its file system are its own. Both boards therefore count exactly 5 ticks and light their <code>GP1</code> LED at the end; with a shared state, the counter would reach 10 and the second board would also see the globals of the first.</p>
<p>With two microcontrollers or more, every line printed by a program is prefixed with the instance name in the simulation log (<code>[mcu1] ...</code>), as the scripted peripherals already do.</p>
</html>"));
end Independent;
