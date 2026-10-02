within MicroPythonMCU;

model MCU "Simulated programmable microcontroller, driven by a MicroPython-compatible Python script"
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
  parameter Modelica.Units.SI.Voltage VOH = Interfaces.VOH "Logic high voltage" annotation(
    Dialog(tab = "Electrical", group = "Logic levels"));
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
  parameter Modelica.Units.SI.Resistance RPullUp = Interfaces.RPull "Internal pull-up resistor to VOH, switched on by Pin(n, mode, Pin.PULL_UP) and by I2C() on SCL/SDA" annotation(
    Dialog(tab = "Electrical", group = "Input stages"));
  parameter Modelica.Units.SI.Resistance RPullDown = Interfaces.RPull "Internal pull-down resistor to GND, switched on by Pin(n, mode, Pin.PULL_DOWN)" annotation(
    Dialog(tab = "Electrical", group = "Input stages"));
  parameter Modelica.Units.SI.Conductance GOff = Interfaces.GOff "Leakage of a pin that does not drive its line (input, released I2C line), towards GND: 1e-9 S = 1 GOhm" annotation(
    Dialog(tab = "Electrical", group = "Input stages"));
  Modelica.Electrical.Analog.Interfaces.PositivePin GP0 "GPIO 0 (machine.Pin(0), machine.ADC(0) or machine.PWM(0))" annotation(
    Placement(transformation(origin = {-62, 50}, extent = {{-7, -7}, {7, 7}})));
  Modelica.Electrical.Analog.Interfaces.PositivePin GP1 "GPIO 1 (machine.Pin(1), machine.ADC(1) or machine.PWM(1))" annotation(
    Placement(transformation(origin = {-62, 20}, extent = {{-7, -7}, {7, 7}})));
  Modelica.Electrical.Analog.Interfaces.PositivePin GP2 "GPIO 2 (machine.Pin(2), machine.ADC(2) or machine.PWM(2))" annotation(
    Placement(transformation(origin = {-62, -20}, extent = {{-7, -7}, {7, 7}})));
  Modelica.Electrical.Analog.Interfaces.PositivePin GP3 "GPIO 3 (machine.Pin(3), machine.ADC(3) or machine.PWM(3))" annotation(
    Placement(transformation(origin = {-62, -50}, extent = {{-7, -7}, {7, 7}})));
  Modelica.Electrical.Analog.Interfaces.PositivePin GP4 "GPIO 4 (machine.Pin(4), machine.ADC(4) or machine.PWM(4))" annotation(
    Placement(transformation(origin = {62, 50}, extent = {{-7, -7}, {7, 7}})));
  Modelica.Electrical.Analog.Interfaces.PositivePin GP5 "GPIO 5 (machine.Pin(5), machine.ADC(5) or machine.PWM(5))" annotation(
    Placement(transformation(origin = {62, 20}, extent = {{-7, -7}, {7, 7}})));
  Modelica.Electrical.Analog.Interfaces.PositivePin GP6 "GPIO 6 (machine.Pin(6), machine.ADC(6) or machine.PWM(6))" annotation(
    Placement(transformation(origin = {62, -20}, extent = {{-7, -7}, {7, 7}})));
  Modelica.Electrical.Analog.Interfaces.PositivePin GP7 "GPIO 7 (machine.Pin(7), machine.ADC(7) or machine.PWM(7))" annotation(
    Placement(transformation(origin = {62, -50}, extent = {{-7, -7}, {7, 7}})));
  Modelica.Electrical.Analog.Interfaces.NegativePin GND "Common reference (ground) - connect it to the ground of the external circuit" annotation(
    Placement(transformation(origin = {0, -78}, extent = {{-6, -6}, {6, 6}}), iconTransformation(origin = {0, -78}, extent = {{-6, -6}, {6, 6}})));
  Interfaces.DisplayLinkOutput Display0 "Logical link to an educational display peripheral (machine.Display(0).write()) - simplified causal link (message delivered instantly at the sync point), no real voltage/current nor bit-by-bit serial waveform, see requirements.md decision \"Périphérique d'affichage pédagogique\"" annotation(
    Placement(transformation(origin = {62, 78}, extent = {{-7, -7}, {7, 7}}), iconTransformation(origin = {49, 75}, extent = {{-10, -10}, {10, 10}}, rotation = 90)));
  MicroPythonMCU.Peripherals.LED builtinLed "On-board LED of the Raspberry Pi Pico (real GP25), permanently wired internally (no external connector). Public (not protected like the rest of the implementation): protected variables do not appear in the simulation results in this OpenModelica installation, which would break the DynamicSelect animation of the icon (checked empirically, see requirements.md) - builtinLed.mean.y, already public through Peripherals.LED, is reused directly." annotation(
    Placement(visible = false, transformation(extent = {{-150, -130}, {-130, -110}})));
