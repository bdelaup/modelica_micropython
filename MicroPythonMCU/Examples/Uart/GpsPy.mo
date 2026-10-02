within MicroPythonMCU.Examples.Uart;

model GpsPy "A GPS module spontaneously pushes its position frames; the microcontroller counts them without ever asking for anything"
  extends Modelica.Icons.Example;
  MCU mcu(scriptPath = Modelica.Utilities.Files.loadResource("modelica://MicroPythonMCU/Resources/Scripts/MCU/uart_gps.py")) "scriptPath = Resources/Scripts/MCU/uart_gps.py" annotation(
    Placement(transformation(origin = {-90, 0}, extent = {{-50, -50}, {50, 50}})));
  MicroPythonMCU.Peripherals.UartGpsModule gps(baudrate = 9600, period = 0.1, behaviour = MicroPythonMCU.Interfaces.UartBehaviour.Script, scriptPath = Modelica.Utilities.Files.loadResource("modelica://MicroPythonMCU/Resources/Scripts/Device/gps.py")) "Transmits an NMEA RMC sentence every 100 ms, without being asked - behaviour described by Resources/Scripts/Device/gps.py" annotation(
    Placement(transformation(origin = {40, 0}, extent = {{-40, -40}, {40, 40}})));
  Modelica.Blocks.Sources.Ramp latitude(height = 0.01, duration = 1, offset = 47.24) "The position changes: successive frames are not identical" annotation(
    Placement(transformation(origin = {160, 45}, extent = {{12, -12}, {-12, 12}})));
  Modelica.Blocks.Sources.Constant longitude(k = 5.9876) annotation(
    Placement(transformation(origin = {160, 10}, extent = {{12, -12}, {-12, 12}})));
  Modelica.Blocks.Sources.Constant speed(k = 12.3) annotation(
    Placement(transformation(origin = {160, -25}, extent = {{12, -12}, {-12, 12}})));
  Modelica.Electrical.Analog.Basic.Ground ground annotation(
    Placement(transformation(origin = {-25, -80}, extent = {{-10, -10}, {10, 10}})));
equation
// Serial link: GP5 (TX) goes down to RX, TX comes back up to GP4 (RX)
  connect(mcu.GP5, gps.RX) annotation(
    Line(points = {{-59, 10}, {-34, 10}, {-34, -13.6}, {-9.6, -13.6}}, color = {0, 0, 255}));
  connect(gps.TX, mcu.GP4) annotation(
    Line(points = {{-9.6, 13.6}, {-34, 13.6}, {-34, 25}, {-59, 25}}, color = {0, 0, 255}));
// The three quantities published in the frame, grouped on the right
  connect(latitude.y, gps.valueIn[1]) annotation(
    Line(points = {{147, 45}, {112, 45}, {112, 13.6}, {89.6, 13.6}}, color = {0, 0, 127}));
  connect(longitude.y, gps.valueIn[2]) annotation(
    Line(points = {{147, 10}, {112, 10}, {112, 13.6}, {89.6, 13.6}}, color = {0, 0, 127}));
  connect(speed.y, gps.valueIn[3]) annotation(
    Line(points = {{147, -25}, {112, -25}, {112, 13.6}, {89.6, 13.6}}, color = {0, 0, 127}));
// Common ground
  connect(mcu.GND, ground.p) annotation(
    Line(points = {{-90, -39}, {-90, -70}, {-25, -70}}, color = {0, 0, 255}));
  connect(gps.GND, ground.p) annotation(
    Line(points = {{40, -28.8}, {40, -70}, {-25, -70}}, color = {0, 0, 255}));
  annotation(
    Diagram(coordinateSystem(extent = {{-160, -100}, {200, 80}})),
    experiment(StopTime = 0.6, Interval = 5e-5),
    Documentation(info = "<html>
<p>The mirror of <code>Examples.Uart.Sensor</code>: here the device speaks first and waits for no question.</p>
<p>Consequence on the embedded program side: reception never wakes it up (no <code>uart.irq()</code>), so it must <strong>poll</strong> its input with <code>uart.any()</code> in a loop, sleeping between two passes. A program that forgot to sleep would prevent simulated time from moving forward; a program that slept too long would miss frames — both defects show up immediately when running, which makes it a useful test bench to validate a polling strategy before porting it to the target.</p>
<p>The module is in <strong>Script</strong> mode (<code>gps.behaviour = Script</code>): <code>Device/gps.py</code> produces complete NMEA RMC sentences — UTC time, hemispheres, <strong>checksum</strong> —, which the command table cannot do. The microcontroller program checks each checksum, exactly like the embedded code of a real receiver. The script also keeps a counter of transmitted sentences, published on <code>gps.valueOut[1]</code>.</p>
<p>The latitude is a ramp: successive sentences differ, which lets you check at a glance in the log that the stream is really alive and not repeated.</p>
</html>"));
end GpsPy;
