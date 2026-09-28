within MicroPythonMCU.Peripherals;
model LED "LED whose icon lights up according to the current flowing through it (inspired by Arduino.Components.LED, Modelica-Arduino library)"
  extends Modelica.Electrical.Analog.Interfaces.TwoPin;

  parameter Modelica.Units.SI.Voltage Vknee = 1.8 "Threshold (knee) voltage of the diode, approximation of a red LED";
  parameter Modelica.Units.SI.Current IMax = 0.0035 "Current giving the maximum brightness of the icon (display scale, not an enforced physical limit) - set to the current typically reached in this project (~3.5 mA with a 330 Ω series resistance, VOH=3.3V, ROut=100 Ω), so that the icon really reaches colorOn in steady state rather than stopping halfway";
  parameter Integer colorOn[3] = {255, 0, 0} "Colour of the icon at full brightness (RGB)";
  parameter Integer colorOff[3] = {90, 25, 25} "Colour of the icon when off (RGB)";

  Modelica.Electrical.Analog.Semiconductors.Diode diode(Ids = 0.005*exp(-Vknee/0.1), Vt = 0.1, R = 1e9) "Diode with a smooth characteristic (not Ideal.IdealDiode: its switching through a discrete event breaks the sync mechanism on very long simulations with a periodic tick, see requirements.md). Ids calibrated for ~5 mA at Vknee; Vt=0.1 (softer than a real physical Vt) for numerical stability, knee voltage close to Vknee to first order." annotation(
    Placement(transformation(extent = {{-40, -10}, {-20, 10}})));
  Modelica.Electrical.Analog.Sensors.CurrentSensor currentSensor annotation(Placement(transformation(extent = {{20, -10}, {40, 10}})));
  Modelica.Blocks.Continuous.FirstOrder mean(T = 0.02, initType = Modelica.Blocks.Types.Init.InitialOutput, y_start = 0) "Smooths the measured current, for a steady icon animation (no electrical role). A continuous first-order filter rather than Blocks.Math.Mean: Mean relies on a sample() that generates an event at each window (50 per simulated second with f=50), a cost that dominates long simulations - see requirements.md. T = 20 ms: short enough compared with the fastest blinking of the project (chaser at 150 ms/pin) not to blur the transitions. Name \"mean\" kept: the icons (DynamicSelect) read mean.y" annotation(
    Placement(transformation(extent = {{40, 40}, {60, 60}})));
equation
  connect(diode.p, p) annotation(Line(points = {{-40, 0}, {-100, 0}}, color = {0, 0, 255}));
  connect(diode.n, currentSensor.p) annotation(Line(points = {{-20, 0}, {20, 0}}, color = {0, 0, 255}));
  connect(currentSensor.i, mean.u) annotation(Line(points = {{30, 11}, {30, 50}, {38, 50}}, color = {0, 0, 127}));
  connect(currentSensor.n, n) annotation(Line(points = {{40, 0}, {100, 0}}, color = {0, 0, 255}));

  annotation(
    Icon(coordinateSystem(preserveAspectRatio = true, extent = {{-100, -100}, {100, 100}}), graphics = {
      Ellipse(extent = {{-60, 60}, {60, -60}}, pattern = LinePattern.None, fillPattern = FillPattern.Solid,
        fillColor = DynamicSelect(colorOn, {integer(colorOff[1] + min(1, max(0, mean.y)/IMax)*(colorOn[1] - colorOff[1])), integer(colorOff[2] + min(1, max(0, mean.y)/IMax)*(colorOn[2] - colorOff[2])), integer(colorOff[3] + min(1, max(0, mean.y)/IMax)*(colorOn[3] - colorOff[3]))})),
      Polygon(points = {{30, 0}, {-30, 40}, {-30, -40}, {30, 0}}, lineColor = {0, 0, 0}),
      Line(points = {{-90, 0}, {-30, 0}}, color = {0, 0, 255}),
      Line(points = {{30, 0}, {90, 0}}, color = {0, 0, 255}),
      Line(points = {{30, 40}, {30, -40}}, color = {0, 0, 255}),
      Line(points = {{38, 52}, {58, 72}}, color = {28, 108, 200}),
      Polygon(points = {{52, 73}, {59, 73}, {59, 66}, {52, 73}}, lineColor = {0, 0, 255}, fillPattern = FillPattern.Solid, fillColor = {0, 0, 255}),
      Polygon(points = {{68, 59}, {75, 59}, {75, 52}, {68, 59}}, lineColor = {0, 0, 255}, fillPattern = FillPattern.Solid, fillColor = {0, 0, 255}),
      Line(points = {{54, 38}, {74, 58}}, color = {28, 108, 200}),
      Text(extent = {{-150, -80}, {150, -110}}, textString = "%name", textColor = {0, 0, 255})}),
    Documentation(info = "<html>
<p>Two-pin LED (<code>p</code>/<code>n</code>), modelled as a <code>Modelica.Electrical.Analog.Semiconductors.Diode</code> (smooth exponential characteristic, not <code>Ideal.IdealDiode</code> — its switching through a discrete event turned out to block the sync mechanism on very long simulations with a periodic tick, see <code>requirements.md</code>), calibrated for a voltage drop close to <code>Vknee</code> once conducting — like a real LED, it needs an external series resistor to limit the current. The current flowing through the LED is measured then smoothed (first-order filter <code>Modelica.Blocks.Continuous.FirstOrder</code>, 20 ms time constant, no discrete event) to drive the brightness of the icon through <code>DynamicSelect</code>: outside the replay of a simulation result (for instance while building a schematic), the icon shows <code>colorOn</code> (bright red by default) to stay clearly visible; during the animated replay of a result, it interpolates between <code>colorOff</code> (zero current) and <code>colorOn</code> (current ≥ <code>IMax</code>). Inspired by <code>Arduino.Components.LED</code> in the <a href=\"https://github.com/CATIA-Systems/Modelica-Arduino\">Modelica-Arduino</a> library (CATIA-Systems).</p>
</html>"));
end LED;
