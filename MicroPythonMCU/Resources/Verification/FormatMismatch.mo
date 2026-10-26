model FormatMismatch "Same circuit as Format, but the device uses odd parity: every byte arrives with a parity error, reported in the log"
  extends Modelica.Icons.Example;
  MicroPythonMCU.MCU mcu(scriptPath = Modelica.Utilities.Files.loadResource("modelica://MicroPythonMCU/Resources/Scripts/MCU/uart_format.py")) "scriptPath = Resources/Scripts/MCU/uart_format.py" annotation(
    Placement(transformation(origin = {-90, 0}, extent = {{-20, -20}, {20, 20}})));
  MicroPythonMCU.Peripherals.UartEchoDevice echo(baudrate = 1200, parity = MicroPythonMCU.Interfaces.UartParity.Odd, stopBits = 2) "Sends back each received byte, in 8O2 unlike the microcontroller" annotation(
    Placement(transformation(origin = {40, 0}, extent = {{-20, -20}, {20, 20}})));
  Modelica.Electrical.Analog.Basic.Ground ground annotation(
    Placement(transformation(origin = {-24, -80}, extent = {{-10, -10}, {10, 10}})));
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
  annotation(
    Diagram(coordinateSystem(extent = {{-160, -100}, {120, 80}})),
    experiment(StopTime = 0.4, Interval = 5e-6),
    Documentation(info = "<html>
<p>Same as <code>Examples.Uart.Format</code>, with a single parameter changed: the device uses <strong>odd</strong> parity while the program asks for even parity — the most common mistake when setting up a serial link.</p>
<p>The data bits are the same on both sides, so each byte is still decoded correctly, and it is <strong>kept</strong>, as on the RP2040 whose receiver stores the byte with an error flag. But its parity bit is wrong: both the device and the microcontroller log a <em>parity error</em> warning for each byte (the first ten, then a total at the end of the simulation). This is precisely what parity is for: detecting that something went wrong on the link.</p>
<p>A mismatch on the number of data bits or on the baud rate, on the other hand, produces wrong bytes — try <code>echo.dataBits = 7</code> or <code>echo.baudrate = 2400</code>.</p>
</html>"));
end FormatMismatch;
