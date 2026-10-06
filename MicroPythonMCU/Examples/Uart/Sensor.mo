within MicroPythonMCU.Examples.Uart;

model Sensor "The microcontroller queries a serial temperature sensor, reads two changing measurements, then sends it a setpoint that comes out on a real output"
  extends Modelica.Icons.Example;
  MCU mcu(scriptPath = Modelica.Utilities.Files.loadResource("modelica://MicroPythonMCU/Resources/Scripts/MCU/uart_sensor.py")) "scriptPath = Resources/Scripts/MCU/uart_sensor.py" annotation(
    Placement(transformation(origin = {-90, 0}, extent = {{-20, -20}, {20, 20}})));
  MicroPythonMCU.Peripherals.UartTemperatureSensor sensor(baudrate = 9600) "Answers AT+TEMP with the temperature present on its input, and SET with a setpoint on its output" annotation(
    Placement(transformation(origin = {40, 0}, extent = {{-20, -20}, {20, 20}})));
  Modelica.Blocks.Sources.Ramp temperature(height = 20, duration = 1, offset = 20) "The measured quantity rises from 20 to 40 °C: the two queries must therefore give two different values" annotation(
    Placement(transformation(origin = {150, 14}, extent = {{10, -10}, {-10, 10}})));
  Modelica.Electrical.Analog.Basic.Ground ground annotation(
    Placement(transformation(origin = {-24, -80}, extent = {{-10, -10}, {10, 10}})));
equation
// Serial link: GP5 (TX) goes down to RX, TX comes back up to GP4 (RX)
  connect(mcu.GP5, sensor.RX) annotation(
    Line(points = {{-78, 4}, {-34, 4}, {-34, -6}, {18, -6}}, color = {0, 0, 255}));
  connect(sensor.TX, mcu.GP4) annotation(
    Line(points = {{18, 6}, {-34, 6}, {-34, 10}, {-78, 10}}, color = {0, 0, 255}));
// The measured quantity comes from the rest of the model, from the right
  connect(temperature.y, sensor.valueIn[1]) annotation(
    Line(points = {{139, 14}, {100, 14}, {100, 6}, {62, 6}}, color = {0, 0, 127}));
// Common ground
  connect(mcu.GND, ground.p) annotation(
    Line(points = {{-90, -14}, {-90, -66}, {-24, -66}, {-24, -70}}, color = {0, 0, 255}));
  connect(sensor.GND, ground.p) annotation(
    Line(points = {{40, -12}, {40, -66}, {-24, -66}, {-24, -70}}, color = {0, 0, 255}));
  annotation(
    Diagram(coordinateSystem(extent = {{-160, -100}, {180, 80}})),
    experiment(StopTime = 0.5, Interval = 5e-5),
    Documentation(info = "<html>
<p>A complete <strong>request / response dialogue</strong>, in both directions, over an electrical serial link.</p>
<p><strong>What the input port brings.</strong> The temperature is not a constant frozen in the sensor: it comes in through the <code>valueIn</code> connector, here from a ramp. The microcontroller queries the sensor twice, 100 ms apart, and reads two different values — any thermal model can be connected instead of the ramp.</p>
<p><strong>And in the other direction.</strong> The program ends with <code>SET 42.5</code>. The sensor recognises this pattern thanks to the capture marker <code>{o1}</code> of its table, and the number comes out on <code>sensor.valueOut[1]</code>. Plotting this variable shows the setpoint appearing at the exact instant the frame finishes arriving. For a complete loop where this output really drives a plant, see <code>Examples.Uart.Regulation</code>.</p>
</html>"));
end Sensor;
