within MicroPythonMCU.Peripherals.Weighing;

model LoadCell "Corps d'épreuve (modèle quasi-statique) : la force appliquée le déforme, sa déformation est transmise aux jauges du pont"
  import Modelica.Units.SI;
  parameter SI.Mass capacity = 5 "Portée : masse qui produit la déformation nominale";
  parameter SI.Force FNom = capacity*Modelica.Constants.g_n "Force nominale (poids de la portée)";
  parameter Real epsNom(unit = "1") = 500e-6 "Déformation vue par les jauges sous la force nominale (500 µm/m, soit 1 mV/V en sortie de pont avec un facteur de jauge de 2)";
  parameter SI.Length sNom = 0.2e-3 "Flèche du corps d'épreuve sous la force nominale";
  Modelica.Mechanics.Translational.Interfaces.Flange_a flange "Point d'application de la charge (plateau) : une force positive déforme le corps d'épreuve" annotation(
    Placement(transformation(origin = {100, 0}, extent = {{-10, -10}, {10, 10}}), iconTransformation(origin = {100, 0}, extent = {{-10, -10}, {10, 10}})));
  Modelica.Blocks.Interfaces.RealOutput eps(unit = "1") "Déformation au droit des jauges, vers le pont de Wheatstone" annotation(
    Placement(transformation(origin = {-110, 0}, extent = {{10, -10}, {-10, 10}}), iconTransformation(origin = {-110, 0}, extent = {{10, -10}, {-10, 10}})));
  SI.Force F "Force appliquée";
  SI.Length s "Flèche";
  // Public : anime l'icône (les variables protected sont absentes des résultats).
  Boolean overload = F > 1.5*FNom "Surcharge : au-delà de 150 % de la portée, un vrai corps d'épreuve se déformerait durablement";
equation
  F = flange.f;
  s = flange.s "appui fixe à s = 0";
  F = FNom/sNom*s "élasticité sans masse : pas de dynamique, la flèche suit la force instantanément";
  eps = epsNom*F/FNom "déformation proportionnelle à la force (loi de Hooke)";
  annotation(
    Icon(coordinateSystem(preserveAspectRatio = true, extent = {{-100, -100}, {100, 100}}), graphics = {Rectangle(fillColor = {160, 160, 160}, pattern = LinePattern.None, fillPattern = FillPattern.Backward, extent = {{-90, -20}, {-70, -60}}), Line(points = {{-90, -20}, {-70, -20}}), Rectangle(lineColor = {60, 60, 60}, fillColor = DynamicSelect({200, 200, 210}, if overload then {230, 80, 60} else {200, 200, 210}), fillPattern = FillPattern.Solid, extent = {{-80, 20}, {70, -20}}), Ellipse(lineColor = {60, 60, 60}, fillColor = {255, 255, 255}, fillPattern = FillPattern.Solid, extent = {{-40, 12}, {-16, -12}}), Ellipse(lineColor = {60, 60, 60}, fillColor = {255, 255, 255}, fillPattern = FillPattern.Solid, extent = {{16, 12}, {40, -12}}), Rectangle(lineColor = {200, 110, 20}, fillColor = {240, 160, 60}, fillPattern = FillPattern.Solid, extent = {{-12, 26}, {12, 20}}), Rectangle(lineColor = {200, 110, 20}, fillColor = {240, 160, 60}, fillPattern = FillPattern.Solid, extent = {{-12, -20}, {12, -26}}), Line(points = {{70, 0}, {90, 0}}, color = {0, 127, 0}), Text(textColor = {0, 0, 255}, extent = {{-150, 80}, {150, 40}}, textString = "%name"), Text(extent = {{-150, -64}, {150, -94}}, textString = "%capacity kg")}),
    Diagram(coordinateSystem(preserveAspectRatio = true, extent = {{-100, -100}, {100, 100}})),
    Documentation(info = "<html>
<p><strong>Corps d'épreuve</strong> d'un capteur de force (<em>load cell</em>) : la pièce métallique qui se déforme sous la charge, et sur laquelle sont collées les jauges de déformation du pont (<code>WheatstoneBridge</code>). Modèle <strong>quasi-statique</strong> : pas de masse ni d'amortissement, la déformation suit la force instantanément. C'est légitime tant que la charge évolue lentement devant la fréquence propre du capteur (plusieurs dizaines de hertz pour une balance de cuisine).</p>
<p>La force arrive par la bride mécanique <code>flange</code>, typiquement depuis une source standard <code>Modelica.Mechanics.Translational.Sources.Force</code> (le poids : masse × <code>g_n</code>). Le corps d'épreuve se comporte comme un ressort de raideur <code>FNom/sNom</code> appuyé sur un point fixe, et sort la déformation <code>eps = epsNom · F/FNom</code> vers le pont.</p>
<p>Ordre de grandeur des paramètres par défaut : capteur de 5 kg, 500 µm/m à pleine charge, soit une sensibilité de 1 mV/V une fois le pont complet câblé (facteur de jauge 2), ce qui est typique des capteurs de balance de cuisine. Au-delà de 150 % de la portée, l'icône passe au rouge (<code>overload</code>) : un vrai corps d'épreuve se déformerait durablement.</p>
</html>"));
end LoadCell;
