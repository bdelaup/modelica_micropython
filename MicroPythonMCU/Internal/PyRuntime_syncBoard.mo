within MicroPythonMCU.Internal;
impure function PyRuntime_syncBoard "Sync point of a core that carries a board link: same as PyRuntime_sync plus the network id wired by the schema (micro:bit radio antenna)"
  extends PartialPyRuntimeSync;
  input Integer boardNetwork "id of the network the board is wired to (microbit.radio air, see Peripherals.Radio.RadioAir), -1 = nothing wired";
  // boardNetwork precedes nextWakeTime on the C side: the external call is spelled out in full.
  external "C" PyRuntime_syncBoard(handle, currentTime, size(pinBoolIn, 1), pinBoolIn, pinAnalogIn, pinBoolOut, pinIsOutput, pinPull, pwmFreq, pwmDuty, displaySeq, displayPayload, uartTxPin, uartTxLevel, powerGood, adcRef, boardNetwork, nextWakeTime) annotation(
    Include = "#include \"PyRuntimeImpl.c\"",
    Library = "-lwinpthread",
    IncludeDirectory = "modelica://MicroPythonMCU/Resources/Include");
end PyRuntime_syncBoard;
