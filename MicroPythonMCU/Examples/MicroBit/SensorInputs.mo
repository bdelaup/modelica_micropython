within MicroPythonMCU.Examples.MicroBit;

model SensorInputs "Every input of the board wired from the diagram: all sensors and both buttons driven by their Connector source - shake and ramps from TimeTable blocks, steady levels from Constant blocks, presses from BooleanPulse"
  extends Modelica.Icons.Example;
  MicroPythonMCU.MicroBit_v2 mb(
    scriptPath = Modelica.Utilities.Files.loadResource("modelica://MicroPythonMCU/Resources/Scripts/MCU/microbit_scenario.py"),
    buttonASource = MicroPythonMCU.MicroBit_v2.InputSource.Connector,
    buttonBSource = MicroPythonMCU.MicroBit_v2.InputSource.Connector,
    accelXSource = MicroPythonMCU.MicroBit_v2.InputSource.Connector,
    accelYSource = MicroPythonMCU.MicroBit_v2.InputSource.Connector,
    accelZSource = MicroPythonMCU.MicroBit_v2.InputSource.Connector,
    magXSource = MicroPythonMCU.MicroBit_v2.InputSource.Connector,
    magYSource = MicroPythonMCU.MicroBit_v2.InputSource.Connector,
    magZSource = MicroPythonMCU.MicroBit_v2.InputSource.Connector,
    tempSource = MicroPythonMCU.MicroBit_v2.InputSource.Connector,
    lightSource = MicroPythonMCU.MicroBit_v2.InputSource.Connector, usbConnected = true) "Program: Resources/Scripts/MCU/microbit_scenario.py; all the sensor inputs (accelerometer on the right edge, compass on the left edge, temperature and light on the top edge) and both buttons wired from the diagram" annotation(
    Placement(transformation(origin = {0, 0}, extent = {{-60, -60}, {60, 60}})));
  Modelica.Blocks.Sources.TimeTable lightSrc(table = {{0, 200}, {5, 50}, {20, 50}}) "Light level: ramp from 200 to 50 over the first 5 s, then held" annotation(
    Placement(transformation(origin = {9.13, 130}, extent = {{-10, -10}, {10, 10}}, rotation = 270)));
  Modelica.Blocks.Sources.TimeTable tempSrc(table = {{0, 27}, {10, 35}, {20, 35}}) "Temperature: ramp from 27 to 35 degC over the run, then held" annotation(
    Placement(transformation(origin = {-9.13, 95}, extent = {{-10, -10}, {10, 10}}, rotation = 270)));
  Modelica.Blocks.Sources.Constant magXSrc(k = 0) "Magnetometer X axis: quiet field" annotation(
    Placement(transformation(origin = {-95, 100}, extent = {{-10, -10}, {10, 10}})));
  Modelica.Blocks.Sources.Constant magYSrc(k = 50) "Magnetometer Y axis: field pointing along +Y" annotation(
    Placement(transformation(origin = {-95, 65}, extent = {{-10, -10}, {10, 10}})));
  Modelica.Blocks.Sources.Constant magZSrc(k = 0) "Magnetometer Z axis: quiet field" annotation(
    Placement(transformation(origin = {-95, 30}, extent = {{-10, -10}, {10, 10}})));
  Modelica.Blocks.Sources.BooleanPulse pressA(width = 10, period = 1, startTime = 2) "Button A pressed during 100 ms, every second from t=2 s" annotation(
    Placement(transformation(origin = {-130, 0}, extent = {{-10, -10}, {10, 10}})));
  Modelica.Blocks.Sources.BooleanPulse pressB(width = 10, period = 5, startTime = 4) "Button B pressed during 500 ms, at t=4 s and t=9 s" annotation(
    Placement(transformation(origin = {130, 0}, extent = {{10, -10}, {-10, 10}}, rotation = -0)));
  Modelica.Blocks.Sources.TimeTable accelXSrc(table = {{0, 0}, {0.5, 0}, {1, 5}, {1.5, 0}, {20, 0}}) "Accelerometer X axis: shake at t=1 s (peak at 5 m/s^2), then at rest" annotation(
    Placement(transformation(origin = {95, 100}, extent = {{10, -10}, {-10, 10}}, rotation = -0)));
  Modelica.Blocks.Sources.Constant accelYSrc(k = 0) "Accelerometer Y axis: at rest" annotation(
    Placement(transformation(origin = {95, 65}, extent = {{10, -10}, {-10, 10}}, rotation = -0)));
  Modelica.Blocks.Sources.Constant accelZSrc(k = -9.81) "Accelerometer Z axis: gravity, board lying display up" annotation(
    Placement(transformation(origin = {95, 30}, extent = {{10, -10}, {-10, 10}}, rotation = -0)));
  Modelica.Electrical.Analog.Basic.Ground ground annotation(
    Placement(transformation(origin = {39.13, -85}, extent = {{-10, -10}, {10, 10}})));
