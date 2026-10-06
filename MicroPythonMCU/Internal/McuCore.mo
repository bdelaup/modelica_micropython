within MicroPythonMCU.Internal;
model McuCore "Programmable core (RP2040 reference): Python program, sync point, electrical stage of each pin, power-on - the component placed inside MCU and RPi_Pico"
  extends PartialMcuSettings;
  parameter Integer nPins "Number of pins of the core (external pins, internal pins of the board, on-board LED) - at most 31 (MAX_PINS on the C side, minus the temperature sensor)";
  parameter Integer pinIds[nPins] "GPIO number of each pin, as written in the script";
  parameter Integer pinCaps[nPins] "Capabilities of each pin: sum of 1 = digital (Pin, PWM), 2 = wired to a connector (UART, I2C, I2CTarget), 4 = ADC input";
  parameter String boardProfile = "generic" "Board profile read by the machine shim: \"generic\" (MCU) or \"pico\" (RPi_Pico)";
  parameter Boolean hasTempSensor = false "On-chip temperature sensor, read by machine.ADC(4) on the pico profile";
  parameter Modelica.Units.NonSI.Temperature_degC dieTemperature = 27 "Temperature of the chip, read by the temperature sensor" annotation(
    Dialog(enable = hasTempSensor));
  parameter Modelica.Units.SI.Current ICore = 0.02 "Current drawn from vdd by the core and its flash while supplied (pins excluded)";
  parameter Modelica.Units.SI.Voltage VPowerOn = 1.8 "Voltage of vdd above which the core starts (power-on reset)";
  parameter Modelica.Units.SI.Voltage VPowerOff = 1.6 "Voltage of vdd below which a running core stops for good (brown-out)";
  parameter Modelica.Units.SI.Resistance RRunPullUp = 50e3 "Internal pull-up of the RUN pin to vdd";
  parameter String instanceName = getInstanceName() "Name shown in the log and given to the copy of the flash: that of the board containing the core (MCU, RPi_Pico), set by it";
  Modelica.Electrical.Analog.Interfaces.PositivePin pin[nPins] "Pins of the core, in the order of pinIds" annotation(
    Placement(transformation(origin = {-110, 0}, extent = {{-10, -10}, {10, 10}})));
  Modelica.Electrical.Analog.Interfaces.PositivePin vdd "Supply of the core and of its pins (IOVDD): high level of the outputs, pull-ups, consumption ICore" annotation(
    Placement(transformation(origin = {0, 110}, extent = {{-10, -10}, {10, 10}})));
  Modelica.Electrical.Analog.Interfaces.NegativePin gnd "Ground" annotation(
    Placement(transformation(origin = {0, -110}, extent = {{-10, -10}, {10, 10}})));
  Modelica.Electrical.Analog.Interfaces.PositivePin vref "Reference voltage of the ADC: read_u16() = 65535 at this voltage" annotation(
    Placement(transformation(origin = {-60, 110}, extent = {{-10, -10}, {10, 10}})));
  Modelica.Electrical.Analog.Interfaces.PositivePin run "Enable (RUN), pulled up to vdd inside the core: to ground, the core is stopped for good - may stay unconnected" annotation(
    Placement(transformation(origin = {110, -60}, extent = {{-10, -10}, {10, 10}})));
  Interfaces.DisplayLinkOutput Display0 "Logical link to an educational display peripheral (machine.Display(0).write())" annotation(
    Placement(transformation(origin = {110, 60}, extent = {{-10, -10}, {10, 10}})));
  // Public: plotted, and protected variables are missing from the simulation results
  Boolean powerGood(start = false, fixed = true) "The core is supplied (vdd above the power-on threshold, RUN high): its program starts the first time this becomes true and stops for good when it falls back. start = false: pins in high impedance during the initialization, where they are all inputs anyway (see pre(powerGood) below)";
  Boolean supplyOk(start = false, fixed = true) "vdd above the power-on threshold, with hysteresis";
  Boolean runHigh "RUN high";
