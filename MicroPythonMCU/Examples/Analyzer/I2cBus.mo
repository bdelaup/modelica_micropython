within MicroPythonMCU.Examples.Analyzer;

model I2cBus "A logic analyser probe decodes the I2C bus of I2c.Echo into a text file: addresses, bytes, acknowledgements, repeated START"
  extends I2c.Echo;
  MicroPythonMCU.Peripherals.Analyzers.LogicAnalyzer analyzer(ch0Name = "SCL", ch1Kind = MicroPythonMCU.Interfaces.ChannelKind.I2cSda, ch1Name = "SDA", ch1ClockChannel = 0, ch2Name = "LED7", ch3Kind = MicroPythonMCU.Interfaces.ChannelKind.Off, ch4Kind = MicroPythonMCU.Interfaces.ChannelKind.Off, ch5Kind = MicroPythonMCU.Interfaces.ChannelKind.Off, ch6Kind = MicroPythonMCU.Interfaces.ChannelKind.Off, ch7Kind = MicroPythonMCU.Interfaces.ChannelKind.Off) "CH0 = SCL (Logic, clock of CH1), CH1 = SDA (I2cSda), CH2 = indicator GP7 (Logic)" annotation(
    Placement(transformation(origin = {170, 10}, extent = {{-40, -40}, {40, 40}})));
equation
  connect(analyzer.CH0, mcu.GP4) annotation(
    Line(points = {{130, 38}, {110, 38}, {110, 70}, {-50, 70}, {-50, 25}, {-59, 25}}, color = {0, 0, 255}));
  connect(analyzer.CH1, mcu.GP5) annotation(
    Line(points = {{130, 30}, {104, 30}, {104, 64}, {-44, 64}, {-44, 10}, {-59, 10}}, color = {0, 0, 255}));
  connect(analyzer.CH2, mcu.GP7) annotation(
    Line(points = {{130, 22}, {98, 22}, {98, -60}, {-55, -60}, {-55, -25}, {-59, -25}}, color = {0, 0, 255}));
  connect(analyzer.GND, ground.p) annotation(
    Line(points = {{170, -30}, {170, -70}, {-25, -70}}, color = {0, 0, 255}));
  annotation(
    Diagram(coordinateSystem(extent = {{-160, -100}, {220, 80}})),
    experiment(StopTime = 0.01, Interval = 1e-5),
    Documentation(info = "<html>
<p>The circuit of <code>Examples.I2c.Echo</code> (write of <code>Hello I2C</code> to the echo at <code>0x42</code>, read back, register read behind a repeated START), plus a <strong>logic analyser probe</strong>: <code>CH0</code> on SCL, <code>CH1</code> on SDA, <code>CH2</code> on the indicator <code>GP7</code>.</p>
<p>The SCL channel is a plain <code>Logic</code> channel; the SDA channel is of kind <code>I2cSda</code> and names its clock channel (<code>ch1ClockChannel = 0</code>). In <code>I2cBus.analyzer.txt</code>, each transaction gives one line in hexadecimal + ASCII (<code>S [42 W] 48 65 6C 6C 6F 20 49 32 43 P</code>; <code>*</code> after a byte not acknowledged, as the last byte of a read), then a frame of the timing diagram with the bits read on each rising edge of SCL, the acknowledgements (<code>A</code>, <code>N</code>), the repeated START (<code>Sr</code>) and the STOP (<code>P</code>). The indicator lights up at the end of the last transaction.</p>
</html>"));
end I2cBus;
