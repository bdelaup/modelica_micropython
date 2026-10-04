within MicroPythonMCU.Examples.Radio;

model Link "Two microcontrollers talk by radio through two radio modules: A sends PING, B answers PONG"
  extends Modelica.Icons.Example;
  MCU mcuA(scriptPath = Modelica.Utilities.Files.loadResource("modelica://MicroPythonMCU/Resources/Scripts/MCU/uart_ping.py")) "Board A: Resources/Scripts/MCU/uart_ping.py (TX = GP0, RX = GP1)" annotation(
    Placement(transformation(origin = {-150, 0}, extent = {{40, -40}, {-40, 40}})));
  MCU mcuB(scriptPath = Modelica.Utilities.Files.loadResource("modelica://MicroPythonMCU/Resources/Scripts/MCU/uart_pong.py")) "Board B: Resources/Scripts/MCU/uart_pong.py (TX = GP0, RX = GP1)" annotation(
    Placement(transformation(origin = {150, 0}, extent = {{-40, -40}, {40, 40}})));
  Peripherals.Radio.RadioModem radioA "Radio module of board A (default settings, those of an APC220: 434 MHz, 9600 bit/s on air, 9600 baud)" annotation(
    Placement(transformation(origin = {-50, 10}, extent = {{-30, -30}, {30, 30}})));
  Peripherals.Radio.RadioModem radioB "Radio module of board B, same settings" annotation(
    Placement(transformation(origin = {50, 10}, extent = {{30, -30}, {-30, 30}})));
  Modelica.Electrical.Analog.Basic.Ground ground annotation(
    Placement(transformation(origin = {0, -100}, extent = {{-15, -15}, {15, 15}})));
equation
  connect(mcuA.GND, ground.p) annotation(
    Line(points = {{-150, -31}, {-150, -85}, {0, -85}}, color = {0, 0, 255}));
  connect(mcuB.GND, ground.p) annotation(
    Line(points = {{150, -31}, {150, -85}, {0, -85}}, color = {0, 0, 255}));
  connect(radioA.GND, ground.p) annotation(
    Line(points = {{-50, -11.6}, {-50, -85}, {0, -85}}, color = {0, 0, 255}));
  connect(radioB.GND, ground.p) annotation(
    Line(points = {{50, -11.6}, {50, -85}, {0, -85}}, color = {0, 0, 255}));
// TX of each board -> RX of its module, TX of the module -> RX of the board
  connect(mcuA.GP0, radioA.RX) annotation(
    Line(points = {{-125, 20}, {-110, 20}, {-110, -0.2}, {-87.2, -0.2}}, color = {0, 0, 255}));
  connect(radioA.TX, mcuA.GP1) annotation(
    Line(points = {{-87.2, 20.2}, {-100, 20.2}, {-100, 8}, {-125, 8}}, color = {0, 0, 255}));
  connect(mcuB.GP0, radioB.RX) annotation(
    Line(points = {{125, 20}, {110, 20}, {110, -0.2}, {87.2, -0.2}}, color = {0, 0, 255}));
  connect(radioB.TX, mcuB.GP1) annotation(
    Line(points = {{87.2, 20.2}, {100, 20.2}, {100, 8}, {125, 8}}, color = {0, 0, 255}));
// The air: ONE wire between the two antennas
  connect(radioA.antenna, radioB.antenna) annotation(
    Line(points = {{-12.8, 20.2}, {12.8, 20.2}}, color = {170, 85, 0}, thickness = 0.5));
  annotation(
    Diagram(coordinateSystem(extent = {{-200, -120}, {200, 60}})),
    experiment(StopTime = 0.25, Interval = 0.0001, StartTime = 0, Tolerance = 1e-06),
    Documentation(info = "<html>
<p>The serial link of <code>Examples.MultiMcu.Uart</code>, but by radio: each board is wired to a <code>RadioModem</code> with its default settings (<code>TX</code> of the board to <code>RX</code> of the module and the reverse, common ground), and the two modules are joined by <strong>one</strong> antenna wire. The programs are exactly the same as with a wired link: the modules are transparent. Board A (<code>uart_ping.py</code>) sends <code>PING 0</code>, <code>PING 1</code>, <code>PING 2</code> and waits each time for the reply of board B (<code>uart_pong.py</code>); A sets <code>GP7</code> high once every reply is right.</p>
<p>Plot <code>mcuA.GP0.v</code> (serial frames of A), <code>radioA.carrierOn</code> (radio frames of A) and <code>mcuB.GP1.v</code> (frames delivered to B): each line arrives a few milliseconds later than by wire — the 5 ms delay of the module, then the radio frame, then the 1 ms delay of the receiver. The drawn carrier <code>radioA.sTx</code> (38.4 kHz) needs an output interval of about 1 µs to be seen: see <code>Examples.Radio.Modulations</code>. At the end, each module writes its summary in the log.</p>
</html>"));
end Link;
