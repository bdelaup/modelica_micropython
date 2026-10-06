within MicroPythonMCU.Examples.Irq;
model Pin "GP1 driven by a square wave (rising and falling edges); the script registers machine.Pin.irq() with trigger=IRQ_RISING on GP1, which toggles GP0 (LED) from the callback - proves the filtering by edge direction"
  extends Modelica.Icons.Example;
  MCU mcu(scriptPath = Modelica.Utilities.Files.loadResource("modelica://MicroPythonMCU/Resources/Verification/pin_irq_demo.py")) "scriptPath = Verification/pin_irq_demo.py" annotation(
    Placement(transformation(origin = {0, 0}, extent = {{-20, -20}, {20, 20}})));
  Modelica.Electrical.Analog.Basic.Ground ground annotation(
    Placement(transformation(origin = {0, -70}, extent = {{-10, -10}, {10, 10}})));

  Modelica.Electrical.Analog.Basic.Resistor r0(R = 330) "limits the current of led0 (GP0)" annotation(
    Placement(transformation(origin = {-62, 18}, extent = {{-10, -10}, {10, 10}})));
  MicroPythonMCU.Peripherals.LED led0 "GP0: toggles on each rising edge of GP1 (IRQ_RISING)" annotation(
    Placement(transformation(origin = {-100, 18}, extent = {{10, -10}, {-10, 10}})));

  Modelica.Electrical.Analog.Sources.SignalVoltage btnSrc "Drives GP1 from outside" annotation(
    Placement(transformation(origin = {-62, -14}, extent = {{10, -10}, {-10, 10}})));
  Modelica.Blocks.Sources.Pulse pulseSrc(amplitude = 3.3, period = 4, width = 50, startTime = 2) "Square wave on GP1: rising edge at t=2s and t=6s, falling at t=4s and t=8s" annotation(
    Placement(transformation(origin = {-62, 48}, extent = {{-10, -10}, {10, 10}})));
equation
  connect(mcu.GND, ground.p) annotation(
    Line(points = {{0, -14}, {0, -60}}, color = {0, 0, 255}));
  connect(mcu.GP0, r0.n) annotation(
    Line(points = {{-12, 10}, {-32, 10}, {-32, 18}, {-52, 18}}, color = {0, 0, 255}));
  connect(r0.p, led0.p) annotation(
    Line(points = {{-72, 18}, {-90, 18}}, color = {0, 0, 255}));
  connect(led0.n, ground.p) annotation(
    Line(points = {{-110, 18}, {-114, 18}, {-114, -56}, {0, -56}, {0, -60}}, color = {0, 0, 255}));
  connect(pulseSrc.y, btnSrc.v) annotation(
    Line(points = {{-51, 48}, {-47, 48}, {-47, 2}, {-62, 2}, {-62, -2}}, color = {0, 0, 127}));
  connect(mcu.GP1, btnSrc.p) annotation(
    Line(points = {{-12, 4}, {-22, 4}, {-22, -14}, {-52, -14}}, color = {0, 0, 255}));
  connect(btnSrc.n, ground.p) annotation(
    Line(points = {{-72, -14}, {-80, -14}, {-80, -56}, {0, -56}, {0, -60}}, color = {0, 0, 255}));
  annotation(
    Diagram(coordinateSystem(extent = {{-112, -98}, {56, 70}})),
    experiment(StopTime = 8, Interval = 0.001, StartTime = 0, Tolerance = 1e-06),
    Documentation(info = "<html>
<p>Verification scenario 11 (see <code>requirements.md</code>): <code>GP1</code> is driven by a square wave (<code>Modelica.Blocks.Sources.Pulse</code>, rising edge at t=2s/t=6s, falling at t=4s/t=8s). The script <code>pin_irq_demo.py</code> registers <code>Pin(1, Pin.IN).irq(handler=on_rise, trigger=Pin.IRQ_RISING)</code> — only a rising edge must trigger the callback, which toggles <code>led0</code> (GP0). Expected result: <code>GP0</code> toggles at t≈2s and stays unchanged at the falling edge of t≈4s (the LED stays on), proof that the filtering by edge direction works (not \"any edge triggers\"), then toggles again at t≈6s. Pins <code>GP2</code>-<code>GP7</code>, unused by this scenario, are left unconnected.</p>
</html>"));
end Pin;
