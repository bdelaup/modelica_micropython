within MicroPythonMCU.Internal;
model PinBridge "Electrical stage of one microcontroller pin: push-pull output fed by the supply rail, switchable internal pull-up/pull-down, leakage, voltage sensing"
  parameter Modelica.Units.SI.Voltage VOL = 0 "Low output level, above GND";
  parameter Modelica.Units.SI.Resistance ROut = 100 "Output series resistance (drive strength), on both the high and the low side";
  parameter Modelica.Units.SI.Resistance RPullUp = 50e3 "Internal pull-up, to the supply rail";
  parameter Modelica.Units.SI.Resistance RPullDown = 50e3 "Internal pull-down, to GND";
  parameter Modelica.Units.SI.Conductance GOff = 1e-9 "Leakage of a pin that does not drive its line, towards GND";
  input Boolean drive "Output stage enabled (pin in output mode, board supplied)";
  input Boolean level "Level driven when the output stage is enabled";
  input Integer pull "Internal pull resistor: 0 = none, 1 = up (to vdd), 2 = down (to gnd)";
  output Modelica.Units.SI.Voltage v "Voltage of the pin, relative to gnd";
  Modelica.Electrical.Analog.Interfaces.PositivePin pin "The pin" annotation(
    Placement(transformation(extent = {{90, -10}, {110, 10}})));
  Modelica.Electrical.Analog.Interfaces.PositivePin vdd "Supply rail (IOVDD): source of the high level and of the pull-up" annotation(
    Placement(transformation(extent = {{-10, 90}, {10, 110}})));
  Modelica.Electrical.Analog.Interfaces.NegativePin gnd "Ground" annotation(
    Placement(transformation(extent = {{-10, -110}, {10, -90}})));
protected
  constant Modelica.Units.SI.Conductance GPullOff = 1e-12 "Conductance of a switched-off branch: never exactly 0, and far below GOff so that a floating input still settles towards GND";
  Modelica.Units.SI.Conductance gUp "High side + pull-up, between vdd and the pin";
  Modelica.Units.SI.Conductance gLow "Low side (or leakage), between the pin and VOL";
  Modelica.Units.SI.Conductance gDown "Pull-down, between the pin and gnd";
  Modelica.Units.SI.Current iUp "Current from vdd into the pin node";
  Modelica.Units.SI.Current iLow "Current from the pin node to VOL";
  Modelica.Units.SI.Current iDown "Current from the pin node to gnd";
equation
  gUp = (if drive and level then 1/ROut else GPullOff) + (if pull == 1 then 1/RPullUp else 0);
  gLow = if drive and not level then 1/ROut else GOff;
  gDown = if pull == 2 then 1/RPullDown else GPullOff;
  v = pin.v - gnd.v;
  iUp = gUp*(vdd.v - pin.v);
  iLow = gLow*(v - VOL);
  iDown = gDown*v;
  pin.i = iLow + iDown - iUp;
  vdd.i = iUp;
  gnd.i = -(iLow + iDown);
  annotation(
    Icon(coordinateSystem(preserveAspectRatio = true, extent = {{-100, -100}, {100, 100}}), graphics = {Rectangle(lineColor = {0, 0, 255}, fillColor = {255, 255, 255}, fillPattern = FillPattern.Solid, extent = {{-80, 80}, {80, -80}}), Text(extent = {{-70, 30}, {70, -30}}, textString = "PIN"), Text(textColor = {0, 0, 255}, extent = {{-150, 130}, {150, 90}}, textString = "%name")}),
    Documentation(info = "<html>
<p>Electrical stage of one pin of a microcontroller (<code>Internal.McuCore</code>), written as equations rather than standard blocks (fewer variables, one instance per pin):</p>
<ul>
<li><b>Output</b> (<code>drive</code>): conductance <code>1/ROut</code> from the supply rail <code>vdd</code> to the pin (high level) or from the pin to <code>VOL</code> (low level). The high level is the voltage of the rail, and the current delivered by the pin is drawn from it: the supply of the board sees the load of its pins.</li>
<li><b>Pulls</b> (<code>pull</code>): <code>RPullUp</code> to <code>vdd</code>, <code>RPullDown</code> to <code>gnd</code>; they act whatever the direction, like on the RP2040.</li>
<li><b>Input</b>: leakage <code>GOff</code> to <code>VOL</code> (≈ GND), so that a floating input reads low.</li>
</ul>
<p>Promoted from the prototype <code>Sandbox.PinBridgeFull</code>, see <code>requirements.md</code>, decision \"Carte Raspberry Pi Pico et alimentation\".</p>
</html>"));
end PinBridge;