protected
  Modelica.Units.SI.Voltage pinNodeVoltage[9] "Actual voltage of each pin (index 9 = internal node of the on-board LED)";
  Boolean pinBoolIn[9](each start = false, each fixed = true) "Logic value read on each pin (voltage compared with the VIL/VIH thresholds), including index 9 (on-board LED), which thus reads back its own state like a normal pin";
  Boolean pinBoolOut[9] "Value driven on each pin (output of the last sync point); index 9 = on-board LED (real GP25)";
  Boolean pinIsOutputD[9] "Direction of each pin (output of the last sync point)";
  Integer pinBoolInC[9] "pinBoolIn as passed to PyRuntime_sync (0/1): arrays of Boolean are not exchanged with the C code, see Internal.PyRuntime_sync";
  discrete Integer pinBoolOutC[9](each start = 0, each fixed = true) "pinBoolOut as returned by PyRuntime_sync (0/1)";
  discrete Integer pinIsOutputC[9](each start = 0, each fixed = true) "pinIsOutputD as returned by PyRuntime_sync (0/1)";
  discrete Integer pinPullC[9](each start = 0, each fixed = true) "Internal pull resistor of each pin as returned by PyRuntime_sync: 0 = none, 1 = PULL_UP, 2 = PULL_DOWN";
  constant Modelica.Units.SI.Conductance GPullOff = 1e-12 "Conductance of a switched-off pull branch: never exactly 0 (a VariableConductor should not reach zero), and far below GOff so that a floating input still settles towards GND";
  discrete Modelica.Units.SI.Frequency pwmFreq[9](each start = 0, each fixed = true) "PWM frequency of each pin (Hz); 0 = not in PWM mode (plain digital output through pinBoolOut), see machine.PWM";
  discrete Real pwmDuty[9](each start = 0, each fixed = true) "PWM duty cycle of each pin (0-1), relevant only if pwmFreq > 0";
  Modelica.Units.SI.Time pwmPeriod[9] "1/pwmFreq, with a floor to avoid a division by zero when pwmFreq = 0 (pin not in PWM)";
  discrete Integer uartTxPin(start = 0, fixed = true) "Pin assigned to serial transmission (0 = none); once assigned it stays so, even between frames, because the idle line must be HIGH - see machine.UART";
  discrete Boolean uartTxLevel(start = true, fixed = true) "Logic level to hold on the transmit pin (idle = high), published by the C code: the next sync point falls on the next level CHANGE of the frame, so consecutive identical bits cost no event";
  discrete Modelica.Units.SI.Time nextWakeTime(start = 0, fixed = true) "Next wake-up requested by the script (sleep), or +inf once finished";
  Internal.PyRuntime rt = Internal.PyRuntime(scriptPath, Modelica.Utilities.Files.loadResource("modelica://MicroPythonMCU/Resources/PythonRuntime"), addScriptDirToPath, libraryPath, Modelica.Utilities.Files.loadResource("modelica://MicroPythonMCU/Resources/Scripts/_shim/machine_time_shim.py"), fsEnabled, Internal.ResolvePath(fsSource), Internal.ResolvePath(fsWorkspace), fsOpenExplorer, getInstanceName(), gpioOpTime) "Embedded Python interpreter running the user script" annotation(
    Placement(visible = false, transformation(extent = {{-20, 75}, {20, 95}})));
  Modelica.Electrical.Analog.Sources.SignalVoltage src[9] "Voltage source driven by the script (VOH/VOL) when the pin is an output; index 9 = on-board LED" annotation(
    Placement(visible = false, transformation(extent = {{-190, -90}, {-150, -50}})));
  Modelica.Electrical.Analog.Basic.Resistor rOut[9](each R = ROut) "Series resistance (drive strength); index 9 = on-board LED" annotation(
    Placement(visible = false, transformation(extent = {{-130, -90}, {-90, -50}})));
  Modelica.Electrical.Analog.Ideal.IdealOpeningSwitch sw[9](each Goff = GOff) "Open (high impedance, leakage GOff) when the pin is an input; index 9 = on-board LED" annotation(
    Placement(visible = false, transformation(extent = {{-70, -90}, {-30, -50}})));
  Modelica.Electrical.Analog.Sensors.VoltageSensor sns[9] "Measures the voltage actually present on the pin, whatever its direction; index 9 = on-board LED" annotation(
    Placement(visible = false, transformation(extent = {{-10, -90}, {30, -50}})));
  Modelica.Electrical.Analog.Sources.ConstantVoltage vPull(V = VOH) "Internal supply rail of the pull-up resistors" annotation(
    Placement(visible = false, transformation(extent = {{30, -130}, {50, -110}})));
  Modelica.Electrical.Analog.Basic.VariableConductor gPullUp[9] "Internal pull-up of each pin, between the pin and vPull: 1/RPullUp when active, GPullOff otherwise - a conductance rather than an Ideal switch, see requirements.md decision \"LED embarquée\" (trap 2)" annotation(
    Placement(visible = false, transformation(extent = {{60, -90}, {100, -50}})));
  Modelica.Electrical.Analog.Basic.VariableConductor gPullDown[9] "Internal pull-down of each pin, between the pin and GND: 1/RPullDown when active, GPullOff otherwise" annotation(
    Placement(visible = false, transformation(extent = {{110, -90}, {150, -50}})));
  Modelica.Electrical.Analog.Basic.Resistor ledResistor(R = ledSeriesR) "Series resistance of the on-board LED, between the internal GPIO bridge (index 9) and builtinLed" annotation(
    Placement(visible = false, transformation(extent = {{-190, -125}, {-170, -115}})));
