within MicroPythonMCU.Examples.MultiMcu;

model I2cIrq "I2C between two microcontrollers: B answers the commands of A from an I2CTarget IRQ handler"
  extends Modelica.Icons.Example;
  MCU mcuA(scriptPath = Modelica.Utilities.Files.loadResource("modelica://MicroPythonMCU/Resources/Scripts/MCU/i2c_controller_irq.py")) "Controller: Resources/Scripts/MCU/i2c_controller_irq.py (SCL = GP4, SDA = GP5)" annotation(
    Placement(transformation(origin = {-60, 0}, extent = {{-40, -40}, {40, 40}})));
  MCU mcuB(scriptPath = Modelica.Utilities.Files.loadResource("modelica://MicroPythonMCU/Resources/Scripts/MCU/i2c_target_irq.py")) "Target at 0x43: Resources/Scripts/MCU/i2c_target_irq.py (SCL = GP4, SDA = GP5)" annotation(
    Placement(transformation(origin = {120, 0}, extent = {{-40, -40}, {40, 40}})));
  Modelica.Electrical.Analog.Basic.Ground ground annotation(
    Placement(transformation(origin = {30, -100}, extent = {{-15, -15}, {15, 15}})));
  Modelica.Electrical.Analog.Sources.ConstantVoltage vdd(V = 3.3) "3.3 V supply of the pull-up resistors" annotation(
    Placement(transformation(origin = {30, 60}, extent = {{-10, -10}, {10, 10}}, rotation = -90)));
  Modelica.Electrical.Analog.Basic.Resistor pullScl(R = 4700) "pull-up of SCL: an I2C bus only rises through its pull-ups" annotation(
    Placement(transformation(origin = {60, 70}, extent = {{-10, -10}, {10, 10}})));
  Modelica.Electrical.Analog.Basic.Resistor pullSda(R = 4700) "pull-up of SDA" annotation(
    Placement(transformation(origin = {60, 40}, extent = {{-10, -10}, {10, 10}})));
equation
  connect(mcuA.GND, ground.p) annotation(
    Line(points = {{-60, -31}, {-60, -85}, {30, -85}}, color = {0, 0, 255}));
  connect(mcuB.GND, ground.p) annotation(
    Line(points = {{120, -31}, {120, -85}, {30, -85}}, color = {0, 0, 255}));
// Bus: SCL and SDA shared by both boards, pulled up to 3.3 V
  connect(vdd.n, ground.p) annotation(
    Line(points = {{30, 50}, {30, -85}}, color = {0, 0, 255}));
  connect(vdd.p, pullScl.p) annotation(
    Line(points = {{30, 70}, {50, 70}}, color = {0, 0, 255}));
  connect(vdd.p, pullSda.p) annotation(
    Line(points = {{30, 70}, {40, 70}, {40, 40}, {50, 40}}, color = {0, 0, 255}));
  connect(mcuA.GP4, pullScl.n) annotation(
    Line(points = {{-35, 20}, {0, 20}, {0, 80}, {80, 80}, {80, 70}, {70, 70}}, color = {0, 0, 255}));
  connect(mcuB.GP4, pullScl.n) annotation(
    Line(points = {{145, 20}, {160, 20}, {160, 80}, {80, 80}, {80, 70}, {70, 70}}, color = {0, 0, 255}));
  connect(mcuA.GP5, pullSda.n) annotation(
    Line(points = {{-35, 8}, {10, 8}, {10, 30}, {90, 30}, {90, 40}, {70, 40}}, color = {0, 0, 255}));
  connect(mcuB.GP5, pullSda.n) annotation(
    Line(points = {{145, 8}, {150, 8}, {150, 30}, {90, 30}, {90, 40}, {70, 40}}, color = {0, 0, 255}));
  annotation(
    Diagram(coordinateSystem(extent = {{-120, -140}, {200, 100}})),
    experiment(StopTime = 0.03, Interval = 1e-05, StartTime = 0, Tolerance = 1e-06),
    Documentation(info = "<html>
<p>Same electrical I2C bus as <code>Examples.MultiMcu.I2c</code>, but board B (<code>i2c_target_irq.py</code>) answers <strong>commands</strong> from an IRQ handler instead of exposing a memory. Board A (<code>i2c_controller_irq.py</code>) writes a command, then reads the reply: <code>ID</code> gives <code>MCU-B</code>, <code>CNT</code> gives the number of commands received so far.</p>
<p>In the handler of B, <code>IRQ_END_WRITE</code> means that the command is complete (B reads it with <code>readinto()</code>), and <code>IRQ_READ_REQ</code> that the controller wants a byte while none is queued (B queues the reply with <code>write()</code>). The handler runs at the same simulated instant as the event: the reply is sent at once, without the clock stretching that a real target would need. A sets its <code>GP7</code> high if the three replies are right.</p>
</html>"));
end I2cIrq;
