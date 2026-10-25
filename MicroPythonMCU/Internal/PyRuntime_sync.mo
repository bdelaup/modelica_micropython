within MicroPythonMCU.Internal;
impure function PyRuntime_sync "Sync point between the Python script and the simulation: passes the pin states, wakes the worker thread up to its next blocking point, returns the driven state and the next requested wake-up"
  extends PartialPyRuntimeSync;
  // Library annotation: -lwinpthread links winpthread dynamically, otherwise ModelicaError crashes
  // the simulation under OpenModelica/Windows (see requirements.md, decision
  // "Comportement en cas d'exception non geree dans le script").
  external "C" PyRuntime_sync(handle, currentTime, size(pinBoolIn, 1), pinBoolIn, pinAnalogIn, pinBoolOut, pinIsOutput, pinPull, pwmFreq, pwmDuty, displaySeq, displayPayload, uartTxPin, uartTxLevel, powerGood, adcRef, nextWakeTime) annotation(
    Include = "#include \"PyRuntimeImpl.c\"",
    Library = "-lwinpthread",
    IncludeDirectory = "modelica://MicroPythonMCU/Resources/Include");
end PyRuntime_sync;
