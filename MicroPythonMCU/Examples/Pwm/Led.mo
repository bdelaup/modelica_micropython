within MicroPythonMCU.Examples.Pwm;

model Led "GP0 drives an LED in PWM (machine.PWM), 200 Hz / ~30% duty cycle, set once then generated continuously on the Modelica side"
  extends Modelica.Icons.Example;
  MCU mcu(scriptPath = Modelica.Utilities.Files.loadResource("modelica://MicroPythonMCU/Resources/Scripts/MCU/pwm_led.py")) "scriptPath = Resources/Scripts/MCU/pwm_led.py" annotation(
    Placement(transformation(origin = {0, 0}, extent = {{-20, -20}, {20, 20}})));
  Modelica.Electrical.Analog.Basic.Ground ground annotation(
    Placement(transformation(origin = {0, -62}, extent = {{-10, -10}, {10, 10}})));
  Modelica.Electrical.Analog.Basic.Resistor r0(R = 330) "limits the current of led0 (GP0)" annotation(
    Placement(transformation(origin = {-62, 18}, extent = {{-10, -10}, {10, 10}})));
  MicroPythonMCU.Peripherals.LED led0 "GP0: PWM square wave (200 Hz, ~30%)" annotation(
    Placement(transformation(origin = {-98, 18}, extent = {{-10, 10}, {10, -10}}, rotation = -180)));
equation
  connect(mcu.GND, ground.p) annotation(
    Line(points = {{0, -14}, {0, -52}}, color = {0, 0, 255}));
  connect(mcu.GP0, r0.n) annotation(
    Line(points = {{-12, 10}, {-32, 10}, {-32, 18}, {-52, 18}}, color = {0, 0, 255}));
  connect(r0.p, led0.p) annotation(
    Line(points = {{-72, 18}, {-88, 18}}, color = {0, 0, 255}));
  connect(led0.n, ground.p) annotation(
    Line(points = {{-108, 18}, {-112, 18}, {-112, -48}, {0, -48}, {0, -52}}, color = {0, 0, 255}));
  annotation(
    Diagram(coordinateSystem(extent = {{-140, -84}, {56, 56}})),
    experiment(StopTime = 0.5, Interval = 0.00002),
    Documentation(info = "<html>
<p>Verification scenario 9 (see <code>requirements.md</code>): <code>GP0</code> is configured as a PWM output (<code>machine.PWM</code>) rather than as a plain digital pin — the script <code>pwm_led.py</code> calls <code>PWM(Pin(0))</code>, <code>freq(200)</code> and <code>duty_u16(19661)</code> (~30%) only once then ends: the square wave is then generated continuously on the Modelica side (expression <code>mod(time, period)</code> in <code>MCU.mo</code>), without any further round trip with the Python thread — true to the real PWM hardware peripheral of the RP2040, which runs independently of the CPU once configured. <code>led0</code> makes the duty cycle visually observable (reduced brightness compared with a digital GPIO permanently on). Pins <code>GP1</code>-<code>GP7</code>, unused by this scenario, are left unconnected.</p>
</html>"));
end Led;
