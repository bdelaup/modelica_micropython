within MicroPythonMCU.Examples;

model UartLoopback "Liaison série électrique réelle bouclée sur elle-même : GP0 (TX) émet une trame, GP1 (RX) la reçoit et la décode, GP3 (LED) confirme que l'octet est arrivé intact"
  extends Modelica.Icons.Example;
  MCU mcu(scriptPath = Modelica.Utilities.Files.loadResource("modelica://MicroPythonMCU/Resources/Scripts/uart_loopback.py")) "scriptPath = Resources/Scripts/uart_loopback.py" annotation(
    Placement(transformation(origin = {1, 0}, extent = {{-50, -50}, {50, 50}})));
  Modelica.Electrical.Analog.Basic.Ground ground annotation(
    Placement(transformation(origin = {0, -90}, extent = {{-15, -15}, {15, 15}})));
  Modelica.Electrical.Analog.Basic.Resistor loopR(R = 1000) "Bouclage TX->RX : résistance de liaison. Un connect() direct entre deux broches du même MCU fait disparaître la tension pilotée des résultats de simulation (fusion d'alias, constaté empiriquement sur PinEcho) - contourné en donnant à RX un véritable état dynamique via loopC, cf. requirements.md" annotation(
    Placement(transformation(origin = {-90, 10}, extent = {{-10, -10}, {10, 10}})));
  Modelica.Electrical.Analog.Basic.Capacitor loopC(C = 1e-9) "Constante de temps du bouclage : (ROut + loopR)*C = 1.1 us, soit 0.13% d'un bit à 1200 bauds (833 us) - assez pour éviter l'alias algébrique exact, trop peu pour déformer la trame" annotation(
    Placement(transformation(origin = {-60, -30}, extent = {{-10, -10}, {10, 10}}, rotation = -90)));
  Modelica.Electrical.Analog.Basic.Resistor r3(R = 330) "limite le courant du témoin de réception" annotation(
    Placement(transformation(origin = {-90, -50}, extent = {{-15, -15}, {15, 15}})));
  MicroPythonMCU.Peripherals.LED led3 "GP3 : s'allume si l'octet reçu est bien celui qui a été émis" annotation(
    Placement(transformation(origin = {-140, -50}, extent = {{-15, 15}, {15, -15}}, rotation = -180)));
equation
  connect(mcu.GND, ground.p) annotation(
    Line(points = {{1, -39}, {1, -57}, {0, -57}, {0, -75}}, color = {0, 0, 255}));
// Bouclage electrique TX -> RX (motif loopR/loopC de PinEcho, cf. requirements.md)
  connect(mcu.GP0, loopR.p) annotation(
    Line(points = {{-30, 25}, {-110, 25}, {-110, 10}, {-100, 10}}, color = {0, 0, 255}));
  connect(loopR.n, mcu.GP1) annotation(
    Line(points = {{-80, 10}, {-30, 10}}, color = {0, 0, 255}));
  connect(loopR.n, loopC.p) annotation(
    Line(points = {{-60, 10}, {-60, -20}}, color = {0, 0, 255}));
  connect(loopC.n, ground.p) annotation(
    Line(points = {{-60, -40}, {-60, -75}, {0, -75}}, color = {0, 0, 255}));
// Temoin de reception
  connect(mcu.GP3, r3.n) annotation(
    Line(points = {{-30, -25}, {-30, -40}, {-75, -40}, {-75, -50}}, color = {0, 0, 255}));
  connect(r3.p, led3.p) annotation(
    Line(points = {{-105, -50}, {-125, -50}}, color = {0, 0, 255}));
  connect(led3.n, ground.p) annotation(
    Line(points = {{-155, -50}, {-155, -75}, {0, -75}}, color = {0, 0, 255}));
  annotation(
    Diagram(coordinateSystem(extent = {{-200, -120}, {80, 80}})),
    experiment(StopTime = 0.05, Interval = 5e-6),
    Documentation(info = "<html>
<p>Démontre la liaison série <code>machine.UART</code> en <strong>signal électrique réel</strong> : la broche TX porte une vraie trame (bit de start à 0, 8 bits de données poids faible en tête, bit de stop à 1), chaque bit durant 1/baudrate. Tracer <code>mcu.GP0.v</code> permet de lire la trame à l'œil dans OMEdit, comme sur un oscilloscope.</p>
<p>Le script attend 5 ms avant d'émettre, pour laisser voir l'<strong>état de repos</strong> sur l'oscillogramme : dès que l'UART est configuré, la broche TX est pilotée activement au niveau haut (état « mark »), avant même le premier <code>write()</code>. C'est le TX qui tient la ligne, pas le RX — la sortie est push-pull, aucune résistance de tirage n'intervient (contrairement à un bus I²C en drain ouvert).</p>
<p>La forme d'onde est générée <strong>en continu par Modelica</strong> à partir du motif de bits calculé une seule fois côté runtime C, sans que le thread Python pilote chaque front — comme le vrai périphérique UART du RP2040, qui tourne indépendamment du CPU une fois programmé (même principe que <code>machine.PWM</code>, cf. <code>requirements.md</code>). La réception, elle, est décodée côté C par échantillonnage au milieu de chaque bit.</p>
<p>Le bouclage TX→RX reprend obligatoirement le motif <code>loopR</code>/<code>loopC</code> de <code>Examples.PinEcho</code> : relier deux broches du même <code>MCU</code> par un <code>connect()</code> direct fait disparaître la tension pilotée des résultats de simulation.</p>
</html>"));
end UartLoopback;
