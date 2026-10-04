within MicroPythonMCU.Examples.Radio;

model Overflow "A burst written faster than the air can carry it: the 16-byte transmit buffer fills up and the end of the burst is lost"
  extends Modelica.Icons.Example;
  MCU mcuA(scriptPath = Modelica.Utilities.Files.loadResource("modelica://MicroPythonMCU/Resources/Scripts/MCU/radio_burst.py")) "Board A: Resources/Scripts/MCU/radio_burst.py (TX = GP0)" annotation(
    Placement(transformation(origin = {-150, 0}, extent = {{40, -40}, {-40, 40}})));
  MCU mcuB(scriptPath = Modelica.Utilities.Files.loadResource("modelica://MicroPythonMCU/Resources/Scripts/MCU/radio_listen.py")) "Board B: Resources/Scripts/MCU/radio_listen.py (RX = GP1)" annotation(
    Placement(transformation(origin = {150, 0}, extent = {{-40, -40}, {40, 40}})));
  Peripherals.Radio.RadioModem radioA(airBaudrate = 1200, txBufferSize = 16) "9600 baud on the UART, only 1200 bit/s on air, 16-byte transmit buffer" annotation(
    Placement(transformation(origin = {-50, 10}, extent = {{-30, -30}, {30, 30}})));
  Peripherals.Radio.RadioModem radioB(airBaudrate = 1200) "Same air data rate, otherwise default settings" annotation(
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
  connect(mcuA.GP0, radioA.RX) annotation(
    Line(points = {{-125, 20}, {-110, 20}, {-110, -0.2}, {-87.2, -0.2}}, color = {0, 0, 255}));
  connect(radioB.TX, mcuB.GP1) annotation(
    Line(points = {{87.2, 20.2}, {100, 20.2}, {100, 8}, {125, 8}}, color = {0, 0, 255}));
  connect(radioA.antenna, radioB.antenna) annotation(
    Line(points = {{-12.8, 20.2}, {12.8, 20.2}}, color = {170, 85, 0}, thickness = 0.5));
  annotation(
    Diagram(coordinateSystem(extent = {{-200, -120}, {200, 60}})),
    experiment(StopTime = 0.5, Interval = 0.0001, StartTime = 0, Tolerance = 1e-06),
    Documentation(info = "<html>
<p>Board A writes 40 bytes at once at 9600 baud (one byte every 1.04 ms), but its radio module only transmits at 1200 bit/s (one radio frame every 8.3 ms) and its transmit buffer holds 16 bytes. The buffer fills up (plot <code>radioA.txFill</code>, or watch the amber bar of the icon), then every byte arriving while it is full is lost (<code>radioA.nDropped</code>, warnings in the log); a place is freed only each time a radio frame leaves. Board B prints what it received: the beginning of the burst, then a few scattered characters.</p>
<p>Try <code>radioA.txBufferSize = 64</code> (nothing is lost, but the last byte arrives much later), or <code>radioA.airBaudrate = 9600</code> (the air keeps up with the serial link).</p>
</html>"));
end Overflow;
