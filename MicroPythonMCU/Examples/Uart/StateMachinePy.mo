within MicroPythonMCU.Examples.Uart;

model StateMachinePy "Serial device whose behaviour is described by a state-machine Python script: its reply depends on what happened before"
  extends Modelica.Icons.Example;
  MCU mcu(scriptPath = Modelica.Utilities.Files.loadResource("modelica://MicroPythonMCU/Resources/Scripts/MCU/uart_state_machine.py")) "scriptPath = Resources/Scripts/MCU/uart_state_machine.py" annotation(
    Placement(transformation(origin = {-90, 0}, extent = {{-20, -20}, {20, 20}})));
  MicroPythonMCU.Peripherals.UartGenericDevice device(baudrate = 9600, behaviour = MicroPythonMCU.Interfaces.UartBehaviour.Script, scriptPath = Modelica.Utilities.Files.loadResource("modelica://MicroPythonMCU/Resources/Scripts/Device/state_machine.py"), useValueInput = true, nOut = 2) "Behaviour described by Resources/Scripts/Device/state_machine.py" annotation(
    Placement(transformation(origin = {40, 0}, extent = {{-20, -20}, {20, 20}})));
  Modelica.Blocks.Sources.Sine measurement(amplitude = 2, f = 5, offset = 20) "Quantity published in the replies to READ" annotation(
    Placement(transformation(origin = {150, 14}, extent = {{10, -10}, {-10, 10}})));
  Modelica.Electrical.Analog.Basic.Ground ground annotation(
    Placement(transformation(origin = {-24, -80}, extent = {{-10, -10}, {10, 10}})));
equation
// Serial link: GP5 (TX) goes down to RX, TX comes back up to GP4 (RX)
  connect(mcu.GP5, device.RX) annotation(
    Line(points = {{-78, 4}, {-34, 4}, {-34, -6}, {18, -6}}, color = {0, 0, 255}));
  connect(device.TX, mcu.GP4) annotation(
    Line(points = {{18, 6}, {-34, 6}, {-34, 10}, {-78, 10}}, color = {0, 0, 255}));
  connect(measurement.y, device.valueIn[1]) annotation(
    Line(points = {{139, 14}, {100, 14}, {100, 6}, {62, 6}}, color = {0, 0, 127}));
  connect(mcu.GND, ground.p) annotation(
    Line(points = {{-90, -14}, {-90, -66}, {-24, -66}, {-24, -70}}, color = {0, 0, 255}));
  connect(device.GND, ground.p) annotation(
    Line(points = {{40, -12}, {40, -66}, {-24, -66}, {-24, -70}}, color = {0, 0, 255}));
  annotation(
    Diagram(coordinateSystem(extent = {{-160, -100}, {180, 80}})),
    experiment(StopTime = 0.4, Interval = 5e-5),
    Documentation(info = "<html>
<p>A serial device whose behaviour is not a table but a <strong>Python script</strong>: <code>device.behaviour = Script</code>, and <code>scriptPath</code> designates <code>Device/state_machine.py</code>.</p>
<p>The command table maps a command to a reply, without memory. This script keeps a state: the device only accepts a read if it has been started, refuses a second start, and counts the reads served. The same <code>READ</code> command therefore gets three different replies over the scenario.</p>
<p>The state is made observable by <code>outputs()</code>, which feeds the <code>valueOut</code> connector: plotting <code>device.valueOut[1]</code> shows the device starting then going back to stopped, and <code>device.valueOut[2]</code> shows the read counter. The script's messages appear in the simulation log, prefixed with the component name.</p>
<p>Each received line is delivered only once to the script, even if the simulation evaluates the same instant several times: a state transition is never replayed.</p>
</html>"));
end StateMachinePy;
