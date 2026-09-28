within MicroPythonMCU.Examples.Irq;
model Pin "GP1 driven by a square wave (rising and falling edges); the script registers machine.Pin.irq() with trigger=IRQ_RISING on GP1, which toggles GP0 (LED) from the callback - proves the filtering by edge direction"
  extends Modelica.Icons.Example;
  MCU mcu(scriptPath = Modelica.Utilities.Files.loadResource("modelica://MicroPythonMCU/Resources/Verification/pin_irq_demo.py")) "scriptPath = Verification/pin_irq_demo.py" annotation(
    Placement(transformation(origin = {0, 0}, extent = {{-50, -50}, {50, 50}})));
  Modelica.Electrical.Analog.Basic.Ground ground annotation(
    Placement(transformation(origin = {0, -100}, extent = {{-15, -15}, {15, 15}})));

  Modelica.Electrical.Analog.Basic.Resistor r0(R = 330) "limits the current of led0 (GP0)" annotation(
    Placement(transformation(origin = {-90, 25}, extent = {{-15, -15}, {15, 15}})));
  MicroPythonMCU.Peripherals.LED led0 "GP0: toggles on each rising edge of GP1 (IRQ_RISING)" annotation(
    Placement(transformation(origin = {-142, 25}, extent = {{15, -15}, {-15, 15}}, rotation = -0)));

  Modelica.Electrical.Analog.Sources.SignalVoltage btnSrc "Drives GP1 from outside" annotation(
    Placement(transformation(origin = {-90, -20}, extent = {{15, -15}, {-15, 15}})));
  Modelica.Blocks.Sources.Pulse pulseSrc(amplitude = 3.3, period = 4, width = 50, startTime = 2) "Square wave on GP1: rising edge at t=2s and t=6s, falling at t=4s and t=8s" annotation(
    Placement(transformation(origin = {-90, 70}, extent = {{-15, -15}, {15, 15}})));
equation
  connect(mcu.GND, ground.p) annotation(
    Line(points = {{0, -39}, {0, -85}}, color = {0, 0, 255}));
  connect(mcu.GP0, r0.n) annotation(
    Line(points = {{-31, 25}, {-75, 25}}, color = {0, 0, 255}));
  connect(r0.p, led0.p) annotation(
    Line(points = {{-105, 25}, {-127, 25}}, color = {0, 0, 255}));
  connect(led0.n, ground.p) annotation(
    Line(points = {{-157, 25}, {-157, -85}, {0, -85}}, color = {0, 0, 255}));
  connect(pulseSrc.y, btnSrc.v) annotation(
    Line(points = {{-90, 55}, {-90, -5}}, color = {0, 0, 127}));
  connect(mcu.GP1, btnSrc.p) annotation(
    Line(points = {{-31, 10}, {-31, -20}, {-75, -20}}, color = {0, 0, 255}));
  connect(btnSrc.n, ground.p) annotation(
    Line(points = {{-105, -20}, {-115, -20}, {-115, -85}, {0, -85}}, color = {0, 0, 255}));
  annotation(
    Diagram(coordinateSystem(extent = {{-160, -140}, {80, 100}})),
    experiment(StopTime = 8, Interval = 0.001, StartTime = 0, Tolerance = 1e-06),
    Documentation(info = "<html>
<p>Verification scenario 11 (see <code>requirements.md</code>): <code>GP1</code> is driven by a square wave (<code>Modelica.Blocks.Sources.Pulse</code>, rising edge at t=2s/t=6s, falling at t=4s/t=8s). The script <code>pin_irq_demo.py</code> registers <code>Pin(1, Pin.IN).irq(handler=on_rise, trigger=Pin.IRQ_RISING)</code> — only a rising edge must trigger the callback, which toggles <code>led0</code> (GP0). Expected result: <code>GP0</code> toggles at t≈2s and stays unchanged at the falling edge of t≈4s (the LED stays on), proof that the filtering by edge direction works (not \"any edge triggers\"), then toggles again at t≈6s. Pins <code>GP2</code>-<code>GP7</code>, unused by this scenario, are left unconnected.</p>
</html>"));
end Pin;
