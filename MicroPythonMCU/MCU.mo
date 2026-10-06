within MicroPythonMCU;

model MCU "Simulated programmable microcontroller, driven by a MicroPython-compatible Python script"
  extends Internal.PartialMcuSettings;
  parameter Modelica.Units.SI.Voltage VOH = Interfaces.VOH "Logic high voltage: ideal internal supply, high level of the outputs and of the pull-ups" annotation(
    Dialog(tab = "Electrical", group = "Logic levels"));
  parameter Boolean useGroundPin = true "Show the GND pin - unchecked: the microcontroller is referenced to the simulation ground (0 V), nothing to wire" annotation(
    Dialog(tab = "Electrical", group = "Supply"),
    choices(checkBox = true));
  Modelica.Electrical.Analog.Interfaces.PositivePin GP0 "GPIO 0 (machine.Pin(0), machine.ADC(0) or machine.PWM(0))" annotation(
    Placement(transformation(origin = {-150, 70}, extent = {{-7, -7}, {7, 7}}), iconTransformation(origin = {-60, 50}, extent = {{-5, -5}, {5, 5}})));
  Modelica.Electrical.Analog.Interfaces.PositivePin GP1 "GPIO 1 (machine.Pin(1), machine.ADC(1) or machine.PWM(1))" annotation(
    Placement(transformation(origin = {-150, 50}, extent = {{-7, -7}, {7, 7}}), iconTransformation(origin = {-60, 20}, extent = {{-5, -5}, {5, 5}})));
  Modelica.Electrical.Analog.Interfaces.PositivePin GP2 "GPIO 2 (machine.Pin(2), machine.ADC(2) or machine.PWM(2))" annotation(
    Placement(transformation(origin = {-150, 30}, extent = {{-7, -7}, {7, 7}}), iconTransformation(origin = {-60, -20}, extent = {{-5, -5}, {5, 5}})));
  Modelica.Electrical.Analog.Interfaces.PositivePin GP3 "GPIO 3 (machine.Pin(3), machine.ADC(3) or machine.PWM(3))" annotation(
    Placement(transformation(origin = {-150, 10}, extent = {{-7, -7}, {7, 7}}), iconTransformation(origin = {-60, -50}, extent = {{-5, -5}, {5, 5}})));
  Modelica.Electrical.Analog.Interfaces.PositivePin GP4 "GPIO 4 (machine.Pin(4), machine.ADC(4) or machine.PWM(4))" annotation(
    Placement(transformation(origin = {-150, -10}, extent = {{-7, -7}, {7, 7}}), iconTransformation(origin = {60, 50}, extent = {{-5, -5}, {5, 5}})));
  Modelica.Electrical.Analog.Interfaces.PositivePin GP5 "GPIO 5 (machine.Pin(5), machine.ADC(5) or machine.PWM(5))" annotation(
    Placement(transformation(origin = {-150, -30}, extent = {{-7, -7}, {7, 7}}), iconTransformation(origin = {60, 20}, extent = {{-5, -5}, {5, 5}})));
  Modelica.Electrical.Analog.Interfaces.PositivePin GP6 "GPIO 6 (machine.Pin(6), machine.ADC(6) or machine.PWM(6))" annotation(
    Placement(transformation(origin = {-150, -50}, extent = {{-7, -7}, {7, 7}}), iconTransformation(origin = {60, -20}, extent = {{-5, -5}, {5, 5}})));
  Modelica.Electrical.Analog.Interfaces.PositivePin GP7 "GPIO 7 (machine.Pin(7), machine.ADC(7) or machine.PWM(7))" annotation(
    Placement(transformation(origin = {-150, -70}, extent = {{-7, -7}, {7, 7}}), iconTransformation(origin = {60, -50}, extent = {{-5, -5}, {5, 5}})));
  Modelica.Electrical.Analog.Interfaces.NegativePin GND if useGroundPin "Common reference (ground) - connect it to the ground of the external circuit - shown when useGroundPin is checked" annotation(
    Placement(transformation(origin = {0, -140}, extent = {{-6, -6}, {6, 6}}), iconTransformation(origin = {0, -70}, extent = {{-5, -5}, {5, 5}})));
  Interfaces.DisplayLinkOutput Display0 "Logical link to an educational display peripheral (machine.Display(0).write()) - simplified causal link (message delivered instantly at the sync point), no real voltage/current nor bit-by-bit serial waveform, see requirements.md decision \"Périphérique d'affichage pédagogique\"" annotation(
    Placement(transformation(origin = {150, 24}, extent = {{-7, -7}, {7, 7}}), iconTransformation(origin = {50, 70}, extent = {{-5, -5}, {5, 5}}, rotation = 90)));
  Internal.McuCore core(final nPins = 9, final pinIds = {0, 1, 2, 3, 4, 5, 6, 7, 25}, final pinCaps = {7, 7, 7, 7, 7, 7, 7, 7, 1}, final boardProfile = "generic", final instanceName = boardName, final scriptPath = scriptPath, final addScriptDirToPath = addScriptDirToPath, final libraryPath = libraryPath, final fsEnabled = fsEnabled, final fsSource = fsSource, final fsWorkspace = fsWorkspace, final fsOpenExplorer = fsOpenExplorer, final tickPeriod = tickPeriod, final gpioOpTime = gpioOpTime, final hangWarningTime = hangWarningTime, final debugEnabled = debugEnabled, final debugPort = debugPort, final VOL = VOL, final VIH = VIH, final VIL = VIL, final ROut = ROut, final ledSeriesR = ledSeriesR, final RPullUp = RPullUp, final RPullDown = RPullDown, final GOff = GOff) "Programmable core: GP0-GP7 = pin[1..8], on-board LED GP25 = pin[9]" annotation(
    Placement(transformation(extent = {{-40, -40}, {40, 40}})));
  MicroPythonMCU.Peripherals.LED builtinLed "On-board LED of the Raspberry Pi Pico (real GP25), wired inside the block (no external connector)" annotation(
    Placement(transformation(origin = {-20, -90}, extent = {{-10, -10}, {10, 10}})));
