within MicroPythonMCU.Examples.Uart;

model FormatMismatch "Same circuit as Format, but the device uses odd parity: every byte arrives with a parity error, reported in the log"
  extends Format(echo(parity = MicroPythonMCU.Interfaces.UartParity.Odd));
  annotation(
    experiment(StopTime = 0.4, Interval = 5e-6),
    Documentation(info = "<html>
<p>Same as <code>Examples.Uart.Format</code>, with a single parameter changed: the device uses <strong>odd</strong> parity while the program asks for even parity — the most common mistake when setting up a serial link.</p>
<p>The data bits are the same on both sides, so each byte is still decoded correctly, and it is <strong>kept</strong>, as on the RP2040 whose receiver stores the byte with an error flag. But its parity bit is wrong: both the device and the microcontroller log a <em>parity error</em> warning for each byte (the first ten, then a total at the end of the simulation). This is precisely what parity is for: detecting that something went wrong on the link.</p>
<p>A mismatch on the number of data bits or on the baud rate, on the other hand, produces wrong bytes — try <code>echo.dataBits = 7</code> or <code>echo.baudrate = 2400</code>.</p>
</html>"));
end FormatMismatch;
