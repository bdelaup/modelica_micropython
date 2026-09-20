within MicroPythonMCU.Internal;
impure function PyRuntime_sync "Point de synchro entre le script Python et la simulation (jalon M5) : transmet l'etat des broches, reveille le thread worker jusqu'a son prochain point de blocage, renvoie l'etat pilote et le prochain reveil demande"
  input PyRuntime handle;
  input Real currentTime;
  input Boolean pinBoolIn[9] "indices 1-8 = GP0-GP7, 9 = LED embarquee (interne)";
  input Real pinAnalogIn[9] "tension brute (V) mesuree sur chaque broche, alignee sur pinBoolIn - lue par machine.ADC ; index 9 (LED) jamais utilise cote ADC";
  output Boolean pinBoolOut[9];
  output Boolean pinIsOutput[9];
  output Real pwmFreq[9] "frequence PWM par broche (Hz), 0 = pas en mode PWM - cf. machine.PWM";
  output Real pwmDuty[9] "rapport cyclique PWM par broche (0-1), pertinent seulement si pwmFreq > 0";
  output Real nextWakeTime;
  external "C" PyRuntime_sync(handle, currentTime, pinBoolIn, pinAnalogIn, pinBoolOut, pinIsOutput, pwmFreq, pwmDuty, nextWakeTime) annotation(
    Include = "#include \"PyRuntimeImpl.c\"",
    IncludeDirectory = "modelica://MicroPythonMCU/Resources/Include",
    Library = "python312",
    LibraryDirectory = "modelica://MicroPythonMCU/Resources/Library/win64");
end PyRuntime_sync;
