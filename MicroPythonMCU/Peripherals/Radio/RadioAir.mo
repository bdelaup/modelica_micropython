within MicroPythonMCU.Peripherals.Radio;

model RadioAir "The air of the micro:bit radio link: every MicroBit_v2 whose Antenna port is wired to the antenna of this component hears every other one - the packets travel between the on-board radio engines, no modulated signal is plotted (unlike RadioModem, which is a real modem on a UART)"
  parameter Integer networkId = 0 "Id of the radio network formed by this air link - leave 0 to derive a unique id from the instance name; boards wired to two different RadioAir never hear each other";
  Interfaces.RadioAirOutput antenna "To the Antenna port of each MicroBit_v2 that shares this air" annotation(
    Placement(transformation(origin = {0, 110}, extent = {{-10, -10}, {10, 10}})));
protected
  final parameter Integer effectiveNetworkId = if networkId <> 0 then networkId else Internal.StringHash(getInstanceName()) "networkId, or a hash of the instance name when left at 0";
equation
  antenna.networkId = effectiveNetworkId;
  annotation(
    Icon(coordinateSystem(preserveAspectRatio = true, extent = {{-100, -100}, {100, 100}}), graphics = {Rectangle(lineColor = {160, 90, 0}, fillColor = {160, 90, 0}, fillPattern = FillPattern.Solid, extent = {{-5, 90}, {5, 10}}), Polygon(lineColor = {160, 90, 0}, fillColor = {160, 90, 0}, fillPattern = FillPattern.Solid, points = {{-30, 12}, {30, 12}, {20, -10}, {-20, -10}}), Ellipse(lineColor = {160, 90, 0}, extent = {{-25, 115}, {25, 65}}), Ellipse(lineColor = {200, 140, 40}, extent = {{-45, 135}, {45, 45}}), Text(textColor = {0, 0, 255}, extent = {{-150, -110}, {150, -140}}, textString = "%name"), Text(textColor = {90, 90, 90}, extent = {{-150, -60}, {150, -80}}, textString = "net %effectiveNetworkId")}),
    Diagram(coordinateSystem(preserveAspectRatio = true, extent = {{-100, -100}, {100, 100}})),
    Documentation(info = "<html>
<p>The shared medium of the <b>micro:bit radio</b> (<code>microbit.radio</code>): each <code>MicroBit_v2</code> exposes an <code>Antenna</code> port (check <code>useRadio</code>); wire the antennas of all the boards that must hear each other to the <code>antenna</code> port of <b>one</b> <code>RadioAir</code>. Boards wired to two different <code>RadioAir</code> components never hear each other - the diagram shows who is on the air, like the single antenna wire of the <code>RadioModem</code>.</p>
<p>Unlike the <code>RadioModem</code> (a real modem on a UART, whose OOK/ASK/FSK/BPSK signal is plotted), the micro:bit radio is modelled as <b>packets</b>: the C engine of each board queues them with the firmware semantics (filtering by <code>channel</code>/<code>group</code>/<code>address</code>, receive queue of depth <code>queue</code>) and delivers them after the air time of the frame (payload + 6 header bytes at 1 or 2 Mbit/s). A board whose antenna is not wired raises an explicit error at <code>radio.on()</code>.</p>
<p><code>networkId</code>: leave 0 (default) and the id is derived from the instance name - unique inside the model; set it explicitly only to force a value.</p>
<p>See the user guide (micro:bit, radio section) and <code>requirements.md</code>, decision \"Radios micro:bit\".</p>
</html>"));
end RadioAir;
