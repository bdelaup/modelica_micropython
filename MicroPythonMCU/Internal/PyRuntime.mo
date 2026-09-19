within MicroPythonMCU.Internal;
class PyRuntime "External Object encapsulant l'interpréteur CPython qui exécute le script utilisateur (jalon M3 : exécution synchrone unique, pas encore de thread/sleep - cf. requirements.md)"
  extends ExternalObject;

  function constructor
    input String scriptPath "Chemin vers le script .py de l'utilisateur";
    input String pythonHome "Chemin vers la distribution Python embarquée (Resources/PythonRuntime)";
    output PyRuntime handle;
    external "C" handle = PyRuntime_new(scriptPath, pythonHome) annotation(
      Include = "#include \"PyRuntimeImpl.c\"",
      IncludeDirectory = "modelica://MicroPythonMCU/Resources/Include",
      Library = "python312",
      LibraryDirectory = "modelica://MicroPythonMCU/Resources/Library/win64");
  end constructor;

  function destructor
    input PyRuntime handle;
    external "C" PyRuntime_destroy(handle) annotation(
      Include = "#include \"PyRuntimeImpl.c\"",
      IncludeDirectory = "modelica://MicroPythonMCU/Resources/Include",
      Library = "python312",
      LibraryDirectory = "modelica://MicroPythonMCU/Resources/Library/win64");
  end destructor;
end PyRuntime;
