within MicroPythonMCU.Internal;

partial model PartialUartDevice "Base of the external serial devices: electrical link, decoding, two transmission modes, quantities exchanged with the model"
  extends PartialUartPins;
  parameter Interfaces.UartBehaviour behaviour = Interfaces.UartBehaviour.Table "Origin of the behaviour: command table or Python script" annotation(
    Dialog(group = "Behaviour"));
  parameter String scriptPath = "" "Script .py describing the behaviour of the device (Script mode)" annotation(
    Dialog(group = "Behaviour", enable = behaviour == Interfaces.UartBehaviour.Script, loadSelector(filter = "Python files (*.py)", caption = "Select the device script")));
  // Integer rather than Real: a serial baud rate is one, and the icon then shows it without decimals.
  parameter Integer baudrate = 1200 "Link speed, in baud" annotation(
    Dialog(group = "Serial link"));
  parameter Integer dataBits(min = 5, max = 8) = 8 "Number of data bits of a frame (5 to 8, as machine.UART bits=)" annotation(
    Dialog(group = "Serial link"));
  parameter Interfaces.UartParity parity = Interfaces.UartParity.None "Parity of a frame (as machine.UART parity=: None, 0 = even, 1 = odd)" annotation(
    Dialog(group = "Serial link"));
  parameter Integer stopBits(min = 1, max = 2) = 1 "Number of stop bits (1 or 2, as machine.UART stop=)" annotation(
    Dialog(group = "Serial link"));
  parameter String terminator = "\n" "Character marking the end of a received command (only the first character is kept)" annotation(
    Dialog(group = "Serial link"));
  parameter Modelica.Units.SI.Time tickPeriod = 0.1 "Period of the minimal sync point: a safety net, the actual pace comes from the engine's deadlines" annotation(
    Dialog(group = "Simulation"));

  parameter Boolean respondEnabled = true "Reply to the recognised commands" annotation(
    Dialog(tab = "Table", group = "Request / response", enable = behaviour == Interfaces.UartBehaviour.Table));
  parameter String commandTable = "" "Table \"CMD=>REPLY|CMD=>REPLY\"; \"|\" and \"=>\" are reserved. {vN} inserts valueIn[N] into the reply, {oN} captures a number of the command into valueOut[N]" annotation(
    Dialog(tab = "Table", group = "Request / response", enable = behaviour == Interfaces.UartBehaviour.Table and respondEnabled));
  parameter Modelica.Units.SI.Time responseDelay = 0.002 "Delay between the recognition of a command and the start of the reply" annotation(
    Dialog(tab = "Table", group = "Request / response", enable = behaviour == Interfaces.UartBehaviour.Script or respondEnabled));
  parameter Boolean echoEnabled = false "Send back every received byte unchanged" annotation(
    Dialog(tab = "Table", group = "Request / response", enable = behaviour == Interfaces.UartBehaviour.Table));
  parameter Boolean periodicEnabled = false "Transmit spontaneously, without being asked" annotation(
    Dialog(tab = "Table", group = "Periodic transmission", enable = behaviour == Interfaces.UartBehaviour.Table));
  parameter Modelica.Units.SI.Time period = 1 "Period of the spontaneous transmission (in Script mode: call period of on_tick)" annotation(
    Dialog(tab = "Table", group = "Periodic transmission", enable = behaviour == Interfaces.UartBehaviour.Script or periodicEnabled));
  parameter String periodicTemplate = "" "Template of the periodically transmitted frame ({vN} inserts valueIn[N])" annotation(
    Dialog(tab = "Table", group = "Periodic transmission", enable = behaviour == Interfaces.UartBehaviour.Table and periodicEnabled));

  parameter Boolean useValueInput = false "Take the quantities from the valueIn connector rather than from a constant" annotation(
    Dialog(tab = "Inputs / outputs", group = "Inputs ({vN}, inserted into transmitted frames)"));
  parameter Integer nIn(min = 1, max = Interfaces.UART_DEV_MAX_VALUES) = 1 "Number of quantities received from the model" annotation(
    Dialog(tab = "Inputs / outputs", group = "Inputs ({vN}, inserted into transmitted frames)", enable = useValueInput));
  parameter Real fixedValue = 0 "Value used when valueIn is not connected" annotation(
    Dialog(tab = "Inputs / outputs", group = "Inputs ({vN}, inserted into transmitted frames)", enable = not useValueInput));
  parameter Integer nOut(min = 1, max = Interfaces.UART_DEV_MAX_VALUES) = 1 "Number of quantities returned to the model - leave the connector unconnected if unused" annotation(
    Dialog(tab = "Inputs / outputs", group = "Outputs ({oN}, captured from received frames)"));
  parameter Real valueOutStart = 0 "Value of valueOut before any capture" annotation(
    Dialog(tab = "Inputs / outputs", group = "Outputs ({oN}, captured from received frames)"));

  Modelica.Blocks.Interfaces.RealInput valueIn[nIn] if useValueInput "Quantities supplied by the model, inserted into the transmitted frames by {v1}..{vN}" annotation(
    Placement(transformation(origin = {124, 34}, extent = {{10, -10}, {-10, 10}}), iconTransformation(origin = {124, 34}, extent = {{10, -10}, {-10, 10}})));
  Modelica.Blocks.Interfaces.RealOutput valueOut[nOut] "Quantities extracted from the received frames by {o1}..{oN} - the device then becomes an actuator" annotation(
    Placement(transformation(origin = {124, -34}, extent = {{-10, -10}, {10, 10}}), iconTransformation(origin = {124, -34}, extent = {{-10, -10}, {10, 10}})));

  // Public: protected variables do not appear in the simulation results
  // in this OpenModelica installation, which would break the DynamicSelect
  // animation of the icon (see requirements.md).
  discrete Boolean txActive(start = false, fixed = true) "A frame is being transmitted";
  discrete Boolean rxBusy(start = false, fixed = true) "A frame is being received";
  String lastRx "Last complete line received";
  String lastTx "Last payload transmitted";
