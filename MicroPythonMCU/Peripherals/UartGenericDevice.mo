within MicroPythonMCU.Peripherals;

model UartGenericDevice "Appareil série externe entièrement décrit par ses paramètres, sans créer de classe dédiée"
  extends Internal.PartialUartDevice(scriptPath = Modelica.Utilities.Files.loadResource("modelica://MicroPythonMCU/Resources/Scripts/uart_generic_device.py"));
  annotation(
    Documentation(info = "<html>
<p>Le composant à poser dans un schéma quand l'appareil à simuler ne correspond à aucun des modèles dérivés fournis et ne justifie pas d'en écrire un. Tout se règle dans le dialogue de paramètres : la table de commandes, l'émission périodique, les grandeurs échangées.</p>
<p>Dès que la même configuration revient dans plusieurs schémas, il vaut mieux en faire une classe : hériter de <code>Internal.PartialUartDevice</code> et fixer les paramètres tient en quelques lignes, et l'appareil gagne un nom, une icône et une documentation propres — c'est ainsi que sont écrits <code>UartEchoDevice</code>, <code>UartTemperatureSensor</code>, <code>UartGpsModule</code> et <code>UartLcd20x2</code>.</p>
</html>"));
end UartGenericDevice;
