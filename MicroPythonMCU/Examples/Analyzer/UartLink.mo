within MicroPythonMCU.Examples.Analyzer;

model UartLink "A logic analyser probe decodes both wires of the 8E2 serial link of Uart.Format into a text file"
  extends Uart.Format;
  MicroPythonMCU.Peripherals.Analyzers.LogicAnalyzer analyzer(ch0Kind = MicroPythonMCU.Interfaces.ChannelKind.Uart, ch0Name = "TX", ch0Baudrate = 1200, ch0Parity = MicroPythonMCU.Interfaces.UartParity.Even, ch0StopBits = 2, ch1Kind = MicroPythonMCU.Interfaces.ChannelKind.Uart, ch1Name = "RX", ch1Baudrate = 1200, ch1Parity = MicroPythonMCU.Interfaces.UartParity.Even, ch1StopBits = 2, ch2Kind = MicroPythonMCU.Interfaces.ChannelKind.Off, ch3Kind = MicroPythonMCU.Interfaces.ChannelKind.Off, ch4Kind = MicroPythonMCU.Interfaces.ChannelKind.Off, ch5Kind = MicroPythonMCU.Interfaces.ChannelKind.Off, ch6Kind = MicroPythonMCU.Interfaces.ChannelKind.Off, ch7Kind = MicroPythonMCU.Interfaces.ChannelKind.Off) "CH0 on the transmit wire of the microcontroller, CH1 on its receive wire, both decoded as UART 1200 baud 8E2" annotation(
    Placement(transformation(origin = {150, 0}, extent = {{-20, -20}, {20, 20}})));
equation
  connect(analyzer.CH0, mcu.GP5) annotation(
    Line(points = {{132, 14}, {100, 14}, {100, 70}, {-50, 70}, {-50, 4}, {-78, 4}}, color = {0, 0, 255}));
  connect(analyzer.CH1, mcu.GP4) annotation(
    Line(points = {{132, 10}, {96, 10}, {96, 64}, {-46, 64}, {-46, 10}, {-78, 10}}, color = {0, 0, 255}));
  connect(analyzer.GND, ground.p) annotation(
    Line(points = {{150, -18}, {150, -66}, {-24, -66}, {-24, -70}}, color = {0, 0, 255}));
  annotation(
    Diagram(coordinateSystem(extent = {{-160, -100}, {200, 80}})),
    experiment(StopTime = 0.4, Interval = 5e-6),
    Documentation(info = "<html>
<p>The circuit of <code>Examples.Uart.Format</code> (serial link in 8E2 with an echo device), plus a <strong>logic analyser probe</strong> (<code>Peripherals.Analyzers.LogicAnalyzer</code>) whose two first channels are clipped onto the two wires of the link: <code>CH0</code> = <code>TX</code> (what the microcontroller transmits), <code>CH1</code> = <code>RX</code> (what the device sends back). Both are of kind <code>Uart</code>, with the format of the link: 1200 baud, 8 data bits, even parity, 2 stop bits; the other channels are <code>Off</code>.</p>
<p>At the end of the simulation, the probe writes <code>UartLink.analyzer.txt</code> in the simulation folder (full path in the log) and opens it in Notepad: the bytes of <code>Hello, parity!</code> in hexadecimal + ASCII for each direction, then the ASCII timing diagram of both wires, each frame bit by bit (<code>S</code> start, data bits, <code>P</code> parity, <code>s</code> stop) above its byte. The echo comes back while the message is still being sent: the two directions overlap.</p>
<p>It also writes <code>UartLink.analyzer.vcd</code>, to be opened in PulseView (<code>analyzer.openPulseView = true</code>) with its UART decoder. <code>Examples.Analyzer.UartErrors</code> shows the same link with a misconfigured device.</p>
</html>"));
end UartLink;