protected
  constant Integer NV = Interfaces.UART_DEV_MAX_VALUES "Fixed size expected by the external C interface";
  Modelica.Blocks.Interfaces.RealInput valueIn_internal[nIn] "Internal connector: a conditional connector cannot be read directly in an equation (MSL idiom)";

  discrete Real vOut[NV](each start = 0, each fixed = true) "Captured quantities, as published by the C code";
  Real vIn[NV] "Quantities passed to the C code, padded with fixedValue beyond nIn";

  discrete Integer eventSeq(start = 0, fixed = true) "Incremented at each received line and each transmitted payload";
  discrete Modelica.Units.SI.Time nextWakeTime(start = 0, fixed = true) "Next deadline requested by the engine";

  // Integer(parity) - 2: None/Even/Odd (1/2/3) -> the machine.UART convention (-1/0/1) expected by the C code.
  Internal.UartDevice dev = Internal.UartDevice(baudrate, dataBits, Integer(parity) - 2, stopBits, commandTable, terminator, responseDelay, respondEnabled, echoEnabled, periodicEnabled, period, periodicTemplate, valueOutStart, Integer(behaviour), scriptPath, Modelica.Utilities.Files.loadResource("modelica://MicroPythonMCU/Resources/PythonRuntime"), getInstanceName()) "Engine of the device: TX/RX queues, decoding, command table, deadlines" annotation(
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

  when {initial(), time >= pre(nextWakeTime), sample(0, tickPeriod), change(rxBoolIn)} then
    (vOut, txActive, txLevel, rxBusy, eventSeq, lastRx, lastTx, nextWakeTime) = Internal.UartDevice_sync(dev, time, rxBoolIn, vIn);
  end when;
  when change(eventSeq) then
    Modelica.Utilities.Streams.print("[" + getInstanceName() + "] t=" + String(time) + " s - received: \"" + lastRx + "\" / sent: \"" + lastTx + "\"");
  end when;
  annotation(
    Icon(coordinateSystem(preserveAspectRatio = true, extent = {{-100, -100}, {100, 100}}), graphics = {Rectangle(fillColor = {70, 70, 85}, fillPattern = FillPattern.Solid, extent = {{-104, 56}, {104, -56}}), Text(textColor = {255, 255, 255}, extent = {{-56, 24}, {56, 2}}, textString = "UART", textStyle = {TextStyle.Bold}), Text(visible = parity == Interfaces.UartParity.None, textColor = {200, 200, 200}, extent = {{-90, -2}, {90, -20}}, textString = "%baudrate,N,%dataBits,%stopBits"), Text(visible = parity == Interfaces.UartParity.Even, textColor = {200, 200, 200}, extent = {{-90, -2}, {90, -20}}, textString = "%baudrate,E,%dataBits,%stopBits"), Text(visible = parity == Interfaces.UartParity.Odd, textColor = {200, 200, 200}, extent = {{-90, -2}, {90, -20}}, textString = "%baudrate,O,%dataBits,%stopBits"), Ellipse(fillColor = DynamicSelect({60, 60, 60}, if txActive then {255, 180, 60} else {60, 60, 60}), fillPattern = FillPattern.Solid, lineColor = {30, 30, 30}, extent = {{-98, 42}, {-86, 30}}), Ellipse(fillColor = DynamicSelect({60, 60, 60}, if rxBusy then {60, 210, 255} else {60, 60, 60}), fillPattern = FillPattern.Solid, lineColor = {30, 30, 30}, extent = {{-98, -30}, {-86, -42}}), Text(textColor = {255, 255, 255}, extent = {{-82, 42}, {-52, 28}}, textString = "TX", horizontalAlignment = TextAlignment.Left), Text(textColor = {255, 255, 255}, extent = {{-82, -28}, {-52, -42}}, textString = "RX", horizontalAlignment = TextAlignment.Left), Text(textColor = {255, 255, 255}, extent = {{56, 42}, {98, 28}}, textString = "val", horizontalAlignment = TextAlignment.Right), Text(textColor = {255, 255, 255}, extent = {{56, -28}, {98, -42}}, textString = "out", horizontalAlignment = TextAlignment.Right), Text(visible = useGroundPin, extent = {{-25, -60}, {25, -69}}, textString = "GND"), Text(origin = {0, -6}, textColor = {0, 0, 255}, extent = {{-150, 108}, {150, 72}}, textString = "%name")}),
    Diagram(coordinateSystem(preserveAspectRatio = true, extent = {{-100, -100}, {100, 100}})),
    Documentation(info = "<html>
<p>Base class of the external serial devices. It cannot be instantiated directly: a concrete device extends it and sets its parameters — see <code>Peripherals.UartEchoDevice</code>, <code>UartTemperatureSensor</code>, <code>UartGpsModule</code>, <code>UartLcd20x2</code>, or <code>Peripherals.UartGenericDevice</code> for a device entirely described by its parameters.</p>
<p>The device is connected <strong>electrically</strong> to two <code>GPx</code> pins of an <code>MCU</code>: it receives real frames and transmits real ones, at its own baud rate and in its own format (<code>dataBits</code>, <code>parity</code>, <code>stopBits</code>: 8N1 by default, same choices as <code>machine.UART</code>). A baud rate or format mismatch with the microcontroller therefore produces wrong bytes, as on a real circuit; a received byte with a wrong parity bit or a low stop bit is kept, with a warning in the log (the first ten, then a total at the end of the simulation).</p>
<p><strong>Two transmission modes, which can be combined</strong>, feeding the same queue:</p>
<ul>
<li><em>Request / response</em>: the received bytes accumulate up to <code>terminator</code>, the complete line is matched against <code>commandTable</code>, and the reply leaves after <code>responseDelay</code>.</li>
<li><em>Periodic</em>: <code>periodicTemplate</code> is transmitted spontaneously every <code>period</code> seconds, without being asked.</li>
</ul>
<p><strong>Quantities exchanged with the rest of the model.</strong> <code>{v1}</code>…<code>{vN}</code> insert <code>valueIn</code> into a transmitted frame (with an optional precision, <code>{v1:.1f}</code>); <code>{o1}</code>…<code>{oN}</code>, placed in a <em>command</em>, capture a number of the received frame into <code>valueOut</code>. The same device can therefore be both sensor and actuator, which lets a control loop be closed inside the model.</p>
<p>The two dots of the icon light up during a transmitted frame (amber) or a received one (cyan) — visible while replaying a result with animation in OMEdit, not on a static rendering. Each received line and each transmitted payload also produce a line in the simulation log, prefixed with the component name.</p>
</html>"));
end PartialUartDevice;
