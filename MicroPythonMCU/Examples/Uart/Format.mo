within MicroPythonMCU.Examples.Uart;

model Format "Serial link in 8E2 (even parity, 2 stop bits) instead of 8N1: the microcontroller and the device must use the same frame format"
  extends Modelica.Icons.Example;
  MCU mcu(scriptPath = Modelica.Utilities.Files.loadResource("modelica://MicroPythonMCU/Resources/Scripts/MCU/uart_format.py")) "scriptPath = Resources/Scripts/MCU/uart_format.py" annotation(
    Placement(transformation(origin = {-90, 0}, extent = {{-50, -50}, {50, 50}})));
  MicroPythonMCU.Peripherals.UartEchoDevice echo(baudrate = 1200, parity = MicroPythonMCU.Interfaces.UartParity.Even, stopBits = 2) "Sends back each received byte, in 8E2 like the microcontroller" annotation(
    Placement(transformation(origin = {40, 0}, extent = {{-40, -40}, {40, 40}})));
  Modelica.Electrical.Analog.Basic.Ground ground annotation(
    Placement(transformation(origin = {-25, -80}, extent = {{-10, -10}, {10, 10}})));
equation
// Serial link: GP5 (TX) goes down to RX, TX comes back up to GP4 (RX).
  connect(mcu.GP5, echo.RX) annotation(
    Line(points = {{-59, 10}, {-34, 10}, {-34, -13.6}, {-9.6, -13.6}}, color = {0, 0, 255}));
  connect(echo.TX, mcu.GP4) annotation(
    Line(points = {{-9.6, 13.6}, {-34, 13.6}, {-34, 25}, {-59, 25}}, color = {0, 0, 255}));
  connect(mcu.GND, ground.p) annotation(
    Line(points = {{-90, -39}, {-90, -70}, {-25, -70}}, color = {0, 0, 255}));
  connect(echo.GND, ground.p) annotation(
    Line(points = {{40, -28.8}, {40, -70}, {-25, -70}}, color = {0, 0, 255}));
  annotation(
    Diagram(coordinateSystem(extent = {{-160, -100}, {120, 80}})),
    experiment(StopTime = 0.4, Interval = 5e-6),
    Documentation(info = "<html>
<p>Same circuit as <code>Examples.Uart.Echo</code>, with another <strong>frame format</strong>: 8 data bits, <strong>even parity</strong>, <strong>2 stop bits</strong> (8E2). The program opens its UART with <code>UART(0, baudrate=1200, bits=8, parity=0, stop=2, ...)</code>, and the device is set to the same format by its parameters <code>dataBits</code>, <code>parity</code> and <code>stopBits</code> (\"Serial link\" group); its icon shows the format it uses.</p>
<p>Plotting <code>mcu.GP5.v</code> shows a 12-bit frame lasting 10 ms: start bit, 8 data bits least significant first, the parity bit, then two stop bits. The parity bit makes the total number of 1 bits even: <code>'H'</code> (0x48) has two of them, so its parity bit is 0.</p>
<p>The program sets <code>GP7</code> high if the line read back is identical to the one sent. <code>Examples.Uart.FormatMismatch</code> extends this example and only changes the parity of the device, to show what a configuration mismatch produces.</p>
</html>"));
end Format;
