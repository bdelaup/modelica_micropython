within MicroPythonMCU.Internal;

partial model PartialI2cDevice "Base of the I2C slave peripherals: open-drain electrical link, bus decoding, behaviour described by a Python script"
  extends PartialSupplyPin;
  parameter String addresses = "0x42" "7-bit address(es) the peripheral answers to, e.g. \"0x42\" or \"0x3E, 0x62\" (at most 4)" annotation(
    Dialog(group = "I2C bus"));
  parameter String scriptPath = "" "Script .py describing the behaviour (on_write / on_read / outputs / lines)" annotation(
    Dialog(group = "Behaviour", loadSelector(filter = "Python files (*.py)", caption = "Select the peripheral script")));
  // Disabled by default: a bus needs only ONE pair of pull-ups, and forgetting it
  // must show (lines staying low, OSError on the microcontroller side) - as
  // on a real circuit. Off-the-shelf modules (Grove...) often carry them:
  // their component then enables it, and several pairs end up in parallel.
  parameter Boolean usePullUp = false "Carry the pull-up resistors of SDA and SCL to the supply (at least one component of the bus must do it)" annotation(
    Dialog(group = "I2C bus"));
  parameter Modelica.Units.SI.Resistance RPullUp = 4700 "Pull-up resistance of each line" annotation(
    Dialog(group = "I2C bus", enable = usePullUp));
  parameter Boolean useValueInput = false "Take the quantities from the valueIn connector rather than from a constant" annotation(
    Dialog(tab = "Inputs / outputs", group = "Inputs (handler argument v)"));
  parameter Integer nIn(min = 1, max = Interfaces.I2C_DEV_MAX_VALUES) = 1 "Number of quantities received from the model" annotation(
    Dialog(tab = "Inputs / outputs", group = "Inputs (handler argument v)", enable = useValueInput));
  parameter Real fixedValue = 0 "Value used when valueIn is not connected" annotation(
    Dialog(tab = "Inputs / outputs", group = "Inputs (handler argument v)", enable = not useValueInput));
  parameter Integer nOut(min = 1, max = Interfaces.I2C_DEV_MAX_VALUES) = 1 "Number of quantities returned to the model by outputs() - leave the connector unconnected if unused" annotation(
    Dialog(tab = "Inputs / outputs", group = "Outputs (return value of outputs())"));
  parameter Modelica.Units.SI.Voltage VIH = Interfaces.VIH "Threshold above which an input reads high" annotation(
    Dialog(tab = "Electrical", group = "Levels"));
  parameter Modelica.Units.SI.Voltage VIL = Interfaces.VIL "Threshold below which an input reads low" annotation(
    Dialog(tab = "Electrical", group = "Levels"));
  parameter Modelica.Units.SI.Resistance ROut = Interfaces.ROut "Resistance of the SDA output transistor when it pulls the line to ground" annotation(
    Dialog(tab = "Electrical", group = "Impedances"));
  parameter Modelica.Units.SI.Conductance GOff = 1e-9 "Leakage of the SDA output transistor when off (line released)" annotation(
    Dialog(tab = "Electrical", group = "Impedances"));
  // CIn is not cosmetic: it gives SDA and SCL a real dynamic state, which
  // breaks the dependency between the when of this peripheral and that of the microcontroller
  // (same role as CIn on the UART side). Against the pull-ups, it also sets the
  // rise time of the lines: 4.7 kΩ x 10 pF = 47 ns, far below the quarter period at 400 kHz
  // (625 ns). Increasing CIn or RPullUp degrades the edges as on a real bus.
  parameter Modelica.Units.SI.Capacitance CIn = 10e-12 "Input capacitance of each pin (SDA, SCL)" annotation(
    Dialog(tab = "Electrical", group = "Impedances"));
  // RIn separates the input capacitance of each peripheral from the bus wire:
  // without it, the CIn of several peripherals on the same bus would be in
  // parallel, i.e. one single alias variable carrying several fixed start values
  // (OpenModelica warning "alias variables with redundant start"). RIn x CIn =
  // 100 ps and the SDA low level rises by about 10 mV: no observable effect.
  parameter Modelica.Units.SI.Resistance RIn = 10 "Series resistance of each pin (pad), between the bus wire and the input capacitance" annotation(
    Dialog(tab = "Electrical", group = "Impedances"));
  Modelica.Electrical.Analog.Interfaces.PositivePin SDA "I2C bus data - to be connected to the SDA pin of the microcontroller and of the other peripherals" annotation(
    Placement(transformation(origin = {-124, 34}, extent = {{-7, -7}, {7, 7}}), iconTransformation(origin = {-110, 30}, extent = {{-5, -5}, {5, 5}})));
  Modelica.Electrical.Analog.Interfaces.PositivePin SCL "I2C bus clock - to be connected to the SCL pin of the microcontroller and of the other peripherals" annotation(
    Placement(transformation(origin = {-124, -34}, extent = {{-7, -7}, {7, 7}}), iconTransformation(origin = {-110, -30}, extent = {{-5, -5}, {5, 5}})));
  Modelica.Blocks.Interfaces.RealInput valueIn[nIn] if useValueInput "Quantities supplied by the model, passed to the script's handlers (argument v)" annotation(
    Placement(transformation(origin = {124, 34}, extent = {{10, -10}, {-10, 10}}), iconTransformation(origin = {110, 30}, extent = {{5, -5}, {-5, 5}})));
  Modelica.Blocks.Interfaces.RealOutput valueOut[nOut] "Quantities returned by outputs() - the peripheral then becomes an actuator" annotation(
    Placement(transformation(origin = {124, -34}, extent = {{-10, -10}, {10, 10}}), iconTransformation(origin = {110, -30}, extent = {{-5, -5}, {5, 5}})));
  // Public: protected variables do not appear in the simulation results
  // in this OpenModelica installation, which would break the DynamicSelect
  // animation of the icon (see requirements.md).
  discrete Boolean sdaDriveLow(start = false, fixed = true) "The peripheral pulls SDA to ground (acknowledge, or 0 bit read by the master)";
  discrete Boolean busy(start = false, fixed = true) "A phase addressed to this peripheral is in progress";
  discrete Integer eventSeq(start = 0, fixed = true) "Incremented at each completed write or read phase";
  String lastEvent "Summary of the last completed phase (log)";
  String line1 "First line of text returned by lines() (displays)";
  String line2 "Second line of text returned by lines()";
