within MicroPythonMCU.Internal;

impure function LogicAnalyzer_record "Records the logic levels of the channels of a LogicAnalyzer at the current instant"
  input LogicAnalyzerCapture an;
  input Real currentTime;
  input Integer levels[:] "Logic level of each channel (0/1) - Integer, never Boolean, in an array passed to C";
  output Integer calls "Number of calls so far, so that the when clause has a variable to assign";
  // Library annotation: -lwinpthread links winpthread dynamically, otherwise ModelicaError crashes
  // the simulation under OpenModelica/Windows (see requirements.md, decision
  // "Comportement en cas d'exception non geree dans le script").
  external "C" calls = LogicAnalyzer_record(an, currentTime, levels, size(levels, 1)) annotation(
    Include = "#include \"AnalyzerImpl.c\"",
    Library = "-lwinpthread",
    IncludeDirectory = "modelica://MicroPythonMCU/Resources/Include");
  annotation(
    Documentation(info = "<html>
<p><code>impure</code>: called from a <code>when</code> at each level change. Called several times at the same instant (event iterations), only the last levels of the instant are written.</p>
</html>"));
end LogicAnalyzer_record;
