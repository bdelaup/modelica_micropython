within MicroPythonMCU.Examples.MicroBit;

model RadioChat "Two micro:bit chatting over the radio: the left one sends PING 1..5 (one per second), the right one displays and counts them - both share one RadioAir, like two boards on the same air"
  extends Modelica.Icons.Example;
  MicroPythonMCU.MicroBit_v2 tx(
    scriptPath = Modelica.Utilities.Files.loadResource("modelica://MicroPythonMCU/Resources/Scripts/MCU/microbit_radio_tx.py"),
    buttonASource = MicroPythonMCU.MicroBit_v2.InputSource.Constant,
    buttonBSource = MicroPythonMCU.MicroBit_v2.InputSource.Constant,
    useRadio = true) "Program: Resources/Scripts/MCU/microbit_radio_tx.py; sends PING 1..5 on the air" annotation(
    Placement(transformation(origin = {-80, 0}, extent = {{-60, -60}, {60, 60}})));
  MicroPythonMCU.MicroBit_v2 rx(
    scriptPath = Modelica.Utilities.Files.loadResource("modelica://MicroPythonMCU/Resources/Scripts/MCU/microbit_radio_rx.py"),
    buttonASource = MicroPythonMCU.MicroBit_v2.InputSource.Constant,
    buttonBSource = MicroPythonMCU.MicroBit_v2.InputSource.Constant,
    useRadio = true) "Program: Resources/Scripts/MCU/microbit_radio_rx.py; listens and counts the PINGs" annotation(
    Placement(transformation(origin = {80, 0}, extent = {{-60, -60}, {60, 60}})));
  MicroPythonMCU.Peripherals.Radio.RadioAir air "The air: the boards wired to its antenna hear each other (network id derived from its name)" annotation(
    Placement(transformation(origin = {36, 118}, extent = {{-40, -40}, {40, 40}})));
  Modelica.Electrical.Analog.Basic.Ground gtx annotation(
    Placement(transformation(origin = {-60.87, -85}, extent = {{-10, -10}, {10, 10}})));
  Modelica.Electrical.Analog.Basic.Ground grx annotation(
    Placement(transformation(origin = {99.13, -85}, extent = {{-10, -10}, {10, 10}})));
equation
  connect(tx.Antenna, air.antenna) annotation(
    Line(points = {{-43.48, 52.37}, {-43.48, 162}, {36, 162}}, color = {160, 90, 0}));
  connect(rx.Antenna, air.antenna) annotation(
    Line(points = {{116.52, 52.37}, {116.52, 162}, {36, 162}}, color = {160, 90, 0}));
  connect(tx.GND, gtx.p) annotation(
    Line(points = {{-40.87, -43.66}, {-40.87, -75}, {-60.87, -75}}, color = {0, 0, 255}));
  connect(rx.GND, grx.p) annotation(
    Line(points = {{119.13, -43.66}, {119.13, -75}, {99.13, -75}}, color = {0, 0, 255}));
  annotation(
    Diagram(coordinateSystem(extent = {{-180, 170}, {180, -110}})),
    experiment(StopTime = 10, Interval = 0.001, StartTime = 0, Tolerance = 1e-06),
    Documentation(info = "<html>
<p>Two <code>MicroBit_v2</code> share one <code>Peripherals.Radio.RadioAir</code>: their <code>Antenna</code> ports (shown by <code>useRadio</code>) are wired to its <code>antenna</code>, so their <code>radio</code> modules hear each other - two boards on the same air, like two real micro:bits with matching <code>channel</code>/<code>group</code>/<code>address</code>.</p>
<p>Expected result: the left board scrolls <code>S1</code>...<code>S5</code> as it sends <code>PING 1</code>...<code>PING 5</code> (one per second), the right one displays and counts each received <code>PING n</code>. In the log, <code>TX 1</code>...<code>TX 5</code>/<code>TX_DONE</code> and <code>RX PING 1</code>...<code>RX PING 5</code>/<code>RX_DONE 5</code> interleave. The buttons are kept released (constant mode): this example is about the radio.</p>
<p>The same programs run unchanged on physical micro:bits. See the user guide (micro:bit, radio section) and <code>Examples.MicroBit.Scenario</code> for the internal-table alternative.</p>
</html>"));
end RadioChat;