protected
  final parameter String boardName = getInstanceName() "Instance name of the board, given to the core (log prefix, name of the copy of the flash): getInstanceName() written in the modifier of core would return the name of the core";
  Modelica.Electrical.Analog.Basic.Resistor ledResistor(R = ledSeriesR) "Series resistance of the on-board LED" annotation(
    Placement(transformation(origin = {-60, -90}, extent = {{-10, -10}, {10, 10}})));
  Modelica.Electrical.Analog.Sources.ConstantVoltage vddSource(V = VOH) "Ideal internal supply (VOH)" annotation(
    Placement(transformation(origin = {60, 90}, extent = {{-10, -10}, {10, 10}})));
  Modelica.Electrical.Analog.Basic.Ground implicitGround if not useGroundPin "Simulation ground, when there is no GND pin" annotation(
    Placement(transformation(origin = {40, -90}, extent = {{-10, -10}, {10, 10}})));
equation
  connect(GP0, core.pin[1]) annotation(
    Line(points = {{-150, 70}, {-90, 70}, {-90, 0}, {-44, 0}}, color = {0, 0, 255}));
  connect(GP1, core.pin[2]) annotation(
    Line(points = {{-150, 50}, {-90, 50}, {-90, 0}, {-44, 0}}, color = {0, 0, 255}));
  connect(GP2, core.pin[3]) annotation(
    Line(points = {{-150, 30}, {-90, 30}, {-90, 0}, {-44, 0}}, color = {0, 0, 255}));
  connect(GP3, core.pin[4]) annotation(
    Line(points = {{-150, 10}, {-90, 10}, {-90, 0}, {-44, 0}}, color = {0, 0, 255}));
  connect(GP4, core.pin[5]) annotation(
    Line(points = {{-150, -10}, {-90, -10}, {-90, 0}, {-44, 0}}, color = {0, 0, 255}));
  connect(GP5, core.pin[6]) annotation(
    Line(points = {{-150, -30}, {-90, -30}, {-90, 0}, {-44, 0}}, color = {0, 0, 255}));
  connect(GP6, core.pin[7]) annotation(
    Line(points = {{-150, -50}, {-90, -50}, {-90, 0}, {-44, 0}}, color = {0, 0, 255}));
  connect(GP7, core.pin[8]) annotation(
    Line(points = {{-150, -70}, {-90, -70}, {-90, 0}, {-44, 0}}, color = {0, 0, 255}));
  connect(core.pin[9], ledResistor.p) annotation(
    Line(points = {{-44, 0}, {-80, 0}, {-80, -90}, {-70, -90}}, color = {0, 0, 255}));
  connect(ledResistor.n, builtinLed.p) annotation(
    Line(points = {{-50, -90}, {-30, -90}}, color = {0, 0, 255}));
  connect(builtinLed.n, core.gnd) annotation(
    Line(points = {{-10, -90}, {0, -90}, {0, -44}}, color = {0, 0, 255}));
  connect(core.gnd, GND) annotation(
    Line(points = {{0, -44}, {0, -140}}, color = {0, 0, 255}));
  connect(vddSource.p, core.vdd) annotation(
    Line(points = {{50, 90}, {0, 90}, {0, 44}}, color = {0, 0, 255}));
  connect(vddSource.p, core.vref) annotation(
    Line(points = {{50, 90}, {-24, 90}, {-24, 44}}, color = {0, 0, 255}));
  connect(vddSource.n, core.gnd) annotation(
    Line(points = {{70, 90}, {170, 90}, {170, -70}, {0, -70}, {0, -44}}, color = {0, 0, 255}));
  connect(implicitGround.p, core.gnd) annotation(
    Line(points = {{40, -80}, {40, -70}, {0, -70}, {0, -44}}, color = {0, 0, 255}));
  connect(core.Display0, Display0) annotation(
    Line(points = {{44, 24}, {150, 24}}, color = {28, 108, 200}));
  annotation(
    Icon(coordinateSystem(preserveAspectRatio = true, extent = {{-100, -100}, {100, 100}}, initialScale = 0.2), graphics = {Rectangle(fillColor = {60, 60, 60}, fillPattern = FillPattern.Solid, extent = {{-55, 65}, {55, -65}}), Ellipse(fillColor = DynamicSelect({40, 90, 40}, {integer(40 + min(1, max(0, builtinLed.mean.y)/builtinLed.IMax)*(-40)), integer(90 + min(1, max(0, builtinLed.mean.y)/builtinLed.IMax)*130), integer(40 + min(1, max(0, builtinLed.mean.y)/builtinLed.IMax)*(-40))}), fillPattern = FillPattern.Solid, extent = {{-6, 46}, {6, 34}}), Text(textColor = {255, 255, 255}, extent = {{-40, 18}, {40, -2}}, textString = "MCU", textStyle = {TextStyle.Bold}), Text(textColor = {255, 255, 255}, extent = {{-46, 57}, {-8, 43}}, textString = "GP0", horizontalAlignment = TextAlignment.Left), Text(textColor = {255, 255, 255}, extent = {{-46, 27}, {-8, 13}}, textString = "GP1", horizontalAlignment = TextAlignment.Left), Text(textColor = {255, 255, 255}, extent = {{-46, -13}, {-8, -27}}, textString = "GP2", horizontalAlignment = TextAlignment.Left), Text(textColor = {255, 255, 255}, extent = {{-46, -43}, {-8, -57}}, textString = "GP3", horizontalAlignment = TextAlignment.Left), Text(textColor = {255, 255, 255}, extent = {{8, 57}, {46, 43}}, textString = "GP4", horizontalAlignment = TextAlignment.Right), Text(textColor = {255, 255, 255}, extent = {{8, 27}, {46, 13}}, textString = "GP5", horizontalAlignment = TextAlignment.Right), Text(textColor = {255, 255, 255}, extent = {{8, -13}, {46, -27}}, textString = "GP6", horizontalAlignment = TextAlignment.Right), Text(textColor = {255, 255, 255}, extent = {{8, -43}, {46, -57}}, textString = "GP7", horizontalAlignment = TextAlignment.Right), Text(visible = useGroundPin, extent = {{7, -66}, {47, -74}}, textString = "GND", horizontalAlignment = TextAlignment.Left), Text(textColor = {28, 108, 200}, extent = {{-10, 74}, {43, 66}}, textString = "DISPLAY", horizontalAlignment = TextAlignment.Right), Text(textColor = {0, 0, 255}, extent = {{-150, 100}, {150, 80}}, textString = "%name")}),
    Diagram(coordinateSystem(preserveAspectRatio = true, extent = {{-180, -150}, {180, 110}})),
    Documentation(info = "<html>
<p>Simplified microcontroller with 8 pins and an ideal internal supply (<code>VOH</code>), made of the programmable core <code>Internal.McuCore</code> (also inside the board replica <code>RPi_Pico</code>), an ideal supply <code>VOH</code> and the on-board LED — see the internal diagram. The <code>GND</code> pin is shown by default; with <code>useGroundPin</code> unchecked (\"Electrical\" tab) it disappears and the microcontroller is referenced to the simulation ground (0 V), common to every <code>Ground</code> block. The core has one electrical stage per pin (<code>Internal.PinBridge</code>: push-pull output fed by the supply, switchable pulls, voltage sensing) controlled by <code>PyRuntime</code>, which runs the user's Python script (MicroPython-compatible, <code>machine.Pin</code>/<code>machine.ADC</code>/<code>machine.PWM</code>/<code>time</code> API) in a thread that intercepts <code>sleep()</code>. API reference: Raspberry Pi Pico (RP2040), see <code>requirements.md</code> — not shown on the icon, to stay generic. Each pin <code>GP0</code>-<code>GP7</code> can be used, as the script chooses, as digital (<code>machine.Pin</code>), analog (<code>machine.ADC</code>, 16-bit reading of the voltage measured by the sensor already present in the bridge) or PWM (<code>machine.PWM</code>, square wave generated continuously on the Modelica side once frequency/duty cycle are set — no round trip with the Python thread at each edge, see <code>requirements.md</code>) — unlike the real Pico, where only some pins are ADC-capable, see the restrictions in <code>requirements.md</code>.</p>
<p>The script can import a helper module (<code>import my_module</code>): by default (<code>addScriptDirToPath</code>), the script's folder is added to the Python search path, and <code>libraryPath</code> can additionally designate a <code>.py</code> file of a shared library (its folder is then added too) — see <code>requirements.md</code>, decision \"Import de modules auxiliaires\".</p>
<p>File system (simulated flash, \"File system\" tab): disabled by default (<code>fsEnabled</code>), <code>open()</code> and <code>os</code> then raise <code>OSError</code>. When enabled, each simulation copies the <code>fsSource</code> folder (empty = blank flash) into a new folder of <code>fsWorkspace</code> (\".\" by default: the simulation folder), named <code>&lt;instance&gt;_&lt;FS name&gt;_&lt;date&gt;_&lt;time&gt;</code>; its full path is shown in the log at the start and at the end of the simulation, and Windows Explorer opens on it at the end (<code>fsOpenExplorer</code>). The script sees it as the root <code>/</code> of the flash: <code>open()</code> and the MicroPython-style <code>os</code> module (<code>listdir</code>, <code>mkdir</code>, <code>remove</code>, <code>rename</code>, <code>stat</code>, <code>statvfs</code>, <code>chdir</code>, <code>getcwd</code>...) are confined to it, and the root as well as <code>/lib</code> are on the import path. The source is never modified: each simulation starts again from the same state and stays deterministic (the timestamp only names the copy, the script does not see it). Program run, as on a board: <code>boot.py</code> from the flash if it exists, then <code>scriptPath</code> instead of <code>main.py</code> (like Thonny on an already booted board), or <code>main.py</code> from the flash if <code>scriptPath</code> is empty. See <code>requirements.md</code>, decision \"Système de fichiers\".</p>
<p>The electrical parameters (logic levels, output resistances) are grouped in the \"Electrical\" tab. The supply is ideal and implicit: <code>VOH</code> is the internal rail, i.e. the high level of the outputs and of the pull-ups; the microcontroller is always supplied. For a board with real supply pins and regulator, see <code>RPi_Pico</code>.</p>
<p>The <code>Display0</code> connector exposes a logical link to an educational display peripheral (<code>machine.Display(0).write(text)</code>): unlike the <code>GPx</code> pins, it is not an electrical connector (<code>Modelica.Electrical.Analog</code>) but a causal logical connector (<code>Interfaces.DisplayLinkOutput</code>, message delivered instantly at the sync point, no serial waveform nor simulated baud rate) — to be connected to the <code>displayLink</code> (<code>Interfaces.DisplayLinkInput</code>) of a <code>Peripherals.Display</code>, an optional component (connect it or not, depending on the circuit). See <code>requirements.md</code>, decision \"Périphérique d'affichage pédagogique\".</p>
<p>The dot on the icon stands for the on-board LED of the Raspberry Pi Pico (wired to <code>GP25</code> on the real board). It is handled like a normal pin, with the same electrical stage as <code>GP0</code>-<code>GP7</code> (<code>core.pin[9]</code>) — only without an external connector: the output of this internal bridge permanently feeds a series resistance (<code>ledResistor</code>) and a real <code>Peripherals.LED</code> (<code>builtinLed</code>) connected to <code>GND</code>, true to the actual wiring of the Pico. It is driven from the script exactly like the 8 GPIO pins (<code>machine.Pin(25, machine.Pin.OUT).on()</code>/<code>.off()</code>); it is not one of the 8 exposed GPIO pins (see the restrictions in <code>requirements.md</code>), so no external circuit can be connected to it. Bright green when on, dark green otherwise — visible while replaying a simulation result with animation in OMEdit (<code>DynamicSelect</code> on <code>builtinLed.mean.y</code>), not on a static rendering.</p>
</html>"));
end MCU;
