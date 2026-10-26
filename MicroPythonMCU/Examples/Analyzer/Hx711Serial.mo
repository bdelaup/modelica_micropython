within MicroPythonMCU.Examples.Analyzer;

model Hx711Serial "A logic analyser probe decodes the clock/data link of an HX711 (synchronous serial, 24-bit words MSB first)"
  extends Modelica.Icons.Example;
  MCU mcu(scriptPath = Modelica.Utilities.Files.loadResource("modelica://MicroPythonMCU/Resources/Scripts/MCU/hx711_read.py")) "scriptPath = Resources/Scripts/MCU/hx711_read.py - imports the driver hx711_gpio.py placed next to it (robert-hh, unchanged)" annotation(
    Placement(transformation(origin = {0, 0}, extent = {{-20, -20}, {20, 20}})));
  MicroPythonMCU.Peripherals.Display display "Codes read by the microcontroller" annotation(
    Placement(transformation(origin = {60, 40}, extent = {{-20, -20}, {20, 20}})));
  MicroPythonMCU.Peripherals.Weighing.Hx711 hx "Converter, without noise: the codes read are exactly predictable" annotation(
    Placement(transformation(origin = {60, -20}, extent = {{-20, -20}, {20, 20}})));
  MicroPythonMCU.Peripherals.Weighing.WheatstoneBridge bridge annotation(
    Placement(transformation(origin = {130, -20}, extent = {{-20, -20}, {20, 20}})));
  MicroPythonMCU.Peripherals.Weighing.LoadCell loadCell "5 kg load cell body" annotation(
    Placement(transformation(origin = {190, -20}, extent = {{-20, -20}, {20, 20}})));
  Modelica.Mechanics.Translational.Sources.Force weight "The weight of the mass placed" annotation(
    Placement(transformation(origin = {230, -20}, extent = {{10, -10}, {-10, 10}})));
  Modelica.Blocks.Math.Gain g(k = Modelica.Constants.g_n) "Weight = mass × g" annotation(
    Placement(transformation(origin = {270, -20}, extent = {{10, -10}, {-10, 10}})));
  Modelica.Blocks.Sources.Constant mass(k = 1) "Mass placed: 1 kg" annotation(
    Placement(transformation(origin = {310, -20}, extent = {{10, -10}, {-10, 10}})));
  Modelica.Electrical.Analog.Basic.Ground ground annotation(
    Placement(transformation(origin = {-20, -70}, extent = {{-10, -10}, {10, 10}})));
  MicroPythonMCU.Peripherals.Analyzers.LogicAnalyzer analyzer(ch0Name = "PD_SCK", ch1Kind = MicroPythonMCU.Interfaces.ChannelKind.SyncData, ch1Name = "DOUT", ch1ClockChannel = 0, ch1ClockEdge = MicroPythonMCU.Interfaces.ClockEdge.Falling, ch1WordBits = 24, ch1Signed = true, ch2Kind = MicroPythonMCU.Interfaces.ChannelKind.Off, ch3Kind = MicroPythonMCU.Interfaces.ChannelKind.Off, ch4Kind = MicroPythonMCU.Interfaces.ChannelKind.Off, ch5Kind = MicroPythonMCU.Interfaces.ChannelKind.Off, ch6Kind = MicroPythonMCU.Interfaces.ChannelKind.Off, ch7Kind = MicroPythonMCU.Interfaces.ChannelKind.Off) "CH0 = PD_SCK (Logic, clock of CH1), CH1 = DOUT (SyncData: read on the falling edge, 24-bit signed words, MSB first)" annotation(
    Placement(transformation(origin = {100, -100}, extent = {{-20, -20}, {20, 20}})));
equation
  connect(mcu.Display0, display.displayLink) annotation(
    Line(points = {{10, 14}, {10, 40}, {38, 40}}));
// Program pinout: PD_SCK on GP6, DOUT on GP7
  connect(mcu.GP6, hx.PD_SCK) annotation(
    Line(points = {{12, -4}, {24, -4}, {24, -14}, {38, -14}}, color = {0, 0, 255}));
  connect(mcu.GP7, hx.DOUT) annotation(
    Line(points = {{12, -10}, {20, -10}, {20, -26}, {38, -26}}, color = {0, 0, 255}));
  connect(hx.E_plus, bridge.E_plus) annotation(
    Line(points = {{82, -14}, {108, -14}}, color = {0, 0, 255}));
  connect(hx.A_plus, bridge.S_plus) annotation(
    Line(points = {{82, -18}, {108, -18}}, color = {0, 0, 255}));
  connect(hx.A_minus, bridge.S_minus) annotation(
    Line(points = {{82, -22}, {108, -22}}, color = {0, 0, 255}));
  connect(hx.E_minus, bridge.E_minus) annotation(
    Line(points = {{82, -26}, {108, -26}}, color = {0, 0, 255}));
  connect(loadCell.eps, bridge.eps) annotation(
    Line(points = {{168, -20}, {152, -20}}, color = {0, 0, 127}));
  connect(weight.flange, loadCell.flange) annotation(
    Line(points = {{220, -20}, {210, -20}}, color = {0, 127, 0}));
  connect(g.y, weight.f) annotation(
    Line(points = {{259, -20}, {242, -20}}, color = {0, 0, 127}));
  connect(mass.y, g.u) annotation(
    Line(points = {{299, -20}, {282, -20}}, color = {0, 0, 127}));
  connect(mcu.GND, ground.p) annotation(
    Line(points = {{0, -14}, {0, -56}, {-20, -56}, {-20, -60}}, color = {0, 0, 255}));
  connect(hx.GND, ground.p) annotation(
    Line(points = {{60, -32}, {60, -56}, {-20, -56}, {-20, -60}}, color = {0, 0, 255}));
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