equation
  connect(lightSrc.y, mb.lightIn) annotation(
    Line(points = {{9.13, 120}, {9.13, 52.37}}, color = {0, 0, 127}));
  connect(tempSrc.y, mb.tempIn) annotation(
    Line(points = {{-9.13, 85}, {-9.13, 52.37}}, color = {0, 0, 127}));
  connect(magXSrc.y, mb.magXIn) annotation(
    Line(points = {{-85, 100}, {-62, 100}, {-62, 35.71}, {-55.49, 35.71}}, color = {0, 0, 127}));
  connect(magYSrc.y, mb.magYIn) annotation(
    Line(points = {{-85, 65}, {-66, 65}, {-66, 25.71}, {-55.49, 25.71}}, color = {0, 0, 127}));
  connect(magZSrc.y, mb.magZIn) annotation(
    Line(points = {{-85, 30}, {-70, 30}, {-70, 15.71}, {-55.49, 15.71}}, color = {0, 0, 127}));
  connect(accelXSrc.y, mb.accelXIn) annotation(
    Line(points = {{85, 100}, {62, 100}, {62, 35.71}, {55.49, 35.71}}, color = {0, 0, 127}));
  connect(accelYSrc.y, mb.accelYIn) annotation(
    Line(points = {{85, 65}, {66, 65}, {66, 25.71}, {55.49, 25.71}}, color = {0, 0, 127}));
  connect(accelZSrc.y, mb.accelZIn) annotation(
    Line(points = {{85, 30}, {70, 30}, {70, 15.71}, {55.49, 15.71}}, color = {0, 0, 127}));
  connect(pressA.y, mb.buttonA) annotation(
    Line(points = {{-120, 0}, {-56.53, 0}}, color = {255, 0, 255}));
  connect(pressB.y, mb.buttonB) annotation(
    Line(points = {{120, 0}, {56.53, 0}}, color = {255, 0, 255}));
  connect(mb.GND, ground.p) annotation(
    Line(points = {{39.13, -43.66}, {39.13, -75}}, color = {0, 0, 255}));
  annotation(
    Diagram(coordinateSystem(extent = {{-150, 150}, {150, -110}})),
    experiment(StopTime = 10, Interval = 0.001, StartTime = 0, Tolerance = 1e-06),
    Documentation(info = "<html>
<p>Every source of the board is set to <b>Connector</b>: the eight sensor inputs and both buttons. Each family faces its ports - compass column on the left, mirrored accelerometer column on the right (their outputs turned towards the board), temperature and light above their ports (turned downwards), buttons straight in front of their connector - so that no wire zigzags or crosses another.</p>
<p>The varying quantities come from <code>TimeTable</code> blocks (shake, temperature and light ramps), the steady levels from <code>Constant</code> blocks (gravity on Z, magnetic field on Y), the presses from <code>BooleanPulse</code> blocks. The program is the same as in <code>Examples.MicroBit.Scenario</code>.</p>
<p>Expected result: heart at start, surprised face at t=1 s (shake from <code>accelXSrc</code>), the counter increments on each button A press (every second from t=2 s) and resets with a sad face at t=4 s and t=9 s (button B), the script scrolls the temperature (27 to 35 degC) and the light level (200 to 50) as they ramp. The same program runs unchanged on a physical micro:bit (wired to real sensors).</p>
</html>"));
end SensorInputs;
