within MicroPythonMCU.Peripherals.Weighing;

model WheatstoneBridge "Full Wheatstone bridge: four strain gauges bonded to the load cell body"
  import Modelica.Units.SI;
  parameter SI.Resistance R0 = 1000 "Resistance of a gauge at rest";
  parameter Real K = 2 "Gauge factor: relative resistance change per unit of strain (dR/R = K·eps)";
  Modelica.Electrical.Analog.Interfaces.PositivePin E_plus "Bridge supply (excitation +)" annotation(
    Placement(transformation(origin = {-110, 45}, extent = {{-7, -7}, {7, 7}}), iconTransformation(origin = {-110, 45}, extent = {{-7, -7}, {7, 7}})));
  Modelica.Electrical.Analog.Interfaces.PositivePin S_plus "Bridge output (signal +), to A+ of the HX711" annotation(
    Placement(transformation(origin = {-110, 15}, extent = {{-7, -7}, {7, 7}}), iconTransformation(origin = {-110, 15}, extent = {{-7, -7}, {7, 7}})));
  Modelica.Electrical.Analog.Interfaces.NegativePin S_minus "Bridge output (signal -), to A- of the HX711" annotation(
    Placement(transformation(origin = {-110, -15}, extent = {{-7, -7}, {7, 7}}), iconTransformation(origin = {-110, -15}, extent = {{-7, -7}, {7, 7}})));
  Modelica.Electrical.Analog.Interfaces.NegativePin E_minus "Bridge supply (excitation -)" annotation(
    Placement(transformation(origin = {-110, -45}, extent = {{-7, -7}, {7, 7}}), iconTransformation(origin = {-110, -45}, extent = {{-7, -7}, {7, 7}})));
  Modelica.Blocks.Interfaces.RealInput eps(unit = "1") "Strain of the load cell body under the gauges" annotation(
    Placement(transformation(origin = {120, 0}, extent = {{20, -20}, {-20, 20}}), iconTransformation(origin = {120, 0}, extent = {{20, -20}, {-20, 20}})));
  // Gauges on the diagonals: j1 and j4 are stretched (R increases), j2 and j3
  // compressed (R decreases). Each half-bridge therefore moves away from E/2 in the
  // opposite direction, and S+ - S- = E·K·eps: four times the sensitivity of a single gauge.
  Modelica.Electrical.Analog.Basic.VariableResistor j1 "Stretched gauge, between E+ and S-" annotation(
    Placement(transformation(origin = {-30, 30}, extent = {{-10, -10}, {10, 10}}, rotation = -45)));
  Modelica.Electrical.Analog.Basic.VariableResistor j2 "Compressed gauge, between S- and E-" annotation(
    Placement(transformation(origin = {-30, -30}, extent = {{-10, -10}, {10, 10}}, rotation = -135)));
  Modelica.Electrical.Analog.Basic.VariableResistor j3 "Compressed gauge, between E+ and S+" annotation(
    Placement(transformation(origin = {30, 30}, extent = {{-10, -10}, {10, 10}}, rotation = -135)));
  Modelica.Electrical.Analog.Basic.VariableResistor j4 "Stretched gauge, between S+ and E-" annotation(
    Placement(transformation(origin = {30, -30}, extent = {{-10, -10}, {10, 10}}, rotation = -45)));
  SI.Voltage vOut "Output voltage of the bridge, S+ - S-";
