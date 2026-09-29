within MicroPythonMCU.Internal;
impure function PyRuntime_sync "Sync point between the Python script and the simulation: passes the pin states, wakes the worker thread up to its next blocking point, returns the driven state and the next requested wake-up"
  input PyRuntime handle;
  input Real currentTime;
  // The three pin arrays are Integer (0/1), not Boolean: an array of Boolean is handed to the C
  // code as is, and its element size depends on the OpenModelica version (int in 1.27, signed char
  // in 1.26 and earlier), whereas omc converts Integer arrays to int explicitly (see requirements.md,
  // decision "Tableaux de booléens et fonctions externes").
  input Integer pinBoolIn[9] "logic level read on each pin (0/1); indices 1-8 = GP0-GP7, 9 = on-board LED (internal)";
  input Real pinAnalogIn[9] "raw voltage (V) measured on each pin, aligned with pinBoolIn - read by machine.ADC; index 9 (LED) never used by the ADC";
  output Integer pinBoolOut[9] "level driven on each pin (0/1)";
  output Integer pinIsOutput[9] "direction of each pin (1 = output)";
  output Real pwmFreq[9] "PWM frequency of each pin (Hz), 0 = not in PWM mode - see machine.PWM";
  output Real pwmDuty[9] "PWM duty cycle of each pin (0-1), relevant only if pwmFreq > 0";
  output Integer displaySeq "incremented at each machine.Display.write() on the single logical link MCU.Display0 - see machine.Display";
  output String displayPayload "last text sent by write() (sample-and-hold)";
  output Integer uartTxPin "pin assigned to serial transmission (0 = none, otherwise 1-9 aligned with pinBoolOut) - see machine.UART";
  output Boolean uartTxLevel "level to hold on the transmit pin until the next sync point (idle = high): nextWakeTime falls on the next level CHANGE of the frame, the frame format stays entirely on the C side";
  output Real nextWakeTime;
  // Library annotation: -lwinpthread links winpthread dynamically, otherwise ModelicaError crashes
  // the simulation under OpenModelica/Windows (see requirements.md, decision
  // "Comportement en cas d'exception non geree dans le script").
  external "C" PyRuntime_sync(handle, currentTime, pinBoolIn, pinAnalogIn, pinBoolOut, pinIsOutput, pwmFreq, pwmDuty, displaySeq, displayPayload, uartTxPin, uartTxLevel, nextWakeTime) annotation(
    Include = "#include \"PyRuntimeImpl.c\"",
    Library = "-lwinpthread",
    IncludeDirectory = "modelica://MicroPythonMCU/Resources/Include");
end PyRuntime_sync;
