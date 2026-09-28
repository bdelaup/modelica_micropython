within MicroPythonMCU.Peripherals;

model UartEchoDevice "Serial echo device: sends back every received byte unchanged"
  extends Internal.PartialUartDevice(echoEnabled = true, respondEnabled = false, periodicEnabled = false, scriptPath = Modelica.Utilities.Files.loadResource("modelica://MicroPythonMCU/Resources/Scripts/Device/echo.py"));
  annotation(
    Icon(graphics = {Text(textColor = {255, 255, 255}, extent = {{-90, -22}, {90, -40}}, textString = "ECHO", textStyle = {TextStyle.Bold})}),
    Documentation(info = "<html>
<p>The simplest of the devices derived from <code>Internal.PartialUartDevice</code>: it only overrides three Booleans. Each decoded byte is immediately put back into the transmit queue, without waiting for the end of the line — hence without any notion of command or delimiter.</p>
<p>Its interest is to be a <strong>real partner</strong> on the link: it replaces the loopback of <code>Examples.Uart.Loopback</code>, which only existed to work around an alias merge between two pins of the same <code>MCU</code>. Here the two ends are two distinct components, and the link is a simple wire.</p>
<p>Each byte goes back with a delay of about one frame, since it must have been fully decoded (up to the stop bit) before it can be sent again — exactly like a real repeater. It is also the component of choice to validate a communication chain before connecting the final device to it.</p>
</html>"));
end UartEchoDevice;
