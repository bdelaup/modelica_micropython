within MicroPythonMCU.Examples.Analyzer;

model UartErrors "The probe of UartLink on a mismatched link (the device answers in odd parity): the bytes sent back are marked with a parity error"
  extends Modelica.Icons.Example;
  MCU mcu(scriptPath = Modelica.Utilities.Files.loadResource("modelica://MicroPythonMCU/Resources/Scripts/MCU/uart_format.py")) "scriptPath = Resources/Scripts/MCU/uart_format.py" annotation(
    Placement(transformation(origin = {-90, 0}, extent = {{-20, -20}, {20, 20}})));
  MicroPythonMCU.Peripherals.UartEchoDevice echo(baudrate = 1200, parity = MicroPythonMCU.Interfaces.UartParity.Odd, stopBits = 2) "Sends back each received byte, in 8O2 unlike the microcontroller" annotation(
    Placement(transformation(origin = {40, 0}, extent = {{-20, -20}, {20, 20}})));
  Modelica.Electrical.Analog.Basic.Ground ground annotation(
    Placement(transformation(origin = {-24, -80}, extent = {{-10, -10}, {10, 10}})));
  MicroPythonMCU.Peripherals.Analyzers.LogicAnalyzer analyzer(ch0Kind = MicroPythonMCU.Interfaces.ChannelKind.Uart, ch0Name = "TX", ch0Baudrate = 1200, ch0Parity = MicroPythonMCU.Interfaces.UartParity.Even, ch0StopBits = 2, ch1Kind = MicroPythonMCU.Interfaces.ChannelKind.Uart, ch1Name = "RX", ch1Baudrate = 1200, ch1Parity = MicroPythonMCU.Interfaces.UartParity.Even, ch1StopBits = 2, ch2Kind = MicroPythonMCU.Interfaces.ChannelKind.Off, ch3Kind = MicroPythonMCU.Interfaces.ChannelKind.Off, ch4Kind = MicroPythonMCU.Interfaces.ChannelKind.Off, ch5Kind = MicroPythonMCU.Interfaces.ChannelKind.Off, ch6Kind = MicroPythonMCU.Interfaces.ChannelKind.Off, ch7Kind = MicroPythonMCU.Interfaces.ChannelKind.Off) "CH0 on the transmit wire of the microcontroller, CH1 on its receive wire, both decoded as UART 1200 baud 8E2" annotation(
    Placement(transformation(origin = {150, 0}, extent = {{-20, -20}, {20, 20}})));
equation
// Serial link: GP5 (TX) goes down to RX, TX comes back up to GP4 (RX).
  connect(mcu.GP5, echo.RX) annotation(
    Line(points = {{-78, 4}, {-34, 4}, {-34, -6}, {18, -6}}, color = {0, 0, 255}));
  connect(echo.TX, mcu.GP4) annotation(
    Line(points = {{18, 6}, {-34, 6}, {-34, 10}, {-78, 10}}, color = {0, 0, 255}));
  connect(mcu.GND, ground.p) annotation(
    Line(points = {{-90, -14}, {-90, -66}, {-24, -66}, {-24, -70}}, color = {0, 0, 255}));
  connect(echo.GND, ground.p) annotation(
    Line(points = {{40, -12}, {40, -66}, {-24, -66}, {-24, -70}}, color = {0, 0, 255}));
  connect(analyzer.CH0, mcu.GP5) annotation(
    Line(points = {{132, 14}, {100, 14}, {100, 70}, {-50, 70}, {-50, 4}, {-78, 4}}, color = {0, 0, 255}));
  connect(analyzer.CH1, mcu.GP4) annotation(
    Line(points = {{132, 10}, {96, 10}, {96, 64}, {-46, 64}, {-46, 10}, {-78, 10}}, color = {0, 0, 255}));
  connect(analyzer.GND, ground.p) annotation(
    Line(points = {{150, -18}, {150, -66}, {-24, -66}, {-24, -70}}, color = {0, 0, 255}));
  annotation(
    Diagram(coordinateSystem(extent = {{-160, -100}, {200, 80}})),
    experiment(StopTime = 0.4, Interval = 5e-6, StartTime = 0, Tolerance = 1e-06),
    Documentation(info = "<html>
<p>Same as <code>Examples.Analyzer.UartLink</code>, but the echo device uses <strong>odd</strong> parity — as in the parity-mismatch verification scenario (<code>verify_45</code>) — while the program and the probe expect even parity.</p>
<p>In <code>UartErrors.analyzer.txt</code>, the bytes transmitted by the microcontroller (<code>TX</code>) are correct; every byte sent back by the device (<code>RX</code>) is followed by <code>!</code> in the hexadecimal section and by <code>!P</code> under its frame in the timing diagram: its data bits are right, its parity bit is not. Setting <code>analyzer.ch1Parity</code> to <code>Odd</code> makes the errors disappear: the probe then reads the device as it is configured.</p>
</html>"));
end UartErrors;
