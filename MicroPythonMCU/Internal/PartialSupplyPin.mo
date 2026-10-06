within MicroPythonMCU.Internal;
partial model PartialSupplyPin "Supply of a peripheral: optional GND and VCC pins, internal supply rail - GND shown and ideal internal supply VOH by default"
  parameter Boolean useSupplyPin = false "Show the VCC supply pin: the peripheral is supplied by the circuit (its high levels follow VCC, its consumption IQ is drawn from VCC) - unchecked: ideal internal supply VOH, nothing to wire" annotation(
    Dialog(tab = "Electrical", group = "Supply"),
    choices(checkBox = true));
  parameter Modelica.Units.SI.Voltage VOH = Interfaces.VOH "Logic high voltage: ideal internal supply, high level of the outputs and of the pull-ups - with the VCC pin, the voltage of VCC is used instead" annotation(
    Dialog(tab = "Electrical", group = "Supply", enable = not useSupplyPin));
  parameter Modelica.Units.SI.Current IQ = 1e-3 "Current drawn from VCC by the peripheral (quiescent consumption, outputs excluded)" annotation(
    Dialog(tab = "Electrical", group = "Supply", enable = useSupplyPin));
  parameter Boolean useGroundPin = true "Show the GND pin - unchecked: the peripheral is referenced to the simulation ground (0 V), nothing to wire" annotation(
    Dialog(tab = "Electrical", group = "Supply"),
    choices(checkBox = true));
  Modelica.Electrical.Analog.Interfaces.NegativePin GND if useGroundPin "Common reference (ground), to be connected to the microcontroller's one - shown when useGroundPin is checked" annotation(
    Placement(transformation(origin = {0, -72}, extent = {{-6, -6}, {6, 6}}), iconTransformation(origin = {0, -60}, extent = {{-5, -5}, {5, 5}})));
  Modelica.Electrical.Analog.Interfaces.PositivePin VCC if useSupplyPin "Supply of the peripheral (e.g. 3V3(OUT) of a Raspberry Pi Pico) - shown when useSupplyPin is checked" annotation(
    Placement(transformation(origin = {-60, -72}, extent = {{-6, -6}, {6, 6}}), iconTransformation(origin = {-60, -60}, extent = {{-5, -5}, {5, 5}})));
protected
  constant Modelica.Units.SI.Voltage VIqFull = 1 "Supply voltage above which the full quiescent current IQ is drawn (below, it decreases linearly to 0: a peripheral without supply draws nothing)";
  constant Modelica.Units.SI.Conductance GLeak = 1e-9 "Leakage of the rail to GND";
  Modelica.Units.SI.Voltage vRail "Voltage of the supply rail relative to GND: VOH, or the voltage of VCC";
  Modelica.Electrical.Analog.Interfaces.NegativePin gnd "Internal reference of the peripheral: GND, or the simulation ground when the GND pin is hidden - the inner wiring connects here, never to GND (conditional)" annotation(
    Placement(visible = false, transformation(extent = {{-70, 10}, {-50, 30}})));
  Modelica.Electrical.Analog.Basic.Ground implicitGround if not useGroundPin "Simulation ground, when there is no GND pin" annotation(
    Placement(visible = false, transformation(extent = {{-110, 10}, {-90, 30}})));
  Modelica.Electrical.Analog.Interfaces.PositivePin rail "Internal supply rail of the peripheral: fed by VCC or by the ideal internal supply" annotation(
    Placement(visible = false, transformation(extent = {{-70, 50}, {-50, 70}})));
  Modelica.Electrical.Analog.Sources.ConstantVoltage internalSupply(V = VOH) if not useSupplyPin "Ideal internal supply, when there is no VCC pin" annotation(
    Placement(visible = false, transformation(extent = {{-110, 50}, {-90, 70}})));
  Modelica.Electrical.Analog.Sources.SignalCurrent quiescent "Quiescent consumption IQ, drawn from the rail (invisible on the ideal internal supply)" annotation(
    Placement(visible = false, transformation(extent = {{-30, 50}, {-10, 70}})));
  Modelica.Electrical.Analog.Sensors.VoltageSensor railSensor "Voltage of the rail" annotation(
    Placement(visible = false, transformation(extent = {{10, 50}, {30, 70}})));
equation
  connect(GND, gnd);
  connect(implicitGround.p, gnd);
  connect(VCC, rail);
  connect(internalSupply.p, rail);
  connect(internalSupply.n, gnd);
  connect(quiescent.p, rail);
  connect(quiescent.n, gnd);
  connect(railSensor.p, rail);
  connect(railSensor.n, gnd);
  vRail = railSensor.v;
  quiescent.i = IQ*min(1, max(vRail, 0)/VIqFull) + GLeak*vRail "GLeak: a VCC pin left unconnected still settles at 0 V";
  annotation(
    Icon(coordinateSystem(preserveAspectRatio = true, extent = {{-100, -100}, {100, 100}}, initialScale = 0.2), graphics = {Text(visible = useSupplyPin, extent = {{-53, -56}, {-13, -64}}, textString = "VCC", horizontalAlignment = TextAlignment.Left)}),
    Documentation(info = "<html>
<p>Supply of a peripheral (serial devices, radio modems, I2C peripherals, HX711), shared by their base classes. The <code>GND</code> pin is shown by default; with <code>useGroundPin</code> unchecked it disappears and the peripheral is referenced to the simulation ground (0 V, an internal <code>Ground</code>), common to every <code>Ground</code> block and to every component whose <code>GND</code> is hidden. The inner wiring of the subclasses connects to the protected node <code>gnd</code>, never to the conditional <code>GND</code>. By default (<code>useSupplyPin</code> unchecked) the peripheral carries an <b>ideal internal supply</b> <code>VOH</code>: nothing to wire, as in all the examples. Checked, a <code>VCC</code> pin appears (bottom left of the icon): the internal rail becomes the voltage of <code>VCC</code> — the high levels of the outputs and the pull-ups follow it — and the peripheral draws its quiescent current <code>IQ</code> from it, so that the supply of the circuit (for instance <code>3V3(OUT)</code> of <code>RPi_Pico</code>, or a battery) sees its load.</p>
<p>Not modelled: the behaviour of the peripheral itself without supply (its engine keeps running; only its electrical levels fall to 0 V), the current of the push-pull outputs (drawn from an ideal source referenced to GND, a few µA in practice). See <code>requirements.md</code>, decision \"Carte Raspberry Pi Pico et alimentation\".</p>
</html>"));
end PartialSupplyPin;
