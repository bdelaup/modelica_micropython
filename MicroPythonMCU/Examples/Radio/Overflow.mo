within MicroPythonMCU.Examples.Radio;

model Overflow "A burst written faster than the air can carry it: the 16-byte transmit buffer fills up and the end of the burst is lost"
  extends Modelica.Icons.Example;
  MCU mcuA(scriptPath = Modelica.Utilities.Files.loadResource("modelica://MicroPythonMCU/Resources/Scripts/MCU/radio_burst.py")) "Board A: Resources/Scripts/MCU/radio_burst.py (TX = GP0)" annotation(
    Placement(transformation(origin = {-104, 0}, extent = {{20, -20}, {-20, 20}})));
  MCU mcuB(scriptPath = Modelica.Utilities.Files.loadResource("modelica://MicroPythonMCU/Resources/Scripts/MCU/radio_listen.py")) "Board B: Resources/Scripts/MCU/radio_listen.py (RX = GP1)" annotation(
    Placement(transformation(origin = {104, 0}, extent = {{-20, -20}, {20, 20}})));
  Peripherals.Radio.RadioModem radioA(airBaudrate = 1200, txBufferSize = 16, warnSampling = false) "9600 baud on the UART, only 1200 bit/s on air, 16-byte transmit buffer - warnSampling = false: the 100 us output interval is chosen for the buffers, not for the drawn carrier" annotation(
    Placement(transformation(origin = {-36, 8}, extent = {{-20, -20}, {20, 20}})));
  Peripherals.Radio.RadioModem radioB(airBaudrate = 1200, warnSampling = false) "Same air data rate, otherwise default settings" annotation(
    Placement(transformation(origin = {36, 8}, extent = {{20, -20}, {-20, 20}})));
  Modelica.Electrical.Analog.Basic.Ground ground annotation(
    Placement(transformation(origin = {0, -70}, extent = {{-10, -10}, {10, 10}})));
equation
  connect(mcuA.GND, ground.p) annotation(
    Line(points = {{-104, -14}, {-104, -56}, {0, -56}, {0, -60}}, color = {0, 0, 255}));
  connect(mcuB.GND, ground.p) annotation(
    Line(points = {{104, -14}, {104, -56}, {0, -56}, {0, -60}}, color = {0, 0, 255}));
  connect(radioA.GND, ground.p) annotation(
    Line(points = {{-36, -4}, {-36, -56}, {0, -56}, {0, -60}}, color = {0, 0, 255}));
  connect(radioB.GND, ground.p) annotation(
    Line(points = {{36, -4}, {36, -56}, {0, -56}, {0, -60}}, color = {0, 0, 255}));
  connect(mcuA.GP0, radioA.RX) annotation(
    Line(points = {{-92, 10}, {-76, 10}, {-76, 2}, {-58, 2}}, color = {0, 0, 255}));
  connect(radioB.TX, mcuB.GP1) annotation(
    Line(points = {{58, 14}, {70, 14}, {70, 4}, {92, 4}}, color = {0, 0, 255}));
  connect(radioA.antenna, radioB.antenna) annotation(
    Line(points = {{-14, 14}, {14, 14}}, color = {170, 85, 0}, thickness = 0.5));
  annotation(
    Diagram(coordinateSystem(extent = {{-140, -84}, {140, 42}})),
    experiment(StopTime = 0.5, Interval = 0.0001, StartTime = 0, Tolerance = 1e-06),
    Documentation(info = "<html>
<p>Board A writes 40 bytes at once at 9600 baud (one byte every 1.04 ms), but its radio module only transmits at 1200 bit/s (one radio frame every 8.3 ms) and its transmit buffer holds 16 bytes. The buffer fills up (plot <code>radioA.txFill</code>, or watch the amber bar of the icon), then every byte arriving while it is full is lost (<code>radioA.nDropped</code>, warnings in the log); a place is freed only each time a radio frame leaves. Board B prints what it received: the beginning of the burst, then a few scattered characters.</p>
<p>Try <code>radioA.txBufferSize = 64</code> (nothing is lost, but the last byte arrives much later), or <code>radioA.airBaudrate = 9600</code> (the air keeps up with the serial link).</p>
</html>"));
end Overflow;
