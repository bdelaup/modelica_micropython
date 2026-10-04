within MicroPythonMCU.Interfaces;

type UartParity = enumeration(
    None "No parity bit",
    Even "Even parity (machine.UART parity=0)",
    Odd "Odd parity (machine.UART parity=1)")
  "Parity of a serial frame, as for machine.UART"
  annotation(
    Documentation(info = "<html>
<p>Parity of the frames of an external serial device (<code>Internal.PartialUartDevice</code>). Same three choices as the <code>parity</code> argument of <code>machine.UART</code> on the microcontroller: <code>None</code>, <code>0</code> (even: the total number of 1 bits, data plus parity, is even) or <code>1</code> (odd). A received byte whose parity bit is wrong is kept, with a warning in the log — the symptom of a transmitter and a receiver configured differently.</p>
</html>"));
