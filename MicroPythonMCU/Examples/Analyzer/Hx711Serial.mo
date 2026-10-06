within MicroPythonMCU.Examples.Analyzer;

model Hx711Serial "A logic analyser probe decodes the clock/data link of an HX711 (synchronous serial, 24-bit words MSB first)"
  extends Weighing.Hx711Read;
  MicroPythonMCU.Peripherals.Analyzers.LogicAnalyzer analyzer(ch0Name = "PD_SCK", ch1Kind = MicroPythonMCU.Interfaces.ChannelKind.SyncData, ch1Name = "DOUT", ch1ClockChannel = 0, ch1ClockEdge = MicroPythonMCU.Interfaces.ClockEdge.Falling, ch1WordBits = 24, ch1Signed = true, ch2Kind = MicroPythonMCU.Interfaces.ChannelKind.Off, ch3Kind = MicroPythonMCU.Interfaces.ChannelKind.Off, ch4Kind = MicroPythonMCU.Interfaces.ChannelKind.Off, ch5Kind = MicroPythonMCU.Interfaces.ChannelKind.Off, ch6Kind = MicroPythonMCU.Interfaces.ChannelKind.Off, ch7Kind = MicroPythonMCU.Interfaces.ChannelKind.Off) "CH0 = PD_SCK (Logic, clock of CH1), CH1 = DOUT (SyncData: read on the falling edge, 24-bit signed words, MSB first)" annotation(
    Placement(transformation(origin = {100, -100}, extent = {{-20, -20}, {20, 20}})));
equation
  connect(analyzer.CH0, mcu.GP6) annotation(
    Line(points = {{82, -86}, {34, -86}, {34, -4}, {12, -4}}, color = {0, 0, 255}));
  connect(analyzer.CH1, mcu.GP7) annotation(
    Line(points = {{82, -90}, {30, -90}, {30, -10}, {12, -10}}, color = {0, 0, 255}));
  connect(analyzer.GND, ground.p) annotation(
    Line(points = {{100, -118}, {100, -122}, {124, -122}, {124, -56}, {-20, -56}, {-20, -60}}, color = {0, 0, 255}));
  annotation(
    Diagram(coordinateSystem(extent = {{-40, -130}, {330, 60}})),
    experiment(StopTime = 1, Interval = 0.001, StartTime = 0, Tolerance = 1e-06),
    Documentation(info = "<html>
<p>The circuit of <code>Examples.Weighing.Hx711Read</code>, plus a <strong>logic analyser probe</strong> on the two-wire link of the HX711: <code>CH0</code> on <code>PD_SCK</code> (clock, driven by the microcontroller), <code>CH1</code> on <code>DOUT</code> (data, driven by the converter).</p>
<p>The data channel is of kind <code>SyncData</code>: read on the falling edge of its clock channel (<code>ch1ClockChannel = 0</code>, <code>ch1ClockEdge = Falling</code>), in words of 24 bits, most significant bit first, in two's complement. In <code>Hx711Serial.analyzer.txt</code>, each conversion gives one line (<code>068DB9 = 429497   + 1 extra clock pulse</code>): the 25th, 26th or 27th pulse selects the gain of the next conversion (128, 32, 64). The timing diagram shows each burst of 25 to 27 pulses as a frame, and the 100 ms between two conversions as a single line of silence.</p>
</html>"));
end Hx711Serial;
