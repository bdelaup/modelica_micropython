within MicroPythonMCU.Examples.MultiMcu;

model I2c "I2C between two microcontrollers: A is the controller, B is a target that behaves as a memory (machine.I2CTarget with mem=)"
  extends Modelica.Icons.Example;
  MCU mcuA(scriptPath = Modelica.Utilities.Files.loadResource("modelica://MicroPythonMCU/Resources/Scripts/MCU/i2c_controller.py")) "Controller: Resources/Scripts/MCU/i2c_controller.py (SCL = GP4, SDA = GP5)" annotation(
    Placement(transformation(origin = {-60, 0}, extent = {{-40, -40}, {40, 40}})));
  MCU mcuB(scriptPath = Modelica.Utilities.Files.loadResource("modelica://MicroPythonMCU/Resources/Scripts/MCU/i2c_target_mem.py")) "Target at 0x42: Resources/Scripts/MCU/i2c_target_mem.py (SCL = GP4, SDA = GP5)" annotation(
    Placement(transformation(origin = {120, 0}, extent = {{-40, -40}, {40, 40}})));
  Modelica.Electrical.Analog.Basic.Ground ground annotation(
    Placement(transformation(origin = {30, -100}, extent = {{-15, -15}, {15, 15}})));
  Modelica.Electrical.Analog.Sources.ConstantVoltage vdd(V = 3.3) "3.3 V supply of the pull-up resistors" annotation(
    Placement(transformation(origin = {30, 60}, extent = {{-10, -10}, {10, 10}}, rotation = -90)));
  Modelica.Electrical.Analog.Basic.Resistor pullScl(R = 4700) "pull-up of SCL: an I2C bus only rises through its pull-ups" annotation(
    Placement(transformation(origin = {60, 70}, extent = {{-10, -10}, {10, 10}})));
  Modelica.Electrical.Analog.Basic.Resistor pullSda(R = 4700) "pull-up of SDA" annotation(
    Placement(transformation(origin = {60, 40}, extent = {{-10, -10}, {10, 10}})));
  Modelica.Electrical.Analog.Sources.ConstantVoltage measured(V = 2) "voltage measured by B on GP2 (ADC), read by A through the bus" annotation(
    Placement(transformation(origin = {80, -40}, extent = {{-10, -10}, {10, 10}}, rotation = -90)));
  Modelica.Electrical.Analog.Basic.Resistor r3(R = 330) "limits the current of ledB" annotation(
    Placement(transformation(origin = {170, -40}, extent = {{-10, -10}, {10, 10}})));
  MicroPythonMCU.Peripherals.LED ledB "mcuB GP3: switched on by A, which writes register 4 of B" annotation(
    Placement(transformation(origin = {170, -70}, extent = {{-10, -10}, {10, 10}}, rotation = -90)));
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
// Board B: measured voltage and LED
  connect(measured.p, mcuB.GP2) annotation(
    Line(points = {{80, -30}, {80, -8}, {95, -8}}, color = {0, 0, 255}));
  connect(measured.n, ground.p) annotation(
    Line(points = {{80, -50}, {80, -85}, {30, -85}}, color = {0, 0, 255}));
  connect(mcuB.GP3, r3.p) annotation(
    Line(points = {{95, -20}, {90, -20}, {90, -60}, {150, -60}, {150, -40}, {160, -40}}, color = {0, 0, 255}));
  connect(r3.n, ledB.p) annotation(
    Line(points = {{180, -40}, {180, -60}, {170, -60}}, color = {0, 0, 255}));
  connect(ledB.n, ground.p) annotation(
    Line(points = {{170, -80}, {170, -85}, {30, -85}}, color = {0, 0, 255}));
  annotation(
    Diagram(coordinateSystem(extent = {{-120, -140}, {200, 100}})),
    experiment(StopTime = 0.06, Interval = 1e-05, StartTime = 0, Tolerance = 1e-06),
    Documentation(info = "<html>
<p>Electrical I2C bus (open drain, 100 kHz) between two <code>MCU</code> blocks: SCL and SDA are shared by both boards and only rise through the two 4.7 kΩ pull-up resistors, as on a real bus. Board A (<code>i2c_controller.py</code>) is the controller (<code>machine.I2C</code>); board B (<code>i2c_target_mem.py</code>) is a target at address <code>0x42</code> (<code>machine.I2CTarget</code>) that exposes a <code>bytearray</code> as a memory: it needs no handler, the library answers the controller on its own while the program of B only keeps the memory up to date.</p>
<p>Register map of B: bytes 0-1 = last ADC reading of its <code>GP2</code> (2 V here), byte 4 = its LED. A scans the bus (it finds <code>0x42</code>), writes 1 to register 4 (<code>writeto_mem</code>: <code>ledB</code> lights up), reads back registers 0-1 (<code>readfrom_mem</code>) and prints the voltage measured by B; its <code>GP7</code> goes high if everything is right. Variant where B answers from an IRQ handler: <code>Examples.MultiMcu.I2cIrq</code>.</p>
</html>"));
end I2c;
