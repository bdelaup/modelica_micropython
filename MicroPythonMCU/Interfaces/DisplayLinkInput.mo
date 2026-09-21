within MicroPythonMCU.Interfaces;
connector DisplayLinkInput "Entree logique causale de la liaison d'affichage pedagogique (cote Peripherals.Display) - image miroir de DisplayLinkOutput"
  input Integer seq;
  input String payload;
  input Integer charCode[DISPLAY_COLS];
  annotation(
    Icon(coordinateSystem(preserveAspectRatio = true, extent = {{-100, -100}, {100, 100}}), graphics = {Polygon(points = {{-100, 50}, {0, 0}, {-100, -50}, {-100, 50}}, lineColor = {28, 108, 200}, fillColor = {28, 108, 200}, fillPattern = FillPattern.Solid)}),
    Documentation(info = "<html>
<p>Connecteur causal (entrée) de la liaison d'affichage pédagogique, à câbler via <code>connect()</code> sur un <code>DisplayLinkOutput</code> (ex. <code>connect(mcu.Display0, display.displayLink)</code>). Pas de valeur par défaut sur les champs eux-mêmes (un défaut inconditionnel entrerait en conflit avec l'équation générée par <code>connect()</code>, piège déjà rencontré et documenté dans <code>requirements.md</code> - <code>Error: Too many equations, over-determined system</code>) : ce connecteur est destiné à toujours être câblé quand <code>Peripherals.Display</code> est utilisé dans un schéma. Cf. <code>DisplayLinkOutput</code> et la décision « Périphérique d'affichage pédagogique » dans <code>requirements.md</code>.</p>
</html>"));
end DisplayLinkInput;
