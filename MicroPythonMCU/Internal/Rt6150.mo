within MicroPythonMCU.Internal;
model Rt6150 "Averaged model of the buck-boost regulator of the Raspberry Pi Pico (RT6150B): 3.3 V output from VSYS, undervoltage lockout, enable input, efficiency"
  parameter Modelica.Units.SI.Voltage VOut = 3.3 "Regulated output voltage";
  parameter Modelica.Units.SI.Resistance ROut = 0.05 "Output resistance while regulating (load regulation)";
  parameter Modelica.Units.SI.Voltage VInOn = 1.8 "Input voltage above which the regulator starts (undervoltage lockout)";
  parameter Modelica.Units.SI.Voltage VInOff = 1.7 "Input voltage below which a running regulator stops (hysteresis)";
  parameter Modelica.Units.SI.Voltage VEn = 1.0 "Threshold of the enable input (3V3_EN)";
  parameter Real eta(min = 0.1, max = 1) = 0.9 "Efficiency: input power = output power / eta";
  parameter Modelica.Units.SI.Current IQ = 50e-6 "Quiescent input current while running";
  parameter Modelica.Units.SI.Conductance GOff = 1e-9 "Leakage of the output and of the input while stopped";
  Modelica.Electrical.Analog.Interfaces.PositivePin vin "Input (VSYS)" annotation(
    Placement(transformation(extent = {{-110, -10}, {-90, 10}})));
  Modelica.Electrical.Analog.Interfaces.PositivePin vout "Regulated output (3V3)" annotation(
    Placement(transformation(extent = {{90, -10}, {110, 10}})));
  Modelica.Electrical.Analog.Interfaces.PositivePin en "Enable (3V3_EN): the regulator runs while this input is above VEn" annotation(
    Placement(transformation(extent = {{-70, -110}, {-50, -90}})));
  Modelica.Electrical.Analog.Interfaces.NegativePin gnd "Ground" annotation(
    Placement(transformation(extent = {{-10, -110}, {10, -90}})));
  Boolean running(start = false, fixed = true) "The regulator is enabled and its input is above the undervoltage lockout";
  Modelica.Units.SI.Voltage vIn "Input voltage";
  Modelica.Units.SI.Voltage vOut "Output voltage";
  Modelica.Units.SI.Current iOut "Current delivered by the output";
  Modelica.Units.SI.Current iIn "Current drawn from the input";
  Modelica.Units.SI.Power pOut "Power delivered by the output";
equation
  vIn = vin.v - gnd.v;
  vOut = vout.v - gnd.v;
  running = en.v - gnd.v > VEn and (if pre(running) then vIn > VInOff else vIn > VInOn);
  // pre(running) in the currents: breaks the algebraic loop input voltage -> running ->
  // input current -> input voltage (battery with an internal resistance); the event
  // iteration settles the state at the same instant.
  iOut = if pre(running) then (VOut - vOut)/ROut else -GOff*vOut;
  pOut = vOut*iOut;
  iIn = if pre(running) then max(pOut, 0)/(eta*max(vIn, VInOff)) + IQ else GOff*vIn;
  vout.i = -iOut;
  vin.i = iIn;
  en.i = 0;
  gnd.i = iOut - iIn;
  annotation(
    Icon(coordinateSystem(preserveAspectRatio = true, extent = {{-100, -100}, {100, 100}}), graphics = {Rectangle(lineColor = {0, 0, 255}, fillColor = {255, 255, 255}, fillPattern = FillPattern.Solid, extent = {{-90, 70}, {90, -90}}), Text(extent = {{-80, 50}, {80, 10}}, textString = "RT6150"), Text(extent = {{-80, -10}, {80, -40}}, textString = "buck-boost"), Text(extent = {{-86, 10}, {-40, -10}}, textString = "VSYS"), Text(extent = {{40, 10}, {86, -10}}, textString = "3V3"), Text(extent = {{-80, -70}, {-40, -86}}, textString = "EN"), Text(textColor = {0, 0, 255}, extent = {{-150, 120}, {150, 80}}, textString = "%name")}),
    Documentation(info = "<html>
<p>Averaged model (no switching) of the RT6150B buck-boost converter that supplies the Raspberry Pi Pico from <code>VSYS</code> (1.8 to 5.5 V): while it runs, the output is held at <code>VOut</code> behind <code>ROut</code>, and the input draws the power delivered divided by the efficiency <code>eta</code>, plus the quiescent current <code>IQ</code> — a battery thus sees the load of the board, raised by the conversion losses, whatever its voltage.</p>
<p>It runs while <code>en</code> (<code>3V3_EN</code>) is above <code>VEn</code> and the input is above the undervoltage lockout (<code>VInOn</code> to start, <code>VInOff</code> to stop). Stopped, the output is in high impedance (leakage <code>GOff</code>): it can be supplied from outside, as on the board with <code>3V3_EN</code> grounded.</p>
<p>Not modelled: switching ripple, current limit, soft start, power-save mode (GPIO23).</p>
</html>"));
end Rt6150;
