within MicroPythonMCU.Internal;

partial model PartialUartDevice "Base des appareils série externes : liaison électrique, décodage, deux modes d'émission, grandeurs échangées avec le modèle"
  parameter Interfaces.UartBehaviour comportement = Interfaces.UartBehaviour.Table "Origine du comportement : table de commandes ou script Python" annotation(
    Dialog(group = "Comportement"));
  parameter String scriptPath = "" "Script .py décrivant le comportement du périphérique (mode Script)" annotation(
    Dialog(group = "Comportement", enable = comportement == Interfaces.UartBehaviour.Script, loadSelector(filter = "Fichiers Python (*.py)", caption = "Sélectionner le script du périphérique")));
  // Integer et non Real : un débit série en est un, et l'icône l'affiche alors sans décimale.
  parameter Integer baudrate = 1200 "Débit de la liaison, en bauds" annotation(
    Dialog(group = "Liaison série"));
  parameter String terminator = "\n" "Caractère marquant la fin d'une commande reçue (seul le premier caractère est retenu)" annotation(
    Dialog(group = "Liaison série"));
  parameter Modelica.Units.SI.Time tickPeriod = 0.1 "Période du point de synchro minimal : filet de sécurité, la cadence réelle vient des échéances du moteur" annotation(
    Dialog(group = "Simulation"));

  parameter Boolean respondEnabled = true "Répondre aux commandes reconnues" annotation(
    Dialog(tab = "Table", group = "Requête / réponse", enable = comportement == Interfaces.UartBehaviour.Table));
  parameter String commandTable = "" "Table « CMD=>REPONSE|CMD=>REPONSE » ; « | » et « => » sont réservés. {vN} insère valueIn[N] dans la réponse, {oN} capture un nombre de la commande vers valueOut[N]" annotation(
    Dialog(tab = "Table", group = "Requête / réponse", enable = comportement == Interfaces.UartBehaviour.Table and respondEnabled));
  parameter Modelica.Units.SI.Time responseDelay = 0.002 "Délai entre la reconnaissance d'une commande et le début de la réponse" annotation(
    Dialog(tab = "Table", group = "Requête / réponse", enable = comportement == Interfaces.UartBehaviour.Script or respondEnabled));
  parameter Boolean echoEnabled = false "Renvoyer tel quel chaque octet reçu" annotation(
    Dialog(tab = "Table", group = "Requête / réponse", enable = comportement == Interfaces.UartBehaviour.Table));
  parameter Boolean periodicEnabled = false "Émettre spontanément, sans être sollicité" annotation(
    Dialog(tab = "Table", group = "Émission périodique", enable = comportement == Interfaces.UartBehaviour.Table));
  parameter Modelica.Units.SI.Time period = 1 "Période d'émission spontanée (en mode Script : période d'appel de on_tick)" annotation(
    Dialog(tab = "Table", group = "Émission périodique", enable = comportement == Interfaces.UartBehaviour.Script or periodicEnabled));
  parameter String periodicTemplate = "" "Gabarit de la trame émise périodiquement ({vN} insère valueIn[N])" annotation(
    Dialog(tab = "Table", group = "Émission périodique", enable = comportement == Interfaces.UartBehaviour.Table and periodicEnabled));

  parameter Boolean useValueInput = false "Prendre les grandeurs sur le connecteur valueIn plutôt qu'une constante" annotation(
    Dialog(tab = "Entrées / sorties", group = "Entrées ({vN}, insérées dans les trames émises)"));
  parameter Integer nIn(min = 1, max = Interfaces.UART_DEV_MAX_VALUES) = 1 "Nombre de grandeurs reçues du modèle" annotation(
    Dialog(tab = "Entrées / sorties", group = "Entrées ({vN}, insérées dans les trames émises)", enable = useValueInput));
  parameter Real fixedValue = 0 "Valeur utilisée quand valueIn n'est pas câblé" annotation(
    Dialog(tab = "Entrées / sorties", group = "Entrées ({vN}, insérées dans les trames émises)", enable = not useValueInput));
  parameter Integer nOut(min = 1, max = Interfaces.UART_DEV_MAX_VALUES) = 1 "Nombre de grandeurs rendues au modèle - laisser le connecteur non câblé si inutilisé" annotation(
    Dialog(tab = "Entrées / sorties", group = "Sorties ({oN}, capturées dans les trames reçues)"));
  parameter Real valueOutStart = 0 "Valeur de valueOut avant toute capture" annotation(
    Dialog(tab = "Entrées / sorties", group = "Sorties ({oN}, capturées dans les trames reçues)"));

  parameter Modelica.Units.SI.Voltage VOH = Interfaces.VOH "Tension logique haute" annotation(
    Dialog(tab = "Électrique", group = "Niveaux"));
  parameter Modelica.Units.SI.Voltage VOL = Interfaces.VOL "Tension logique basse" annotation(
    Dialog(tab = "Électrique", group = "Niveaux"));
  parameter Modelica.Units.SI.Voltage VIH = Interfaces.VIH "Seuil de reconnaissance d'une entrée haute" annotation(
    Dialog(tab = "Électrique", group = "Niveaux"));
  parameter Modelica.Units.SI.Voltage VIL = Interfaces.VIL "Seuil de reconnaissance d'une entrée basse" annotation(
    Dialog(tab = "Électrique", group = "Niveaux"));
  parameter Modelica.Units.SI.Resistance ROut = Interfaces.ROut "Résistance série de sortie" annotation(
    Dialog(tab = "Électrique", group = "Impédances"));
  // RPullUp : une entrée débranchée lit ainsi un niveau de repos, et le nœud RX
  // n'est jamais indéterminé quand rien n'y est câblé.
  parameter Modelica.Units.SI.Resistance RPullUp = 1e6 "Tirage de l'entrée RX vers VOH" annotation(
    Dialog(tab = "Électrique", group = "Impédances"));
  // CIn n'est pas cosmétique : elle donne au nœud de réception un état dynamique
  // réel, ce qui rompt la dépendance mutuelle entre le when de cet appareil et
  // celui du microcontrôleur lorsque les deux sens sont câblés — sans elle, le
  // modèle combiné ne se construit pas. Face aux 100 Ω de sortie, la constante de
  // temps vaut 0,1 µs. Détail dans docs/peripheriques-uart-externes.md.
  parameter Modelica.Units.SI.Capacitance CIn = 1e-9 "Capacité d'entrée de la broche RX (broche + câble)" annotation(
    Dialog(tab = "Électrique", group = "Impédances"));

  Modelica.Electrical.Analog.Interfaces.PositivePin TX "Émission du périphérique - à câbler sur la broche de réception du microcontrôleur" annotation(
    Placement(transformation(origin = {-124, 34}, extent = {{-7, -7}, {7, 7}}), iconTransformation(origin = {-124, 34}, extent = {{-7, -7}, {7, 7}})));
  Modelica.Electrical.Analog.Interfaces.PositivePin RX "Réception du périphérique - à câbler sur la broche d'émission du microcontrôleur" annotation(
    Placement(transformation(origin = {-124, -34}, extent = {{-7, -7}, {7, 7}}), iconTransformation(origin = {-124, -34}, extent = {{-7, -7}, {7, 7}})));
  Modelica.Electrical.Analog.Interfaces.NegativePin GND "Référence commune (masse), à relier à celle du microcontrôleur" annotation(
    Placement(transformation(origin = {0, -72}, extent = {{-6, -6}, {6, 6}}), iconTransformation(origin = {0, -72}, extent = {{-6, -6}, {6, 6}})));
  Modelica.Blocks.Interfaces.RealInput valueIn[nIn] if useValueInput "Grandeurs fournies par le modèle, insérées dans les trames émises par {v1}..{vN}" annotation(
    Placement(transformation(origin = {124, 34}, extent = {{10, -10}, {-10, 10}}), iconTransformation(origin = {124, 34}, extent = {{10, -10}, {-10, 10}})));
  Modelica.Blocks.Interfaces.RealOutput valueOut[nOut] "Grandeurs extraites des trames reçues par {o1}..{oN} - le périphérique devient alors un actionneur" annotation(
    Placement(transformation(origin = {124, -34}, extent = {{-10, -10}, {10, 10}}), iconTransformation(origin = {124, -34}, extent = {{-10, -10}, {10, 10}})));

  // Publiques : les variables protected n'apparaissent pas dans les résultats de
  // simulation dans cette installation OpenModelica, ce qui casserait l'animation
  // DynamicSelect de l'icône (cf. requirements.md).
  discrete Boolean txActive(start = false, fixed = true) "Une trame est en cours d'émission";
  discrete Boolean rxBusy(start = false, fixed = true) "Une trame est en cours de réception";
  String lastRx "Dernière ligne complète reçue";
  String lastTx "Dernière charge utile émise";
