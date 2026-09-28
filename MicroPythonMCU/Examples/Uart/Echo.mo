within MicroPythonMCU.Examples.Uart;

model Echo "Same circuit as EchoPy, with the parameterised echo of Table mode: each byte goes back as soon as it is decoded"
  // Extends EchoPy and only changes the mode: the schematic is written once, and
  // both examples stay identical by construction. The Py variant carries the
  // full schematic, so that the script path appears there as a value
  // of the component itself in the parameter dialog.
  extends EchoPy(echo(behaviour = MicroPythonMCU.Interfaces.UartBehaviour.Table));
  annotation(
    experiment(StopTime = 0.1, Interval = 5e-6),
    Documentation(info = "<html>
<p>Same as <code>Examples.Uart.EchoPy</code> — schematic, microcontroller program, device — with a single parameter changed: <code>echo.behaviour = Table</code>. The script <code>Device/echo.py</code> is then no longer used; the parameterised echo of the component (<code>echoEnabled</code>) answers instead.</p>
<p>The difference shows when plotting <code>mcu.GP5.v</code> and <code>mcu.GP4.v</code>: here each byte goes back <strong>as soon as it is decoded</strong>, stop bit included, with a delay of about one frame — without waiting for the end of the line, like a repeater. In <code>EchoPy</code>, the script only sees whole lines and only answers after the line feed.</p>
<p>The microcontroller program reads back the same line in both cases: the two examples are kept side by side so that each mode has its own regression scenario.</p>
</html>"));
end Echo;
