within MicroPythonMCU.Examples.Analyzer;

model UartErrors "The probe of UartLink on the mismatched link of Uart.FormatMismatch: the bytes sent back are marked with a parity error"
  extends UartLink(echo(parity = MicroPythonMCU.Interfaces.UartParity.Odd));
  annotation(
    experiment(StopTime = 0.4, Interval = 5e-6),
    Documentation(info = "<html>
<p>Same as <code>Examples.Analyzer.UartLink</code>, but the echo device uses <strong>odd</strong> parity, as in <code>Examples.Uart.FormatMismatch</code>, while the program and the probe expect even parity.</p>
<p>In <code>UartErrors.analyzer.txt</code>, the bytes transmitted by the microcontroller (<code>TX</code>) are correct; every byte sent back by the device (<code>RX</code>) is followed by <code>!</code> in the hexadecimal section and by <code>!P</code> under its frame in the timing diagram: its data bits are right, its parity bit is not. Setting <code>analyzer.ch1Parity</code> to <code>Odd</code> makes the errors disappear: the probe then reads the device as it is configured.</p>
</html>"));
end UartErrors;