protected
  constant Integer TEMP_SENSOR_ID = 30 "Pseudo-pin of the temperature sensor (no GPIO 30 on the RP2040), aligned with _PICO_ADC_TEMP in the machine shim";
  constant Integer CAP_ADC = 4;
  parameter Integer nTemp = if hasTempSensor then 1 else 0;
  parameter Integer nAll = nPins + nTemp "Pins seen by the C code: the pins, then the temperature sensor";
  parameter Integer allIds[nAll] = cat(1, pinIds, fill(TEMP_SENSOR_ID, nTemp));
  parameter Integer allCaps[nAll] = cat(1, pinCaps, fill(CAP_ADC, nTemp));
  Modelica.Units.SI.Voltage adcRef "Reference voltage of the ADC";
  Modelica.Units.SI.Voltage pinNodeVoltage[nAll] "Actual voltage of each pin, relative to gnd";
  Boolean pinBoolIn[nAll](each start = false, each fixed = true) "Logic value read on each pin (voltage compared with the VIL/VIH thresholds), including the on-board LED, which thus reads back its own state like a normal pin";
  Boolean pinBoolOut[nAll] "Value driven on each pin (output of the last sync point)";
  Boolean pinIsOutputD[nAll](each start = false, each fixed = true) "Direction of each pin (output of the last sync point)";
  Integer pinBoolInC[nAll] "pinBoolIn as passed to PyRuntime_sync (0/1): arrays of Boolean are not exchanged with the C code, see Internal.PyRuntime_sync";
  discrete Integer pinBoolOutC[nAll](each start = 0, each fixed = true) "pinBoolOut as returned by PyRuntime_sync (0/1)";
  discrete Integer pinIsOutputC[nAll](each start = 0, each fixed = true) "pinIsOutputD as returned by PyRuntime_sync (0/1)";
  discrete Integer pinPullC[nAll](each start = 0, each fixed = true) "Internal pull resistor of each pin as returned by PyRuntime_sync: 0 = none, 1 = PULL_UP, 2 = PULL_DOWN";
  discrete Modelica.Units.SI.Frequency pwmFreq[nAll](each start = 0, each fixed = true) "PWM frequency of each pin (Hz); 0 = not in PWM mode (plain digital output through pinBoolOut), see machine.PWM";
  discrete Real pwmDuty[nAll](each start = 0, each fixed = true) "PWM duty cycle of each pin (0-1), relevant only if pwmFreq > 0";
  Modelica.Units.SI.Time pwmPeriod[nAll] "1/pwmFreq, with a floor to avoid a division by zero when pwmFreq = 0 (pin not in PWM)";
  discrete Integer uartTxPin(start = 0, fixed = true) "Pin index assigned to serial transmission (0 = none); once assigned it stays so, even between frames, because the idle line must be HIGH - see machine.UART";
  discrete Boolean uartTxLevel(start = true, fixed = true) "Logic level to hold on the transmit pin (idle = high), published by the C code: the next sync point falls on the next level CHANGE of the frame, so consecutive identical bits cost no event";
  discrete Modelica.Units.SI.Time nextWakeTime(start = 0, fixed = true) "Next wake-up requested by the script (sleep), or +inf once finished";
  Internal.PyRuntime rt = Internal.PyRuntime(scriptPath, Modelica.Utilities.Files.loadResource("modelica://MicroPythonMCU/Resources/PythonRuntime"), addScriptDirToPath, libraryPath, Modelica.Utilities.Files.loadResource("modelica://MicroPythonMCU/Resources/Scripts/_shim/machine_time_shim.py"), fsEnabled, Internal.ResolvePath(fsSource), Internal.ResolvePath(fsWorkspace), fsOpenExplorer, instanceName, gpioOpTime, hangWarningTime, debugEnabled, debugPort, allIds, allCaps, boardProfile) "Embedded Python interpreter running the user script" annotation(
    Placement(visible = false, transformation(extent = {{-20, 75}, {20, 95}})));
  Internal.PinBridge bridge[nAll](each VOL = VOL, each ROut = ROut, each RPullUp = RPullUp, each RPullDown = RPullDown, each GOff = GOff) "Electrical stage of each pin, fed by vdd" annotation(
    Placement(visible = false, transformation(extent = {{-60, -20}, {-20, 20}})));
  Modelica.Electrical.Analog.Sources.SignalCurrent coreLoad "Consumption ICore of the core, drawn from vdd" annotation(
    Placement(visible = false, transformation(extent = {{20, 40}, {40, 60}})));
  Modelica.Electrical.Analog.Basic.Resistor runPullUp(R = RRunPullUp) "Internal pull-up of RUN to vdd" annotation(
    Placement(visible = false, transformation(extent = {{60, -70}, {80, -50}})));
  Modelica.Electrical.Analog.Sources.SignalVoltage tempSensor "Temperature sensor (a pin of the C table when hasTempSensor, unconnected otherwise)" annotation(
    Placement(visible = false, transformation(extent = {{20, -40}, {40, -20}})));
