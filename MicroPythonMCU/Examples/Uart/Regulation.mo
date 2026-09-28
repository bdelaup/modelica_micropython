within MicroPythonMCU.Examples.Uart;

model Regulation "Control loop closed through the serial link alone: the real output of the sensor drives the plant, whose response comes back on its input"
  extends Modelica.Icons.Example;
  MCU mcu(scriptPath = Modelica.Utilities.Files.loadResource("modelica://MicroPythonMCU/Resources/Scripts/MCU/uart_regulation.py")) "scriptPath = Resources/Scripts/MCU/uart_regulation.py" annotation(
    Placement(transformation(origin = {-90, 0}, extent = {{-50, -50}, {50, 50}})));
  MicroPythonMCU.Peripherals.UartTemperatureSensor sensor(baudrate = 9600) "Sensor AND actuator: {v1} publishes the measurement, {o1} captures the command" annotation(
    Placement(transformation(origin = {40, 0}, extent = {{-40, -40}, {40, 40}})));
  Modelica.Blocks.Continuous.FirstOrder plant(T = 0.15, k = 0.5, initType = Modelica.Blocks.Types.Init.InitialOutput, y_start = 20) "First-order thermal plant: input = command (0-100), output = temperature (°C)" annotation(
    Placement(transformation(origin = {150, -13.6}, extent = {{-12, -12}, {12, 12}})));
  Modelica.Electrical.Analog.Basic.Ground ground annotation(
    Placement(transformation(origin = {-25, -80}, extent = {{-10, -10}, {10, 10}})));
equation
// Serial link: GP5 (TX) goes down to RX, TX comes back up to GP4 (RX)
  connect(mcu.GP5, sensor.RX) annotation(
    Line(points = {{-59, 10}, {-34, 10}, {-34, -13.6}, {-9.6, -13.6}}, color = {0, 0, 255}));
  connect(sensor.TX, mcu.GP4) annotation(
    Line(points = {{-9.6, 13.6}, {-34, 13.6}, {-34, 25}, {-59, 25}}, color = {0, 0, 255}));
// Loop: the captured command drives the plant, whose output comes back as the measurement.
// The return path goes OVER THE TOP, above both components, so as not to run along either of them.
  connect(sensor.valueOut[1], plant.u) annotation(
    Line(points = {{89.6, -13.6}, {135, -13.6}}, color = {0, 0, 127}));
  connect(plant.y, sensor.valueIn[1]) annotation(
    Line(points = {{163, -13.6}, {180, -13.6}, {180, 55}, {110, 55}, {110, 13.6}, {89.6, 13.6}}, color = {0, 0, 127}));
// Common ground
  connect(mcu.GND, ground.p) annotation(
    Line(points = {{-90, -39}, {-90, -70}, {-25, -70}}, color = {0, 0, 255}));
  connect(sensor.GND, ground.p) annotation(
    Line(points = {{40, -28.8}, {40, -70}, {-25, -70}}, color = {0, 0, 255}));
  annotation(
    Diagram(coordinateSystem(extent = {{-160, -100}, {200, 80}})),
    experiment(StopTime = 1, Interval = 1e-4),
    Documentation(info = "<html>
<p>The example that really uses the <strong>real output</strong> of the serial device. All the rest of the family shows quantities that <em>go into</em> the frames; here a quantity <em>comes out</em> of them and drives the model.</p>
<p>The loop is closed and only goes through the two wires of the serial link:</p>
<ol>
<li>the microcontroller sends <code>AT+TEMP</code>; the sensor answers with the value present on <code>valueIn[1]</code>;</li>
<li>the program computes a command (proportional controller with static gain compensation) and sends <code>SET &lt;command&gt;</code>;</li>
<li>the <code>{o1}</code> marker of the table captures this number and publishes it on <code>valueOut[1]</code>;</li>
<li><code>valueOut[1]</code> drives the first-order plant, whose output comes back on <code>valueIn[1]</code>.</li>
</ol>
<p>Plotting <code>plant.y</code> shows the temperature reaching the 40 °C setpoint, and <code>sensor.valueOut[1]</code> shows the command changing in steps — one step per dialogue cycle, since the control is only refreshed at the pace of the serial exchanges. This is precisely what this circuit lets you study: the effect of the <strong>sampling period imposed by the link speed</strong> on the loop dynamics. Lowering <code>baudrate</code> spaces the cycles out and visibly degrades the response.</p>
</html>"));
end Regulation;
