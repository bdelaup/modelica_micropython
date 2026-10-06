within MicroPythonMCU.Examples.MultiMcu;

model Handshake "Two microcontrollers wired together: A raises a request, B acknowledges it from a Pin.irq handler"
  extends Modelica.Icons.Example;
  MCU mcuA(scriptPath = Modelica.Utilities.Files.loadResource("modelica://MicroPythonMCU/Resources/Scripts/MCU/handshake_a.py")) "Board A: Resources/Scripts/MCU/handshake_a.py (REQ on GP0, ACK read on GP1)" annotation(
    Placement(transformation(origin = {-60, 0}, extent = {{-20, -20}, {20, 20}})));
  MCU mcuB(scriptPath = Modelica.Utilities.Files.loadResource("modelica://MicroPythonMCU/Resources/Scripts/MCU/handshake_b.py")) "Board B: Resources/Scripts/MCU/handshake_b.py (REQ read on GP0, ACK on GP1)" annotation(
    Placement(transformation(origin = {120, 0}, extent = {{-20, -20}, {20, 20}})));
  Modelica.Electrical.Analog.Basic.Ground ground annotation(
    Placement(transformation(origin = {30, -100}, extent = {{-10, -10}, {10, 10}})));
  Modelica.Electrical.Analog.Basic.Resistor pullReq(R = 100e3) "pull-down of the REQ line, so that it does not float while neither board drives it" annotation(
    Placement(transformation(origin = {10, 50}, extent = {{-10, -10}, {10, 10}}, rotation = -90)));
  Modelica.Electrical.Analog.Basic.Resistor pullAck(R = 100e3) "pull-down of the ACK line" annotation(
    Placement(transformation(origin = {50, 50}, extent = {{-10, -10}, {10, 10}}, rotation = -90)));
  Modelica.Electrical.Analog.Basic.Resistor r2(R = 330) "limits the current of ledDone" annotation(
    Placement(transformation(origin = {-140, -10}, extent = {{-10, -10}, {10, 10}})));
  MicroPythonMCU.Peripherals.LED ledDone "mcuA GP2: lit once every round has been acknowledged" annotation(
    Placement(transformation(origin = {-180, -10}, extent = {{-10, 10}, {10, -10}}, rotation = -180)));
equation
  connect(mcuA.GND, ground.p) annotation(
    Line(points = {{-60, -14}, {-60, -84}, {30, -84}, {30, -90}}, color = {0, 0, 255}));
  connect(mcuB.GND, ground.p) annotation(
    Line(points = {{120, -14}, {120, -84}, {30, -84}, {30, -90}}, color = {0, 0, 255}));
// REQ: A.GP0 -> B.GP0
  connect(mcuA.GP0, mcuB.GP0) annotation(
    Line(points = {{-72, 10}, {-100, 10}, {-100, 70}, {80, 70}, {80, 10}, {108, 10}}, color = {0, 0, 255}));
  connect(pullReq.p, mcuB.GP0) annotation(
    Line(points = {{10, 60}, {10, 70}, {80, 70}, {80, 10}, {108, 10}}, color = {0, 0, 255}));
  connect(pullReq.n, ground.p) annotation(
    Line(points = {{10, 40}, {10, -84}, {30, -84}, {30, -90}}, color = {0, 0, 255}));
// ACK: B.GP1 -> A.GP1
  connect(mcuB.GP1, mcuA.GP1) annotation(
    Line(points = {{108, 4}, {70, 4}, {70, 30}, {-124, 30}, {-124, 4}, {-72, 4}}, color = {0, 0, 255}));
  connect(pullAck.p, mcuB.GP1) annotation(
    Line(points = {{50, 60}, {50, 64}, {70, 64}, {70, 4}, {108, 4}}, color = {0, 0, 255}));
  connect(pullAck.n, ground.p) annotation(
    Line(points = {{50, 40}, {50, -84}, {30, -84}, {30, -90}}, color = {0, 0, 255}));
  connect(mcuA.GP2, r2.n) annotation(
    Line(points = {{-72, -4}, {-110, -4}, {-110, -10}, {-130, -10}}, color = {0, 0, 255}));
  connect(r2.p, ledDone.p) annotation(
    Line(points = {{-150, -10}, {-170, -10}}, color = {0, 0, 255}));
  connect(ledDone.n, ground.p) annotation(
    Line(points = {{-190, -10}, {-200, -10}, {-200, -86}, {30, -86}, {30, -90}}, color = {0, 0, 255}));
  annotation(
    Diagram(coordinateSystem(extent = {{-220, -140}, {180, 100}})),
    experiment(StopTime = 0.35, Interval = 0.0001, StartTime = 0, Tolerance = 1e-06),
    Documentation(info = "<html>
<p>Two-wire request/acknowledge handshake between two <code>MCU</code> blocks. Board A (<code>handshake_a.py</code>) raises <code>REQ</code> on <code>GP0</code>; board B (<code>handshake_b.py</code>) sleeps in its main loop, and a <code>Pin.irq</code> handler on its <code>GP0</code> copies the level onto <code>ACK</code> (<code>GP1</code>), which A reads on its own <code>GP1</code>. A prints how long B took to answer (a few microseconds: the execution time of the pin accesses, <code>gpioOpTime</code>), releases <code>REQ</code>, waits for <code>ACK</code> to fall, three times, then lights <code>ledDone</code>. The 100 kΩ resistors keep each line at 0 V while no board drives it.</p>
<p>Each board runs in its own Python sub-interpreter and thread: the electrical edge produced by one wakes the other at the next event iteration of Modelica, exactly as with a peripheral component.</p>
</html>"));
end Handshake;
