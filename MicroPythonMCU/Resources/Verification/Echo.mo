model Echo "Table-mode echo device: each byte goes back as soon as it is decoded - regression model of the Table behaviour (verify_20)"
  // Same schematic as Examples.Uart.EchoPy, with echo.behaviour = Table:
  // the device answers byte by byte instead of line by line. The Python
  // script of the device is then unused; the parameterised echo of the
  // component (echoEnabled) answers instead.
  extends Modelica.Icons.Example;
  MicroPythonMCU.MCU mcu(scriptPath = Modelica.Utilities.Files.loadResource("modelica://MicroPythonMCU/Resources/Scripts/MCU/uart_echo.py")) "scriptPath = Resources/Scripts/MCU/uart_echo.py" annotation(
    Placement(transformation(origin = {-90, 0}, extent = {{-20, -20}, {20, 20}})));
  MicroPythonMCU.Peripherals.UartEchoDevice echo(baudrate = 1200, behaviour = MicroPythonMCU.Interfaces.UartBehaviour.Table, scriptPath = Modelica.Utilities.Files.loadResource("modelica://MicroPythonMCU/Resources/Scripts/Device/echo.py")) "Sends back each received byte, as soon as it is decoded - parameterised echo (echoEnabled)" annotation(
    Placement(transformation(origin = {40, 0}, extent = {{-20, -20}, {20, 20}})));
  Modelica.Electrical.Analog.Basic.Ground ground annotation(
    Placement(transformation(origin = {-24, -80}, extent = {{-10, -10}, {10, 10}})));
equation
// Serial link: GP5 (TX) goes down to RX, TX comes back up to GP4 (RX).
// Both wires stay in the free space between the two components.
  connect(mcu.GP5, echo.RX) annotation(
    Line(points = {{-78, 4}, {-34, 4}, {-34, -6}, {18, -6}}, color = {0, 0, 255}));
  connect(echo.TX, mcu.GP4) annotation(
    Line(points = {{18, 6}, {-34, 6}, {-34, 10}, {-78, 10}}, color = {0, 0, 255}));
// Ground shared by both devices, brought in from below
  connect(mcu.GND, ground.p) annotation(
    Line(points = {{-90, -14}, {-90, -66}, {-24, -66}, {-24, -70}}, color = {0, 0, 255}));
  connect(echo.GND, ground.p) annotation(
    Line(points = {{40, -12}, {40, -66}, {-24, -66}, {-24, -70}}, color = {0, 0, 255}));
  annotation(
    Diagram(coordinateSystem(extent = {{-160, -100}, {120, 80}})),
    experiment(StopTime = 0.1, Interval = 5e-6),
    Documentation(info = "<html>
<p>Same as <code>Examples.Uart.EchoPy</code> — schematic, microcontroller program, device — with a single parameter changed: <code>echo.behaviour = Table</code>. The script <code>Device/echo.py</code> is then no longer used; the parameterised echo of the component (<code>echoEnabled</code>) answers instead.</p>
<p>The difference shows when plotting <code>mcu.GP5.v</code> and <code>mcu.GP4.v</code>: here each byte goes back <strong>as soon as it is decoded</strong>, stop bit included, with a delay of about one frame — without waiting for the end of the line, like a repeater. In <code>EchoPy</code>, the script only sees whole lines and only answers after the line feed.</p>
<p>The microcontroller program reads back the same line in both cases. This model is the regression scenario of the Table behaviour (<code>verify_20_uart_echo_table.mos</code>, in this folder).</p>
</html>"));
end Echo;
