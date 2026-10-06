within MicroPythonMCU.Examples.Adc;

model Read "GP1 used as an analog input (machine.ADC), driven by an external voltage divider; the script copies a threshold to GP0 (LED) to make the reading observable"
  extends Modelica.Icons.Example;
  MCU mcu(scriptPath = Modelica.Utilities.Files.loadResource("modelica://MicroPythonMCU/Resources/Scripts/MCU/adc_read.py")) "scriptPath = Resources/Scripts/MCU/adc_read.py" annotation(
    Placement(transformation(origin = {0, 0}, extent = {{-20, -20}, {20, 20}})));
  Modelica.Electrical.Analog.Basic.Ground ground annotation(
    Placement(transformation(origin = {0, -62}, extent = {{-10, -10}, {10, 10}})));
  Modelica.Electrical.Analog.Basic.Resistor r0(R = 330) "limits the current of led0 (GP0)" annotation(
    Placement(transformation(origin = {-62, 18}, extent = {{-10, -10}, {10, 10}})));
  MicroPythonMCU.Peripherals.LED led0 "GP0: copy of (v > half of the ADC scale)?" annotation(
    Placement(transformation(origin = {-98, 18}, extent = {{-10, 10}, {10, -10}}, rotation = -180)));
  Modelica.Electrical.Analog.Sources.ConstantVoltage supply(V = 3.3) "supply of the voltage divider (independent of MCU)" annotation(
    Placement(transformation(origin = {-88, -26}, extent = {{-10, -10}, {10, 10}}, rotation = -90)));
  Modelica.Electrical.Analog.Basic.Resistor rTop(R = 1000) "top of the voltage divider" annotation(
    Placement(transformation(origin = {-62, -8}, extent = {{-10, -10}, {10, 10}})));
  Modelica.Electrical.Analog.Basic.Resistor rBot(R = 2000) "bottom of the voltage divider: GP1 reads ~3.3*2/3 = 2.2 V" annotation(
    Placement(transformation(origin = {-52, -36}, extent = {{-10, -10}, {10, 10}}, rotation = -90)));
equation
  connect(mcu.GND, ground.p) annotation(
    Line(points = {{0, -14}, {0, -52}}, color = {0, 0, 255}));
  connect(mcu.GP0, r0.n) annotation(
    Line(points = {{-12, 10}, {-32, 10}, {-32, 18}, {-52, 18}}, color = {0, 0, 255}));
  connect(r0.p, led0.p) annotation(
    Line(points = {{-72, 18}, {-88, 18}}, color = {0, 0, 255}));
  connect(led0.n, ground.p) annotation(
    Line(points = {{-108, 18}, {-112, 18}, {-112, -48}, {0, -48}, {0, -52}}, color = {0, 0, 255}));
  connect(supply.n, ground.p) annotation(
    Line(points = {{-88, -36}, {-88, -48}, {0, -48}, {0, -52}}, color = {0, 0, 255}));
  connect(supply.p, rTop.p) annotation(
    Line(points = {{-88, -16}, {-88, -8}, {-72, -8}}, color = {0, 0, 255}));
  connect(rTop.n, rBot.p) annotation(
    Line(points = {{-52, -8}, {-48, -8}, {-48, -22}, {-52, -22}, {-52, -26}}, color = {0, 0, 255}));
  connect(rTop.n, mcu.GP1) annotation(
    Line(points = {{-52, -8}, {-32, -8}, {-32, 4}, {-12, 4}}, color = {0, 0, 255}));
  connect(rBot.n, ground.p) annotation(
    Line(points = {{-52, -46}, {-52, -48}, {0, -48}, {0, -52}}, color = {0, 0, 255}));
  annotation(
    Diagram(coordinateSystem(extent = {{-154, -84}, {56, 56}})),
    experiment(StopTime = 1, Interval = 0.001),
    Documentation(info = "<html>
<p>Verification scenario 8 (see <code>requirements.md</code>): <code>GP1</code> is used as an analog input (<code>machine.ADC(1)</code>) rather than as a digital pin — an external voltage divider (<code>supply</code>/<code>rTop</code>/<code>rBot</code>, independent of <code>MCU</code>) sets it to ~2.2 V (3.3 V × 2000/3000). The script <code>adc_read.py</code> reads <code>ADC(1).read_u16()</code> and drives <code>Pin(0, Pin.OUT)</code> according to a threshold (half of the 16-bit scale) — <code>led0</code> makes this threshold observable, acting as a probe that validates the whole pipeline (voltage division → ADC → threshold → output) without relying on reading a float directly. Pins <code>GP2</code>-<code>GP7</code>, unused by this scenario, are left unconnected.</p>
</html>"));
end Read;
