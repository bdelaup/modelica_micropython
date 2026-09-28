within MicroPythonMCU.Examples.Uart;

model EchoPy "The microcontroller talks to an external serial device: it sends a line, the device sends it back"
  extends Modelica.Icons.Example;
  MCU mcu(scriptPath = Modelica.Utilities.Files.loadResource("modelica://MicroPythonMCU/Resources/Scripts/MCU/uart_echo.py")) "scriptPath = Resources/Scripts/MCU/uart_echo.py" annotation(
    Placement(transformation(origin = {-90, 0}, extent = {{-50, -50}, {50, 50}})));
  MicroPythonMCU.Peripherals.UartEchoDevice echo(baudrate = 1200, behaviour = MicroPythonMCU.Interfaces.UartBehaviour.Script, scriptPath = Modelica.Utilities.Files.loadResource("modelica://MicroPythonMCU/Resources/Scripts/Device/echo.py")) "Sends back each received line - behaviour described by Resources/Scripts/Device/echo.py" annotation(
    Placement(transformation(origin = {40, 0}, extent = {{-40, -40}, {40, 40}})));
  Modelica.Electrical.Analog.Basic.Ground ground annotation(
    Placement(transformation(origin = {-25, -80}, extent = {{-10, -10}, {10, 10}})));
equation
// Serial link: GP5 (TX) goes down to RX, TX comes back up to GP4 (RX).
// Both wires stay in the free space between the two components.
  connect(mcu.GP5, echo.RX) annotation(
    Line(points = {{-59, 10}, {-34, 10}, {-34, -13.6}, {-9.6, -13.6}}, color = {0, 0, 255}));
  connect(echo.TX, mcu.GP4) annotation(
    Line(points = {{-9.6, 13.6}, {-34, 13.6}, {-34, 25}, {-59, 25}}, color = {0, 0, 255}));
// Ground shared by both devices, brought in from below
  connect(mcu.GND, ground.p) annotation(
    Line(points = {{-90, -39}, {-90, -70}, {-25, -70}}, color = {0, 0, 255}));
  connect(echo.GND, ground.p) annotation(
    Line(points = {{40, -28.8}, {40, -70}, {-25, -70}}, color = {0, 0, 255}));
  annotation(
    Diagram(coordinateSystem(extent = {{-160, -100}, {120, 80}})),
    experiment(StopTime = 0.1, Interval = 5e-6),
    Documentation(info = "<html>
<p>First example where the microcontroller talks to a <strong>partner</strong> rather than to itself. <code>Examples.Uart.Loopback</code> sent the frame back to itself through a <code>loopR</code>/<code>loopC</code> network that only existed to work around an alias merge between two pins of the same component. Here the two ends are two distinct components: the link becomes a simple wire in each direction again, and the schematic looks like real wiring.</p>
<p>Both devices must share their <strong>ground</strong> — as on a real circuit, where connecting only TX and RX is not enough.</p>
<p>The behaviour of the device is described by a <strong>Python script</strong> (<code>echo.behaviour = Script</code>): <code>Device/echo.py</code>, a one-line function that sends back each received line. Plotting <code>mcu.GP5.v</code> (what the microcontroller transmits) and <code>mcu.GP4.v</code> (what the device sends back) shows that the reply only leaves once the complete line has been received, terminator included, and <code>responseDelay</code> has elapsed: a script only sees whole lines.</p>
<p>Switching <code>echo.behaviour</code> back to <code>Table</code> enables instead the parameterised echo of the component, <strong>byte by byte</strong>: each byte goes back as soon as it is decoded, with a delay of about one frame, without waiting for the end of the line. This is exactly <code>Examples.Uart.Echo</code>, which extends this example and only changes this parameter. The microcontroller program works identically in both cases.</p>
<p>The program sets pin <code>GP7</code> high if the line read back is identical to the one sent. It is connected to nothing: its voltage is what we observe, a display component would add nothing here.</p>
</html>"));
end EchoPy;
