within MicroPythonMCU.Internal;

partial model PartialRadioModem "Base of the transparent radio modems: serial link with the microcontroller, radio frames on air, buffers, fixed delays, drawn modulated signal"
  extends PartialUartPins;
  import Modelica.Constants.pi;

  parameter Integer baudrate = 9600 "Speed of the serial link with the microcontroller, in baud" annotation(
    Dialog(group = "Serial link (microcontroller side)"));
  parameter Integer dataBits(min = 5, max = 8) = 8 "Number of data bits of a serial frame (5 to 8, as machine.UART bits=)" annotation(
    Dialog(group = "Serial link (microcontroller side)"));
  parameter Interfaces.UartParity parity = Interfaces.UartParity.None "Parity of a serial frame (as machine.UART parity=: None, 0 = even, 1 = odd)" annotation(
    Dialog(group = "Serial link (microcontroller side)"));
  parameter Integer stopBits(min = 1, max = 2) = 1 "Number of stop bits of a serial frame (1 or 2, as machine.UART stop=)" annotation(
    Dialog(group = "Serial link (microcontroller side)"));

  parameter Interfaces.Modulation modulation = Interfaces.Modulation.FSK "Modulation of the carrier by the bits of the radio frame - a receiver only hears a transmitter using the same one" annotation(
    Dialog(group = "Radio"));
  parameter Modelica.Units.SI.Frequency fCarrier = 434e6 "Nominal carrier frequency (channel) - a receiver only hears a transmitter whose carrier is within half a channel width of its own" annotation(
    Dialog(group = "Radio"));
  parameter Modelica.Units.SI.Frequency channelWidth = 200e3 "Width of the channel heard around fCarrier" annotation(
    Dialog(group = "Radio"));
  parameter Integer airBaudrate = 9600 "Air data rate, in bit/s - radio frame 8N1, independent of the serial link; both modules must use the same" annotation(
    Dialog(group = "Radio"));
  parameter Boolean halfDuplex = true "Deaf while transmitting: a frame arriving during our own transmission is lost (one radio channel cannot carry both directions at once)" annotation(
    Dialog(group = "Radio"));

  parameter Integer txBufferSize(min = 1, max = 4096) = 256 "Transmit buffer (UART -> air), in bytes - a byte arriving from the UART while it is full is lost" annotation(
    Dialog(group = "Buffers and delays"));
  parameter Integer rxBufferSize(min = 1, max = 4096) = 256 "Receive buffer (air -> UART), in bytes - a byte arriving from the air while it is full is lost" annotation(
    Dialog(group = "Buffers and delays"));
  parameter Modelica.Units.SI.Time txDelay = 0.005 "Fixed delay between the end of a byte on the UART and its earliest transmission on air" annotation(
    Dialog(group = "Buffers and delays"));
  parameter Modelica.Units.SI.Time rxDelay = 0.001 "Fixed delay between the end of a byte on air and its earliest transmission on the UART" annotation(
    Dialog(group = "Buffers and delays"));

  parameter Modelica.Units.SI.Frequency fDisplay = 4*airBaudrate "Scaled carrier used to draw sTx (a real carrier, hundreds of MHz, cannot be drawn) - keep several periods per bit" annotation(
    Dialog(tab = "Drawn signal"));
  parameter Modelica.Units.SI.Frequency deltaFDisplay = airBaudrate "FSK only: shift of the drawn carrier, fDisplay - deltaFDisplay for a 0 and fDisplay + deltaFDisplay for a 1" annotation(
    Dialog(tab = "Drawn signal", enable = modulation == Interfaces.Modulation.FSK));
  parameter Real askLowAmplitude(min = 0, max = 1) = 0.3 "ASK only: amplitude of the drawn carrier for a 0 (1 for a 1)" annotation(
    Dialog(tab = "Drawn signal", enable = modulation == Interfaces.Modulation.ASK));
  parameter Modelica.Units.SI.Time tickPeriod = 0.1 "Period of the minimal sync point: a safety net, the actual pace comes from the engine's deadlines" annotation(
    Dialog(tab = "Drawn signal", group = "Simulation"));

  Interfaces.Antenna antenna "Antenna: connect it with ONE wire to the antenna of the module(s) to talk to" annotation(
    Placement(transformation(origin = {124, 34}, extent = {{-10, -10}, {10, 10}}), iconTransformation(origin = {124, 34}, extent = {{-10, -10}, {10, 10}})));

  // Public: protected variables do not appear in the simulation results
  // in this OpenModelica installation, which would break the DynamicSelect
  // animation of the icon (see requirements.md).
  Real sTx "Modulated signal transmitted, drawn with the scaled carrier fDisplay (0 when not transmitting) - reduce the output interval to see the carrier";
  Real sRx "Signal of the other transmitter as received by this module, whatever its tuning (0 when no other module transmits)";
  // Plain copies of internal variables, without start values: a variable
  // declared with start/fixed would appear in an "Initialization" group of
  // the parameter dialog, although the engine overwrites it at t = 0.
  Boolean carrierOn = carrierOnC "A radio frame is being transmitted";
  Boolean airRxBusy = airRxBusyC "A radio frame is being received";
  Integer txFill = txFillC "Bytes waiting in the transmit buffer (UART -> air)";
  Integer rxFill = rxFillC "Bytes waiting in the receive buffer (air -> UART)";
  Integer nSent = nSentC "Radio frames transmitted so far";
  Integer nReceived = nReceivedC "Radio frames received intact so far";
  Integer nDropped = nDroppedC "Bytes lost so far because a buffer was full";
  Integer nCorrupted = nCorruptedC "Radio frames lost so far: corrupted (air data rate mismatch...), collided, or cut by our own transmission in half duplex";
  Boolean heard "Exactly one other module transmits, on our channel and with our modulation: its frame reaches the decoder";
  Boolean collision = jam "Two other modules or more transmit at once: the frame being received is lost";