equation
  for i in 1:nPins loop
    connect(bridge[i].pin, pin[i]);
  end for;
  for k in 1:nTemp loop
    connect(bridge[nPins + k].pin, tempSensor.p);
  end for;
  connect(tempSensor.n, gnd);
  tempSensor.v = 0.706 - 0.001721*(dieTemperature - 27) "RP2040 datasheet, section 4.9.5";
  connect(coreLoad.p, vdd);
  connect(coreLoad.n, gnd);
  coreLoad.i = if pre(supplyOk) then ICore else 0 "pre(): breaks the algebraic loop vdd -> supplyOk -> load -> vdd";
  connect(runPullUp.p, vdd);
  connect(runPullUp.n, run);
  supplyOk = if pre(supplyOk) then vdd.v - gnd.v > VPowerOff else vdd.v - gnd.v > VPowerOn;
  runHigh = run.v - gnd.v > (VIL + VIH)/2;
  powerGood = supplyOk and runHigh;
  adcRef = vref.v - gnd.v;
  vref.i = 0 "infinite input impedance";
  for i in 1:nAll loop
    connect(bridge[i].vdd, vdd);
    connect(bridge[i].gnd, gnd);
    pinNodeVoltage[i] = bridge[i].v;
    pinBoolIn[i] = pinNodeVoltage[i] > (VIL + VIH)/2 "logic threshold halfway (approximation)";
    pinBoolInC[i] = if pinBoolIn[i] then 1 else 0;
    pinBoolOut[i] = pre(pinBoolOutC[i]) <> 0;
    pinIsOutputD[i] = pre(pinIsOutputC[i]) <> 0;
    pwmPeriod[i] = 1/max(pre(pwmFreq[i]), 1e-6);
    bridge[i].drive = pre(powerGood) and pinIsOutputD[i] "high impedance while the core is not supplied - pre(): breaks the algebraic loop vdd -> powerGood -> load of the pins -> vdd";
    bridge[i].level = if pre(uartTxPin) == i then pre(uartTxLevel) elseif pre(pwmFreq[i]) > 0 then mod(time, pwmPeriod[i]) < pre(pwmDuty[i])*pwmPeriod[i] else pinBoolOut[i] "serial frame (level published by the C code at each change) if the pin is assigned to the UART, otherwise PWM square wave if pwmFreq > 0, otherwise plain digital output - see requirements.md";
    bridge[i].pull = if pre(powerGood) then pre(pinPullC[i]) else 0;
  end for;
  // initial() must stand alone (or in a literal vector) to be recognized by omc: the
  // vector of conditions is built with cat() to cover any number of pins, hence the
  // separate initial branch.
  when initial() then
    (pinBoolOutC, pinIsOutputC, pinPullC, pwmFreq, pwmDuty, Display0.seq, Display0.payload, uartTxPin, uartTxLevel, nextWakeTime) = Internal.PyRuntime_sync(rt, time, pinBoolInC, pinNodeVoltage, powerGood, adcRef);
    Display0.charCode = Internal.StringToCharCodes(Internal.DisplayMessage(Display0.payload, Internal.DisplayMessageCount(Display0.payload)), Interfaces.DISPLAY_COLS) "ASCII codes of the last message of Display0.payload (a String, which cannot be stored in the results), so that the connected display peripheral can animate the text actually received on its icon - see Internal.StringToCharCodes";
  elsewhen cat(1, {time >= pre(nextWakeTime), sample(0, tickPeriod), change(powerGood)}, {change(pinBoolIn[i]) and not pre(pinIsOutputD[i]) for i in 1:nAll}) then
    (pinBoolOutC, pinIsOutputC, pinPullC, pwmFreq, pwmDuty, Display0.seq, Display0.payload, uartTxPin, uartTxLevel, nextWakeTime) = Internal.PyRuntime_sync(rt, time, pinBoolInC, pinNodeVoltage, powerGood, adcRef);
    Display0.charCode = Internal.StringToCharCodes(Internal.DisplayMessage(Display0.payload, Internal.DisplayMessageCount(Display0.payload)), Interfaces.DISPLAY_COLS);
  end when;
  annotation(
    Icon(coordinateSystem(preserveAspectRatio = true, extent = {{-100, -100}, {100, 100}}), graphics = {Rectangle(lineColor = {20, 20, 20}, fillColor = {45, 45, 45}, fillPattern = FillPattern.Solid, extent = {{-100, 100}, {100, -100}}, radius = 6), Text(textColor = {230, 230, 230}, extent = {{-80, 30}, {80, -10}}, textString = "RP2040", textStyle = {TextStyle.Bold}), Text(textColor = {180, 180, 180}, extent = {{-80, -20}, {80, -44}}, textString = "MCU core"), Text(textColor = {200, 200, 200}, extent = {{-96, 10}, {-60, -10}}, textString = "GP", horizontalAlignment = TextAlignment.Left), Text(textColor = {200, 200, 200}, extent = {{-20, 96}, {20, 80}}, textString = "VDD"), Text(textColor = {200, 200, 200}, extent = {{-80, 96}, {-40, 80}}, textString = "VREF"), Text(textColor = {200, 200, 200}, extent = {{-20, -80}, {20, -96}}, textString = "GND"), Text(textColor = {200, 200, 200}, extent = {{50, -50}, {96, -70}}, textString = "RUN", horizontalAlignment = TextAlignment.Right), Text(textColor = {200, 200, 200}, extent = {{30, 70}, {96, 50}}, textString = "DISPLAY", horizontalAlignment = TextAlignment.Right), Text(textColor = {0, 0, 255}, extent = {{-150, 150}, {150, 120}}, textString = "%name")}),
    Documentation(info = "<html>
<p>The programmable core placed inside <code>MCU</code> and <code>RPi_Pico</code>: embedded Python interpreter (<code>PyRuntime</code>), sync point (<code>PyRuntime_sync</code>), one electrical stage <code>Internal.PinBridge</code> per pin, power-on logic. Its parameters are those of the board that contains it (<code>Internal.PartialMcuSettings</code>), plus the pin table (<code>nPins</code>, <code>pinIds</code>, <code>pinCaps</code>, <code>boardProfile</code>) set by the board.</p>
<ul>
<li><b>Pins</b> <code>pin[nPins]</code>: push-pull outputs fed by <code>vdd</code> — their high level is the voltage of <code>vdd</code>, and their current is drawn from it.</li>
<li><b>Supply</b> <code>vdd</code>/<code>gnd</code>: the core draws <code>ICore</code> while supplied.</li>
<li><b>Power-on</b>: <code>powerGood</code> = <code>vdd</code> above <code>VPowerOn</code> (down to <code>VPowerOff</code>, hysteresis) and <code>run</code> high (internal pull-up, may stay unconnected). The program starts at the first supplied sync point, <code>time.ticks_ms()</code> counting from there; a later loss stops it for good (no restart), pins in high impedance.</li>
<li><b>ADC reference</b> <code>vref</code>: high impedance input.</li>
<li><b>Temperature sensor</b> (<code>hasTempSensor</code>): an extra ADC channel at the end of the pin table (pseudo-pin 30, <code>ADC(4)</code> on the pico profile), 0.706 V at 27 °C, −1.721 mV/°C.</li>
</ul>
<p>See <code>requirements.md</code>, decision \"Carte Raspberry Pi Pico et alimentation\".</p>
</html>"));
end McuCore;
