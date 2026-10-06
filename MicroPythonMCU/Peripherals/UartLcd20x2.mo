within MicroPythonMCU.Peripherals;

model UartLcd20x2 "Serial 20x2 display: shows on its icon the lines received on its RX pin, with scrolling"
  // final: OMEdit does not show these settings, meaningless for a display; only the
  // frame format (baudrate, dataBits, parity, stopBits) and the Electrical tab remain.
  // No TX pin nor valueOut connector: the display never transmits nor returns anything.
  extends Internal.PartialUartDevice(
    final behaviour = Interfaces.UartBehaviour.Table,
    final scriptPath = "",
    final terminator = "\n",
    final tickPeriod = 0.1,
    final respondEnabled = false,
    final commandTable = "",
    final responseDelay = 0.002,
    final echoEnabled = false,
    final periodicEnabled = false,
    final period = 1,
    final periodicTemplate = "",
    final useTxPin = false,
    final useValueInput = false,
    final nIn = 1,
    final fixedValue = 0,
    final useValueOutput = false,
    final nOut = 1,
    final valueOutStart = 0);
  extends Internal.TwoLineTextIcon;
equation
  when {initial(), change(eventSeq)} then
    line2CharCode = pre(line1CharCode) "the former line 1 moves down, like a display shifting its history";
    line1CharCode = Internal.StringToCharCodes(lastRx, Interfaces.DISPLAY_COLS) "the line just received takes line 1";
  end when;
  annotation(
    Documentation(info = "<html>
<p>The <strong>electrically real</strong> counterpart of <code>Peripherals.Display</code>. Where <code>Display</code> receives its text in one go through a causal logical link (<code>machine.Display</code>, no simulated baud rate), this one decodes a real serial frame arriving on its <code>RX</code> pin, bit by bit, at its own baud rate. A baud rate mismatch with the microcontroller therefore shows directly on the screen, as wrong characters.</p>
<p>On the embedded program side, writing a line ending with a line feed is enough: the device validates the line and triggers the display, exactly like the <code>terminator</code> of a command.</p>
<p>It extends two classes: <code>Internal.PartialUartDevice</code> for all the serial mechanics, and <code>Internal.TwoLineTextIcon</code> for the text rendering — the same 20x2 icon as <code>Display</code>, written only once. Beyond 20 characters, the line is truncated on the screen; the full text remains readable in the simulation log.</p>
<p>Write only: the device never answers nor transmits, nor returns anything to the model. Its <code>TX</code> pin (<code>useTxPin</code>) and its <code>valueOut</code> connector (<code>useValueOutput</code>) are therefore removed, like the settings of the request/response mechanics: only <code>RX</code> (and <code>GND</code>, <code>VCC</code> depending on the <em>Electrical</em> tab) remains to be wired.</p>
</html>"));
end UartLcd20x2;
