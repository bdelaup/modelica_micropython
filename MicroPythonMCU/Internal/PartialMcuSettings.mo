within MicroPythonMCU.Internal;
partial model PartialMcuSettings "User parameters of a microcontroller (program, file system, execution time, debugging, electrical stages of the pins) - declared once, shared by MCU, RPi_Pico and their core Internal.McuCore"
  parameter String scriptPath = Modelica.Utilities.Files.loadResource("modelica://MicroPythonMCU/Resources/Scripts/MCU/demo.py") "Path of the user script (.py) - with an active file system, run after boot.py instead of main.py; empty = main.py from the flash" annotation(
    Dialog(group = "Python script", loadSelector(filter = "Python files (*.py)", caption = "Select a Python script")));
  parameter Boolean addScriptDirToPath = true "Make the .py files next to the script importable (e.g. import my_module) - mimics the real Pico (flash root folder on sys.path)" annotation(
    Dialog(group = "Python script"));
  parameter String libraryPath = "" "Optional: a .py file from a shared library folder to make importable (the folder containing this file is added to the module search path) - leave empty if unused" annotation(
    Dialog(group = "Python script", loadSelector(filter = "Python files (*.py)", caption = "Select a file of the library to add")));
  parameter Boolean fsEnabled = false "Enable the file system (simulated flash) - disabled: open() and os raise OSError" annotation(
    Dialog(tab = "File system", group = "Simulated flash"),
    choices(checkBox = true));
  parameter String fsSource = "" "Initial image of the flash (folder: data, boot.py, main.py, lib/), copied at each simulation and never modified - any file of the folder, the folder path or a modelica:// URI; empty = blank flash, only the script runs" annotation(
    Dialog(tab = "File system", group = "Simulated flash", enable = fsEnabled, loadSelector(filter = "All files (*)", caption = "Select a file of the file system folder")));
  parameter String fsWorkspace = "." "Workspace: folder where each simulation creates its copy, named <instance>_<FS name>_<date>_<time> (created if missing) - \".\" or relative path = from the simulation folder; full path of the copy shown in the log" annotation(
    Dialog(tab = "File system", group = "Simulated flash", enable = fsEnabled, saveSelector(filter = "All files (*)", caption = "Choose (or name) the workspace folder")));
  parameter Boolean fsOpenExplorer = true "Open Windows Explorer on the copy at the end of the simulation" annotation(
    Dialog(tab = "File system", group = "Simulated flash", enable = fsEnabled),
    choices(checkBox = true));
  parameter Modelica.Units.SI.Time tickPeriod = 0.1 "Period of the minimal sync point (output freshness if the script never sleeps)";
  parameter Modelica.Units.SI.Time gpioOpTime = 5e-6 "Execution time of a pin access (Pin.value(), on(), off()): two writes without sleep() give a pulse of this width (bit-banging) - order of magnitude of MicroPython on RP2040; 0 = instantaneous accesses" annotation(
    Dialog(tab = "Execution time"));
  parameter Modelica.Units.SI.Time hangWarningTime = 10 "Real (wall-clock) time after which a warning is logged if the script does not let the simulation advance (loop without sleep() nor pin access, or with gpioOpTime = 0) - the simulation keeps waiting; 0 = no warning" annotation(
    Dialog(tab = "Execution time"));
  parameter Boolean debugEnabled = false "Debug the program with VS Code: at the start of the simulation, the microcontroller waits until VS Code attaches (debugpy, Run and Debug > attach to localhost:debugPort); simulated time stays frozen while the program is paused - one microcontroller per model" annotation(
    Dialog(tab = "Debugging"),
    choices(checkBox = true));
  parameter Integer debugPort = 5678 "Local TCP port on which the debugger (debugpy) listens - the port of the VS Code attach configuration" annotation(
    Dialog(tab = "Debugging", enable = debugEnabled));
  parameter Modelica.Units.SI.Voltage VOL = Interfaces.VOL "Logic low voltage" annotation(
    Dialog(tab = "Electrical", group = "Logic levels"));
  parameter Modelica.Units.SI.Voltage VIH = Interfaces.VIH "Threshold above which an input reads high" annotation(
    Dialog(tab = "Electrical", group = "Logic levels"));
  parameter Modelica.Units.SI.Voltage VIL = Interfaces.VIL "Threshold below which an input reads low" annotation(
    Dialog(tab = "Electrical", group = "Logic levels"));
  parameter Modelica.Units.SI.Resistance ROut = Interfaces.ROut "Output series resistance (drive strength)" annotation(
    Dialog(tab = "Electrical", group = "Output stages"));
  parameter Modelica.Units.SI.Resistance ledSeriesR = 330 "Series resistance of the on-board LED (internal, GP25)" annotation(
    Dialog(tab = "Electrical", group = "Output stages"));
  parameter Modelica.Units.SI.Resistance RPullUp = Interfaces.RPull "Internal pull-up resistor to the supply, switched on by Pin(n, mode, Pin.PULL_UP) and by I2C() on SCL/SDA" annotation(
    Dialog(tab = "Electrical", group = "Input stages"));
  parameter Modelica.Units.SI.Resistance RPullDown = Interfaces.RPull "Internal pull-down resistor to GND, switched on by Pin(n, mode, Pin.PULL_DOWN)" annotation(
    Dialog(tab = "Electrical", group = "Input stages"));
  parameter Modelica.Units.SI.Conductance GOff = Interfaces.GOff "Leakage of a pin that does not drive its line (input, released I2C line), towards GND: 1e-9 S = 1 GOhm" annotation(
    Dialog(tab = "Electrical", group = "Input stages"));
  annotation(
    Documentation(info = "<html>
<p>Parameters set by the user on <code>MCU</code> or <code>RPi_Pico</code>, with their dialog tabs. Both boards extend this class and pass every parameter on to their core (<code>Internal.McuCore</code>, which extends it too), so that the parameters are written only once. <code>ledSeriesR</code> is used by the boards (on-board LED), not by the core.</p>
</html>"));
end PartialMcuSettings;
