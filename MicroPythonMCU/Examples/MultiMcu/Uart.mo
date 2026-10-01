within MicroPythonMCU.Examples.MultiMcu;

model Uart "Two microcontrollers talk over a real serial link: A sends PING, B answers PONG"
  extends Modelica.Icons.Example;
  MCU mcuA(scriptPath = Modelica.Utilities.Files.loadResource("modelica://MicroPythonMCU/Resources/Scripts/MCU/uart_ping.py")) "Board A: Resources/Scripts/MCU/uart_ping.py (TX = GP0, RX = GP1)" annotation(
    Placement(transformation(origin = {-60, 0}, extent = {{-40, -40}, {40, 40}})));
  MCU mcuB(scriptPath = Modelica.Utilities.Files.loadResource("modelica://MicroPythonMCU/Resources/Scripts/MCU/uart_pong.py")) "Board B: Resources/Scripts/MCU/uart_pong.py (TX = GP0, RX = GP1)" annotation(
    Placement(transformation(origin = {120, 0}, extent = {{-40, -40}, {40, 40}})));
  Modelica.Electrical.Analog.Basic.Ground ground annotation(
    Placement(transformation(origin = {30, -100}, extent = {{-15, -15}, {15, 15}})));
equation
  connect(mcuA.GND, ground.p) annotation(
    Line(points = {{-60, -31}, {-60, -85}, {30, -85}}, color = {0, 0, 255}));
  connect(mcuB.GND, ground.p) annotation(
    Line(points = {{120, -31}, {120, -85}, {30, -85}}, color = {0, 0, 255}));
// TX of A -> RX of B
  connect(mcuA.GP0, mcuB.GP1) annotation(
    Line(points = {{-85, 20}, {-100, 20}, {-100, 60}, {80, 60}, {80, 8}, {95, 8}}, color = {0, 0, 255}));
// TX of B -> RX of A
  connect(mcuB.GP0, mcuA.GP1) annotation(
    Line(points = {{95, 20}, {70, 20}, {70, 40}, {-110, 40}, {-110, 8}, {-85, 8}}, color = {0, 0, 255}));
  annotation(
    Diagram(coordinateSystem(extent = {{-140, -140}, {180, 80}})),
    experiment(StopTime = 0.2, Interval = 0.0001, StartTime = 0, Tolerance = 1e-06),
    Documentation(info = "<html>
<p>Real electrical serial link (<code>machine.UART</code>, 9600 baud, 8N1) between two <code>MCU</code> blocks, crossed as on a breadboard: <code>TX</code> of each board to <code>RX</code> of the other, and a common ground. Board A (<code>uart_ping.py</code>) sends <code>PING 0</code>, <code>PING 1</code>, <code>PING 2</code> and waits each time for the reply; board B (<code>uart_pong.py</code>) answers every line with <code>PONG n</code>. A sets <code>GP7</code> high once every reply is right. Plot <code>mcuA.GP0.v</code> and <code>mcuB.GP0.v</code> to see the frames go one way, then the other.</p>
</html>"));
end Uart;
