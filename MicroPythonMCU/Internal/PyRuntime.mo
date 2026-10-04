within MicroPythonMCU.Internal;
class PyRuntime "External Object wrapping the CPython interpreter that runs the user script in a worker thread, with sleep() interception - see requirements.md"
  extends ExternalObject;

  function constructor
    input String scriptPath "Path of the user's .py script (empty string: main.py of the file system)";
    input String pythonHome "Path of the embedded Python distribution (Resources/PythonRuntime)";
    input Boolean addScriptDirToPath "Adds the folder of scriptPath to the Python module search path";
    input String libraryPath "Optional (empty string = disabled): .py file of a shared library - its folder is added to the search path";
    input String shimPath "Path of the library's machine/time shim (Resources/Scripts/_shim/machine_time_shim.py), run before the user script";
    input Boolean fsEnabled "File system enabled";
    input String fsSource "Folder of the initial file system, copied at each simulation (empty string = blank flash)";
    input String fsWorkspace "Folder where the timestamped copy of the file system is created (empty or relative: from the simulation folder)";
    input Boolean fsOpenExplorer "Open Windows Explorer on the copy at the end of the simulation";
    input String instanceName "Instance name (getInstanceName()), reused in the name of the copy";
    input Real gpioOpTime "Execution time (s) of a pin access (Pin.value()/on()/off()); 0 = instantaneous accesses";
    input Real hangWarningTime "Real (wall-clock) time (s) after which a warning is logged if the script does not let the simulation advance; 0 = never";
    input Boolean debugEnabled "Waits for VS Code (debugpy) at the start of the simulation, to debug the program";
    input Integer debugPort "Local TCP port on which debugpy listens";
    output PyRuntime handle;
    // Library annotation: -lwinpthread links winpthread dynamically, otherwise ModelicaError crashes
    // the simulation under OpenModelica/Windows (see requirements.md, decision
    // "Comportement en cas d'exception non geree dans le script").
    external "C" handle = PyRuntime_new(scriptPath, pythonHome, addScriptDirToPath, libraryPath, shimPath, fsEnabled, fsSource, fsWorkspace, fsOpenExplorer, instanceName, gpioOpTime, hangWarningTime, debugEnabled, debugPort) annotation(
      Include = "#include \"PyRuntimeImpl.c\"",
      Library = "-lwinpthread",
      IncludeDirectory = "modelica://MicroPythonMCU/Resources/Include");
  end constructor;

  function destructor
    input PyRuntime handle;
    external "C" PyRuntime_destroy(handle) annotation(
      Include = "#include \"PyRuntimeImpl.c\"",
      Library = "-lwinpthread",
      IncludeDirectory = "modelica://MicroPythonMCU/Resources/Include");
  end destructor;
end PyRuntime;
