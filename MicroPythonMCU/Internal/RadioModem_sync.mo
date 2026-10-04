within MicroPythonMCU.Internal;

impure function RadioModem_sync "Sync point of a radio modem: advances the serial and radio frames, moves the bytes through the buffers, and returns the next deadline"
  input RadioModem modem;
  input Real currentTime;
  input Boolean serRxLevel "Logic level read on the RX pin (bytes coming from the microcontroller)";
  input Boolean airLevel "Level of the radio frame heard (idle = high; already idle on the Modelica side when nothing audible)";
  input Boolean airJam "Two transmitters or more at once: the frame being received is lost";
  output Boolean serTxLevel "Level to hold on TX until the next sync point (idle = high)";
  output Boolean airTxLevel "Bit being transmitted on air (idle = high)";
  output Boolean carrierOn "A radio frame is being transmitted";
  output Boolean airRxBusy "A radio frame is being received";
  output Integer txFill "Bytes waiting in the transmit buffer (UART -> air)";
  output Integer rxFill "Bytes waiting in the receive buffer (air -> UART)";
  output Real airId "Identifier of the module (1, 2, 3... one per instance)";
  output Integer nSent "Radio frames transmitted so far";
  output Integer nReceived "Radio frames received intact so far";
  output Integer nDropped "Bytes lost so far because a buffer was full";
  output Integer nCorrupted "Radio frames lost so far: corrupted, collided, or cut by our own transmission in half duplex";
  output Real nextWakeTime "Nearest deadline: edge to transmit on either side, middle of a stop bit, byte ready to leave";
  // Library annotation: -lwinpthread links winpthread dynamically, otherwise ModelicaError crashes
  // the simulation under OpenModelica/Windows (see requirements.md, decision
  // "Comportement en cas d'exception non geree dans le script").
  external "C" RadioModem_sync(modem, currentTime, serRxLevel, airLevel, airJam, serTxLevel, airTxLevel, carrierOn, airRxBusy, txFill, rxFill, airId, nSent, nReceived, nDropped, nCorrupted, nextWakeTime) annotation(
    Include = "#include \"RadioModemImpl.c\"",
    Library = "-lwinpthread",
    IncludeDirectory = "modelica://MicroPythonMCU/Resources/Include");
  annotation(
    Documentation(info = "<html>
<p><code>impure</code>: the function carries the state of the modem — like <code>UartDevice_sync</code>. Called again several times at the same simulated instant (Modelica iterates over events), it does nothing more: all its steps are driven by deadlines or consume what they process.</p>
</html>"));
end RadioModem_sync;
