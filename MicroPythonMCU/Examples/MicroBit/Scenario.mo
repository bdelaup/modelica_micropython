within MicroPythonMCU.Examples.MicroBit;

model Scenario "Scenario driven by time tables: button presses, accelerometer shake, temperature and light ramps - no external wiring needed"
  extends Modelica.Icons.Example;
  MicroPythonMCU.MicroBit_v2 mb(scriptPath = Modelica.Utilities.Files.loadResource("modelica://MicroPythonMCU/Resources/Scripts/MCU/microbit_scenario.py"), buttonASource = MicroPythonMCU.MicroBit_v2.InputSource.Table, buttonBSource = MicroPythonMCU.MicroBit_v2.InputSource.Table, accelXSource = MicroPythonMCU.MicroBit_v2.InputSource.Table, tempSource = MicroPythonMCU.MicroBit_v2.InputSource.Table, lightSource = MicroPythonMCU.MicroBit_v2.InputSource.Table) "Program: Resources/Scripts/MCU/microbit_scenario.py; boutons et capteurs pilotes par les tables horaires internes (onglets Buttons et Sensors)" annotation(
    Placement(transformation(origin = {0, 0}, extent = {{-60, -60}, {60, 60}})));
  Modelica.Electrical.Analog.Basic.Ground ground annotation(
    Placement(transformation(origin = {40, -85}, extent = {{-10, -10}, {10, 10}})));
equation
  connect(mb.GND, ground.p) annotation(
    Line(points = {{40, -43.66}, {40, -75}}, color = {0, 0, 255}));
  annotation(
    Diagram(coordinateSystem(extent = {{-120, 60}, {120, -100}})),
    experiment(StopTime = 10, Interval = 0.001, StartTime = 0, Tolerance = 1e-06),
    Documentation(info = "<html>
<p>Expected result: the script starts by showing a heart, then reacts to the time-table-driven events:</p>
<ul>
<li><b>t=1 s</b> : accelerometer shake (accelX table peaks at 5 m/s^2) - the display shows a surprised face briefly.</li>
<li><b>t=2 s</b> : button A pressed (table) - the counter increments, the display shows the count.</li>
<li><b>t=3 s</b> : button B pressed (table) - the counter resets, the display shows a sad face.</li>
<li><b>t=5 s</b> : button A pressed again - the counter shows 1.</li>
<li><b>t=0..5 s</b> : light ramps from 200 to 50 (table) - the script scrolls the light level when it changes by 30+.</li>
<li><b>t=0..10 s</b> : temperature ramps from 27 to 35 degC (table) - the script scrolls the temperature when it changes by 2+ degC.</li>
</ul>
<p>No external wiring is needed: each button and sensor source is set to <i>Table</i> (dropdowns of the <i>Buttons</i> and <i>Sensors</i> tabs), with the default time tables of the board. The same program runs unchanged on a physical micro:bit (wired to real buttons and sensors).</p>
</html>"));
end Scenario;
