within MicroPythonMCU.Examples.Pico;

model UartDuo "Two Raspberry Pi Pico talking over TWO serial links at the same time: UART(0) on GP0/GP1, UART(1) on GP4/GP5 - the two UART engines of the RP2040, each with its own wires"
  extends Modelica.Icons.Example;
  RPi_Pico picoA(scriptPath = Modelica.Utilities.Files.loadResource("modelica://MicroPythonMCU/Resources/Scripts/MCU/uart_duo_a.py")) "Board A: Resources/Scripts/MCU/uart_duo_a.py (UART(0) on GP0/GP1, UART(1) on GP4/GP5)" annotation(
    Placement(transformation(origin = {-60, 20}, extent = {{-20, -42}, {20, 54}})));
  RPi_Pico picoB(scriptPath = Modelica.Utilities.Files.loadResource("modelica://MicroPythonMCU/Resources/Scripts/MCU/uart_duo_b.py")) "Board B: Resources/Scripts/MCU/uart_duo_b.py (same pins, answers PONG and WORLD)" annotation(
    Placement(transformation(origin = {80, 20}, extent = {{-20, -42}, {20, 54}})));
  Modelica.Electrical.Analog.Basic.Ground ground annotation(
    Placement(transformation(origin = {10, -90}, extent = {{-10, -10}, {10, 10}})));
equation
// Link 0 : TX of A -> RX of B
  connect(picoA.GP0, picoB.GP1) annotation(
    Line(points = {{-74, 34}, {-90, 34}, {-90, 78}, {66, 78}, {66, 24}}, color = {0, 0, 255}));
// Link 0 : TX of B -> RX of A
  connect(picoB.GP0, picoA.GP1) annotation(
    Line(points = {{66, 34}, {50, 34}, {50, 90}, {-80, 90}, {-80, 14}, {-74, 14}}, color = {0, 0, 255}));
// Link 1 : TX of A -> RX of B
  connect(picoA.GP4, picoB.GP5) annotation(
    Line(points = {{-74, 6}, {-96, 6}, {-96, 96}, {94, 96}, {94, 6}, {100, 6}}, color = {0, 0, 255}));
// Link 1 : TX of B -> RX of A
  connect(picoB.GP4, picoA.GP5) annotation(
    Line(points = {{66, 6}, {58, 6}, {58, 62}, {-70, 62}, {-70, -14}, {-74, -14}}, color = {0, 0, 255}));
// Common ground
  connect(picoA.GND_3, ground.p) annotation(
    Line(points = {{-78, -8}, {-78, -70}, {10, -70}, {10, -80}}, color = {0, 0, 255}));
  connect(picoB.GND_3, ground.p) annotation(
    Line(points = {{62, -8}, {62, -70}, {10, -70}, {10, -80}}, color = {0, 0, 255}));
  annotation(
    Diagram(coordinateSystem(extent = {{-160, 130}, {160, -130}})),
    experiment(StopTime = 4, Interval = 0.0001, StartTime = 0, Tolerance = 1e-06),
    __OpenModelica_simulationFlags(nlssMaxDensity = "0"),
    Documentation(info = "<html>
<p>Two <code>RPi_Pico</code> talking over <b>two real serial links at the same time</b>: <code>UART(0)</code> on GP0/GP1 and <code>UART(1)</code> on GP4/GP5, the default pins of the two UART engines of the RP2040. Board A (<code>uart_duo_a.py</code>) sends <code>PING n</code> on the first link and <code>HELLO n</code> on the second, five times; board B (<code>uart_duo_b.py</code>) answers <code>PONG n</code> and <code>WORLD n</code> on the respective link. In the log, A prints <code>SENT n</code> then <code>BOTH n</code> when both replies of the round arrived together - the two engines really run in parallel.</p>
<p>Since the refactoring of the micro:bit radio (decision \"Radios micro:bit\" of <code>requirements.md</code>), the runtime carries two UART engines: <code>machine.UART(0)</code> and <code>machine.UART(1)</code> are now independent - on the micro:bit, the second one belongs to the on-board radio. See <code>Examples.MultiMcu.Uart</code> for a single link between two <code>MCU</code>.</p>
</html>"));
end UartDuo;
