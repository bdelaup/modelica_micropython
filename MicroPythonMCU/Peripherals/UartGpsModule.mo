within MicroPythonMCU.Peripherals;

model UartGpsModule "Serial GPS module: spontaneously pushes a position frame, without being asked"
  extends Internal.PartialUartDevice(
    respondEnabled = false,
    periodicEnabled = true,
    period = 1,
    periodicTemplate = "$GPGLL,{v1:.4f},{v2:.4f},{v3:.1f}\r\n",
    useValueInput = true,
    nIn = 3,
    fixedValue = 0,
    scriptPath = Modelica.Utilities.Files.loadResource("modelica://MicroPythonMCU/Resources/Scripts/Device/gps.py"));
  annotation(
    Icon(graphics = {Text(textColor = {255, 255, 255}, extent = {{-90, -22}, {90, -40}}, textString = "GPS", textStyle = {TextStyle.Bold})}),
    Documentation(info = "<html>
<p>Representative of the <strong>second transmission mode</strong>: unlike the temperature sensor, this module waits for no question. It pushes a frame every <code>period</code> seconds, which forces the embedded program to watch its serial input — typically with <code>uart.any()</code> in a loop, since reception never wakes the script up (no <code>uart.irq()</code> in v0).</p>
<p>The three quantities of the <code>valueIn</code> connector are latitude, longitude and speed. Connecting a motion model to it makes a real trajectory scroll through the frames, which lets the embedded decoding code be tested on moving data.</p>
<p><em>Deliberately simplified frame</em>: a real NMEA sentence (<code>$GPGLL</code>) also carries the N/S and E/W direction indicators, the UTC time, a validity flag and a checksum. Only the three numeric fields are kept here, enough to exercise the transmission mechanism and the splitting on the program side. A more faithful format belongs to the script mode, since the command table cannot compute a checksum — see <code>Examples.Uart.GpsPy</code>.</p>
</html>"));
end UartGpsModule;
