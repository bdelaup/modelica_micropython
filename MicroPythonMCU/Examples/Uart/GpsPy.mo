within MicroPythonMCU.Examples.Uart;

model GpsPy "Un module GPS pousse spontanément ses trames de position ; le microcontrôleur les compte sans jamais rien demander"
  extends Modelica.Icons.Example;
  MCU mcu(scriptPath = Modelica.Utilities.Files.loadResource("modelica://MicroPythonMCU/Resources/Scripts/MCU/uart_gps.py")) "scriptPath = Resources/Scripts/MCU/uart_gps.py" annotation(
    Placement(transformation(origin = {-90, 0}, extent = {{-50, -50}, {50, 50}})));
  MicroPythonMCU.Peripherals.UartGpsModule gps(baudrate = 9600, period = 0.1, comportement = MicroPythonMCU.Interfaces.UartBehaviour.Script, scriptPath = Modelica.Utilities.Files.loadResource("modelica://MicroPythonMCU/Resources/Scripts/Device/gps.py")) "Émet une phrase NMEA RMC toutes les 100 ms, sans sollicitation - comportement décrit par Resources/Scripts/Device/gps.py" annotation(
    Placement(transformation(origin = {40, 0}, extent = {{-40, -40}, {40, 40}})));
  Modelica.Blocks.Sources.Ramp latitude(height = 0.01, duration = 1, offset = 47.24) "La position évolue : les trames successives ne sont pas identiques" annotation(
    Placement(transformation(origin = {160, 45}, extent = {{12, -12}, {-12, 12}})));
  Modelica.Blocks.Sources.Constant longitude(k = 5.9876) annotation(
    Placement(transformation(origin = {160, 10}, extent = {{12, -12}, {-12, 12}})));
  Modelica.Blocks.Sources.Constant vitesse(k = 12.3) annotation(
    Placement(transformation(origin = {160, -25}, extent = {{12, -12}, {-12, 12}})));
  Modelica.Electrical.Analog.Basic.Ground ground annotation(
    Placement(transformation(origin = {-25, -80}, extent = {{-10, -10}, {10, 10}})));
equation
// Liaison serie : GP5 (TX) descend vers RX, TX remonte vers GP4 (RX)
  connect(mcu.GP5, gps.RX) annotation(
    Line(points = {{-59, 10}, {-34, 10}, {-34, -13.6}, {-9.6, -13.6}}, color = {0, 0, 255}));
  connect(gps.TX, mcu.GP4) annotation(
    Line(points = {{-9.6, 13.6}, {-34, 13.6}, {-34, 25}, {-59, 25}}, color = {0, 0, 255}));
// Les trois grandeurs publiees dans la trame, regroupees sur la droite
  connect(latitude.y, gps.valueIn[1]) annotation(
    Line(points = {{147, 45}, {112, 45}, {112, 13.6}, {89.6, 13.6}}, color = {0, 0, 127}));
  connect(longitude.y, gps.valueIn[2]) annotation(
    Line(points = {{147, 10}, {112, 10}, {112, 13.6}, {89.6, 13.6}}, color = {0, 0, 127}));
  connect(vitesse.y, gps.valueIn[3]) annotation(
    Line(points = {{147, -25}, {112, -25}, {112, 13.6}, {89.6, 13.6}}, color = {0, 0, 127}));
// Masse commune
  connect(mcu.GND, ground.p) annotation(
    Line(points = {{-90, -39}, {-90, -70}, {-25, -70}}, color = {0, 0, 255}));
  connect(gps.GND, ground.p) annotation(
    Line(points = {{40, -28.8}, {40, -70}, {-25, -70}}, color = {0, 0, 255}));
  annotation(
    Diagram(coordinateSystem(extent = {{-160, -100}, {200, 80}})),
    experiment(StopTime = 0.6, Interval = 5e-5),
    Documentation(info = "<html>
<p>Le miroir de <code>Examples.Uart.Sensor</code> : ici l'appareil parle le premier et n'attend aucune question.</p>
<p>Conséquence côté programme embarqué : la réception ne le réveille jamais (pas de <code>uart.irq()</code> en v0), il doit donc <strong>surveiller</strong> son entrée avec <code>uart.any()</code> dans une boucle, en dormant entre deux passages. Un programme qui oublierait de dormir empêcherait le temps simulé d'avancer ; un programme qui dormirait trop longtemps manquerait des trames — les deux défauts se constatent immédiatement à l'exécution, ce qui en fait un banc d'essai utile pour valider une stratégie de scrutation avant de la porter sur la cible.</p>
<p>Le module est en mode <strong>Script</strong> (<code>gps.comportement = Script</code>) : <code>Device/gps.py</code> produit des phrases NMEA RMC complètes — heure UTC, hémisphères, <strong>somme de contrôle</strong> —, ce que la table de commandes ne sait pas faire. Le programme du microcontrôleur vérifie chaque somme de contrôle, exactement comme le code embarqué d'un récepteur réel. Le script tient aussi un compteur de phrases émises, publié sur <code>gps.valueOut[1]</code>.</p>
<p>La latitude est une rampe : les phrases successives diffèrent, ce qui permet de vérifier d'un coup d'œil dans le journal que le flux est bien vivant et pas répété.</p>
</html>"));
end GpsPy;
