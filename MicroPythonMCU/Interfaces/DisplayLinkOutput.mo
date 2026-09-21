within MicroPythonMCU.Interfaces;
connector DisplayLinkOutput "Sortie logique causale de la liaison d'affichage pedagogique (cote MCU) : pas de tension/courant reels, cf. Décision « Périphérique d'affichage pédagogique » dans requirements.md"
  output Integer seq "Incremente a chaque machine.Display.write() - sert de declencheur d'edge-detection (change(seq)) cote recepteur, plus fiable qu'une comparaison de String";
  output String payload "Dernier texte transmis par write() (echantillonne-bloque jusqu'au prochain write)";
  output Integer charCode[DISPLAY_COLS] "Codes ASCII des DISPLAY_COLS premiers caracteres de payload (espace = 32 si payload plus court) - permet d'afficher le texte reellement recu sur l'icone d'un Peripherals.Display via DynamicSelect, contrairement a payload (String) qui n'est jamais stocke dans les resultats de simulation, cf. Internal.StringToCharCodes";
  annotation(
    Icon(coordinateSystem(preserveAspectRatio = true, extent = {{-100, -100}, {100, 100}}), graphics = {Polygon(points = {{-100, 50}, {0, 0}, {-100, -50}, {-100, 50}}, lineColor = {28, 108, 200}, fillColor = {255, 255, 255}, fillPattern = FillPattern.Solid)}),
    Documentation(info = "<html>
<p>Connecteur causal (sortie) de la liaison d'affichage pédagogique exposée par <code>MCU</code>. Ne représente pas une broche électrique réelle : la liaison est modélisée comme un message logique livré instantanément au point de synchro, pas une forme d'onde série bit-à-bit - simplification v0 assumée, cf. <code>requirements.md</code>.</p>
</html>"));
end DisplayLinkOutput;
