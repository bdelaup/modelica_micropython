within MicroPythonMCU.Internal;

partial model PartialI2cDevice "Base des périphériques I2C esclaves : liaison électrique en drain ouvert, décodage du bus, comportement décrit par un script Python"
  parameter String addresses = "0x42" "Adresse(s) sur 7 bits auxquelles le périphérique répond, ex. \"0x42\" ou \"0x3E, 0x62\" (au plus 4)" annotation(
    Dialog(group = "Bus I2C"));
  parameter String scriptPath = "" "Script .py décrivant le comportement (on_write / on_read / outputs / lines)" annotation(
    Dialog(group = "Comportement", loadSelector(filter = "Fichiers Python (*.py)", caption = "Sélectionner le script du périphérique")));
  // Désactivé par défaut : un bus n'a besoin que d'UNE paire de tirages, et l'oublier
  // doit se voir (lignes qui restent basses, OSError côté microcontrôleur) - comme
  // sur un montage réel. Les modules du commerce (Grove...) les portent souvent :
  // leur composant l'active alors, et plusieurs paires se mettent en parallèle.
  parameter Boolean usePullUp = false "Porter les résistances de tirage de SDA et SCL vers VOH (au moins un composant du bus doit le faire)" annotation(
    Dialog(group = "Bus I2C"));
  parameter Modelica.Units.SI.Resistance RPullUp = 4700 "Résistance de tirage de chaque ligne" annotation(
    Dialog(group = "Bus I2C", enable = usePullUp));
  parameter Boolean useValueInput = false "Prendre les grandeurs sur le connecteur valueIn plutôt qu'une constante" annotation(
    Dialog(tab = "Entrées / sorties", group = "Entrées (argument v des gestionnaires)"));
  parameter Integer nIn(min = 1, max = Interfaces.I2C_DEV_MAX_VALUES) = 1 "Nombre de grandeurs reçues du modèle" annotation(
    Dialog(tab = "Entrées / sorties", group = "Entrées (argument v des gestionnaires)", enable = useValueInput));
  parameter Real fixedValue = 0 "Valeur utilisée quand valueIn n'est pas câblé" annotation(
    Dialog(tab = "Entrées / sorties", group = "Entrées (argument v des gestionnaires)", enable = not useValueInput));
  parameter Integer nOut(min = 1, max = Interfaces.I2C_DEV_MAX_VALUES) = 1 "Nombre de grandeurs rendues au modèle par outputs() - laisser le connecteur non câblé si inutilisé" annotation(
    Dialog(tab = "Entrées / sorties", group = "Sorties (valeur de retour de outputs())"));
  parameter Modelica.Units.SI.Voltage VOH = Interfaces.VOH "Tension d'alimentation des tirages" annotation(
    Dialog(tab = "Électrique", group = "Niveaux"));
  parameter Modelica.Units.SI.Voltage VIH = Interfaces.VIH "Seuil de reconnaissance d'une entrée haute" annotation(
    Dialog(tab = "Électrique", group = "Niveaux"));
  parameter Modelica.Units.SI.Voltage VIL = Interfaces.VIL "Seuil de reconnaissance d'une entrée basse" annotation(
    Dialog(tab = "Électrique", group = "Niveaux"));
  parameter Modelica.Units.SI.Resistance ROut = Interfaces.ROut "Résistance du transistor de sortie de SDA quand il tire la ligne à la masse" annotation(
    Dialog(tab = "Électrique", group = "Impédances"));
  parameter Modelica.Units.SI.Conductance GOff = 1e-9 "Fuite du transistor de sortie de SDA bloqué (ligne relâchée)" annotation(
    Dialog(tab = "Électrique", group = "Impédances"));
  // CIn n'est pas cosmétique : elle donne à SDA et SCL un état dynamique réel, ce qui
  // rompt la dépendance entre le when de ce périphérique et celui du microcontrôleur
  // (même rôle que CIn côté UART). Face aux tirages, elle fixe aussi le temps de
  // montée des lignes : 4,7 kΩ x 10 pF = 47 ns, loin du quart de période à 400 kHz
  // (625 ns). Augmenter CIn ou RPullUp dégrade les fronts comme sur un vrai bus.
  parameter Modelica.Units.SI.Capacitance CIn = 10e-12 "Capacité d'entrée de chaque broche (SDA, SCL)" annotation(
    Dialog(tab = "Électrique", group = "Impédances"));
  Modelica.Electrical.Analog.Interfaces.PositivePin SDA "Données du bus I2C - à câbler sur la broche SDA du microcontrôleur et des autres périphériques" annotation(
    Placement(transformation(origin = {-124, 34}, extent = {{-7, -7}, {7, 7}}), iconTransformation(origin = {-124, 34}, extent = {{-7, -7}, {7, 7}})));
  Modelica.Electrical.Analog.Interfaces.PositivePin SCL "Horloge du bus I2C - à câbler sur la broche SCL du microcontrôleur et des autres périphériques" annotation(
    Placement(transformation(origin = {-124, -34}, extent = {{-7, -7}, {7, 7}}), iconTransformation(origin = {-124, -34}, extent = {{-7, -7}, {7, 7}})));
  Modelica.Electrical.Analog.Interfaces.NegativePin GND "Référence commune (masse), à relier à celle du microcontrôleur" annotation(
    Placement(transformation(origin = {0, -72}, extent = {{-6, -6}, {6, 6}}), iconTransformation(origin = {0, -72}, extent = {{-6, -6}, {6, 6}})));
  Modelica.Blocks.Interfaces.RealInput valueIn[nIn] if useValueInput "Grandeurs fournies par le modèle, transmises aux gestionnaires du script (argument v)" annotation(
    Placement(transformation(origin = {124, 34}, extent = {{10, -10}, {-10, 10}}), iconTransformation(origin = {124, 34}, extent = {{10, -10}, {-10, 10}})));
  Modelica.Blocks.Interfaces.RealOutput valueOut[nOut] "Grandeurs rendues par outputs() - le périphérique devient alors un actionneur" annotation(
    Placement(transformation(origin = {124, -34}, extent = {{-10, -10}, {10, 10}}), iconTransformation(origin = {124, -34}, extent = {{-10, -10}, {10, 10}})));
  // Publiques : les variables protected n'apparaissent pas dans les résultats de
  // simulation dans cette installation OpenModelica, ce qui casserait l'animation
  // DynamicSelect de l'icône (cf. requirements.md).
  discrete Boolean sdaDriveLow(start = false, fixed = true) "Le périphérique tire SDA à la masse (acquittement, ou bit à 0 lu par le maître)";
  discrete Boolean busy(start = false, fixed = true) "Une phase adressée à ce périphérique est en cours";
  discrete Integer eventSeq(start = 0, fixed = true) "Incrémenté à chaque phase d'écriture ou de lecture close";
  String lastEvent "Résumé de la dernière phase close (journal)";
  String line1 "Première ligne de texte rendue par lines() (afficheurs)";
  String line2 "Seconde ligne de texte rendue par lines()";
