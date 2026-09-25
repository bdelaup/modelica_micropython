within MicroPythonMCU.Peripherals;

model UartGpsModule "Module GPS série : pousse spontanément une trame de position, sans être sollicité"
  extends Internal.PartialUartDevice(
    respondEnabled = false,
    periodicEnabled = true,
    period = 1,
    periodicTemplate = "$GPGLL,{v1:.4f},{v2:.4f},{v3:.1f}\r\n",
    useValueInput = true,
    nIn = 3,
    fixedValue = 0,
    scriptPath = Modelica.Utilities.Files.loadResource("modelica://MicroPythonMCU/Resources/Scripts/Device/gps.py"));
  annotation(
    Icon(graphics = {Text(textColor = {255, 255, 255}, extent = {{-90, -22}, {90, -40}}, textString = "GPS", textStyle = {TextStyle.Bold})}),
    Documentation(info = "<html>
<p>Représentant du <strong>second mode d'émission</strong> : contrairement au capteur de température, ce module n'attend aucune question. Il pousse une trame toutes les <code>period</code> secondes, ce qui oblige le programme embarqué à surveiller son entrée série — typiquement par <code>uart.any()</code> dans une boucle, puisque la réception ne réveille jamais le script (pas de <code>uart.irq()</code> en v0).</p>
<p>Les trois grandeurs du connecteur <code>valueIn</code> sont latitude, longitude et vitesse. Y brancher un modèle de déplacement fait défiler une trajectoire réelle dans les trames, ce qui permet d'éprouver le code de décodage embarqué sur des données qui bougent.</p>
<p><em>Trame volontairement simplifiée</em> : une phrase NMEA réelle (<code>$GPGLL</code>) porte en plus les indicateurs de sens N/S et E/W, l'heure UTC, un indicateur de validité et une somme de contrôle. On garde ici les trois champs numériques, suffisants pour exercer le mécanisme d'émission et le découpage côté programme. Un format plus fidèle relèverait du mode script, la table de commandes ne sachant pas calculer une somme de contrôle.</p>
</html>"));
end UartGpsModule;
