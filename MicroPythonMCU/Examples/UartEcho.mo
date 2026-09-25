within MicroPythonMCU.Examples;

model UartEcho "Le microcontrôleur dialogue avec un appareil série externe : il envoie une ligne, l'appareil la lui renvoie"
  extends Modelica.Icons.Example;
  MCU mcu(scriptPath = Modelica.Utilities.Files.loadResource("modelica://MicroPythonMCU/Resources/Scripts/uart_echo.py")) "scriptPath = Resources/Scripts/uart_echo.py" annotation(
    Placement(transformation(origin = {-90, 0}, extent = {{-50, -50}, {50, 50}})));
  MicroPythonMCU.Peripherals.UartEchoDevice echo(baudrate = 1200, comportement = MicroPythonMCU.Interfaces.UartBehaviour.Script, scriptPath = Modelica.Utilities.Files.loadResource("modelica://MicroPythonMCU/Resources/Scripts/uart_echo_device.py")) "Renvoie chaque ligne reçue - comportement décrit par Resources/Scripts/uart_echo_device.py" annotation(
    Placement(transformation(origin = {40, 0}, extent = {{-40, -40}, {40, 40}})));
  Modelica.Electrical.Analog.Basic.Ground ground annotation(
    Placement(transformation(origin = {-25, -80}, extent = {{-10, -10}, {10, 10}})));
equation
// Liaison serie : GP5 (TX) descend vers RX, TX remonte vers GP4 (RX).
// Les deux brins restent dans l'espace libre entre les deux composants.
  connect(mcu.GP5, echo.RX) annotation(
    Line(points = {{-59, 10}, {-34, 10}, {-34, -13.6}, {-9.6, -13.6}}, color = {0, 0, 255}));
  connect(echo.TX, mcu.GP4) annotation(
    Line(points = {{-9.6, 13.6}, {-34, 13.6}, {-34, 25}, {-59, 25}}, color = {0, 0, 255}));
// Masse commune aux deux appareils, ramenee par le dessous
  connect(mcu.GND, ground.p) annotation(
    Line(points = {{-90, -39}, {-90, -70}, {-25, -70}}, color = {0, 0, 255}));
  connect(echo.GND, ground.p) annotation(
    Line(points = {{40, -28.8}, {40, -70}, {-25, -70}}, color = {0, 0, 255}));
  annotation(
    Diagram(coordinateSystem(extent = {{-160, -100}, {120, 80}})),
    experiment(StopTime = 0.1, Interval = 5e-6),
    Documentation(info = "<html>
<p>Premier exemple où le microcontrôleur parle à un <strong>interlocuteur</strong> et non plus à lui-même. <code>Examples.UartLoopback</code> renvoyait la trame vers lui-même à travers un réseau <code>loopR</code>/<code>loopC</code> qui n'existait que pour contourner une fusion d'alias entre deux broches d'un même composant. Ici les deux extrémités sont deux composants distincts : la liaison redevient un simple fil dans chaque sens, et le schéma ressemble à un câblage réel.</p>
<p>Les deux appareils doivent partager leur <strong>masse</strong> — comme sur un montage réel, où relier seulement TX et RX ne suffit pas.</p>
<p>Le comportement de l'appareil est décrit par un <strong>script Python</strong> (<code>echo.comportement = Script</code>) : <code>uart_echo_device.py</code>, une fonction d'une ligne qui renvoie chaque ligne reçue. Tracer <code>mcu.GP5.v</code> (ce que le microcontrôleur émet) et <code>mcu.GP4.v</code> (ce que l'appareil renvoie) montre que la réponse ne part qu'une fois la ligne complète reçue, terminateur compris, puis <code>responseDelay</code> écoulé : un script ne voit que des lignes entières.</p>
<p>Repasser <code>echo.comportement</code> sur <code>Table</code> active à la place l'écho paramétré du composant, <strong>octet par octet</strong> : chaque octet repart dès qu'il est décodé, avec environ une trame de décalage, sans attendre la fin de la ligne. Le programme du microcontrôleur fonctionne à l'identique dans les deux cas.</p>
<p>La broche <code>GP7</code> est mise à l'état haut par le programme si la ligne relue est identique à celle envoyée. Elle n'est raccordée à rien : c'est sa tension que l'on observe, un composant d'affichage n'apporterait rien ici.</p>
</html>"));
end UartEcho;