protected
  constant Integer NV = Interfaces.I2C_DEV_MAX_VALUES "Taille fixe attendue par l'interface externe C";
  Modelica.Blocks.Interfaces.RealInput valueIn_internal[nIn] "Connecteur interne : un connecteur conditionnel ne peut pas être lu directement dans une équation (idiome MSL)";
  discrete Real vOut[NV](each start = 0, each fixed = true) "Grandeurs publiées par le C (outputs())";
  Real vIn[NV] "Grandeurs transmises au C, complétées par fixedValue au-delà de nIn";
  Boolean sclBool "Valeur logique lue sur SCL";
  Boolean sdaBool "Valeur logique lue sur SDA";
  // Pont électrique en drain ouvert. Pas de composant Ideal.* commutant : la sortie
  // SDA est une conductance variable (ROut ou GOff), cf. le piège des Ideal.* laissés
  // longtemps dans un état non sollicité (requirements.md). SCL n'a pas de sortie :
  // le périphérique ne l'étire jamais (pas de clock stretching en v0).
  Modelica.Electrical.Analog.Basic.VariableConductor sdaOut "Transistor de sortie de SDA : ROut quand il tire la ligne, GOff sinon" annotation(
    Placement(visible = false, transformation(extent = {{-190, -90}, {-150, -50}})));
  Modelica.Electrical.Analog.Sensors.VoltageSensor sdaSns "Tension réellement présente sur SDA" annotation(
    Placement(visible = false, transformation(extent = {{-130, -90}, {-90, -50}})));
  Modelica.Electrical.Analog.Sensors.VoltageSensor sclSns "Tension réellement présente sur SCL" annotation(
    Placement(visible = false, transformation(extent = {{-70, -90}, {-30, -50}})));
  Modelica.Electrical.Analog.Basic.Capacitor cSda(C = CIn) "Capacité d'entrée de SDA - donne au nœud un état dynamique réel, cf. CIn" annotation(
    Placement(visible = false, transformation(extent = {{-10, -90}, {30, -50}})));
  Modelica.Electrical.Analog.Basic.Capacitor cScl(C = CIn) "Capacité d'entrée de SCL" annotation(
    Placement(visible = false, transformation(extent = {{50, -90}, {90, -50}})));
  Modelica.Electrical.Analog.Sources.ConstantVoltage pullSrc(V = VOH) if usePullUp "Rail des tirages" annotation(
    Placement(visible = false, transformation(extent = {{110, -90}, {150, -50}})));
  Modelica.Electrical.Analog.Basic.Resistor rPullSda(R = RPullUp) if usePullUp "Tirage de SDA vers VOH" annotation(
    Placement(visible = false, transformation(extent = {{110, -130}, {150, -90}})));
  Modelica.Electrical.Analog.Basic.Resistor rPullScl(R = RPullUp) if usePullUp "Tirage de SCL vers VOH" annotation(
    Placement(visible = false, transformation(extent = {{50, -130}, {90, -90}})));
  Internal.I2cDevice dev = Internal.I2cDevice(addresses, scriptPath, Modelica.Utilities.Files.loadResource("modelica://MicroPythonMCU/Resources/PythonRuntime"), getInstanceName()) "Moteur du périphérique : décodage du bus, script Python" annotation(
    Placement(visible = false, transformation(extent = {{-20, 75}, {20, 95}})));
