within MicroPythonMCU.Examples.Adc;

model Read "GP1 used as an analog input (machine.ADC), driven by an external voltage divider; the script copies a threshold to GP0 (LED) to make the reading observable"
  extends Modelica.Icons.Example;
  MCU mcu(scriptPath = Modelica.Utilities.Files.loadResource("modelica://MicroPythonMCU/Resources/Scripts/MCU/adc_read.py")) "scriptPath = Resources/Scripts/MCU/adc_read.py" annotation(
    Placement(transformation(origin = {0, 0}, extent = {{-50, -50}, {50, 50}})));
  Modelica.Electrical.Analog.Basic.Ground ground annotation(
    Placement(transformation(origin = {0, -90}, extent = {{-15, -15}, {15, 15}})));
  Modelica.Electrical.Analog.Basic.Resistor r0(R = 330) "limits the current of led0 (GP0)" annotation(
    Placement(transformation(origin = {-90, 25}, extent = {{-15, -15}, {15, 15}})));
  MicroPythonMCU.Peripherals.LED led0 "GP0: copy of (v > half of the ADC scale)?" annotation(
    Placement(transformation(origin = {-140, 25}, extent = {{-15, 15}, {15, -15}}, rotation = -180)));
  Modelica.Electrical.Analog.Sources.ConstantVoltage supply(V = 3.3) "supply of the voltage divider (independent of MCU)" annotation(
    Placement(transformation(origin = {-126, -36}, extent = {{-15, -15}, {15, 15}}, rotation = -90)));
  Modelica.Electrical.Analog.Basic.Resistor rTop(R = 1000) "top of the voltage divider" annotation(
    Placement(transformation(origin = {-90, -10}, extent = {{-15, -15}, {15, 15}})));
  Modelica.Electrical.Analog.Basic.Resistor rBot(R = 2000) "bottom of the voltage divider: GP1 reads ~3.3*2/3 = 2.2 V" annotation(
    Placement(transformation(origin = {-74, -50}, extent = {{-15, -15}, {15, 15}}, rotation = -90)));
equation
  connect(mcu.GND, ground.p) annotation(
    Line(points = {{0, -39}, {0, -75}}, color = {0, 0, 255}));
  connect(mcu.GP0, r0.n) annotation(
    Line(points = {{-31, 25}, {-75, 25}}, color = {0, 0, 255}));
  connect(r0.p, led0.p) annotation(
    Line(points = {{-105, 25}, {-125, 25}}, color = {0, 0, 255}));
  connect(led0.n, ground.p) annotation(
    Line(points = {{-155, 25}, {-155, -75}, {0, -75}}, color = {0, 0, 255}));
  connect(supply.n, ground.p) annotation(
    Line(points = {{-126, -51}, {-126, -75}, {0, -75}}, color = {0, 0, 255}));
  connect(supply.p, rTop.p) annotation(
    Line(points = {{-126, -21}, {-126, -10}, {-105, -10}}, color = {0, 0, 255}));
  connect(rTop.n, rBot.p) annotation(
    Line(points = {{-75, -10}, {-75, -35}, {-74, -35}}, color = {0, 0, 255}));
  connect(rTop.n, mcu.GP1) annotation(
    Line(points = {{-75, -10}, {-75, 10}, {-31, 10}}, color = {0, 0, 255}));
  connect(rBot.n, ground.p) annotation(
    Line(points = {{-74, -65}, {-74, -75}, {0, -75}}, color = {0, 0, 255}));
  annotation(
    Diagram(coordinateSystem(extent = {{-220, -120}, {80, 80}})),
    experiment(StopTime = 1, Interval = 0.001),
    Documentation(info = "<html>
<p>Verification scenario 8 (see <code>requirements.md</code>): <code>GP1</code> is used as an analog input (<code>machine.ADC(1)</code>) rather than as a digital pin — an external voltage divider (<code>supply</code>/<code>rTop</code>/<code>rBot</code>, independent of <code>MCU</code>) sets it to ~2.2 V (3.3 V × 2000/3000). The script <code>adc_read.py</code> reads <code>ADC(1).read_u16()</code> and drives <code>Pin(0, Pin.OUT)</code> according to a threshold (half of the 16-bit scale) — <code>led0</code> makes this threshold observable, acting as a probe that validates the whole pipeline (voltage division → ADC → threshold → output) without relying on reading a float directly. Pins <code>GP2</code>-<code>GP7</code>, unused by this scenario, are left unconnected.</p>
</html>"));
end Read;
