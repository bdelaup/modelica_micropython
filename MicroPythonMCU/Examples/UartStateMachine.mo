within MicroPythonMCU.Examples;

model UartStateMachine "Appareil série dont le comportement est décrit par un script Python à machine d'état : sa réponse dépend de ce qui s'est passé avant"
  extends Modelica.Icons.Example;
  MCU mcu(scriptPath = Modelica.Utilities.Files.loadResource("modelica://MicroPythonMCU/Resources/Scripts/uart_state_machine.py")) "scriptPath = Resources/Scripts/uart_state_machine.py" annotation(
    Placement(transformation(origin = {-90, 0}, extent = {{-50, -50}, {50, 50}})));
  MicroPythonMCU.Peripherals.UartGenericDevice appareil(baudrate = 9600, comportement = MicroPythonMCU.Interfaces.UartBehaviour.Script, scriptPath = Modelica.Utilities.Files.loadResource("modelica://MicroPythonMCU/Resources/Scripts/uart_state_machine_device.py"), useValueInput = true, nOut = 2) "Comportement décrit par Resources/Scripts/uart_state_machine_device.py" annotation(
    Placement(transformation(origin = {40, 0}, extent = {{-40, -40}, {40, 40}})));
  Modelica.Blocks.Sources.Sine mesure(amplitude = 2, f = 5, offset = 20) "Grandeur publiée dans les réponses à READ" annotation(
    Placement(transformation(origin = {150, 13.6}, extent = {{12, -12}, {-12, 12}})));
  Modelica.Electrical.Analog.Basic.Ground ground annotation(
    Placement(transformation(origin = {-25, -80}, extent = {{-10, -10}, {10, 10}})));
equation
// Liaison serie : GP5 (TX) descend vers RX, TX remonte vers GP4 (RX)
  connect(mcu.GP5, appareil.RX) annotation(
    Line(points = {{-59, 10}, {-34, 10}, {-34, -13.6}, {-9.6, -13.6}}, color = {0, 0, 255}));
  connect(appareil.TX, mcu.GP4) annotation(
    Line(points = {{-9.6, 13.6}, {-34, 13.6}, {-34, 25}, {-59, 25}}, color = {0, 0, 255}));
  connect(mesure.y, appareil.valueIn[1]) annotation(
    Line(points = {{137, 13.6}, {89.6, 13.6}}, color = {0, 0, 127}));
  connect(mcu.GND, ground.p) annotation(
    Line(points = {{-90, -39}, {-90, -70}, {-25, -70}}, color = {0, 0, 255}));
  connect(appareil.GND, ground.p) annotation(
    Line(points = {{40, -28.8}, {40, -70}, {-25, -70}}, color = {0, 0, 255}));
  annotation(
    Diagram(coordinateSystem(extent = {{-160, -100}, {180, 80}})),
    experiment(StopTime = 0.4, Interval = 5e-5),
    Documentation(info = "<html>
<p>Un appareil série dont le comportement n'est pas une table mais un <strong>script Python</strong> : <code>appareil.comportement = Script</code>, et <code>scriptPath</code> désigne <code>uart_state_machine_device.py</code>.</p>
<p>La table de commandes associe une commande à une réponse, sans mémoire. Ce script, lui, tient un état : l'appareil n'accepte une lecture que s'il a été démarré, refuse un second démarrage, et compte les lectures servies. La même commande <code>READ</code> reçoit donc trois réponses différentes au fil du scénario.</p>
<p>L'état est rendu observable par <code>outputs()</code>, qui alimente le connecteur <code>valueOut</code> : tracer <code>appareil.valueOut[1]</code> montre l'appareil passer en marche puis revenir à l'arrêt, et <code>appareil.valueOut[2]</code> montre le compteur de lectures. Les messages du script apparaissent dans le journal de simulation, préfixés du nom du composant.</p>
<p>Chaque ligne reçue n'est livrée qu'une fois au script, même si la simulation réévalue plusieurs fois le même instant : une transition d'état n'est jamais rejouée.</p>
</html>"));
end UartStateMachine;
