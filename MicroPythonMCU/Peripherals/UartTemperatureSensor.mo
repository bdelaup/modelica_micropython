within MicroPythonMCU.Peripherals;

model UartTemperatureSensor "Capteur de température série : répond AT+TEMP par la valeur mesurée, et accepte une consigne par SET"
  extends Internal.PartialUartDevice(
    respondEnabled = true,
    commandTable = "AT+TEMP=>TEMP={v1:.1f}\r\n|AT+ID=>SIM-TEMP-1\r\n|SET {o1}=>OK\r\n",
    responseDelay = 0.005,
    useValueInput = true,
    nIn = 1,
    nOut = 1,
    fixedValue = 20,
    periodicEnabled = false,
    scriptPath = Modelica.Utilities.Files.loadResource("modelica://MicroPythonMCU/Resources/Scripts/uart_temperature_device.py"));
  annotation(
    Icon(graphics = {Text(textColor = {255, 255, 255}, extent = {{-90, -22}, {90, -40}}, textString = "TEMP", textStyle = {TextStyle.Bold})}),
    Documentation(info = "<html>
<p>Appareil dérivé de <code>Internal.PartialUartDevice</code> par la seule redéfinition de paramètres — aucune logique recodée. Il répond à trois commandes, toutes terminées par un saut de ligne :</p>
<ul>
<li><code>AT+TEMP</code> → <code>TEMP=&lt;valeur&gt;</code>, où la valeur est celle présente sur le connecteur <code>valueIn[1]</code> au moment de la question. On y branche une rampe, un modèle thermique, ou n'importe quelle grandeur du modèle.</li>
<li><code>AT+ID</code> → une chaîne d'identification fixe, comme tout module AT réel.</li>
<li><code>SET &lt;nombre&gt;</code> → <code>OK</code>, et le nombre reçu ressort sur <code>valueOut[1]</code>.</li>
</ul>
<p>Cette dernière commande est ce qui fait de l'appareil un <strong>actionneur autant qu'un capteur</strong> : le microcontrôleur lit la mesure par la liaison série et renvoie une consigne par la même liaison, ce qui permet de refermer une boucle de régulation à l'intérieur du modèle, sans aucun fil supplémentaire. Voir <code>Examples.UartRegulation</code>.</p>
<p><code>responseDelay</code> vaut 5 ms : un appareil réel ne répond pas instantanément, et le programme embarqué doit donc attendre sa réponse plutôt que de la supposer déjà arrivée.</p>
</html>"));
end UartTemperatureSensor;
