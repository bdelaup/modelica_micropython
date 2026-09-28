within MicroPythonMCU.Peripherals;

model I2cEchoDevice "Test I2C peripheral: reads back to the master what it has just written to it"
  extends Internal.PartialI2cDevice(addresses = "0x42", nOut = 3, scriptPath = Modelica.Utilities.Files.loadResource("modelica://MicroPythonMCU/Resources/Scripts/Device/i2c_echo.py"));
  annotation(
    Icon(graphics = {Text(textColor = {255, 255, 255}, extent = {{-90, -22}, {90, -40}}, textString = "ECHO", textStyle = {TextStyle.Bold})}),
  Documentation(info = "<html>
<p>The test component of the I2C bus, counterpart of <code>UartEchoDevice</code>. Its script (<code>Resources/Scripts/Device/i2c_echo.py</code>) remembers the bytes of the last write phase and sends them back unchanged when the master reads — several times in a row if the master asks for more.</p>
<p>It is used to validate a complete chain before connecting the final peripheral: multi-byte frames, register read behind a repeated START (<code>readfrom_mem</code>), several peripherals at different addresses on the same bus (change <code>addresses</code>), and operation with or without pull-up resistors (<code>usePullUp</code>).</p>
<p><code>valueOut</code>: number of write phases received, total number of bytes received, first byte of the last write (-1 as long as nothing has been received).</p>
</html>"));
end I2cEchoDevice;
