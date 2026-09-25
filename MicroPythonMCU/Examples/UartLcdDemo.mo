within MicroPythonMCU.Examples;

model UartLcdDemo "Le microcontrôleur écrit deux lignes sur un afficheur 20x2 par une vraie liaison série ; l'afficheur les montre sur son icône avec défilement"
  extends Modelica.Icons.Example;
  MCU mcu(scriptPath = Modelica.Utilities.Files.loadResource("modelica://MicroPythonMCU/Resources/Scripts/uart_lcd.py")) "scriptPath = Resources/Scripts/uart_lcd.py" annotation(
    Placement(transformation(origin = {-90, 0}, extent = {{-50, -50}, {50, 50}})));
  MicroPythonMCU.Peripherals.UartLcd20x2 lcd(baudrate = 9600) "Affiche les lignes reçues sur sa broche RX" annotation(
    Placement(transformation(origin = {40, 0}, extent = {{-40, -40}, {40, 40}})));
  Modelica.Electrical.Analog.Basic.Ground ground annotation(
    Placement(transformation(origin = {-25, -80}, extent = {{-10, -10}, {10, 10}})));
equation
// Liaison serie : GP5 (TX) descend vers RX, TX remonte vers GP4 (RX).
// L'afficheur n'emet jamais, mais sa broche TX reste cablee - comme sur un
// module serie reel, ou les deux fils sont presents meme si l'un ne sert pas.
  connect(mcu.GP5, lcd.RX) annotation(
    Line(points = {{-59, 10}, {-34, 10}, {-34, -13.6}, {-9.6, -13.6}}, color = {0, 0, 255}));
  connect(lcd.TX, mcu.GP4) annotation(
    Line(points = {{-9.6, 13.6}, {-34, 13.6}, {-34, 25}, {-59, 25}}, color = {0, 0, 255}));
  connect(mcu.GND, ground.p) annotation(
    Line(points = {{-90, -39}, {-90, -70}, {-25, -70}}, color = {0, 0, 255}));
  connect(lcd.GND, ground.p) annotation(
    Line(points = {{40, -28.8}, {40, -70}, {-25, -70}}, color = {0, 0, 255}));
  annotation(
    Diagram(coordinateSystem(extent = {{-160, -100}, {120, 80}})),
    experiment(StopTime = 0.2, Interval = 1e-5),
    Documentation(info = "<html>
<p>À comparer directement avec <code>Examples.DisplayDemo</code>, qui affiche le même genre de texte à travers la liaison <strong>logique</strong> <code>machine.Display</code>. Le résultat visuel est identique, le chemin ne l'est pas du tout :</p>
<ul>
<li><code>DisplayDemo</code> : le message est livré d'un bloc au point de synchro, sans durée ni tension. Pratique, mais rien à sonder.</li>
<li><code>UartLcdDemo</code> : le texte traverse un vrai fil, un caractère toutes les 1,04 ms à 9600 bauds. Tracer <code>mcu.GP5.v</code> montre chaque caractère partir bit à bit, et c'est le saut de ligne qui déclenche l'affichage.</li>
</ul>
<p>Régler le débit de l'afficheur sur une autre valeur que celle du microcontrôleur fait apparaître des caractères faux à l'écran — le symptôme exact d'un désaccord de configuration sur un montage réel, reproduit ici sans matériel.</p>
</html>"));
end UartLcdDemo;
