within MicroPythonMCU.Examples.Radio;

model Modulations "One character sent through four radio links, in OOK, ASK, FSK and BPSK: the drawn signal of each modulation"
  extends Modelica.Icons.Example;
  MCU mcu(scriptPath = Modelica.Utilities.Files.loadResource("modelica://MicroPythonMCU/Resources/Scripts/MCU/radio_beacon.py")) "Resources/Scripts/MCU/radio_beacon.py: writes 'U' once (TX = GP0)" annotation(
    Placement(transformation(origin = {-110, 0}, extent = {{-20, -20}, {20, 20}})));
  Peripherals.Radio.RadioModem txOOK(airBaudrate = 1200, modulation = Interfaces.Modulation.OOK) "Transmitter, OOK" annotation(
    Placement(transformation(origin = {-20, 60}, extent = {{-20, -20}, {20, 20}})));
  Peripherals.Radio.RadioModem rxOOK(airBaudrate = 1200, modulation = Interfaces.Modulation.OOK) "Receiver, OOK" annotation(
    Placement(transformation(origin = {80, 60}, extent = {{20, -20}, {-20, 20}})));
  Peripherals.Radio.RadioModem txASK(airBaudrate = 1200, modulation = Interfaces.Modulation.ASK) "Transmitter, ASK" annotation(
    Placement(transformation(origin = {-20, 20}, extent = {{-20, -20}, {20, 20}})));
  Peripherals.Radio.RadioModem rxASK(airBaudrate = 1200, modulation = Interfaces.Modulation.ASK) "Receiver, ASK" annotation(
    Placement(transformation(origin = {80, 20}, extent = {{20, -20}, {-20, 20}})));
  Peripherals.Radio.RadioModem txFSK(airBaudrate = 1200, modulation = Interfaces.Modulation.FSK) "Transmitter, FSK" annotation(
    Placement(transformation(origin = {-20, -20}, extent = {{-20, -20}, {20, 20}})));
  Peripherals.Radio.RadioModem rxFSK(airBaudrate = 1200, modulation = Interfaces.Modulation.FSK) "Receiver, FSK" annotation(
    Placement(transformation(origin = {80, -20}, extent = {{20, -20}, {-20, 20}})));
  Peripherals.Radio.RadioModem txBPSK(airBaudrate = 1200, modulation = Interfaces.Modulation.BPSK) "Transmitter, BPSK" annotation(
    Placement(transformation(origin = {-20, -60}, extent = {{-20, -20}, {20, 20}})));
  Peripherals.Radio.RadioModem rxBPSK(airBaudrate = 1200, modulation = Interfaces.Modulation.BPSK) "Receiver, BPSK" annotation(
    Placement(transformation(origin = {80, -60}, extent = {{20, -20}, {-20, 20}})));
  Modelica.Electrical.Analog.Basic.Ground ground annotation(
    Placement(transformation(origin = {20, -124}, extent = {{-10, -10}, {10, 10}})));
