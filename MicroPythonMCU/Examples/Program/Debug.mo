within MicroPythonMCU.Examples.Program;

model Debug "Debugging with VS Code: the simulation waits until VS Code attaches, then the program can be paused, stepped and inspected"
  extends Modelica.Icons.Example;
  MCU mcu(scriptPath = Modelica.Utilities.Files.loadResource("modelica://MicroPythonMCU/Resources/Scripts/MCU/debug_demo.py"), debugEnabled = true) "scriptPath = Resources/Scripts/MCU/debug_demo.py, debugEnabled = true (tab Debugging): waits for VS Code on port 5678" annotation(
    Placement(transformation(origin = {0, 0}, extent = {{-20, -20}, {20, 20}})));
  Modelica.Electrical.Analog.Basic.Ground ground annotation(
    Placement(transformation(origin = {0, -90}, extent = {{-10, -10}, {10, 10}})));
  Modelica.Electrical.Analog.Basic.Resistor r0(R = 330) "limits the current of led0 (GP0)" annotation(
    Placement(transformation(origin = {-90, 24}, extent = {{-10, -10}, {10, 10}})));
  MicroPythonMCU.Peripherals.LED led0 "GP0: toggled by the main loop" annotation(
    Placement(transformation(origin = {-128, 24}, extent = {{-10, 10}, {10, -10}}, rotation = -180)));
  Modelica.Electrical.Analog.Basic.Resistor r1(R = 330) "limits the current of led1 (GP1)" annotation(
    Placement(transformation(origin = {-90, -4}, extent = {{-10, -10}, {10, 10}})));
  MicroPythonMCU.Peripherals.LED led1 "GP1: toggled by the timer callback" annotation(
    Placement(transformation(origin = {-128, -4}, extent = {{-10, 10}, {10, -10}}, rotation = -180)));
  Modelica.Electrical.Analog.Ideal.IdealClosingSwitch button "pressed between t = 0.8 s and t = 1.2 s: pulls GP2 to ground (internal pull-up)" annotation(
    Placement(transformation(origin = {-90, -50}, extent = {{-10, -10}, {10, 10}})));
  Modelica.Blocks.Sources.BooleanPulse press(width = 20, period = 2, startTime = 0.8) "button pressed from 0.8 s to 1.2 s" annotation(
    Placement(transformation(origin = {-124, -36}, extent = {{-10, -10}, {10, 10}})));
equation
  connect(mcu.GND, ground.p) annotation(
    Line(points = {{0, -14}, {0, -80}}, color = {0, 0, 255}));
  connect(mcu.GP0, r0.n) annotation(
    Line(points = {{-12, 10}, {-46, 10}, {-46, 24}, {-80, 24}}, color = {0, 0, 255}));
  connect(r0.p, led0.p) annotation(
    Line(points = {{-100, 24}, {-118, 24}}, color = {0, 0, 255}));
  connect(led0.n, ground.p) annotation(
    Line(points = {{-138, 24}, {-150, 24}, {-150, -76}, {0, -76}, {0, -80}}, color = {0, 0, 255}));
  connect(mcu.GP1, r1.n) annotation(
    Line(points = {{-12, 4}, {-60, 4}, {-60, -4}, {-80, -4}}, color = {0, 0, 255}));
  connect(r1.p, led1.p) annotation(
    Line(points = {{-100, -4}, {-118, -4}}, color = {0, 0, 255}));
  connect(led1.n, ground.p) annotation(
    Line(points = {{-138, -4}, {-150, -4}, {-150, -76}, {0, -76}, {0, -80}}, color = {0, 0, 255}));
  connect(mcu.GP2, button.n) annotation(
    Line(points = {{-12, -4}, {-50, -4}, {-50, -50}, {-80, -50}}, color = {0, 0, 255}));
  connect(button.p, ground.p) annotation(
    Line(points = {{-100, -50}, {-150, -50}, {-150, -76}, {0, -76}, {0, -80}}, color = {0, 0, 255}));
  connect(press.y, button.control) annotation(
    Line(points = {{-113, -36}, {-90, -36}, {-90, -38}}, color = {255, 0, 255}));
  annotation(
    Diagram(coordinateSystem(extent = {{-200, -120}, {80, 80}})),
    experiment(StopTime = 2.5, Interval = 0.001, StartTime = 0, Tolerance = 1e-06),
    Documentation(info = "<html>
<p><b>The simulation waits for VS Code</b> (<code>debugEnabled = true</code>): the log shows <code>Debugger: waiting for VS Code on port 5678</code>. In VS Code, open <code>Resources/Scripts/MCU/debug_demo.py</code>, put a breakpoint, then <i>Run and Debug</i> &gt; attach to <code>localhost:5678</code> (configuration given in the user guide, page <i>Debugging</i>). The program then runs, stops on the breakpoint, and can be stepped; the variables (<code>count</code>, <code>presses</code>) are shown by VS Code. While the program is paused, the simulation waits: simulated time is frozen, the results are the same as without the debugger.</p>
<p>Expected result: <code>led0</code> toggles every 100 ms during 2 s, <code>led1</code> every 250 ms (timer callback); the button is pressed between t = 0.8 s and t = 1.2 s, so the log reports 4 loops with the button pressed.</p>
</html>"));
end Debug;
