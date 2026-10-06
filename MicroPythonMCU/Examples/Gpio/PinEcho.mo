within MicroPythonMCU.Examples.Gpio;

model PinEcho "GP1 toggles, GP2 reads back its electrical state, GP3 copies what was read (with LEDs on GP1 and GP3 for visualisation)"
  extends Modelica.Icons.Example;
  MCU mcu(scriptPath = Modelica.Utilities.Files.loadResource("modelica://MicroPythonMCU/Resources/Scripts/MCU/pin_echo.py")) "scriptPath = Resources/Scripts/MCU/pin_echo.py" annotation(
    Placement(transformation(origin = {0, 0}, extent = {{-20, -20}, {20, 20}})));
  Modelica.Electrical.Analog.Basic.Ground ground annotation(
    Placement(transformation(origin = {0, -90}, extent = {{-10, -10}, {10, 10}})));
  Modelica.Electrical.Analog.Basic.Resistor r1(R = 330) "limits the current of led1 (GP1, the source)" annotation(
    Placement(transformation(origin = {-90, 10}, extent = {{-10, -10}, {10, 10}})));
  Modelica.Electrical.Analog.Basic.Resistor r3(R = 330) "limits the current of led3 (GP3, the echo)" annotation(
    Placement(transformation(origin = {-90, -24}, extent = {{-10, -10}, {10, 10}})));
  MicroPythonMCU.Peripherals.LED led1 "GP1: toggles (source)" annotation(
    Placement(transformation(origin = {-138, 10}, extent = {{-10, 10}, {10, -10}}, rotation = -180)));
  MicroPythonMCU.Peripherals.LED led3 "GP3: copies what GP2 read on GP1 (echo)" annotation(
    Placement(transformation(origin = {-138, -24}, extent = {{-10, 10}, {10, -10}}, rotation = -180)));
  Modelica.Electrical.Analog.Basic.Resistor loopR(R = 1000) "GP1->GP2 loopback: link resistance. A direct connect() (or an exact algebraic equality through a sensor + ideal source) between GP1 and GP2 turned out to cancel the driven voltage of GP1 in the results (observed empirically, reproduced with several different loopback mechanisms) - worked around by giving GP2 a real dynamic state (see loopC) rather than an exact algebraic alias of GP1, see requirements.md" annotation(
    Placement(transformation(origin = {-56, -8}, extent = {{-10, -10}, {10, 10}})));
  Modelica.Electrical.Analog.Basic.Capacitor loopC(C = 1e-9, v(start = 0, fixed = true)) "Time constant of the loopback (R*C = 1 microsecond, completely negligible compared with PERIOD=0.3s of pin_echo.py): just enough for GP2 to be a real dynamic state rather than an exact algebraic alias of GP1, see loopR" annotation(
    Placement(transformation(origin = {-48, -56}, extent = {{-10, -10}, {10, 10}}, rotation = -90)));
equation
  connect(mcu.GND, ground.p) annotation(
    Line(points = {{0, -14}, {0, -80}}, color = {0, 0, 255}));
  connect(mcu.GP1, r1.n) annotation(
    Line(points = {{-12, 4}, {-36, 4}, {-36, 10}, {-80, 10}}, color = {0, 0, 255}));
  connect(r1.p, led1.p) annotation(
    Line(points = {{-100, 10}, {-128, 10}}, color = {0, 0, 255}));
  connect(led1.n, ground.p) annotation(
    Line(points = {{-148, 10}, {-152, 10}, {-152, -76}, {0, -76}, {0, -80}}, color = {0, 0, 255}));
  connect(mcu.GP3, r3.n) annotation(
    Line(points = {{-12, -10}, {-30, -10}, {-30, -24}, {-80, -24}}, color = {0, 0, 255}));
  connect(r3.p, led3.p) annotation(
    Line(points = {{-100, -24}, {-128, -24}}, color = {0, 0, 255}));
  connect(led3.n, ground.p) annotation(
    Line(points = {{-148, -24}, {-152, -24}, {-152, -76}, {0, -76}, {0, -80}}, color = {0, 0, 255}));
  connect(r1.n, loopR.p) annotation(
    Line(points = {{-80, 10}, {-76, 10}, {-76, -8}, {-66, -8}}, color = {0, 0, 255}));
  connect(loopR.n, mcu.GP2) annotation(
    Line(points = {{-46, -8}, {-24, -8}, {-24, -4}, {-12, -4}}, color = {0, 0, 255}));
  connect(loopR.n, loopC.p) annotation(
    Line(points = {{-46, -8}, {-40, -8}, {-40, -40}, {-48, -40}, {-48, -46}}, color = {0, 0, 255}));
  connect(loopC.n, ground.p) annotation(
    Line(points = {{-48, -66}, {-48, -76}, {0, -76}, {0, -80}}, color = {0, 0, 255}));
  annotation(
    Diagram(coordinateSystem(extent = {{-200, -120}, {80, 80}})),
    experiment(StopTime = 3, Interval = 0.001),
    Documentation(info = "<html>
<p>Demonstrator (outside the verification scenarios of <code>requirements.md</code> — except the dedicated scenario 7, which reuses this model): <code>GP1</code> toggles (on/off every <code>PERIOD</code>=0.3 s, driven by <code>pin_echo.py</code>), <code>GP2</code> reads back the real electrical state of <code>GP1</code> (loopback <code>loopR</code>/<code>loopC</code>, not just the Python variable already known) before copying it to <code>GP3</code>. <code>led1</code> shows the source, <code>led3</code> the echo (no LED on <code>GP2</code>: almost the same potential as <code>GP1</code>, it would duplicate <code>led1</code>). The unused pins (<code>GP0</code>, <code>GP4</code>-<code>GP7</code>) are left unconnected.</p>
<p><b>GP1→GP2 loopback (<code>loopR</code>/<code>loopC</code>) rather than a plain wire</b>: a direct <code>connect(mcu.GP1, mcu.GP2)</code> (or even a sensor + ideal voltage source, electrically equivalent) loses the driven voltage of <code>GP1</code> in the results — observed empirically with several different loopback mechanisms, as long as <code>GP2</code> stays a pure algebraic alias of <code>GP1</code>. Giving <code>GP2</code> a real dynamic state through a negligible RC time constant (1 µs, with no visible effect on the 0.3 s blinking) works around the problem. See <code>requirements.md</code> for the full bisection trace.</p>
<p><b>Sync point needed between the write and the read-back</b>: the script inserts a short <code>time.sleep_ms(1)</code> between <code>pin1.on()</code>/<code>pin1.off()</code> and the reading of <code>pin2.value()</code> — without this sync point, the read would see the state <i>before</i> the write (several consecutive immediate calls stay in the same pass on the C runtime side, without going back through the resolution of the Modelica circuit). See the user guide, page \"machine / time API\" (Limitations section), for the details of this behaviour — it is not a noticeable delay in the result (the input reactivity mechanism, already checked by the <code>Gpio.InputReactivity</code> scenario, wakes the script up as soon as the pin changes, without waiting for the deadline of this sleep).</p>
</html>"));
end PinEcho;
