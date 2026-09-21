within MicroPythonMCU.Peripherals;
model LED "LED dont l'icône s'éclaire en fonction du courant qui la traverse (inspiré de Arduino.Components.LED, bibliothèque Modelica-Arduino)"
  extends Modelica.Electrical.Analog.Interfaces.TwoPin;

  parameter Modelica.Units.SI.Voltage Vknee = 1.8 "Tension de seuil (genou) de la diode, approximation d'une LED rouge";
  parameter Modelica.Units.SI.Current IMax = 0.0035 "Courant correspondant à la luminosité maximale de l'icône (échelle d'affichage, pas une limite physique imposée) — calé sur le courant typiquement atteint dans ce projet (~3.5 mA avec une résistance série de 330 Ω, VOH=3.3V, ROut=100 Ω), pour que l'icône atteigne vraiment colorOn en régime établi plutôt que de plafonner à mi-course";
  parameter Integer colorOn[3] = {255, 0, 0} "Couleur de l'icône à pleine luminosité (RGB)";
  parameter Integer colorOff[3] = {90, 25, 25} "Couleur de l'icône éteinte (RGB)";

  Modelica.Electrical.Analog.Semiconductors.Diode diode(Ids = 0.005*exp(-Vknee/0.1), Vt = 0.1, R = 1e9) "Diode a caracteristique lisse (pas Ideal.IdealDiode : sa commutation par evenement discret casse le mecanisme de synchro sur les tres longues simulations a tick periodique, cf. requirements.md). Ids calibre pour ~5 mA a Vknee ; Vt=0.1 (plus doux qu'un Vt physique reel) pour la stabilite numerique, tension de coude proche de Vknee au premier ordre." annotation(
    Placement(transformation(extent = {{-40, -10}, {-20, 10}})));
  Modelica.Electrical.Analog.Sensors.CurrentSensor currentSensor annotation(Placement(transformation(extent = {{20, -10}, {40, 10}})));
  Modelica.Blocks.Math.Mean mean(f = 50) "Lisse le courant mesuré, pour une animation d'icône stable (pas de rôle électrique). f=50 (fenêtre 20 ms) plutôt que 10 (100 ms) : une fenêtre trop longue par rapport à un clignotement rapide (ex. chenillard à 150 ms/broche) dilue le pic de luminosité et floute les transitions au lieu de les montrer nettement" annotation(
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
<p>LED à deux broches (<code>p</code>/<code>n</code>), modélisée comme une <code>Modelica.Electrical.Analog.Semiconductors.Diode</code> (caractéristique exponentielle lisse, pas <code>Ideal.IdealDiode</code> — sa commutation par événement discret s'est avérée bloquer le mécanisme de synchro sur de très longues simulations à tick périodique, cf. <code>requirements.md</code>), calibrée pour une chute de tension proche de <code>Vknee</code> une fois passante — nécessite comme une vraie LED une résistance série externe pour limiter le courant. Le courant traversant la LED est mesuré puis lissé (<code>Modelica.Blocks.Math.Mean</code>) pour piloter la luminosité de l'icône via <code>DynamicSelect</code> : hors lecture d'un résultat de simulation (par exemple en train de construire un schéma), l'icône affiche <code>colorOn</code> (rouge vif par défaut) pour rester bien visible ; pendant la lecture animée d'un résultat, elle interpole entre <code>colorOff</code> (courant nul) et <code>colorOn</code> (courant ≥ <code>IMax</code>). Inspiré de <code>Arduino.Components.LED</code> dans la bibliothèque <a href=\"https://github.com/CATIA-Systems/Modelica-Arduino\">Modelica-Arduino</a> (CATIA-Systems).</p>
</html>"));
end LED;