protected
  constant Integer NV = Interfaces.I2C_DEV_MAX_VALUES "Fixed size expected by the external C interface";
  Modelica.Blocks.Interfaces.RealInput valueIn_internal[nIn] "Internal connector: a conditional connector cannot be read directly in an equation (MSL idiom)";
  discrete Real vOut[NV](each start = 0, each fixed = true) "Quantities published by the C code (outputs())";
  Real vIn[NV] "Quantities passed to the C code, padded with fixedValue beyond nIn";
  Boolean sclBool(start = false, fixed = true) "Logic value read on SCL";
  Boolean sdaBool(start = false, fixed = true) "Logic value read on SDA";
  // Open-drain electrical bridge. No switching Ideal.* component: the SDA output
  // is a variable conductance (ROut or GOff), see the pitfall of Ideal.* components left
  // for a long time in an unsolicited state (requirements.md). SCL has no output:
  // the peripheral never stretches it (no clock stretching).
  Modelica.Electrical.Analog.Basic.VariableConductor sdaOut "SDA output transistor: ROut when it pulls the line, GOff otherwise" annotation(
    Placement(visible = false, transformation(extent = {{-190, -90}, {-150, -50}})));
  Modelica.Electrical.Analog.Sensors.VoltageSensor sdaSns "Voltage actually present on SDA" annotation(
    Placement(visible = false, transformation(extent = {{-130, -90}, {-90, -50}})));
  Modelica.Electrical.Analog.Sensors.VoltageSensor sclSns "Voltage actually present on SCL" annotation(
    Placement(visible = false, transformation(extent = {{-70, -90}, {-30, -50}})));
  Modelica.Electrical.Analog.Basic.Capacitor cSda(C = CIn, v(start = 0, fixed = true)) "Input capacitance of SDA - gives the node a real dynamic state, see CIn" annotation(
    Placement(visible = false, transformation(extent = {{-10, -90}, {30, -50}})));
  Modelica.Electrical.Analog.Basic.Capacitor cScl(C = CIn, v(start = 0, fixed = true)) "Input capacitance of SCL" annotation(
    Placement(visible = false, transformation(extent = {{50, -90}, {90, -50}})));
  Modelica.Electrical.Analog.Basic.Resistor rInSda(R = RIn) "Pad resistance of SDA: the output transistor and the input sense the inner node, behind it" annotation(
    Placement(visible = false, transformation(extent = {{-10, -130}, {30, -90}})));
  Modelica.Electrical.Analog.Basic.Resistor rInScl(R = RIn) "Pad resistance of SCL" annotation(
    Placement(visible = false, transformation(extent = {{-70, -130}, {-30, -90}})));
  Modelica.Electrical.Analog.Basic.Resistor rPullSda(R = RPullUp) if usePullUp "Pull-up of SDA to the supply rail" annotation(
    Placement(visible = false, transformation(extent = {{110, -130}, {150, -90}})));
  Modelica.Electrical.Analog.Basic.Resistor rPullScl(R = RPullUp) if usePullUp "Pull-up of SCL to the supply rail" annotation(
    Placement(visible = false, transformation(extent = {{50, -130}, {90, -90}})));
  Internal.I2cDevice dev = Internal.I2cDevice(addresses, scriptPath, Modelica.Utilities.Files.loadResource("modelica://MicroPythonMCU/Resources/PythonRuntime"), getInstanceName()) "Engine of the peripheral: bus decoding, Python script" annotation(
    Placement(visible = false, transformation(extent = {{-20, 75}, {20, 95}})));