equation
  connect(mcu.GND, ground.p) annotation(
    Line(points = {{-110, -14}, {-110, -110}, {20, -110}, {20, -114}}, color = {0, 0, 255}));
  connect(mcu.GP0, txOOK.RX) annotation(
    Line(points = {{-122, 10}, {-150, 10}, {-150, 100}, {-50, 100}, {-50, 54}, {-42, 54}}, color = {0, 0, 255}));
  connect(txOOK.GND, ground.p) annotation(
    Line(points = {{-20, 48}, {-20, 46}, {20, 46}, {20, -114}}, color = {0, 0, 255}));
  connect(rxOOK.GND, ground.p) annotation(
    Line(points = {{80, 48}, {80, 46}, {20, 46}, {20, -114}}, color = {0, 0, 255}));
  connect(txOOK.antenna, rxOOK.antenna) annotation(
    Line(points = {{2, 66}, {58, 66}}, color = {170, 85, 0}, thickness = 0.5));
  connect(mcu.GP0, txASK.RX) annotation(
    Line(points = {{-122, 10}, {-150, 10}, {-150, 100}, {-50, 100}, {-50, 14}, {-42, 14}}, color = {0, 0, 255}));
  connect(txASK.GND, ground.p) annotation(
    Line(points = {{-20, 8}, {-20, 6}, {20, 6}, {20, -114}}, color = {0, 0, 255}));
  connect(rxASK.GND, ground.p) annotation(
    Line(points = {{80, 8}, {80, 6}, {20, 6}, {20, -114}}, color = {0, 0, 255}));
  connect(txASK.antenna, rxASK.antenna) annotation(
    Line(points = {{2, 26}, {58, 26}}, color = {170, 85, 0}, thickness = 0.5));
  connect(mcu.GP0, txFSK.RX) annotation(
    Line(points = {{-122, 10}, {-150, 10}, {-150, 100}, {-50, 100}, {-50, -26}, {-42, -26}}, color = {0, 0, 255}));
  connect(txFSK.GND, ground.p) annotation(
    Line(points = {{-20, -32}, {-20, -34}, {20, -34}, {20, -114}}, color = {0, 0, 255}));
  connect(rxFSK.GND, ground.p) annotation(
    Line(points = {{80, -32}, {80, -34}, {20, -34}, {20, -114}}, color = {0, 0, 255}));
  connect(txFSK.antenna, rxFSK.antenna) annotation(
    Line(points = {{2, -14}, {58, -14}}, color = {170, 85, 0}, thickness = 0.5));
  connect(mcu.GP0, txBPSK.RX) annotation(
    Line(points = {{-122, 10}, {-150, 10}, {-150, 100}, {-50, 100}, {-50, -66}, {-42, -66}}, color = {0, 0, 255}));
  connect(txBPSK.GND, ground.p) annotation(
    Line(points = {{-20, -72}, {-20, -74}, {20, -74}, {20, -114}}, color = {0, 0, 255}));
  connect(rxBPSK.GND, ground.p) annotation(
    Line(points = {{80, -72}, {80, -74}, {20, -74}, {20, -114}}, color = {0, 0, 255}));
  connect(txBPSK.antenna, rxBPSK.antenna) annotation(
    Line(points = {{2, -54}, {58, -54}}, color = {170, 85, 0}, thickness = 0.5));
  annotation(
    Diagram(coordinateSystem(extent = {{-160, -150}, {120, 110}})),
    experiment(StopTime = 0.04, Interval = 1e-05, StartTime = 0, Tolerance = 1e-06),
    Documentation(info = "<html>
<p>The microcontroller writes the character <code>U</code> once (<code>0x55</code>: on air, with its start and stop bits, the frame alternates 0 and 1 at every bit). Its <code>TX</code> pin feeds four transmitters, each joined to its receiver by its own antenna wire and using another modulation. The air data rate is 1200 bit/s, so the drawn carrier is at <code>fDisplay</code> = 4800 Hz (four periods per bit) and the output interval of 10 &micro;s is fine enough to see it.</p>
<p>Plot <code>txOOK.sTx</code>, <code>txASK.sTx</code>, <code>txFSK.sTx</code> and <code>txBPSK.sTx</code> between 25 and 35 ms:</p>
<ul>
<li>OOK: the carrier is there for a 1, absent for a 0;</li>
<li>ASK: full amplitude for a 1, reduced amplitude (0.3) for a 0;</li>
<li>FSK: 3 periods per bit for a 0 (3600 Hz), 5 for a 1 (6000 Hz), without a phase jump;</li>
<li>BPSK: the carrier is inverted at every bit change.</li>
</ul>
<p>Each receiver gets the character (<code>rxOOK.nReceived</code>... equal to 1): the receiver here does not demodulate the drawn signal, it decodes the bit carried by the antenna wire (masked synchronisation, see the user guide).</p>
</html>"));
end Modulations;
