within MicroPythonMCU.Peripherals.Weighing;

model WheatstoneBridge "Pont de Wheatstone complet : quatre jauges de déformation collées sur le corps d'épreuve"
  import Modelica.Units.SI;
  parameter SI.Resistance R0 = 1000 "Résistance d'une jauge au repos";
  parameter Real K = 2 "Facteur de jauge : variation relative de résistance par unité de déformation (dR/R = K·eps)";
  Modelica.Electrical.Analog.Interfaces.PositivePin E_plus "Alimentation du pont (excitation +)" annotation(
    Placement(transformation(origin = {-110, 45}, extent = {{-7, -7}, {7, 7}}), iconTransformation(origin = {-110, 45}, extent = {{-7, -7}, {7, 7}})));
  Modelica.Electrical.Analog.Interfaces.PositivePin S_plus "Sortie du pont (signal +), vers A+ du HX711" annotation(
    Placement(transformation(origin = {-110, 15}, extent = {{-7, -7}, {7, 7}}), iconTransformation(origin = {-110, 15}, extent = {{-7, -7}, {7, 7}})));
  Modelica.Electrical.Analog.Interfaces.NegativePin S_minus "Sortie du pont (signal -), vers A- du HX711" annotation(
    Placement(transformation(origin = {-110, -15}, extent = {{-7, -7}, {7, 7}}), iconTransformation(origin = {-110, -15}, extent = {{-7, -7}, {7, 7}})));
  Modelica.Electrical.Analog.Interfaces.NegativePin E_minus "Alimentation du pont (excitation -)" annotation(
    Placement(transformation(origin = {-110, -45}, extent = {{-7, -7}, {7, 7}}), iconTransformation(origin = {-110, -45}, extent = {{-7, -7}, {7, 7}})));
  Modelica.Blocks.Interfaces.RealInput eps(unit = "1") "Déformation du corps d'épreuve au droit des jauges" annotation(
    Placement(transformation(origin = {120, 0}, extent = {{20, -20}, {-20, 20}}), iconTransformation(origin = {120, 0}, extent = {{20, -20}, {-20, 20}})));
  // Jauges en diagonale : j1 et j4 sont étirées (R augmente), j2 et j3
  // comprimées (R diminue). Chaque demi-pont s'écarte donc de E/2 en sens
  // opposé, et S+ - S- = E·K·eps : quatre fois la sensibilité d'une jauge seule.
  Modelica.Electrical.Analog.Basic.VariableResistor j1 "Jauge étirée, entre E+ et S-" annotation(
    Placement(transformation(origin = {-30, 30}, extent = {{-10, -10}, {10, 10}}, rotation = -45)));
  Modelica.Electrical.Analog.Basic.VariableResistor j2 "Jauge comprimée, entre S- et E-" annotation(
    Placement(transformation(origin = {-30, -30}, extent = {{-10, -10}, {10, 10}}, rotation = -135)));
  Modelica.Electrical.Analog.Basic.VariableResistor j3 "Jauge comprimée, entre E+ et S+" annotation(
    Placement(transformation(origin = {30, 30}, extent = {{-10, -10}, {10, 10}}, rotation = -135)));
  Modelica.Electrical.Analog.Basic.VariableResistor j4 "Jauge étirée, entre S+ et E-" annotation(
    Placement(transformation(origin = {30, -30}, extent = {{-10, -10}, {10, 10}}, rotation = -45)));
  SI.Voltage vOut "Tension de sortie du pont, S+ - S-";
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
<p><strong>Pont de Wheatstone complet</strong> formé de quatre jauges de déformation collées sur le corps d'épreuve (<code>LoadCell</code>). La résistance d'une jauge varie avec la déformation qu'elle subit : <code>R = R0·(1 ± K·eps)</code>, où <code>K</code> est le facteur de jauge (environ 2 pour une jauge métallique).</p>
<p>Deux jauges sont étirées (<code>j1</code>, <code>j4</code>) et deux comprimées (<code>j2</code>, <code>j3</code>), montées en diagonale : les deux demi-ponts s'écartent de <code>E/2</code> en sens opposé, et la tension de sortie vaut <code>vOut = S+ − S− = E·K·eps</code>. Elle est quatre fois plus grande qu'avec une seule jauge, et <strong>proportionnelle à la tension d'excitation <code>E</code></strong> : c'est pourquoi le HX711 compare la sortie du pont à cette même excitation (mesure <em>ratiométrique</em>), ce qui rend la mesure insensible aux variations de l'alimentation.</p>
<p>Ordre de grandeur : 1 mV/V à pleine charge (<code>K·eps</code> = 2 × 500 µm/m), soit 4,3 mV pour une excitation de 4,3 V. Ce signal très faible explique le gain de 128 du HX711.</p>
<p>Le schéma interne (onglet Diagramme) montre les quatre jauges, pour relier le composant à un pont dessiné en cours.</p>
</html>"));
end WheatstoneBridge;
