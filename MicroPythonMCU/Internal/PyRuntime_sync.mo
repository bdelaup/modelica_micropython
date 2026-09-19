within MicroPythonMCU.Internal;
impure function PyRuntime_sync "Point de synchro entre le script Python et la simulation (jalon M5) : transmet l'etat des broches, reveille le thread worker jusqu'a son prochain point de blocage, renvoie l'etat pilote et le prochain reveil demande"
  input PyRuntime handle;
  input Real currentTime;
  input Boolean pinBoolIn[8];
  output Boolean pinBoolOut[8];
  output Boolean pinIsOutput[8];
  output Real nextWakeTime;
  external "C" PyRuntime_sync(handle, currentTime, pinBoolIn, pinBoolOut, pinIsOutput, nextWakeTime) annotation(
    Include = "#include \"PyRuntimeImpl.c\"",
    IncludeDirectory = "modelica://MicroPythonMCU/Resources/Include",
    Library = "python312",
    LibraryDirectory = "modelica://MicroPythonMCU/Resources/Library/win64");
end PyRuntime_sync;
