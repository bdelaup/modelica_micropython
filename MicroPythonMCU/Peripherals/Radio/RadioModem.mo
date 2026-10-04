within MicroPythonMCU.Peripherals.Radio;

model RadioModem "Transparent radio modem, every setting adjustable: serial link, modulation, channel, air data rate, duplex, buffers, delays"
  extends Internal.PartialRadioModem;
  annotation(
    Icon(graphics = {Text(textColor = {255, 255, 255}, extent = {{-80, 32}, {70, 6}}, textString = "RADIO", textStyle = {TextStyle.Bold}), Text(textColor = {200, 230, 220}, extent = {{-70, 2}, {70, -14}}, textString = "%airBaudrate bps")}),
    Documentation(info = "<html>
<p>Generic transparent radio modem. Its default settings are those of an APC220 module (9600 baud on the UART, 9600 bit/s on air, 434 MHz, 256-byte buffers, half duplex); every one of them can be changed here, including the ones the real module does not offer — air data rate very different from the serial speed, tiny buffers, full duplex — to show what they change. For a module set up exactly like an APC220, use <code>Apc220</code>.</p>
<p>Operation, parameters and limits: see <code>Internal.PartialRadioModem</code> and the user guide (Peripherals, radio link).</p>
</html>"));
end RadioModem;
