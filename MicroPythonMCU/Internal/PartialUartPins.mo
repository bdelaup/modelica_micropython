within MicroPythonMCU.Internal;

partial model PartialUartPins "Electrical side of a serial device: TX output and RX input on two pins, common ground, optional VCC pin - shared by the serial devices and the radio modems"
  extends PartialSupplyPin;
  parameter Modelica.Units.SI.Voltage VOL = Interfaces.VOL "Logic low voltage" annotation(
    Dialog(tab = "Electrical", group = "Levels"));
  parameter Modelica.Units.SI.Voltage VIH = Interfaces.VIH "Threshold above which an input reads high" annotation(
    Dialog(tab = "Electrical", group = "Levels"));
  parameter Modelica.Units.SI.Voltage VIL = Interfaces.VIL "Threshold below which an input reads low" annotation(
    Dialog(tab = "Electrical", group = "Levels"));
  parameter Modelica.Units.SI.Resistance ROut = Interfaces.ROut "Output series resistance" annotation(
    Dialog(tab = "Electrical", group = "Impedances"));
  // RPullUp: a disconnected input thus reads an idle level, and the RX node
  // is never undetermined when nothing is connected to it.
  parameter Modelica.Units.SI.Resistance RPullUp = 1e6 "Pull-up of the RX input to the supply" annotation(
    Dialog(tab = "Electrical", group = "Impedances"));

  Modelica.Electrical.Analog.Interfaces.PositivePin TX "Transmission of the device - to be connected to the receive pin of the microcontroller" annotation(
    Placement(transformation(origin = {-124, 34}, extent = {{-7, -7}, {7, 7}}), iconTransformation(origin = {-110, 30}, extent = {{-5, -5}, {5, 5}})));
  Modelica.Electrical.Analog.Interfaces.PositivePin RX "Reception of the device - to be connected to the transmit pin of the microcontroller" annotation(
    Placement(transformation(origin = {-124, -34}, extent = {{-7, -7}, {7, 7}}), iconTransformation(origin = {-110, -30}, extent = {{-5, -5}, {5, 5}})));
protected
  // CIn is not cosmetic: it gives the receive node a real dynamic state,
  // which breaks the mutual dependency between the when of this device and
  // that of the microcontroller when both directions are connected — without it, the
  // combined model does not build. Protected, hence absent from the parameter
  // dialog: facing a 100 Ω push-pull output, the time constant
  // (0.1 µs) has no visible effect on the frame, and changing it would teach
  // the user nothing (unlike the CIn of the I2C peripherals, which sets the
  // rise time against the pull-ups and stays a parameter). Details in
  // docs/fr/interne/uart-peripheriques.md.
  parameter Modelica.Units.SI.Capacitance CIn = 1e-9 "Input capacitance of the RX pin (pin + cable) - internal, breaks the cycle between the when clauses of this device and of the microcontroller";
  // RIn separates the input capacitance of each device from the wire: without
  // it, the CIn of several devices listening to the same TX pin (one
  // microcontroller feeding several devices) would be in parallel, i.e. one
  // single alias variable carrying several fixed start values (OpenModelica
  // warning "alias variables with redundant start") - same remedy as the I2C
  // peripherals. RIn x CIn = 10 ns, invisible at serial speeds.
  parameter Modelica.Units.SI.Resistance RIn = 10 "Series resistance of the RX pin (pad), between the wire and the input capacitance - internal";

  discrete Boolean txLevel(start = true, fixed = true) "Logic level to hold on TX (idle = high), assigned by the when of the derived class from what the C code publishes: the next sync point falls on the next level CHANGE of the frame, so consecutive identical bits cost no event";

  Modelica.Units.SI.Voltage rxVoltage "Actual voltage on the receive pin";
  Boolean rxBoolIn(start = false, fixed = true) "Logic value read on RX (voltage compared with the VIL/VIH thresholds)";

  // Electrical bridge deliberately simpler than the microcontroller's: the
  // directions are fixed (TX always an output, RX always an input), hence
  // no IdealOpeningSwitch — requirements.md documents that switching
  // Ideal.* components break sleep compression over long simulations.
  Modelica.Electrical.Analog.Sources.SignalVoltage src "Voltage source driven by the frame pattern (supply voltage / VOL)" annotation(
    Placement(visible = false, transformation(extent = {{-190, -90}, {-150, -50}})));
  Modelica.Electrical.Analog.Basic.Resistor rOut(R = ROut) "Output series resistance" annotation(
    Placement(visible = false, transformation(extent = {{-130, -90}, {-90, -50}})));
  Modelica.Electrical.Analog.Basic.Resistor rIn(R = RIn) "Pad resistance of RX: the input capacitance, the pull-up and the sensor are behind it, see RIn" annotation(
    Placement(visible = false, transformation(extent = {{170, -90}, {210, -50}})));
  Modelica.Electrical.Analog.Sensors.VoltageSensor sns "Measures the voltage actually present on RX" annotation(
    Placement(visible = false, transformation(extent = {{-70, -90}, {-30, -50}})));
  Modelica.Electrical.Analog.Basic.Resistor rPull(R = RPullUp) "Pull-up of RX to the supply rail" annotation(
    Placement(visible = false, transformation(extent = {{50, -90}, {90, -50}})));
  Modelica.Electrical.Analog.Basic.Capacitor cIn(C = CIn, v(start = 0, fixed = true)) "Input capacitance of RX - gives the node a real dynamic state, see CIn" annotation(
    Placement(visible = false, transformation(extent = {{110, -90}, {150, -50}})));
equation
  connect(src.n, gnd);
  connect(src.p, rOut.p);
  connect(rOut.n, TX);
  connect(rIn.p, RX);
  connect(sns.p, rIn.n);
  connect(sns.n, gnd);
  connect(rail, rPull.p);
  connect(rPull.n, rIn.n);
  connect(cIn.p, rIn.n);
  connect(cIn.n, gnd);

  rxVoltage = sns.v;
  rxBoolIn = rxVoltage > (VIL + VIH)/2 "logic threshold halfway, same approximation as the microcontroller";
  src.v = if txLevel then vRail else VOL "the line is actively held HIGH when idle between frames, like a real push-pull output; the high level is the supply voltage (VOH, or VCC with useSupplyPin)";
  annotation(
    Documentation(info = "<html>
<p>Electrical side shared by the external serial devices (<code>Internal.PartialUartDevice</code>) and the radio modems (<code>Internal.PartialRadioModem</code>): <code>TX</code> is a push-pull output (voltage source at the supply voltage or <code>VOL</code>, behind <code>ROut</code>; supply: <code>Internal.PartialSupplyPin</code>, ideal <code>VOH</code> or the <code>VCC</code> pin), <code>RX</code> a high-impedance input with a weak pull-up and an input capacitance, read against the halfway threshold. The derived class assigns <code>txLevel</code> in its <code>when</code> and reacts to <code>change(rxBoolIn)</code>.</p>
</html>"));
end PartialUartPins;
