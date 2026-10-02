within MicroPythonMCU.Examples.Gpio;
model Timing "Time cost of GPIO accesses (gpioOpTime): on()/off() pulse without sleep, bit-bang burst, busy wait, masked IRQ, idle(), high()/low()"
  extends Modelica.Icons.Example;
  MCU mcu(scriptPath = Modelica.Utilities.Files.loadResource("modelica://MicroPythonMCU/Resources/Verification/gpio_timing.py")) "scriptPath = Verification/gpio_timing.py; default gpioOpTime (5 µs)" annotation(
    Placement(transformation(origin = {0, 0}, extent = {{-50, -50}, {50, 50}})));
  Modelica.Electrical.Analog.Basic.Ground ground annotation(
    Placement(transformation(origin = {0, -100}, extent = {{-15, -15}, {15, 15}})));
  Modelica.Electrical.Analog.Basic.Resistor rLoad(R = 10e3) "Load of GP0, the pulse pin" annotation(
    Placement(transformation(origin = {-90, 25}, extent = {{-15, -15}, {15, 15}})));
  Modelica.Electrical.Analog.Sources.SignalVoltage inSrc "Drives GP1: the input watched by the busy wait" annotation(
    Placement(transformation(origin = {-90, -20}, extent = {{15, -15}, {-15, 15}})));
  Modelica.Blocks.Sources.Step inStep(height = 3.3, startTime = 0.3) "Rising edge on GP1 at t = 300 ms" annotation(
    Placement(transformation(origin = {-90, 70}, extent = {{-15, -15}, {15, 15}})));
  Modelica.Electrical.Analog.Sources.SignalVoltage irqSrc "Drives GP3: the IRQ input" annotation(
    Placement(transformation(origin = {-90, -60}, extent = {{15, -15}, {-15, 15}})));
  Modelica.Blocks.Sources.Step irqStep(height = 3.3, startTime = 0.45) "Rising edge on GP3 at t = 450 ms, while IRQs are masked" annotation(
    Placement(transformation(origin = {-140, -60}, extent = {{-15, -15}, {15, 15}})));
  Boolean gp0High = mcu.GP0.v > 1.65 "GP0 as seen by an external observer";
  discrete Modelica.Units.SI.Time tRise(start = 0, fixed = true) "Last rising edge of GP0";
  discrete Modelica.Units.SI.Time pulseWidth(start = 0, fixed = true) "Width of the last pulse of GP0, measured on the Modelica side";
  discrete Integer pulseCount(start = 0, fixed = true) "Number of pulses seen on GP0";
  discrete Modelica.Units.SI.Time tFlag(start = -1, fixed = true) "Instant when GP2 rises: exit of the busy wait";
  discrete Modelica.Units.SI.Time tIrq(start = -1, fixed = true) "Instant when GP4 rises: execution of the IRQ callback";
equation
  when gp0High then
    tRise = time;
    pulseCount = pre(pulseCount) + 1;
  end when;
  when not gp0High then
    pulseWidth = time - pre(tRise);
  end when;
  when mcu.GP2.v > 1.65 then
    tFlag = time;
  end when;
  when mcu.GP4.v > 1.65 then
    tIrq = time;
  end when;
  connect(mcu.GND, ground.p) annotation(
    Line(points = {{0, -39}, {0, -85}}, color = {0, 0, 255}));
  connect(mcu.GP0, rLoad.n) annotation(
    Line(points = {{-31, 25}, {-75, 25}}, color = {0, 0, 255}));
  connect(rLoad.p, ground.p) annotation(
    Line(points = {{-105, 25}, {-157, 25}, {-157, -85}, {0, -85}}, color = {0, 0, 255}));
  connect(inStep.y, inSrc.v) annotation(
    Line(points = {{-90, 54}, {-90, -8}}, color = {0, 0, 127}));
  connect(mcu.GP1, inSrc.p) annotation(
    Line(points = {{-31, 10}, {-31, -20}, {-75, -20}}, color = {0, 0, 255}));
  connect(inSrc.n, ground.p) annotation(
    Line(points = {{-105, -20}, {-115, -20}, {-115, -85}, {0, -85}}, color = {0, 0, 255}));
  connect(irqStep.y, irqSrc.v) annotation(
    Line(points = {{-124, -60}, {-110, -60}, {-110, -40}, {-90, -40}, {-90, -48}}, color = {0, 0, 127}));
  connect(mcu.GP3, irqSrc.p) annotation(
    Line(points = {{-31, -25}, {-50, -25}, {-50, -60}, {-75, -60}}, color = {0, 0, 255}));
  connect(irqSrc.n, ground.p) annotation(
    Line(points = {{-105, -60}, {-115, -60}, {-115, -85}, {0, -85}}, color = {0, 0, 255}));
  annotation(
    Diagram(coordinateSystem(extent = {{-170, -120}, {80, 100}})),
    experiment(StopTime = 0.6, Interval = 0.001, StartTime = 0, Tolerance = 1e-06),
    Documentation(info = "<html>
<p>Verification scenario 28: the <strong>time cost of GPIO accesses</strong>. Each <code>Pin.value()</code>, <code>on()</code>, <code>off()</code> or <code>pin(x)</code> keeps the processor busy for <code>mcu.gpioOpTime</code> (5 µs by default, the order of magnitude of MicroPython on RP2040): two writes without <code>sleep()</code> between them therefore give a real pulse, visible by the circuit. This is what enables <em>bit-banging</em> (the HX711 driver, for instance).</p>
<p>The script <code>Verification/gpio_timing.py</code> runs, at fixed instants:</p>
<ul>
<li>t = 100 ms: <code>on()</code> then <code>off()</code> on GP0 → a 5 µs pulse (<code>pulseWidth</code>, measured here on the Modelica side);</li>
<li>t = 200 ms: 10 pulses through <code>out(1); out(0)</code> → 11 pulses in total (<code>pulseCount</code>), and the script measures 100 µs with <code>ticks_us()</code>;</li>
<li>t = 280 ms: busy wait <code>while not inp(): pass</code>, without <code>sleep()</code>: time moves forward by 5 µs per read, and the edge of GP1 at t = 300 ms is seen → GP2 rises just after (<code>tFlag</code>);</li>
<li>t = 400 ms: <code>disable_irq()</code>; the edge of GP3 at t = 450 ms does not trigger the callback right away, it runs at <code>enable_irq()</code>, at t = 500 ms (<code>tIrq</code>, GP4);</li>
<li><code>idle()</code> returns at the next whole millisecond;</li>
<li>t = 550 ms: <code>high()</code> then <code>low()</code> (aliases of <code>on()</code>/<code>off()</code> on the rp2 port) → a last 5 µs pulse, 12 in total.</li>
</ul>
<p>The script shows <code>dt=100 id=0</code> on the <code>Display0</code> link (duration of the burst in µs, remainder of <code>ticks_us()</code> modulo 1000 after <code>idle()</code>).</p>
</html>"));
end Timing;
