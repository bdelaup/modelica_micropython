within MicroPythonMCU.Internal;
partial impure function PartialPyRuntimeSync "Interface shared by the sync points PyRuntime_sync and PyRuntime_syncBoard: passes the pin states, wakes the worker thread up to its next blocking point, returns the driven state and the next requested wake-up"
  input PyRuntime handle;
  input Real currentTime;
  // The pin arrays are Integer (0/1, or 0/1/2 for pinPull), not Boolean: an array of Boolean is handed to the C
  // code as is, and its element size depends on the OpenModelica version (int in 1.27, signed char
  // in 1.26 and earlier), whereas omc converts Integer arrays to int explicitly (see requirements.md,
  // decision "Tableaux de booléens et fonctions externes").
  input Integer pinBoolIn[:] "logic level read on each pin (0/1), in the order of the pin table given to PyRuntime (MCU: indices 1-8 = GP0-GP7, 9 = on-board LED)";
  input Real pinAnalogIn[size(pinBoolIn, 1)] "raw voltage (V) measured on each pin, aligned with pinBoolIn - read by machine.ADC on the ADC-capable pins";
  input Boolean powerGood "the board is supplied: the program starts at the first supplied sync point and stops for good at the first supply loss";
  input Real adcRef "reference voltage of the ADC (V): read_u16() = 65535 at this voltage";
  output Integer pinBoolOut[size(pinBoolIn, 1)] "level driven on each pin (0/1)";
  output Integer pinIsOutput[size(pinBoolIn, 1)] "direction of each pin (1 = output)";
  output Integer pinPull[size(pinBoolIn, 1)] "internal pull resistor of each pin (0 = none, 1 = Pin.PULL_UP, 2 = Pin.PULL_DOWN)";
  output Real pwmFreq[size(pinBoolIn, 1)] "PWM frequency of each pin (Hz), 0 = not in PWM mode - see machine.PWM";
  output Real pwmDuty[size(pinBoolIn, 1)] "PWM duty cycle of each pin (0-1), relevant only if pwmFreq > 0";
  output Integer displaySeq "incremented at each machine.Display.write() on the single logical link MCU.Display0 - see machine.Display";
  output String displayPayload "last text sent by write() (sample-and-hold)";
  output Integer uartTxPin "pin assigned to serial transmission (0 = none, otherwise its index, aligned with pinBoolOut) - see machine.UART";
  output Boolean uartTxLevel "level to hold on the transmit pin until the next sync point (idle = high): nextWakeTime falls on the next level CHANGE of the frame, the frame format stays entirely on the C side";
  output Real nextWakeTime;
end PartialPyRuntimeSync;
