within MicroPythonMCU.Internal;

impure function LogicAnalyzer_finish "Notes the final instant of the simulation, so that the recording of a LogicAnalyzer covers the whole simulated time"
  input LogicAnalyzerCapture an;
  input Real currentTime;
  output Integer done;
  // Library annotation: -lwinpthread links winpthread dynamically, otherwise ModelicaError crashes
  // the simulation under OpenModelica/Windows (see requirements.md, decision
  // "Comportement en cas d'exception non geree dans le script").
  external "C" done = LogicAnalyzer_finish(an, currentTime) annotation(
    Include = "#include \"AnalyzerImpl.c\"",
    Library = "-lwinpthread",
    IncludeDirectory = "modelica://MicroPythonMCU/Resources/Include");
end LogicAnalyzer_finish;
