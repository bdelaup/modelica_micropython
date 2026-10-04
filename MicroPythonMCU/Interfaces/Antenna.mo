within MicroPythonMCU.Interfaces;
connector Antenna "Antenna of a radio module: one wire between the modules that share the air"
  Real s "Modulated signal on the air (normalised, amplitude 1): mean of the signals of the modules transmitting, 0 when none transmits";
  flow Real iS "Contribution of a module to s (internal)";
  Real bit "Masked baseband level: mean of the bits (0 or 1) of the modules transmitting";
  flow Real iBit "Contribution of a module to bit (internal)";
  Modelica.Units.SI.Frequency f "Nominal carrier frequency: mean over the modules transmitting";
  flow Real iF "Contribution of a module to f (internal)";
  Real modulation "Modulation (Interfaces.Modulation, as an integer): mean over the modules transmitting";
  flow Real iModulation "Contribution of a module to modulation (internal)";
  Real id "Identifier of the transmitter (1, 2, 3... one per module): mean over the modules transmitting";
  flow Real iId "Contribution of a module to id (internal)";
  Real idSq "Square of the identifier: mean over the modules transmitting - equal to id^2 only when exactly one module transmits";
  flow Real iIdSq "Contribution of a module to idSq (internal)";
  annotation(
    Icon(coordinateSystem(preserveAspectRatio = true, extent = {{-100, -100}, {100, 100}}), graphics = {Ellipse(lineColor = {170, 85, 0}, fillColor = {255, 170, 85}, fillPattern = FillPattern.Solid, extent = {{-100, 100}, {100, -100}}), Line(points = {{0, -60}, {0, 50}}, color = {120, 50, 0}, thickness = 1), Line(points = {{-40, 50}, {0, 0}, {40, 50}}, color = {120, 50, 0}, thickness = 1)}),
    Diagram(coordinateSystem(preserveAspectRatio = true, extent = {{-100, -100}, {100, 100}}), graphics = {Ellipse(lineColor = {170, 85, 0}, fillColor = {255, 170, 85}, fillPattern = FillPattern.Solid, extent = {{-40, 40}, {40, -40}})}),
    Documentation(info = "<html>
<p>Antenna of a radio module of <code>Peripherals.Radio</code>. Two modules (or more) that can hear each other are joined by <strong>one</strong> wire, antenna to antenna — the air between them. It is not an electrical connection: the wire carries the masked quantities of the radio link.</p>
<p>Each pair (potential, flow) works as a node where every module <em>transmitting</em> pulls the potential towards its own value with a unit conductance, the others with a negligible one: the potential is therefore the <strong>mean over the transmitting modules</strong>. With one transmitter, it is exactly its value (signal, bit, frequency, modulation, identifier); with none, it is zero; with two at once, the mean of the squared identifiers (<code>idSq</code>) no longer equals the square of their mean (<code>id</code>) — their variance is no longer zero — and the receivers detect the collision. A module whose antenna is connected to nothing simply transmits into the void.</p>
<p>The flow variables are internal to this mechanism: there is nothing to read in them.</p>
</html>"));
end Antenna;
