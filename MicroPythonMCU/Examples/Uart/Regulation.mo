within MicroPythonMCU.Examples.Uart;

model Regulation "Boucle de régulation fermée à travers la seule liaison série : la sortie réelle du capteur pilote le procédé, dont la réponse revient sur son entrée"
  extends Modelica.Icons.Example;
  MCU mcu(scriptPath = Modelica.Utilities.Files.loadResource("modelica://MicroPythonMCU/Resources/Scripts/MCU/uart_regulation.py")) "scriptPath = Resources/Scripts/MCU/uart_regulation.py" annotation(
    Placement(transformation(origin = {-90, 0}, extent = {{-50, -50}, {50, 50}})));
  MicroPythonMCU.Peripherals.UartTemperatureSensor capteur(baudrate = 9600) "Capteur ET actionneur : {v1} publie la mesure, {o1} capture la commande" annotation(
    Placement(transformation(origin = {40, 0}, extent = {{-40, -40}, {40, 40}})));
  Modelica.Blocks.Continuous.FirstOrder procede(T = 0.15, k = 0.5, initType = Modelica.Blocks.Types.Init.InitialOutput, y_start = 20) "Procédé thermique du premier ordre : entrée = commande (0-100), sortie = température (°C)" annotation(
    Placement(transformation(origin = {150, -13.6}, extent = {{-12, -12}, {12, 12}})));
  Modelica.Electrical.Analog.Basic.Ground ground annotation(
    Placement(transformation(origin = {-25, -80}, extent = {{-10, -10}, {10, 10}})));
equation
// Liaison serie : GP5 (TX) descend vers RX, TX remonte vers GP4 (RX)
  connect(mcu.GP5, capteur.RX) annotation(
    Line(points = {{-59, 10}, {-34, 10}, {-34, -13.6}, {-9.6, -13.6}}, color = {0, 0, 255}));
  connect(capteur.TX, mcu.GP4) annotation(
    Line(points = {{-9.6, 13.6}, {-34, 13.6}, {-34, 25}, {-59, 25}}, color = {0, 0, 255}));
// Boucle : la commande capturee attaque le procede, dont la sortie revient en mesure.
// Le retour passe PAR LE DESSUS, au-dessus des deux composants, pour ne longer aucun d'eux.
  connect(capteur.valueOut[1], procede.u) annotation(
    Line(points = {{89.6, -13.6}, {135, -13.6}}, color = {0, 0, 127}));
  connect(procede.y, capteur.valueIn[1]) annotation(
    Line(points = {{163, -13.6}, {180, -13.6}, {180, 55}, {110, 55}, {110, 13.6}, {89.6, 13.6}}, color = {0, 0, 127}));
// Masse commune
  connect(mcu.GND, ground.p) annotation(
    Line(points = {{-90, -39}, {-90, -70}, {-25, -70}}, color = {0, 0, 255}));
  connect(capteur.GND, ground.p) annotation(
    Line(points = {{40, -28.8}, {40, -70}, {-25, -70}}, color = {0, 0, 255}));
  annotation(
    Diagram(coordinateSystem(extent = {{-160, -100}, {200, 80}})),
    experiment(StopTime = 1, Interval = 1e-4),
    Documentation(info = "<html>
<p>L'exemple qui exploite réellement la <strong>sortie réelle</strong> de l'appareil série. Tout le reste de la famille montre des grandeurs qui <em>entrent</em> dans les trames ; ici une grandeur en <em>sort</em> et pilote le modèle.</p>
<p>La boucle est fermée et ne passe que par les deux fils de la liaison série :</p>
<ol>
<li>le microcontrôleur envoie <code>AT+TEMP</code> ; le capteur répond avec la valeur présente sur <code>valueIn[1]</code> ;</li>
<li>le programme calcule une commande (correcteur proportionnel avec compensation du gain statique) et envoie <code>SET &lt;commande&gt;</code> ;</li>
<li>le marqueur <code>{o1}</code> de la table capture ce nombre et le publie sur <code>valueOut[1]</code> ;</li>
<li><code>valueOut[1]</code> attaque le procédé du premier ordre, dont la sortie revient sur <code>valueIn[1]</code>.</li>
</ol>
<p>Tracer <code>procede.y</code> montre la température rejoindre la consigne de 40 °C, et <code>capteur.valueOut[1]</code> montre la commande évoluer en escalier — un palier par cycle de dialogue, puisque la régulation n'est rafraîchie qu'au rythme des échanges série. C'est précisément ce que ce montage permet d'étudier : l'effet de la <strong>période d'échantillonnage imposée par le débit de la liaison</strong> sur la dynamique de la boucle. Abaisser <code>baudrate</code> espace les cycles et dégrade visiblement la réponse.</p>
</html>"));
end Regulation;
