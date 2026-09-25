within MicroPythonMCU.Peripherals;

model UartEchoDevice "Périphérique série d'écho : renvoie tel quel chaque octet reçu"
  extends Internal.PartialUartDevice(echoEnabled = true, respondEnabled = false, periodicEnabled = false, scriptPath = Modelica.Utilities.Files.loadResource("modelica://MicroPythonMCU/Resources/Scripts/uart_echo_device.py"));
  annotation(
    Icon(graphics = {Text(textColor = {255, 255, 255}, extent = {{-90, -22}, {90, -40}}, textString = "ECHO", textStyle = {TextStyle.Bold})}),
    Documentation(info = "<html>
<p>Le plus simple des appareils dérivés de <code>Internal.PartialUartDevice</code> : il ne redéfinit que trois booléens. Chaque octet décodé est immédiatement remis dans la file d'émission, sans attendre la fin de la ligne — donc sans notion de commande ni de délimiteur.</p>
<p>Son intérêt est d'être un <strong>véritable partenaire</strong> sur la liaison : il remplace le bouclage de <code>Examples.UartLoopback</code>, qui n'existait que pour contourner une fusion d'alias entre deux broches d'un même <code>MCU</code>. Ici les deux extrémités sont deux composants distincts, et la liaison est un simple fil.</p>
<p>Chaque octet repart avec un décalage d'environ une trame, puisqu'il faut l'avoir entièrement décodé (jusqu'au bit de stop) avant de pouvoir le réémettre — exactement comme un répéteur réel. C'est aussi le composant de choix pour valider une chaîne de communication avant d'y brancher l'appareil définitif.</p>
</html>"));
end UartEchoDevice;