protected
  discrete Boolean carrierOnC(start = false, fixed = true) "carrierOn, as published by the C code";
  discrete Boolean airRxBusyC(start = false, fixed = true) "airRxBusy, as published by the C code";
  discrete Integer txFillC(start = 0, fixed = true) "txFill, as published by the C code";
  discrete Integer rxFillC(start = 0, fixed = true) "rxFill, as published by the C code";
  discrete Integer nSentC(start = 0, fixed = true) "nSent, as published by the C code";
  discrete Integer nReceivedC(start = 0, fixed = true) "nReceived, as published by the C code";
  discrete Integer nDroppedC(start = 0, fixed = true) "nDropped, as published by the C code";
  discrete Integer nCorruptedC(start = 0, fixed = true) "nCorrupted, as published by the C code";
  Boolean jam(start = false, fixed = true) "Two other modules or more transmit at once (collision, before its public copy)";
  constant Real EPS = 1e-9 "Weight of a module that is not transmitting in the antenna node: negligible, but keeps the node determined when nobody transmits";
  discrete Boolean airTxLevel(start = true, fixed = true) "Bit being transmitted on air, as published by the C code (idle = high)";
  discrete Real airId(start = 0, fixed = true) "Identifier of this module (1, 2, 3...), published by the C code";
  discrete Modelica.Units.SI.Time nextWakeTime(start = 0, fixed = true) "Next deadline requested by the engine";
  // One event iteration late, like the outputs of MCU (pre()): without it, the
  // when clauses of two modules sharing the air would depend on each other at
  // the same instant, an algebraic loop between discrete equations.
  Boolean txOn(start = false, fixed = true) "carrierOnC, one event iteration later";
  Boolean txBit(start = true, fixed = true) "airTxLevel, one event iteration later";
  Real myId "airId, one event iteration later (constant after the initialisation)";
  parameter Real modulationCode = Integer(modulation) "Modulation as a number, as carried by the antenna wire";
  Real g "Weight of this module in the antenna node";
  Boolean othersOn "At least one other module transmits";
  Boolean single "Exactly one other module transmits";
  Real oId "Identifier of the other transmitter (our own contribution removed)";
  Real oBit "Bit of the other transmitter";
  Modelica.Units.SI.Frequency oF "Nominal carrier frequency of the other transmitter";
  Real oModulation "Modulation of the other transmitter";
  Boolean airLevelIn(start = true, fixed = true) "Level of the radio frame passed to the decoder (idle = high when nothing is audible)";
  discrete Real phi0(start = 0, fixed = true) "Phase of the drawn FSK carrier at the last bit change (continuous phase)";
  discrete Modelica.Units.SI.Time tRef(start = 0, fixed = true) "Instant of the last bit change of the drawn FSK carrier";

  // Integer(parity) - 2: None/Even/Odd (1/2/3) -> the machine.UART convention (-1/0/1) expected by the C code.
  Internal.RadioModem modem = Internal.RadioModem(baudrate, dataBits, Integer(parity) - 2, stopBits, airBaudrate, txBufferSize, rxBufferSize, txDelay, rxDelay, halfDuplex, getInstanceName()) "Engine of the modem: serial and radio frames, buffers, delays" annotation(
    Placement(visible = false, transformation(extent = {{-20, 75}, {20, 95}})));
