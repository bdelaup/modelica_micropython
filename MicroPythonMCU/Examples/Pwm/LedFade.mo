within MicroPythonMCU.Examples.Pwm;

model LedFade "GP0 drives an LED in PWM (machine.PWM) at 1 kHz: the duty cycle rises from 0 to 100 % in 1 s, then falls back to 0 in 1 s"
  extends Modelica.Icons.Example;
  MCU mcu(scriptPath = Modelica.Utilities.Files.loadResource("modelica://MicroPythonMCU/Resources/Scripts/MCU/pwm_led_fade.py")) "scriptPath = Resources/Scripts/MCU/pwm_led_fade.py" annotation(
    Placement(transformation(origin = {0, 0}, extent = {{-20, -20}, {20, 20}})));
  Modelica.Electrical.Analog.Basic.Ground ground annotation(
    Placement(transformation(origin = {0, -62}, extent = {{-10, -10}, {10, 10}})));
  Modelica.Electrical.Analog.Basic.Resistor r0(R = 330) "limits the current of led0 (GP0)" annotation(
    Placement(transformation(origin = {-62, 18}, extent = {{-10, -10}, {10, 10}})));
  MicroPythonMCU.Peripherals.LED led0 "GP0: PWM at 1 kHz, varying duty cycle (fade in, fade out)" annotation(
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
    experiment(StopTime = 4, Interval = 0.008, StartTime = 0, Tolerance = 1e-06),
    Documentation(info = "<html>
<p>Demonstrator (outside the verification scenarios): the script <code>pwm_led_fade.py</code> sets <code>GP0</code> as a 1 kHz PWM output, waits 0.5 s, raises the duty cycle from 0 to 100 % in 1000 steps of 1 ms (<code>duty_u16()</code> called at each step), waits 0.5 s, lowers it back to 0 the same way, then releases the pin (<code>deinit()</code>). Unlike <code>Examples.Pwm.Led</code>, where the duty cycle is set once, it changes here while running: each call to <code>duty_u16()</code> is taken into account at the next sync point, and the square wave is still generated on the Modelica side between two calls. <code>led0</code> lights up then dims gradually when the result is replayed with animation in OMEdit. Pins <code>GP1</code>-<code>GP7</code>, unused by this scenario, are left unconnected.</p>
</html>"));
end LedFade;