public
equation
  connect(sw[1].n, GP0);
  connect(sns[1].p, GP0);
  connect(sw[2].n, GP1);
  connect(sns[2].p, GP1);
  connect(sw[3].n, GP2);
  connect(sns[3].p, GP2);
  connect(sw[4].n, GP3);
  connect(sns[4].p, GP3);
  connect(sw[5].n, GP4);
  connect(sns[5].p, GP4);
  connect(sw[6].n, GP5);
  connect(sns[6].p, GP5);
  connect(sw[7].n, GP6);
  connect(sns[7].p, GP6);
  connect(sw[8].n, GP7);
  connect(sns[8].p, GP7);
  for i in 1:9 loop
    connect(src[i].n, GND);
    connect(src[i].p, rOut[i].p);
    connect(rOut[i].n, sw[i].p);
    connect(sns[i].n, GND);
    pinNodeVoltage[i] = sns[i].v;
    pinBoolIn[i] = pinNodeVoltage[i] > (VIL + VIH)/2 "logic threshold halfway (approximation)";
    pinBoolInC[i] = if pinBoolIn[i] then 1 else 0;
    pinBoolOut[i] = pre(pinBoolOutC[i]) <> 0;
    pinIsOutputD[i] = pre(pinIsOutputC[i]) <> 0;
    pwmPeriod[i] = 1/max(pre(pwmFreq[i]), 1e-6);
    src[i].v = if pinIsOutputD[i] then (if pre(uartTxPin) == i then (if pre(uartTxLevel) then VOH else VOL) elseif pre(pwmFreq[i]) > 0 then (if mod(time, pwmPeriod[i]) < pre(pwmDuty[i])*pwmPeriod[i] then VOH else VOL) else (if pinBoolOut[i] then VOH else VOL)) else 0 "serial frame (level published by the C code at each change) if the pin is assigned to the UART, otherwise PWM square wave if pwmFreq > 0, otherwise plain digital output - see requirements.md";
    sw[i].control = not pinIsOutputD[i] "open (high impedance) if the pin is an input";
    connect(gPullUp[i].p, vPull.p);
    connect(gPullUp[i].n, sns[i].p);
    connect(gPullDown[i].p, sns[i].p);
    connect(gPullDown[i].n, GND);
    gPullUp[i].G = if pre(pinPullC[i]) == 1 then 1/RPullUp else GPullOff;
    gPullDown[i].G = if pre(pinPullC[i]) == 2 then 1/RPullDown else GPullOff;
  end for;
  connect(vPull.n, GND);
  connect(sw[9].n, ledResistor.p);
  connect(sns[9].p, ledResistor.p);
  connect(ledResistor.n, builtinLed.p);
  connect(builtinLed.n, GND);
  when {initial(), time >= pre(nextWakeTime), sample(0, tickPeriod), change(pinBoolIn[1]) and not pre(pinIsOutputD[1]), change(pinBoolIn[2]) and not pre(pinIsOutputD[2]), change(pinBoolIn[3]) and not pre(pinIsOutputD[3]), change(pinBoolIn[4]) and not pre(pinIsOutputD[4]), change(pinBoolIn[5]) and not pre(pinIsOutputD[5]), change(pinBoolIn[6]) and not pre(pinIsOutputD[6]), change(pinBoolIn[7]) and not pre(pinIsOutputD[7]), change(pinBoolIn[8]) and not pre(pinIsOutputD[8]), change(pinBoolIn[9]) and not pre(pinIsOutputD[9])} then
    (pinBoolOutC, pinIsOutputC, pinPullC, pwmFreq, pwmDuty, Display0.seq, Display0.payload, uartTxPin, uartTxLevel, nextWakeTime) = Internal.PyRuntime_sync(rt, time, pinBoolInC, pinNodeVoltage);
    Display0.charCode = Internal.StringToCharCodes(Display0.payload, Interfaces.DISPLAY_COLS) "ASCII codes derived from Display0.payload (a String, which cannot be stored in the results), so that the connected display peripheral can animate the text actually received on its icon - see Internal.StringToCharCodes";
  end when;
  annotation(
    Icon(coordinateSystem(preserveAspectRatio = true, extent = {{-100, -100}, {100, 100}}), graphics = {Rectangle(fillColor = {60, 60, 60}, fillPattern = FillPattern.Solid, extent = {{-55, 65}, {55, -65}}), Ellipse(fillColor = DynamicSelect({40, 90, 40}, {integer(40 + min(1, max(0, builtinLed.mean.y)/builtinLed.IMax)*(-40)), integer(90 + min(1, max(0, builtinLed.mean.y)/builtinLed.IMax)*130), integer(40 + min(1, max(0, builtinLed.mean.y)/builtinLed.IMax)*(-40))}), fillPattern = FillPattern.Solid, extent = {{-6, 46}, {6, 34}}), Text(textColor = {255, 255, 255}, extent = {{-40, 18}, {40, -2}}, textString = "MCU", textStyle = {TextStyle.Bold}), Text(textColor = {255, 255, 255}, extent = {{-46, 57}, {-8, 43}}, textString = "GP0", horizontalAlignment = TextAlignment.Left), Text(textColor = {255, 255, 255}, extent = {{-46, 27}, {-8, 13}}, textString = "GP1", horizontalAlignment = TextAlignment.Left), Text(textColor = {255, 255, 255}, extent = {{-46, -13}, {-8, -27}}, textString = "GP2", horizontalAlignment = TextAlignment.Left), Text(textColor = {255, 255, 255}, extent = {{-46, -43}, {-8, -57}}, textString = "GP3", horizontalAlignment = TextAlignment.Left), Text(textColor = {255, 255, 255}, extent = {{8, 57}, {46, 43}}, textString = "GP4", horizontalAlignment = TextAlignment.Right), Text(textColor = {255, 255, 255}, extent = {{8, 27}, {46, 13}}, textString = "GP5", horizontalAlignment = TextAlignment.Right), Text(textColor = {255, 255, 255}, extent = {{8, -13}, {46, -27}}, textString = "GP6", horizontalAlignment = TextAlignment.Right), Text(textColor = {255, 255, 255}, extent = {{8, -43}, {46, -57}}, textString = "GP7", horizontalAlignment = TextAlignment.Right), Text(extent = {{-25, -83}, {25, -90}}, textString = "GND"), Text(origin = {-54, -51}, textColor = {255, 255, 255}, extent = {{55, 106}, {108, 115}}, textString = "DISPLAY", horizontalAlignment = TextAlignment.Right), Text(origin = {0, -34}, textColor = {0, 0, 255}, extent = {{-150, 140}, {150, 100}}, textString = "%name")}),
    Diagram(coordinateSystem(preserveAspectRatio = true, extent = {{-100, -100}, {100, 100}}), graphics),
    Documentation(info = "<html>
<p>Complete model: electrical GPIO bridge (driven voltage source, series resistance, ideal switch, voltage sensor) controlled by <code>PyRuntime</code>, which runs the user's Python script (MicroPython-compatible, <code>machine.Pin</code>/<code>machine.ADC</code>/<code>machine.PWM</code>/<code>time</code> API) in a thread that intercepts <code>sleep()</code>. API reference: Raspberry Pi Pico (RP2040), see <code>requirements.md</code> — not shown on the icon, to stay generic. Each pin <code>GP0</code>-<code>GP7</code> can be used, as the script chooses, as digital (<code>machine.Pin</code>), analog (<code>machine.ADC</code>, 16-bit reading of the voltage measured by the sensor already present in the bridge) or PWM (<code>machine.PWM</code>, square wave generated continuously on the Modelica side once frequency/duty cycle are set — no round trip with the Python thread at each edge, see <code>requirements.md</code>) — unlike the real Pico, where only some pins are ADC-capable, see the restrictions in <code>requirements.md</code>.</p>
<p>The script can import a helper module (<code>import my_module</code>): by default (<code>addScriptDirToPath</code>), the script's folder is added to the Python search path, and <code>libraryPath</code> can additionally designate a <code>.py</code> file of a shared library (its folder is then added too) — see <code>requirements.md</code>, decision \"Import de modules auxiliaires\".</p>
<p>File system (simulated flash, \"File system\" tab): disabled by default (<code>fsEnabled</code>), <code>open()</code> and <code>os</code> then raise <code>OSError</code>. When enabled, each simulation copies the <code>fsSource</code> folder (empty = blank flash) into a new folder of <code>fsWorkspace</code> (\".\" by default: the simulation folder), named <code>&lt;instance&gt;_&lt;FS name&gt;_&lt;date&gt;_&lt;time&gt;</code>; its full path is shown in the log at the start and at the end of the simulation, and Windows Explorer opens on it at the end (<code>fsOpenExplorer</code>). The script sees it as the root <code>/</code> of the flash: <code>open()</code> and the MicroPython-style <code>os</code> module (<code>listdir</code>, <code>mkdir</code>, <code>remove</code>, <code>rename</code>, <code>stat</code>, <code>statvfs</code>, <code>chdir</code>, <code>getcwd</code>...) are confined to it, and the root as well as <code>/lib</code> are on the import path. The source is never modified: each simulation starts again from the same state and stays deterministic (the timestamp only names the copy, the script does not see it). Program run, as on a board: <code>boot.py</code> from the flash if it exists, then <code>scriptPath</code> instead of <code>main.py</code> (like Thonny on an already booted board), or <code>main.py</code> from the flash if <code>scriptPath</code> is empty. See <code>requirements.md</code>, decision \"Système de fichiers\".</p>
<p>The electrical parameters (logic levels, output resistances) are grouped in the \"Electrical\" tab.</p>
<p>The <code>Display0</code> connector exposes a logical link to an educational display peripheral (<code>machine.Display(0).write(text)</code>): unlike the <code>GPx</code> pins, it is not an electrical connector (<code>Modelica.Electrical.Analog</code>) but a causal logical connector (<code>Interfaces.DisplayLinkOutput</code>, message delivered instantly at the sync point, no serial waveform nor simulated baud rate) — to be connected to the <code>displayLink</code> (<code>Interfaces.DisplayLinkInput</code>) of a <code>Peripherals.Display</code>, an optional component (connect it or not, depending on the circuit). See <code>requirements.md</code>, decision \"Périphérique d'affichage pédagogique\".</p>
<p>The dot on the icon stands for the on-board LED of the Raspberry Pi Pico (wired to <code>GP25</code> on the real board). It is handled like a normal pin, with the same internal electrical bridge as <code>GP0</code>-<code>GP7</code> (<code>SignalVoltage</code>/<code>Resistor</code>/<code>IdealOpeningSwitch</code>/<code>VoltageSensor</code>, index 9 of the same arrays) — only without an external connector: the output of this internal bridge permanently feeds a series resistance (<code>ledResistor</code>) and a real <code>Peripherals.LED</code> (<code>builtinLed</code>) connected to <code>GND</code>, true to the actual wiring of the Pico. It is driven from the script exactly like the 8 GPIO pins (<code>machine.Pin(25, machine.Pin.OUT).on()</code>/<code>.off()</code>); it is not one of the 8 exposed GPIO pins (see the restrictions in <code>requirements.md</code>), so no external circuit can be connected to it. Bright green when on, dark green otherwise — visible while replaying a simulation result with animation in OMEdit (<code>DynamicSelect</code> on <code>builtinLed.mean.y</code>), not on a static rendering.</p>
<p><em>Internal schematic (Diagram) deliberately empty: the blocks of the electrical bridge are hidden (<code>visible = false</code>) rather than neatly routed — a readable schematic will be drawn later, see requirements.md.</em></p>
</html>"));
end MCU;