public
equation
  connect(valueIn, valueIn_internal);
  if not useValueInput then
    valueIn_internal = fill(fixedValue, nIn) "sans cette équation, le connecteur interne serait indéterminé quand valueIn n'est pas câblé";
  end if;
  for k in 1:NV loop
    vIn[k] = if k <= nIn then valueIn_internal[k] else fixedValue;
  end for;
  for k in 1:nOut loop
    valueOut[k] = vOut[k];
  end for;
  connect(sdaOut.p, SDA);
  connect(sdaOut.n, GND);
  connect(sdaSns.p, SDA);
  connect(sdaSns.n, GND);
  connect(sclSns.p, SCL);
  connect(sclSns.n, GND);
  connect(cSda.p, SDA);
  connect(cSda.n, GND);
  connect(cScl.p, SCL);
  connect(cScl.n, GND);
  connect(pullSrc.n, GND);
  connect(pullSrc.p, rPullSda.p);
  connect(rPullSda.n, SDA);
  connect(pullSrc.p, rPullScl.p);
  connect(rPullScl.n, SCL);
  sdaOut.G = if sdaDriveLow then 1/ROut else GOff;
  sclBool = sclSns.v > (VIL + VIH)/2 "seuil logique médian, même approximation que le microcontrôleur";
  sdaBool = sdaSns.v > (VIL + VIH)/2;
  when {initial(), change(sclBool), change(sdaBool)} then
    (vOut, sdaDriveLow, busy, eventSeq, lastEvent, line1, line2) = Internal.I2cDevice_sync(dev, time, sclBool, sdaBool, vIn);
  end when;
  when change(eventSeq) then
    Modelica.Utilities.Streams.print("[" + getInstanceName() + "] t=" + String(time) + " s - " + lastEvent);
  end when;
  annotation(
    Icon(coordinateSystem(preserveAspectRatio = true, extent = {{-100, -100}, {100, 100}}), graphics = {Rectangle(fillColor = {50, 80, 95}, fillPattern = FillPattern.Solid, extent = {{-104, 56}, {104, -56}}), Text(textColor = {255, 255, 255}, extent = {{-56, 24}, {56, 2}}, textString = "I2C", textStyle = {TextStyle.Bold}), Text(textColor = {200, 220, 230}, extent = {{-90, -2}, {90, -20}}, textString = "%addresses"), Ellipse(fillColor = DynamicSelect({60, 60, 60}, if busy then {60, 210, 255} else {60, 60, 60}), fillPattern = FillPattern.Solid, lineColor = {30, 30, 30}, extent = {{86, 52}, {98, 40}}), Ellipse(fillColor = DynamicSelect({60, 60, 60}, if sdaDriveLow then {255, 180, 60} else {60, 60, 60}), fillPattern = FillPattern.Solid, lineColor = {30, 30, 30}, extent = {{-98, 52}, {-86, 40}}), Text(textColor = {255, 255, 255}, extent = {{-94, 40}, {-52, 26}}, textString = "SDA", horizontalAlignment = TextAlignment.Left), Text(textColor = {255, 255, 255}, extent = {{-94, -26}, {-52, -40}}, textString = "SCL", horizontalAlignment = TextAlignment.Left), Text(textColor = {255, 255, 255}, extent = {{56, 42}, {98, 28}}, textString = "val", horizontalAlignment = TextAlignment.Right), Text(textColor = {255, 255, 255}, extent = {{56, -28}, {98, -42}}, textString = "out", horizontalAlignment = TextAlignment.Right), Text(extent = {{-25, -60}, {25, -69}}, textString = "GND"), Text(origin = {0, -6}, textColor = {0, 0, 255}, extent = {{-150, 108}, {150, 72}}, textString = "%name")}),
    Diagram(coordinateSystem(preserveAspectRatio = true, extent = {{-100, -100}, {100, 100}})),
    Documentation(info = "<html>
<p>Classe de base des périphériques I2C esclaves. Elle n'est pas instanciable directement : un périphérique concret en hérite et fixe ses paramètres — voir <code>Peripherals.I2cEchoDevice</code>, <code>Peripherals.I2cGroveLcdRgb</code>, ou <code>Peripherals.I2cGenericDevice</code> pour partir d'un gabarit de script.</p>
<p><strong>Électrique.</strong> Le périphérique est branché sur un vrai bus <code>SDA</code>/<code>SCL</code> en <em>drain ouvert</em> : il ne sait que tirer SDA à la masse ou la relâcher. Plusieurs périphériques et le microcontrôleur se partagent les deux mêmes fils ; le « ET câblé » du bus découle simplement des lois de Kirchhoff. Les lignes ne remontent que grâce aux <strong>résistances de tirage</strong> : il en faut au moins une paire sur le bus, portée par un composant dont <code>usePullUp = true</code>. Sans elles, les lignes restent basses et le microcontrôleur lève <code>OSError(ETIMEDOUT)</code>, comme sur un montage réel.</p>
<p><strong>Comportement : uniquement un script Python</strong>, au niveau <em>transaction</em> — le script ne voit ni les bits, ni les START/STOP, ni les acquittements :</p>
<ul>
<li><code>on_write(addr, data, t, v)</code> : une phase d'écriture qui lui était adressée vient de se clore (STOP ou START répété) ; <code>data</code> contient tous les octets reçus.</li>
<li><code>on_read(addr, t, v)</code> : le maître commence à lire ; rendre les octets à lui envoyer (<code>bytes</code>, <code>str</code>, liste d'entiers ou entier). Ils sortent un par un ; si le maître en demande davantage, <code>on_read()</code> est rappelée.</li>
<li><code>outputs()</code> : relue après chaque gestionnaire, alimente <code>valueOut</code>.</li>
<li><code>lines()</code> : facultative, relue après chaque gestionnaire, alimente <code>line1</code>/<code>line2</code> (afficheurs).</li>
</ul>
<p>Le composant acquitte automatiquement toute adresse de la liste <code>addresses</code> et tout octet écrit. Il ne répond pas aux autres adresses : c'est ce qui permet de brancher plusieurs périphériques sur le même bus.</p>
<p>Les deux pastilles de l'icône s'allument quand le périphérique tire SDA (ambre) et pendant une phase qui lui est adressée (cyan) — visible pendant la lecture animée d'un résultat dans OMEdit. Chaque phase close produit une ligne dans le journal de simulation, préfixée du nom du composant.</p>
</html>"));
end PartialI2cDevice;
