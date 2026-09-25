within MicroPythonMCU.Examples.Uart;

model Sensor "Le microcontrôleur interroge un capteur de température série, lit deux mesures qui évoluent, puis lui transmet une consigne qui ressort sur une sortie réelle"
  extends Modelica.Icons.Example;
  MCU mcu(scriptPath = Modelica.Utilities.Files.loadResource("modelica://MicroPythonMCU/Resources/Scripts/MCU/uart_sensor.py")) "scriptPath = Resources/Scripts/MCU/uart_sensor.py" annotation(
    Placement(transformation(origin = {-90, 0}, extent = {{-50, -50}, {50, 50}})));
  MicroPythonMCU.Peripherals.UartTemperatureSensor capteur(baudrate = 9600) "Répond AT+TEMP par la température présente sur son entrée, et SET par une consigne sur sa sortie" annotation(
    Placement(transformation(origin = {40, 0}, extent = {{-40, -40}, {40, 40}})));
  Modelica.Blocks.Sources.Ramp temperature(height = 20, duration = 1, offset = 20) "La grandeur mesurée monte de 20 à 40 °C : les deux interrogations doivent donc donner deux valeurs différentes" annotation(
    Placement(transformation(origin = {150, 13.6}, extent = {{12, -12}, {-12, 12}})));
  Modelica.Electrical.Analog.Basic.Ground ground annotation(
    Placement(transformation(origin = {-25, -80}, extent = {{-10, -10}, {10, 10}})));
equation
// Liaison serie : GP5 (TX) descend vers RX, TX remonte vers GP4 (RX)
  connect(mcu.GP5, capteur.RX) annotation(
    Line(points = {{-59, 10}, {-34, 10}, {-34, -13.6}, {-9.6, -13.6}}, color = {0, 0, 255}));
  connect(capteur.TX, mcu.GP4) annotation(
    Line(points = {{-9.6, 13.6}, {-34, 13.6}, {-34, 25}, {-59, 25}}, color = {0, 0, 255}));
// La grandeur mesuree vient du reste du modele, par la droite
  connect(temperature.y, capteur.valueIn[1]) annotation(
    Line(points = {{137, 13.6}, {89.6, 13.6}}, color = {0, 0, 127}));
// Masse commune
  connect(mcu.GND, ground.p) annotation(
    Line(points = {{-90, -39}, {-90, -70}, {-25, -70}}, color = {0, 0, 255}));
  connect(capteur.GND, ground.p) annotation(
    Line(points = {{40, -28.8}, {40, -70}, {-25, -70}}, color = {0, 0, 255}));
  annotation(
    Diagram(coordinateSystem(extent = {{-160, -100}, {180, 80}})),
    experiment(StopTime = 0.5, Interval = 5e-5),
    Documentation(info = "<html>
<p>Un <strong>dialogue requête / réponse</strong> complet, dans les deux sens, sur une liaison série électrique.</p>
<p><strong>Ce que le port d'entrée apporte.</strong> La température n'est pas une constante figée dans le capteur : elle arrive par le connecteur <code>valueIn</code>, ici depuis une rampe. Le microcontrôleur interroge le capteur deux fois à 100 ms d'intervalle et lit deux valeurs différentes — on peut y brancher n'importe quel modèle thermique à la place de la rampe.</p>
<p><strong>Et dans l'autre sens.</strong> Le programme termine par <code>SET 42.5</code>. Le capteur reconnaît ce motif grâce au marqueur de capture <code>{o1}</code> de sa table, et le nombre ressort sur <code>capteur.valueOut[1]</code>. Tracer cette variable montre la consigne apparaître à l'instant exact où la trame finit d'arriver. Pour une boucle complète où cette sortie pilote réellement un procédé, voir <code>Examples.Uart.Regulation</code>.</p>
</html>"));
end Sensor;
