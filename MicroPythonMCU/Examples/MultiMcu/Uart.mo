within MicroPythonMCU.Examples.MultiMcu;

model Uart "Two microcontrollers talk over a real serial link: A sends PING, B answers PONG"
  extends Modelica.Icons.Example;
  MCU mcuA(scriptPath = Modelica.Utilities.Files.loadResource("modelica://MicroPythonMCU/Resources/Scripts/MCU/uart_ping.py")) "Board A: Resources/Scripts/MCU/uart_ping.py (TX = GP0, RX = GP1)" annotation(
    Placement(transformation(origin = {-42, 0}, extent = {{-20, -20}, {20, 20}})));
  MCU mcuB(scriptPath = Modelica.Utilities.Files.loadResource("modelica://MicroPythonMCU/Resources/Scripts/MCU/uart_pong.py")) "Board B: Resources/Scripts/MCU/uart_pong.py (TX = GP0, RX = GP1)" annotation(
    Placement(transformation(origin = {84, 0}, extent = {{-20, -20}, {20, 20}})));
  Modelica.Electrical.Analog.Basic.Ground ground annotation(
    Placement(transformation(origin = {20, -70}, extent = {{-10, -10}, {10, 10}})));
equation
  connect(mcuA.GND, ground.p) annotation(
    Line(points = {{-42, -14}, {-42, -56}, {20, -56}, {20, -60}}, color = {0, 0, 255}));
  connect(mcuB.GND, ground.p) annotation(
    Line(points = {{84, -14}, {84, -56}, {20, -56}, {20, -60}}, color = {0, 0, 255}));
// TX of A -> RX of B
  connect(mcuA.GP0, mcuB.GP1) annotation(
    Line(points = {{-54, 10}, {-70, 10}, {-70, 42}, {56, 42}, {56, 4}, {72, 4}}, color = {0, 0, 255}));
// TX of B -> RX of A
  connect(mcuB.GP0, mcuA.GP1) annotation(
    Line(points = {{72, 10}, {48, 10}, {48, 28}, {-76, 28}, {-76, 4}, {-54, 4}}, color = {0, 0, 255}));
  annotation(
    Diagram(coordinateSystem(extent = {{-98, -98}, {126, 56}})),
    experiment(StopTime = 0.2, Interval = 0.0001, StartTime = 0, Tolerance = 1e-06),
    Documentation(info = "<html>
<p>Real electrical serial link (<code>machine.UART</code>, 9600 baud, 8N1) between two <code>MCU</code> blocks, crossed as on a breadboard: <code>TX</code> of each board to <code>RX</code> of the other, and a common ground. Board A (<code>uart_ping.py</code>) sends <code>PING 0</code>, <code>PING 1</code>, <code>PING 2</code> and waits each time for the reply; board B (<code>uart_pong.py</code>) answers every line with <code>PONG n</code>. A sets <code>GP7</code> high once every reply is right. Plot <code>mcuA.GP0.v</code> and <code>mcuB.GP0.v</code> to see the frames go one way, then the other.</p>
</html>"));
end Uart;
