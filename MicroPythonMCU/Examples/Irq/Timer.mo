within MicroPythonMCU.Examples.Irq;
model Timer "GP0 drives an LED toggled by a periodic machine.Timer (500 ms) while the main script sleeps once, for a long time - proves that the Timer keeps firing without making this sleep() return early"
  extends Modelica.Icons.Example;
  MCU mcu(scriptPath = Modelica.Utilities.Files.loadResource("modelica://MicroPythonMCU/Resources/Verification/timer_toggle.py")) "scriptPath = Verification/timer_toggle.py" annotation(
    Placement(transformation(origin = {0, 0}, extent = {{-50, -50}, {50, 50}})));
  Modelica.Electrical.Analog.Basic.Ground ground annotation(
    Placement(transformation(origin = {0, -90}, extent = {{-15, -15}, {15, 15}})));

  Modelica.Electrical.Analog.Basic.Resistor r0(R = 330) "limits the current of led0 (GP0)" annotation(
    Placement(transformation(origin = {-90, 25}, extent = {{-15, -15}, {15, 15}})));
  MicroPythonMCU.Peripherals.LED led0 "GP0: toggles every 500 ms, driven by machine.Timer" annotation(
    Placement(transformation(origin = {-142, 25}, extent = {{15, -15}, {-15, 15}}, rotation = -0)));
equation
  connect(mcu.GND, ground.p) annotation(
    Line(points = {{0, -39}, {0, -75}}, color = {0, 0, 255}));
  connect(mcu.GP0, r0.n) annotation(
    Line(points = {{-31, 25}, {-75, 25}}, color = {0, 0, 255}));
  connect(r0.p, led0.p) annotation(
    Line(points = {{-105, 25}, {-127, 25}}, color = {0, 0, 255}));
  connect(led0.n, ground.p) annotation(
    Line(points = {{-157, 25}, {-157, -75}, {0, -75}}, color = {0, 0, 255}));
  annotation(
    Diagram(coordinateSystem(extent = {{-200, -120}, {80, 80}})),
    experiment(StopTime = 2.5, Interval = 0.0005, StartTime = 0, Tolerance = 1e-06),
    Documentation(info = "<html>
<p>Verification scenario 12 (see <code>requirements.md</code>): the script <code>timer_toggle.py</code> arms a <code>Timer(period=500, mode=Timer.PERIODIC)</code> that toggles <code>led0</code> (GP0) every 500 ms, then does a single <code>time.sleep(3600)</code> — without ever reading/writing a pin itself outside the Timer callback. Expected result: <code>GP0</code> toggles at each 500 ms deadline (t≈0.5/1.0/1.5/2.0 s) although nothing changes on any input of the model, proof that the Timer \"pitstop\" mechanism fires independently of the current <code>sleep()</code>, without making it return early (unlike a real input transition, see <code>Examples.Gpio.InputReactivity</code>). Pins <code>GP1</code>-<code>GP7</code>, unused by this scenario, are left unconnected.</p>
</html>"));
end Timer;