equation
  j1.R = R0*(1 + K*eps);
  j2.R = R0*(1 - K*eps);
  j3.R = R0*(1 - K*eps);
  j4.R = R0*(1 + K*eps);
  vOut = S_plus.v - S_minus.v;
  connect(E_plus, j1.p) annotation(
    Line(points = {{-110, 45}, {-60, 45}, {-60, 60}, {0, 60}, {0, 50}, {-37, 37}}, color = {0, 0, 255}));
  connect(j1.n, S_minus) annotation(
    Line(points = {{-23, 23}, {-50, 0}, {-50, -15}, {-110, -15}}, color = {0, 0, 255}));
  connect(S_minus, j2.p) annotation(
    Line(points = {{-110, -15}, {-50, -15}, {-50, 0}, {-23, -23}}, color = {0, 0, 255}));
  connect(j2.n, E_minus) annotation(
    Line(points = {{-37, -37}, {0, -50}, {0, -60}, {-60, -60}, {-60, -45}, {-110, -45}}, color = {0, 0, 255}));
  connect(E_plus, j3.p) annotation(
    Line(points = {{-110, 45}, {-60, 45}, {-60, 60}, {0, 60}, {0, 50}, {37, 37}}, color = {0, 0, 255}));
  connect(j3.n, S_plus) annotation(
    Line(points = {{23, 23}, {50, 0}, {70, 0}, {70, 80}, {-80, 80}, {-80, 15}, {-110, 15}}, color = {0, 0, 255}));
  connect(S_plus, j4.p) annotation(
    Line(points = {{-110, 15}, {-80, 15}, {-80, 80}, {70, 80}, {70, 0}, {50, 0}, {23, -23}}, color = {0, 0, 255}));
  connect(j4.n, E_minus) annotation(
    Line(points = {{37, -37}, {0, -50}, {0, -60}, {-60, -60}, {-60, -45}, {-110, -45}}, color = {0, 0, 255}));
  annotation(
    Icon(coordinateSystem(preserveAspectRatio = true, extent = {{-100, -100}, {100, 100}}), graphics = {Rectangle(lineColor = {0, 0, 255}, fillColor = {245, 245, 250}, fillPattern = FillPattern.Solid, extent = {{-100, 70}, {100, -70}}), Line(points = {{0, 60}, {-60, 0}, {0, -60}, {60, 0}, {0, 60}}, color = {0, 0, 255}), Rectangle(origin = {-30, 30}, rotation = 45, lineColor = {200, 110, 20}, fillColor = {240, 160, 60}, fillPattern = FillPattern.Solid, extent = {{-14, 6}, {14, -6}}), Rectangle(origin = {30, 30}, rotation = -45, lineColor = {200, 110, 20}, fillColor = {240, 160, 60}, fillPattern = FillPattern.Solid, extent = {{-14, 6}, {14, -6}}), Rectangle(origin = {-30, -30}, rotation = -45, lineColor = {200, 110, 20}, fillColor = {240, 160, 60}, fillPattern = FillPattern.Solid, extent = {{-14, 6}, {14, -6}}), Rectangle(origin = {30, -30}, rotation = 45, lineColor = {200, 110, 20}, fillColor = {240, 160, 60}, fillPattern = FillPattern.Solid, extent = {{-14, 6}, {14, -6}}), Line(points = {{-100, 45}, {-80, 45}, {-80, 64}, {0, 64}, {0, 60}}, color = {0, 0, 255}), Line(points = {{-100, -45}, {-80, -45}, {-80, -64}, {0, -64}, {0, -60}}, color = {0, 0, 255}), Line(points = {{-100, -15}, {-60, -15}, {-60, 0}}, color = {0, 0, 255}), Line(points = {{-100, 15}, {-88, 15}, {-88, 76}, {76, 76}, {76, 0}, {60, 0}}, color = {0, 0, 255}), Text(extent = {{-98, 58}, {-84, 50}}, textString = "E+"), Text(extent = {{-98, 30}, {-84, 22}}, textString = "S+"), Text(extent = {{-98, -22}, {-84, -30}}, textString = "S-"), Text(extent = {{-98, -50}, {-84, -58}}, textString = "E-"), Text(extent = {{84, 26}, {100, 16}}, textString = "ε"), Text(textColor = {0, 0, 255}, extent = {{-150, 110}, {150, 80}}, textString = "%name")}),
    Diagram(coordinateSystem(preserveAspectRatio = true, extent = {{-100, -100}, {100, 100}})),
    Documentation(info = "<html>
<p><strong>Full Wheatstone bridge</strong> made of four strain gauges bonded to the load cell body (<code>LoadCell</code>). The resistance of a gauge changes with the strain it undergoes: <code>R = R0·(1 ± K·eps)</code>, where <code>K</code> is the gauge factor (about 2 for a metal gauge).</p>
<p>Two gauges are stretched (<code>j1</code>, <code>j4</code>) and two compressed (<code>j2</code>, <code>j3</code>), mounted on the diagonals: the two half-bridges move away from <code>E/2</code> in opposite directions, and the output voltage is <code>vOut = S+ − S− = E·K·eps</code>. It is four times larger than with a single gauge, and <strong>proportional to the excitation voltage <code>E</code></strong>: this is why the HX711 compares the bridge output with this same excitation (<em>ratiometric</em> measurement), which makes the measurement insensitive to supply variations.</p>
<p>Order of magnitude: 1 mV/V at full load (<code>K·eps</code> = 2 × 500 µm/m), i.e. 4.3 mV for a 4.3 V excitation. This very weak signal explains the gain of 128 of the HX711.</p>
<p>The internal schematic (Diagram view) shows the four gauges, to relate the component to a bridge drawn in class.</p>
</html>"));
end WheatstoneBridge;
