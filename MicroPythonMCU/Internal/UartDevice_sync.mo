within MicroPythonMCU.Internal;

impure function UartDevice_sync "Sync point of an external serial device: advances transmission and reception, delivers the received lines, arms the transmissions, and returns the next deadline"
  input UartDevice dev;
  input Real currentTime;
  input Boolean rxLevel "Logic level read on the receive pin (voltage thresholded on the Modelica side)";
  input Real valueIn[Interfaces.UART_DEV_MAX_VALUES] "Quantities coming from the model, substituted by {vN} in the transmitted frames";
  output Real valueOut[Interfaces.UART_DEV_MAX_VALUES] "Quantities captured by {oN} from the received frames (held between two frames)";
  output Boolean txActive "A frame is being transmitted (icon indicator)";
  output Boolean txLevel "Level to hold on TX until the next sync point (idle = high): nextWakeTime falls on the next level CHANGE of the frame";
  output Boolean rxBusy "A frame is being received (icon activity indicator)";
  output Integer eventSeq "Incremented at each received line and each transmitted payload - trigger for the edge detection change(eventSeq), same pattern as Display0.seq";
  output String lastRx "Last complete line received (log, display)";
  output String lastTx "Last payload transmitted (log)";
  output Real nextWakeTime "Nearest deadline: edge to transmit, end of frame, middle of the stop bit of a received frame, armed reply or periodic tick";
  // Library annotation: -lwinpthread links winpthread dynamically, otherwise ModelicaError crashes
  // the simulation under OpenModelica/Windows (see requirements.md, decision
  // "Comportement en cas d'exception non geree dans le script").
  external "C" UartDevice_sync(dev, currentTime, rxLevel, valueIn, valueOut, txActive, txLevel, rxBusy, eventSeq, lastRx, lastTx, nextWakeTime) annotation(
    Include = "#include \"UartDeviceImpl.c\"",
    Library = "-lwinpthread",
    IncludeDirectory = "modelica://MicroPythonMCU/Resources/Include");
  annotation(
    Documentation(info = "<html>
<p><code>impure</code>: the function carries the state of the device and does not return the same thing for the same arguments — like <code>PyRuntime_sync</code>. It is only called from a <code>when</code>, never during a trial evaluation of the solver.</p>
<p>Called again several times at the same simulated instant (Modelica iterates over events), it does nothing more: all its steps are driven by deadlines or consume what they process.</p>
</html>"));
end UartDevice_sync;
