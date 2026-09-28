within MicroPythonMCU.Examples.FileSystem;

model Boot "Système de fichiers : sans script, le microcontrôleur exécute boot.py puis main.py d'une image de flash recopiée à chaque simulation ; main.py enregistre les mesures de l'ADC (GP0) dans /data/mesures.csv"
  extends Modelica.Icons.Example;
  MCU mcu(scriptPath = "", fsEnabled = true, fsSource = "modelica://MicroPythonMCU/Resources/FileSystems/datalogger") "scriptPath vide : boot.py puis main.py de l'image Resources/FileSystems/datalogger ; copie créée dans le dossier de simulation (fsWorkspace = \".\" par défaut), ouverte dans l'Explorateur en fin de simulation" annotation(
    Placement(transformation(origin = {0, 0}, extent = {{-50, -50}, {50, 50}})));
  Modelica.Electrical.Analog.Basic.Ground ground annotation(
    Placement(transformation(origin = {0, -90}, extent = {{-15, -15}, {15, 15}})));
  Modelica.Electrical.Analog.Sources.RampVoltage ramp(V = 3.3, duration = 1) "tension mesurée par l'ADC (GP0) : rampe de 0 à 3,3 V en 1 s" annotation(
    Placement(transformation(origin = {-110, -30}, extent = {{-15, -15}, {15, 15}}, rotation = -90)));
  Modelica.Electrical.Analog.Basic.Resistor r1(R = 330) "limite le courant de led1 (GP1)" annotation(
    Placement(transformation(origin = {-90, 10}, extent = {{-15, -15}, {15, 15}})));
  MicroPythonMCU.Peripherals.LED led1 "GP1 : auto-contrôle de main.py réussi" annotation(
    Placement(transformation(origin = {-140, 10}, extent = {{-15, 15}, {15, -15}}, rotation = -180)));
equation
  connect(mcu.GND, ground.p) annotation(
    Line(points = {{0, -39}, {0, -75}}, color = {0, 0, 255}));
  connect(ramp.p, mcu.GP0) annotation(
    Line(points = {{-110, -15}, {-110, 25}, {-31, 25}}, color = {0, 0, 255}));
  connect(ramp.n, ground.p) annotation(
    Line(points = {{-110, -45}, {-110, -75}, {0, -75}}, color = {0, 0, 255}));
  connect(mcu.GP1, r1.n) annotation(
    Line(points = {{-31, 10}, {-75, 10}}, color = {0, 0, 255}));
  connect(r1.p, led1.p) annotation(
    Line(points = {{-105, 10}, {-125, 10}}, color = {0, 0, 255}));
  connect(led1.n, ground.p) annotation(
    Line(points = {{-155, 10}, {-165, 10}, {-165, -75}, {0, -75}}, color = {0, 0, 255}));
  annotation(
    Diagram(coordinateSystem(extent = {{-180, -120}, {80, 80}})),
    experiment(StopTime = 1.5, Interval = 0.001, StartTime = 0, Tolerance = 1e-06),
    Documentation(info = "<html>
<p>Scénario de vérification 25 (cf. <code>requirements.md</code>, décision « Système de fichiers ») : le système de fichiers est actif (<code>fsEnabled</code>) et <code>scriptPath</code> est vide, donc le microcontrôleur démarre comme une vraie carte — <code>boot.py</code> puis <code>main.py</code>, lus à la racine de la flash.</p>
<p>À chaque simulation, l'image <code>Resources/FileSystems/datalogger</code> (<code>fsSource</code>) est recopiée dans un nouveau dossier de l'espace de travail (<code>fsWorkspace = \".\"</code> par défaut : le dossier de simulation), nommé <code>mcu_datalogger_&lt;date&gt;_&lt;heure&gt;</code> — son chemin exact est annoncé dans le journal de simulation, au début et à la fin, et l'Explorateur Windows s'ouvre dessus en fin de simulation (<code>fsOpenExplorer</code>). L'image d'origine n'est jamais modifiée : chaque simulation repart du même état et produit les mêmes fichiers.</p>
<ul>
<li><code>boot.py</code> crée le dossier <code>/data</code> ;</li>
<li><code>main.py</code> lit ses réglages dans <code>/config.txt</code>, importe le module <code>Journal</code> depuis <code>/lib</code>, puis enregistre toutes les 100 ms la tension lue par l'ADC sur <code>GP0</code> (rampe de 0 à 3,3 V) dans <code>/data/mesures.csv</code> ;</li>
<li>il se contrôle enfin lui-même (relecture du fichier, <code>os.listdir</code>, <code>os.stat</code>, tentative de sortir de la flash par <code>../..</code>) et allume <code>led1</code> (<code>GP1</code>) si tout est conforme.</li>
</ul>
<p>Pour relancer sur ses propres fichiers : pointer <code>fsSource</code> sur un dossier contenant <code>boot.py</code>/<code>main.py</code>, et éventuellement <code>fsWorkspace</code> sur le dossier où retrouver les copies. Variante avec un script à la place de <code>main.py</code> : <code>Examples.FileSystem.Script</code>.</p>
</html>"));
end Boot;