equation
  assert(fDisplay > 0 and deltaFDisplay >= 0 and deltaFDisplay < fDisplay, "fDisplay must be positive and deltaFDisplay smaller than fDisplay");

  txOn = pre(carrierOnC);
  txBit = pre(airTxLevel);
  myId = pre(airId);

  // Contribution to the antenna node: unit weight while transmitting,
  // negligible otherwise, so that each potential is the mean over the
  // modules transmitting (see Interfaces.Antenna).
  g = if txOn then 1 else EPS;
  antenna.iS = g*(antenna.s - sTx);
  antenna.iBit = g*(antenna.bit - (if txOn and txBit then 1 else 0));
  antenna.iF = g*(antenna.f - (if txOn then fCarrier else 0));
  antenna.iModulation = g*(antenna.modulation - (if txOn then modulationCode else 0));
  antenna.iId = g*(antenna.id - (if txOn then myId else 0));
  antenna.iIdSq = g*(antenna.idSq - (if txOn then myId^2 else 0));

  // The others, as heard from here. While we transmit (full duplex), our own
  // contribution is removed from the mean, assuming one other transmitter;
  // the variance of the identifiers tells whether that assumption holds.
  // noEvent: these quantities only jump at events (they derive from discrete
  // variables), so no crossing function is needed between events.
  othersOn = if txOn then noEvent(antenna.idSq - antenna.id^2 > 1e-6*antenna.id^2) else noEvent(antenna.id > 0.5);
  oId = if txOn then 2*antenna.id - myId else antenna.id;
  single = othersOn and (if txOn then noEvent(abs((myId^2 + oId^2)/2 - antenna.idSq) <= 1e-6*antenna.idSq) else noEvent(antenna.idSq - antenna.id^2 <= 1e-6*antenna.id^2));
  oBit = if txOn then 2*antenna.bit - (if txBit then 1 else 0) else antenna.bit;
  oF = if txOn then 2*antenna.f - fCarrier else antenna.f;
  oModulation = if txOn then 2*antenna.modulation - modulationCode else antenna.modulation;
  sRx = if othersOn then (if txOn then 2*antenna.s - sTx else antenna.s) else 0;

  heard = single and noEvent(abs(oF - fCarrier) <= channelWidth/2 and abs(oModulation - modulationCode) < 0.5);
  jam = othersOn and not single;
  airLevelIn = if heard then noEvent(oBit > 0.5) else true;

  // Drawn signal. OOK, ASK and BPSK: carrier in phase with time 0. FSK: continuous
  // phase, accumulated at each bit change.
  when change(txBit) or change(txOn) then
    phi0 = mod(pre(phi0) + 2*pi*(if pre(txBit) then fDisplay + deltaFDisplay else fDisplay - deltaFDisplay)*(time - pre(tRef)), 2*pi);
    tRef = time;
  end when;
  sTx = if not txOn then 0
    elseif modulation == Interfaces.Modulation.OOK then (if txBit then sin(2*pi*fDisplay*time) else 0)
    elseif modulation == Interfaces.Modulation.ASK then (if txBit then 1 else askLowAmplitude)*sin(2*pi*fDisplay*time)
    elseif modulation == Interfaces.Modulation.BPSK then (if txBit then 1 else -1)*sin(2*pi*fDisplay*time)
    else sin(phi0 + 2*pi*(if txBit then fDisplay + deltaFDisplay else fDisplay - deltaFDisplay)*(time - tRef));

  when {initial(), time >= pre(nextWakeTime), sample(0, tickPeriod), change(rxBoolIn), change(airLevelIn), change(jam)} then
    (txLevel, airTxLevel, carrierOnC, airRxBusyC, txFillC, rxFillC, airId, nSentC, nReceivedC, nDroppedC, nCorruptedC, nextWakeTime) = Internal.RadioModem_sync(modem, time, rxBoolIn, airLevelIn, jam);
  end when;
  annotation(
    Icon(coordinateSystem(preserveAspectRatio = true, extent = {{-100, -100}, {100, 100}}), graphics = {Rectangle(fillColor = {40, 90, 75}, fillPattern = FillPattern.Solid, extent = {{-104, 56}, {104, -56}}), Line(points = {{100, 34}, {88, 34}, {88, 18}}, color = {255, 200, 120}, thickness = 0.75), Line(points = {{88, 18}, {88, 48}}, color = {255, 200, 120}, thickness = 0.75), Line(points = {{78, 50}, {88, 40}, {98, 50}}, color = {255, 200, 120}, thickness = 0.75), Text(visible = modulation == Interfaces.Modulation.OOK, textColor = {255, 220, 150}, extent = {{-70, -16}, {70, -32}}, textString = "OOK"), Text(visible = modulation == Interfaces.Modulation.ASK, textColor = {255, 220, 150}, extent = {{-70, -16}, {70, -32}}, textString = "ASK"), Text(visible = modulation == Interfaces.Modulation.FSK, textColor = {255, 220, 150}, extent = {{-70, -16}, {70, -32}}, textString = "FSK"), Text(visible = modulation == Interfaces.Modulation.BPSK, textColor = {255, 220, 150}, extent = {{-70, -16}, {70, -32}}, textString = "BPSK"), Text(textColor = {255, 255, 255}, extent = {{-98, 42}, {-68, 28}}, textString = "TX", horizontalAlignment = TextAlignment.Left), Text(textColor = {255, 255, 255}, extent = {{-98, -28}, {-68, -42}}, textString = "RX", horizontalAlignment = TextAlignment.Left), Ellipse(fillColor = DynamicSelect({60, 60, 60}, if carrierOn then {255, 180, 60} else {60, 60, 60}), fillPattern = FillPattern.Solid, lineColor = {30, 30, 30}, extent = {{52, 48}, {64, 36}}), Ellipse(fillColor = DynamicSelect({60, 60, 60}, if airRxBusy then {60, 210, 255} else {60, 60, 60}), fillPattern = FillPattern.Solid, lineColor = {30, 30, 30}, extent = {{52, 30}, {64, 18}}), Rectangle(lineColor = {200, 230, 220}, extent = {{20, -38}, {90, -44}}), Rectangle(fillColor = {255, 180, 60}, fillPattern = FillPattern.Solid, pattern = LinePattern.None, extent = DynamicSelect({{20, -38}, {20, -44}}, {{20, -38}, {20 + 70*min(1, txFill/txBufferSize), -44}})), Rectangle(lineColor = {200, 230, 220}, extent = {{20, -47}, {90, -53}}), Rectangle(fillColor = {60, 210, 255}, fillPattern = FillPattern.Solid, pattern = LinePattern.None, extent = DynamicSelect({{20, -47}, {20, -53}}, {{20, -47}, {20 + 70*min(1, rxFill/rxBufferSize), -53}})), Text(textColor = {200, 230, 220}, extent = {{-18, -37}, {18, -45}}, textString = "buf TX", horizontalAlignment = TextAlignment.Right), Text(textColor = {200, 230, 220}, extent = {{-18, -46}, {18, -54}}, textString = "buf RX", horizontalAlignment = TextAlignment.Right), Text(extent = {{-25, -60}, {25, -69}}, textString = "GND"), Text(origin = {0, -6}, textColor = {0, 0, 255}, extent = {{-150, 108}, {150, 72}}, textString = "%name")}),
    Diagram(coordinateSystem(preserveAspectRatio = true, extent = {{-100, -100}, {100, 100}})),
    Documentation(info = "<html>
<p>Base class of the transparent radio modems. It cannot be instantiated directly: see <code>Peripherals.Radio.RadioModem</code> (every setting adjustable) and <code>Peripherals.Radio.Apc220</code> (the settings of an APC220 datasheet).</p>
<p>The modem is connected <strong>electrically</strong> to two <code>GPx</code> pins of an <code>MCU</code> (<code>machine.UART</code>), and to the other module(s) by <strong>one</strong> antenna wire. What it receives on its UART leaves on air, and what it hears on air comes out on its UART:</p>
<ul>
<li>a byte received from the microcontroller waits in the transmit buffer (<code>txBufferSize</code> bytes) at least <code>txDelay</code>, then leaves in a radio frame of 8N1 type at <code>airBaudrate</code>, possibly different from the serial speed;</li>
<li>a radio frame heard intact waits in the receive buffer (<code>rxBufferSize</code>) at least <code>rxDelay</code>, then leaves on the UART;</li>
<li>a byte that finds its buffer full is lost; a corrupted radio frame (different air data rates, for example) is dropped, as by a real module that checks its packets; in half duplex, a frame arriving while the module transmits is lost.</li>
</ul>
<p><strong>Masked synchronisation.</strong> The receiver does not demodulate <code>sTx</code>: the antenna wire also carries the bit being transmitted, which the receiver decodes as a real serial receiver would, at its own air data rate. The modulated signal is drawn for teaching purposes, with a scaled carrier (<code>fDisplay</code>) since a real carrier cannot be drawn; to see it, reduce the output interval of the simulation well below <code>1/fDisplay</code>. A receiver only hears a transmitter on its channel (<code>fCarrier</code> within half a <code>channelWidth</code>) and with its modulation.</p>
<p>The icon shows the radio frames being transmitted (amber dot) and received (cyan dot) and the filling of the two buffers, while replaying a result with animation in OMEdit. At the end of the simulation, each module writes a summary line in the log: bytes passed, bytes lost and why.</p>
</html>"));
end PartialRadioModem;