public
equation
  connect(valueIn, valueIn_internal);
  if not useValueInput then
    valueIn_internal = fill(fixedValue, nIn) "without this equation, the internal connector would be undetermined when valueIn is not connected";
  end if;
  for k in 1:NV loop
    vIn[k] = if k <= nIn then valueIn_internal[k] else fixedValue;
  end for;
  for k in 1:nOut loop
    valueOut[k] = vOut[k];
  end for;
  connect(rInSda.p, SDA);
  connect(rInScl.p, SCL);
  connect(sdaOut.p, rInSda.n);
  connect(sdaOut.n, gnd);
  connect(sdaSns.p, rInSda.n);
  connect(sdaSns.n, gnd);
  connect(sclSns.p, rInScl.n);
  connect(sclSns.n, gnd);
  connect(cSda.p, rInSda.n);
  connect(cSda.n, gnd);
  connect(cScl.p, rInScl.n);
  connect(cScl.n, gnd);
  connect(rail, rPullSda.p);
  connect(rPullSda.n, SDA);
  connect(rail, rPullScl.p);
  connect(rPullScl.n, SCL);
  sdaOut.G = if sdaDriveLow then 1/ROut else GOff;
  sclBool = sclSns.v > (VIL + VIH)/2 "logic threshold halfway, same approximation as the microcontroller";
  sdaBool = sdaSns.v > (VIL + VIH)/2;
  when {initial(), change(sclBool), change(sdaBool)} then
    (vOut, sdaDriveLow, busy, eventSeq, lastEvent, line1, line2) = Internal.I2cDevice_sync(dev, time, sclBool, sdaBool, vIn);
  end when;
  when change(eventSeq) then
    Modelica.Utilities.Streams.print("[" + getInstanceName() + "] t=" + String(time) + " s - " + lastEvent);
  end when;
  annotation(
    Icon(coordinateSystem(preserveAspectRatio = true, extent = {{-100, -100}, {100, 100}}, initialScale = 0.2), graphics = {Rectangle(fillColor = {50, 80, 95}, fillPattern = FillPattern.Solid, extent = {{-104, 56}, {104, -56}}), Text(textColor = {255, 255, 255}, extent = {{-56, 24}, {56, 2}}, textString = "I2C", textStyle = {TextStyle.Bold}), Text(textColor = {200, 220, 230}, extent = {{-90, -2}, {90, -20}}, textString = "%addresses"), Ellipse(fillColor = DynamicSelect({60, 60, 60}, if busy then {60, 210, 255} else {60, 60, 60}), fillPattern = FillPattern.Solid, lineColor = {30, 30, 30}, extent = {{86, 52}, {98, 40}}), Ellipse(fillColor = DynamicSelect({60, 60, 60}, if sdaDriveLow then {255, 180, 60} else {60, 60, 60}), fillPattern = FillPattern.Solid, lineColor = {30, 30, 30}, extent = {{-98, 52}, {-86, 40}}), Text(textColor = {255, 255, 255}, extent = {{-94, 37}, {-52, 23}}, textString = "SDA", horizontalAlignment = TextAlignment.Left), Text(textColor = {255, 255, 255}, extent = {{-94, -23}, {-52, -37}}, textString = "SCL", horizontalAlignment = TextAlignment.Left), Text(textColor = {255, 255, 255}, extent = {{56, 38}, {98, 24}}, textString = "val", horizontalAlignment = TextAlignment.Right), Text(textColor = {255, 255, 255}, extent = {{56, -24}, {98, -38}}, textString = "out", horizontalAlignment = TextAlignment.Right), Text(visible = useGroundPin, extent = {{7, -56}, {47, -64}}, textString = "GND", horizontalAlignment = TextAlignment.Left), Text(textColor = {0, 0, 255}, extent = {{-150, 80}, {150, 60}}, textString = "%name")}),
    Diagram(coordinateSystem(preserveAspectRatio = true, extent = {{-100, -100}, {100, 100}})),
    Documentation(info = "<html>
<p>Base class of the I2C slave peripherals. It cannot be instantiated directly: a concrete peripheral extends it and sets its parameters — see <code>Peripherals.I2cEchoDevice</code>, <code>Peripherals.I2cGroveLcdRgb</code>, or <code>Peripherals.I2cGenericDevice</code> to start from a script template.</p>
<p><strong>Electrical.</strong> The peripheral is connected to a real <em>open-drain</em> <code>SDA</code>/<code>SCL</code> bus: it can only pull SDA to ground or release it. Several peripherals and the microcontroller share the same two wires; the \"wired AND\" of the bus simply follows from Kirchhoff's laws. The lines only go back up thanks to the <strong>pull-up resistors</strong>: the bus needs at least one pair, carried by a component with <code>usePullUp = true</code>. Without them, the lines stay low and the microcontroller raises <code>OSError(ETIMEDOUT)</code>, as on a real circuit.</p>
<p><strong>Behaviour: a Python script only</strong>, at the <em>transaction</em> level — the script sees neither the bits, nor the START/STOP conditions, nor the acknowledges:</p>
<ul>
<li><code>on_write(addr, data, t, v)</code>: a write phase addressed to it has just ended (STOP or repeated START); <code>data</code> holds all the received bytes.</li>
<li><code>on_read(addr, t, v)</code>: the master starts reading; return the bytes to send to it (<code>bytes</code>, <code>str</code>, list of integers or integer). They go out one by one; if the master asks for more, <code>on_read()</code> is called again.</li>
<li><code>outputs()</code>: read again after each handler, feeds <code>valueOut</code>.</li>
<li><code>lines()</code>: optional, read again after each handler, feeds <code>line1</code>/<code>line2</code> (displays).</li>
</ul>
<p>The component automatically acknowledges any address of the <code>addresses</code> list and any written byte. It does not answer the other addresses: this is what lets several peripherals share the same bus.</p>
<p>The two dots of the icon light up when the peripheral pulls SDA (amber) and during a phase addressed to it (cyan) — visible while replaying a result with animation in OMEdit. Each completed phase produces a line in the simulation log, prefixed with the component name.</p>
</html>"));
end PartialI2cDevice;
