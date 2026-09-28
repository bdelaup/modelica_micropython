within MicroPythonMCU.Peripherals.Weighing;

model LoadCell "Load cell body (quasi-static model): the applied force deforms it, its strain is passed on to the gauges of the bridge"
  import Modelica.Units.SI;
  parameter SI.Mass capacity = 5 "Capacity: mass producing the nominal strain";
  parameter SI.Force FNom = capacity*Modelica.Constants.g_n "Nominal force (weight of the capacity)";
  parameter Real epsNom(unit = "1") = 500e-6 "Strain seen by the gauges under the nominal force (500 µm/m, i.e. 1 mV/V at the bridge output with a gauge factor of 2)";
  parameter SI.Length sNom = 0.2e-3 "Deflection of the load cell body under the nominal force";
  Modelica.Mechanics.Translational.Interfaces.Flange_a flange "Point where the load is applied (pan): a positive force deforms the load cell body" annotation(
    Placement(transformation(origin = {100, 0}, extent = {{-10, -10}, {10, 10}}), iconTransformation(origin = {100, 0}, extent = {{-10, -10}, {10, 10}})));
  Modelica.Blocks.Interfaces.RealOutput eps(unit = "1") "Strain under the gauges, to the Wheatstone bridge" annotation(
    Placement(transformation(origin = {-110, 0}, extent = {{10, -10}, {-10, 10}}), iconTransformation(origin = {-110, 0}, extent = {{10, -10}, {-10, 10}})));
  SI.Force F "Applied force";
  SI.Length s "Deflection";
  // Public: animates the icon (protected variables are missing from the results).
  Boolean overload = F > 1.5*FNom "Overload: beyond 150 % of the capacity, a real load cell body would be permanently deformed";
equation
  F = flange.f;
  s = flange.s "fixed support at s = 0";
  F = FNom/sNom*s "massless elasticity: no dynamics, the deflection follows the force instantly";
  eps = epsNom*F/FNom "strain proportional to the force (Hooke's law)";
  annotation(
    Icon(coordinateSystem(preserveAspectRatio = true, extent = {{-100, -100}, {100, 100}}), graphics = {Rectangle(fillColor = {160, 160, 160}, pattern = LinePattern.None, fillPattern = FillPattern.Backward, extent = {{-90, -20}, {-70, -60}}), Line(points = {{-90, -20}, {-70, -20}}), Rectangle(lineColor = {60, 60, 60}, fillColor = DynamicSelect({200, 200, 210}, if overload then {230, 80, 60} else {200, 200, 210}), fillPattern = FillPattern.Solid, extent = {{-80, 20}, {70, -20}}), Ellipse(lineColor = {60, 60, 60}, fillColor = {255, 255, 255}, fillPattern = FillPattern.Solid, extent = {{-40, 12}, {-16, -12}}), Ellipse(lineColor = {60, 60, 60}, fillColor = {255, 255, 255}, fillPattern = FillPattern.Solid, extent = {{16, 12}, {40, -12}}), Rectangle(lineColor = {200, 110, 20}, fillColor = {240, 160, 60}, fillPattern = FillPattern.Solid, extent = {{-12, 26}, {12, 20}}), Rectangle(lineColor = {200, 110, 20}, fillColor = {240, 160, 60}, fillPattern = FillPattern.Solid, extent = {{-12, -20}, {12, -26}}), Line(points = {{70, 0}, {90, 0}}, color = {0, 127, 0}), Text(textColor = {0, 0, 255}, extent = {{-150, 80}, {150, 40}}, textString = "%name"), Text(extent = {{-150, -64}, {150, -94}}, textString = "%capacity kg")}),
    Diagram(coordinateSystem(preserveAspectRatio = true, extent = {{-100, -100}, {100, 100}})),
    Documentation(info = "<html>
<p><strong>Load cell body</strong> of a force sensor (<em>load cell</em>): the metal part that deforms under the load, and to which the strain gauges of the bridge (<code>WheatstoneBridge</code>) are bonded. <strong>Quasi-static</strong> model: no mass nor damping, the strain follows the force instantly. This is legitimate as long as the load changes slowly compared with the natural frequency of the sensor (several tens of hertz for a kitchen scale).</p>
<p>The force comes in through the mechanical flange <code>flange</code>, typically from a standard source <code>Modelica.Mechanics.Translational.Sources.Force</code> (the weight: mass × <code>g_n</code>). The load cell body behaves like a spring of stiffness <code>FNom/sNom</code> resting on a fixed point, and outputs the strain <code>eps = epsNom · F/FNom</code> to the bridge.</p>
<p>Order of magnitude of the default parameters: 5 kg sensor, 500 µm/m at full load, i.e. a sensitivity of 1 mV/V once the full bridge is wired (gauge factor 2), which is typical of kitchen scale sensors. Beyond 150 % of the capacity, the icon turns red (<code>overload</code>): a real load cell body would be permanently deformed.</p>
</html>"));
end LoadCell;
