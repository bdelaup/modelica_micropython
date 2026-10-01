within MicroPythonMCU.Examples.MultiMcu;

model Independent "Two microcontrollers run the same program and import the same module: each keeps its own state"
  extends Modelica.Icons.Example;
  MCU mcu1(scriptPath = Modelica.Utilities.Files.loadResource("modelica://MicroPythonMCU/Resources/Scripts/MCU/multi_counter.py")) "First board: Resources/Scripts/MCU/multi_counter.py" annotation(
    Placement(transformation(origin = {-60, 0}, extent = {{-40, -40}, {40, 40}})));
  MCU mcu2(scriptPath = Modelica.Utilities.Files.loadResource("modelica://MicroPythonMCU/Resources/Scripts/MCU/multi_counter.py")) "Second board: the same program" annotation(
    Placement(transformation(origin = {120, 0}, extent = {{-40, -40}, {40, 40}})));
  Modelica.Electrical.Analog.Basic.Ground ground annotation(
    Placement(transformation(origin = {30, -100}, extent = {{-15, -15}, {15, 15}})));
  Modelica.Electrical.Analog.Basic.Resistor r10(R = 330) "limits the current of led10" annotation(
    Placement(transformation(origin = {-140, 30}, extent = {{-15, -15}, {15, 15}})));
  MicroPythonMCU.Peripherals.LED led10 "mcu1 GP0: blinks with the ticks of mcu1" annotation(
    Placement(transformation(origin = {-180, 30}, extent = {{-15, 15}, {15, -15}}, rotation = -180)));
  Modelica.Electrical.Analog.Basic.Resistor r11(R = 330) "limits the current of led11" annotation(
    Placement(transformation(origin = {-140, -10}, extent = {{-15, -15}, {15, 15}})));
  MicroPythonMCU.Peripherals.LED led11 "mcu1 GP1: lit at the end if mcu1 counted only its own 5 ticks" annotation(
    Placement(transformation(origin = {-180, -10}, extent = {{-15, 15}, {15, -15}}, rotation = -180)));
  Modelica.Electrical.Analog.Basic.Resistor r20(R = 330) "limits the current of led20" annotation(
    Placement(transformation(origin = {40, 30}, extent = {{-15, -15}, {15, 15}})));
  MicroPythonMCU.Peripherals.LED led20 "mcu2 GP0: blinks with the ticks of mcu2" annotation(
    Placement(transformation(origin = {0, 30}, extent = {{-15, 15}, {15, -15}}, rotation = -180)));
  Modelica.Electrical.Analog.Basic.Resistor r21(R = 330) "limits the current of led21" annotation(
    Placement(transformation(origin = {40, -10}, extent = {{-15, -15}, {15, 15}})));
  MicroPythonMCU.Peripherals.LED led21 "mcu2 GP1: lit at the end if mcu2 counted only its own 5 ticks" annotation(
    Placement(transformation(origin = {0, -10}, extent = {{-15, 15}, {15, -15}}, rotation = -180)));
equation
  connect(mcu1.GND, ground.p) annotation(
    Line(points = {{-60, -31}, {-60, -85}, {30, -85}}, color = {0, 0, 255}));
  connect(mcu2.GND, ground.p) annotation(
    Line(points = {{120, -31}, {120, -85}, {30, -85}}, color = {0, 0, 255}));
  connect(mcu1.GP0, r10.n) annotation(
    Line(points = {{-85, 20}, {-110, 20}, {-110, 30}, {-125, 30}}, color = {0, 0, 255}));
  connect(r10.p, led10.p) annotation(
    Line(points = {{-155, 30}, {-165, 30}}, color = {0, 0, 255}));
  connect(led10.n, ground.p) annotation(
    Line(points = {{-195, 30}, {-200, 30}, {-200, -85}, {30, -85}}, color = {0, 0, 255}));
  connect(mcu1.GP1, r11.n) annotation(
    Line(points = {{-85, 8}, {-110, 8}, {-110, -10}, {-125, -10}}, color = {0, 0, 255}));
  connect(r11.p, led11.p) annotation(
    Line(points = {{-155, -10}, {-165, -10}}, color = {0, 0, 255}));
  connect(led11.n, ground.p) annotation(
    Line(points = {{-195, -10}, {-200, -10}, {-200, -85}, {30, -85}}, color = {0, 0, 255}));
  connect(mcu2.GP0, r20.n) annotation(
    Line(points = {{95, 20}, {70, 20}, {70, 30}, {55, 30}}, color = {0, 0, 255}));
  connect(r20.p, led20.p) annotation(
    Line(points = {{25, 30}, {15, 30}}, color = {0, 0, 255}));
  connect(led20.n, ground.p) annotation(
    Line(points = {{-15, 30}, {-20, 30}, {-20, -85}, {30, -85}}, color = {0, 0, 255}));
  connect(mcu2.GP1, r21.n) annotation(
    Line(points = {{95, 8}, {70, 8}, {70, -10}, {55, -10}}, color = {0, 0, 255}));
  connect(r21.p, led21.p) annotation(
    Line(points = {{25, -10}, {15, -10}}, color = {0, 0, 255}));
  connect(led21.n, ground.p) annotation(
    Line(points = {{-15, -10}, {-20, -10}, {-20, -85}, {30, -85}}, color = {0, 0, 255}));
  annotation(
    Diagram(coordinateSystem(extent = {{-220, -140}, {180, 80}})),
    experiment(StopTime = 0.8, Interval = 0.001, StartTime = 0, Tolerance = 1e-06),
    Documentation(info = "<html>
<p>Two <code>MCU</code> blocks run the same program, <code>multi_counter.py</code>, which imports the module <code>multi_counter_lib.py</code> (placed next to it) and increments its module-level counter every 100 ms, five times. Each microcontroller runs in its own Python sub-interpreter: its program globals, its imported modules (here the counter), <code>machine</code>, <code>time</code>, <code>sys.path</code> and its file system are its own. Both boards therefore count exactly 5 ticks and light their <code>GP1</code> LED at the end; with a shared state, the counter would reach 10 and the second board would also see the globals of the first.</p>
<p>With two microcontrollers or more, every line printed by a program is prefixed with the instance name in the simulation log (<code>[mcu1] ...</code>), as the scripted peripherals already do.</p>
</html>"));
end Independent;
