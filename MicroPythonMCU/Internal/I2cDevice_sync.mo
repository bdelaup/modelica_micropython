within MicroPythonMCU.Internal;

impure function I2cDevice_sync "Sync point of an I2C slave peripheral: interprets the SCL or SDA edge that just occurred, calls the script at the right moments, and returns the state of its SDA output"
  input I2cDevice dev;
  input Real currentTime;
  input Boolean sclLevel "Logic level read on SCL (voltage thresholded on the Modelica side)";
  input Boolean sdaLevel "Logic level read on SDA";
  input Real valueIn[Interfaces.I2C_DEV_MAX_VALUES] "Quantities coming from the model, passed to the script's handlers (argument v)";
  output Real valueOut[Interfaces.I2C_DEV_MAX_VALUES] "Quantities returned by outputs() (held between two calls)";
  output Boolean sdaDriveLow "The peripheral pulls SDA to ground (acknowledge, or 0 bit of a byte read by the master)";
  output Boolean busy "A phase addressed to this peripheral is in progress (icon activity indicator)";
  output Integer eventSeq "Incremented at each completed write or read phase - trigger change(eventSeq)";
  output String lastEvent "Summary of the last completed phase, e.g. \"write 0x3E: 80 01\" (log)";
  output String line1 "First line returned by lines() (displays)";
  output String line2 "Second line returned by lines()";
  // Library annotation: -lwinpthread links winpthread dynamically, otherwise ModelicaError crashes
  // the simulation under OpenModelica/Windows (see requirements.md, decision
  // "Comportement en cas d'exception non geree dans le script").
  external "C" I2cDevice_sync(dev, currentTime, sclLevel, sdaLevel, valueIn, valueOut, sdaDriveLow, busy, eventSeq, lastEvent, line1, line2) annotation(
    Include = "#include \"I2cDeviceImpl.c\"",
    Library = "-lwinpthread",
    IncludeDirectory = "modelica://MicroPythonMCU/Resources/Include");
  annotation(
    Documentation(info = "<html>
<p><code>impure</code>: the function carries the state of the peripheral — like <code>UartDevice_sync</code>. It is only called from a <code>when</code> triggered by an edge of SCL or SDA, never during a trial evaluation of the solver.</p>
<p>Called again several times at the same instant with the same levels (Modelica event iterations), it does nothing: there is no new edge to interpret.</p>
</html>"));
end I2cDevice_sync;