protected
  constant Integer NV = Interfaces.UART_DEV_MAX_VALUES "Taille fixe attendue par l'interface externe C";
  parameter Modelica.Units.SI.Time bitDur = 1/baudrate "Durée d'un bit - connue côté Modelica, le C n'a pas à la republier";

  Modelica.Blocks.Interfaces.RealInput valueIn_internal[nIn] "Connecteur interne : un connecteur conditionnel ne peut pas être lu directement dans une équation (idiome MSL)";

  discrete Real vOut[NV](each start = 0, each fixed = true) "Grandeurs capturées, telles que publiées par le C";
  Real vIn[NV] "Grandeurs transmises au C, complétées par fixedValue au-delà de nIn";

  discrete Modelica.Units.SI.Time txStart(start = 0, fixed = true) "Instant du front de start de la trame en cours";
  discrete Integer txNumBits(start = 10, fixed = true) "Nombre de bits utiles de la trame (10 en 8N1)";
  discrete Real txBits[Interfaces.UART_MAX_FRAME_BITS](each start = 1, each fixed = true) "Motif de bits déjà sérialisé côté C : Modelica ne fait que le rejouer dans le temps";
  discrete Integer eventSeq(start = 0, fixed = true) "Incrémenté à chaque ligne reçue et à chaque charge utile émise";
  discrete Modelica.Units.SI.Time nextWakeTime(start = 0, fixed = true) "Prochaine échéance demandée par le moteur";

  Real txPhase "Position temporelle dans la trame, en nombre de bits. Vaut -1 (constante) hors trame : floor() ne croise alors jamais rien, donc aucun événement parasite au repos";
  Real txBitIdx "Index du bit en cours d'émission (-1 hors trame)";
  Boolean txLevel "Niveau logique à émettre (repos = haut)";
  Modelica.Units.SI.Voltage rxVoltage "Tension effective sur la broche de réception";
  Boolean rxBoolIn "Valeur logique lue sur RX (tension comparée aux seuils VIL/VIH)";

  // Pont électrique volontairement plus simple que celui du microcontrôleur : les
  // directions sont fixes (TX toujours en sortie, RX toujours en entrée), donc
  // aucun IdealOpeningSwitch — requirements.md documente que les composants
  // Ideal.* commutants cassent la compression des sleep sur longue simulation.
  Modelica.Electrical.Analog.Sources.SignalVoltage src "Source de tension pilotée par le motif de trame (VOH/VOL)" annotation(
    Placement(visible = false, transformation(extent = {{-190, -90}, {-150, -50}})));
  Modelica.Electrical.Analog.Basic.Resistor rOut(R = ROut) "Résistance série de sortie" annotation(
    Placement(visible = false, transformation(extent = {{-130, -90}, {-90, -50}})));
  Modelica.Electrical.Analog.Sensors.VoltageSensor sns "Mesure la tension réellement présente sur RX" annotation(
    Placement(visible = false, transformation(extent = {{-70, -90}, {-30, -50}})));
  Modelica.Electrical.Analog.Sources.ConstantVoltage pullSrc(V = VOH) "Rail du tirage de RX" annotation(
    Placement(visible = false, transformation(extent = {{-10, -90}, {30, -50}})));
  Modelica.Electrical.Analog.Basic.Resistor rPull(R = RPullUp) "Tirage de RX vers VOH" annotation(
    Placement(visible = false, transformation(extent = {{50, -90}, {90, -50}})));
  Modelica.Electrical.Analog.Basic.Capacitor cIn(C = CIn) "Capacité d'entrée de RX - donne au nœud un état dynamique réel, cf. CIn" annotation(
    Placement(visible = false, transformation(extent = {{110, -90}, {150, -50}})));

  Internal.UartDevice dev = Internal.UartDevice(baudrate, commandTable, terminator, responseDelay, respondEnabled, echoEnabled, periodicEnabled, period, periodicTemplate, valueOutStart, Integer(comportement), scriptPath, Modelica.Utilities.Files.loadResource("modelica://MicroPythonMCU/Resources/PythonRuntime"), getInstanceName()) "Moteur du périphérique : files TX/RX, décodage, table de commandes, échéances" annotation(
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

  connect(src.n, GND);
  connect(src.p, rOut.p);
  connect(rOut.n, TX);
  connect(sns.p, RX);
  connect(sns.n, GND);
  connect(pullSrc.n, GND);
  connect(pullSrc.p, rPull.p);
  connect(rPull.n, RX);
  connect(cIn.p, RX);
  connect(cIn.n, GND);

  rxVoltage = sns.v;
  rxBoolIn = rxVoltage > (VIL + VIH)/2 "seuil logique médian, même approximation que le microcontrôleur";
  txPhase = if txActive then (time - txStart)/bitDur else -1.0;
  txBitIdx = floor(txPhase);
  txLevel = Interfaces.uartBitLevel(txBitIdx, txNumBits, txBits) "c'est floor() ci-dessus, pas la fonction, qui engendre l'événement à chaque front de bit";
  src.v = if txLevel then VOH else VOL "la ligne est tenue activement au repos HAUT hors trame, comme une sortie push-pull réelle";

  when {initial(), time >= pre(nextWakeTime), sample(0, tickPeriod), change(rxBoolIn)} then
    (vOut, txActive, txStart, txNumBits, txBits, rxBusy, eventSeq, lastRx, lastTx, nextWakeTime) = Internal.UartDevice_sync(dev, time, rxBoolIn, vIn);
  end when;
  when change(eventSeq) then
    Modelica.Utilities.Streams.print("[" + getInstanceName() + "] t=" + String(time) + " s - reçu: \"" + lastRx + "\" / émis: \"" + lastTx + "\"");
  end when;
  annotation(
    Icon(coordinateSystem(preserveAspectRatio = true, extent = {{-100, -100}, {100, 100}}), graphics = {Rectangle(fillColor = {70, 70, 85}, fillPattern = FillPattern.Solid, extent = {{-104, 56}, {104, -56}}), Text(textColor = {255, 255, 255}, extent = {{-56, 24}, {56, 2}}, textString = "UART", textStyle = {TextStyle.Bold}), Text(textColor = {200, 200, 200}, extent = {{-90, -2}, {90, -20}}, textString = "%baudrate,N,8,1"), Ellipse(fillColor = DynamicSelect({60, 60, 60}, if txActive then {255, 180, 60} else {60, 60, 60}), fillPattern = FillPattern.Solid, lineColor = {30, 30, 30}, extent = {{-98, 42}, {-86, 30}}), Ellipse(fillColor = DynamicSelect({60, 60, 60}, if rxBusy then {60, 210, 255} else {60, 60, 60}), fillPattern = FillPattern.Solid, lineColor = {30, 30, 30}, extent = {{-98, -30}, {-86, -42}}), Text(textColor = {255, 255, 255}, extent = {{-82, 42}, {-52, 28}}, textString = "TX", horizontalAlignment = TextAlignment.Left), Text(textColor = {255, 255, 255}, extent = {{-82, -28}, {-52, -42}}, textString = "RX", horizontalAlignment = TextAlignment.Left), Text(textColor = {255, 255, 255}, extent = {{56, 42}, {98, 28}}, textString = "val", horizontalAlignment = TextAlignment.Right), Text(textColor = {255, 255, 255}, extent = {{56, -28}, {98, -42}}, textString = "out", horizontalAlignment = TextAlignment.Right), Text(extent = {{-25, -60}, {25, -69}}, textString = "GND"), Text(origin = {0, -6}, textColor = {0, 0, 255}, extent = {{-150, 108}, {150, 72}}, textString = "%name")}),
    Diagram(coordinateSystem(preserveAspectRatio = true, extent = {{-100, -100}, {100, 100}})),
    Documentation(info = "<html>
<p>Classe de base des appareils série externes. Elle n'est pas instanciable directement : un appareil concret en hérite et fixe ses paramètres — voir <code>Peripherals.UartEchoDevice</code>, <code>UartTemperatureSensor</code>, <code>UartGpsModule</code>, <code>UartLcd20x2</code>, ou <code>Peripherals.UartGenericDevice</code> pour un appareil entièrement décrit par ses paramètres.</p>
<p>L'appareil est branché <strong>électriquement</strong> sur deux broches <code>GPx</code> d'un <code>MCU</code> : il reçoit de vraies trames 8N1 et en émet de vraies, avec un débit qui lui est propre. Un désaccord de débit avec le microcontrôleur produit donc des octets faux, comme sur un montage réel.</p>
<p><strong>Deux modes d'émission, cumulables</strong>, qui alimentent la même file :</p>
<ul>
<li><em>Requête / réponse</em> : les octets reçus s'accumulent jusqu'à <code>terminator</code>, la ligne complète est confrontée à <code>commandTable</code>, et la réponse part après <code>responseDelay</code>.</li>
<li><em>Périodique</em> : <code>periodicTemplate</code> est émis spontanément toutes les <code>period</code> secondes, sans sollicitation.</li>
</ul>
<p><strong>Grandeurs échangées avec le reste du modèle.</strong> <code>{v1}</code>…<code>{vN}</code> insèrent <code>valueIn</code> dans une trame émise (avec une précision facultative, <code>{v1:.1f}</code>) ; <code>{o1}</code>…<code>{oN}</code>, placés dans une <em>commande</em>, capturent un nombre de la trame reçue vers <code>valueOut</code>. Un même appareil peut donc être capteur et actionneur, ce qui permet de refermer une boucle de régulation à l'intérieur du modèle.</p>
<p>Les deux pastilles de l'icône s'allument pendant une trame émise (ambre) ou reçue (cyan) — visible pendant la lecture animée d'un résultat dans OMEdit, pas sur un rendu statique. Chaque ligne reçue et chaque charge utile émise produisent en outre une ligne dans le journal de simulation, préfixée du nom du composant.</p>
</html>"));
end PartialUartDevice;
