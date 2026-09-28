within MicroPythonMCU.Peripherals.Weighing;

model Hx711 "Convertisseur HX711 : amplificateur et CAN 24 bits pour pont de jauges, liaison série PD_SCK/DOUT"
  import Modelica.Units.SI;
  parameter Real rate(unit = "Hz") = 10 "Cadence de conversion (broche RATE du circuit : 10 ou 80 échantillons par seconde)" annotation(
    Dialog(group = "Conversion"));
  parameter SI.Voltage AVDD = 4.3 "Tension d'excitation du pont, sortie E+ (module alimenté en 5 V)" annotation(
    Dialog(group = "Conversion"));
  parameter Real noiseLsb = 0 "Bruit de conversion, écart-type en LSB (0 = mesure parfaite, reproductible)" annotation(
    Dialog(group = "Conversion"));
  parameter Integer seed = 711 "Graine du bruit : même graine, même suite de mesures" annotation(
    Dialog(group = "Conversion", enable = noiseLsb > 0));
  parameter SI.Time tPowerDown = 60e-6 "PD_SCK maintenue haute plus longtemps : mise en veille" annotation(
    Dialog(group = "Chronogramme"));
  parameter SI.Time tUpdate = 10e-6 "Durée pendant laquelle DOUT remonte avant chaque nouvelle donnée, quand la précédente n'a pas été lue" annotation(
    Dialog(group = "Chronogramme"));
  parameter Integer settlingConversions = 4 "Conversions écartées après la mise sous tension ou la sortie de veille (400 ms à 10 échantillons/s)" annotation(
    Dialog(group = "Chronogramme"));
  parameter SI.Voltage VOH = Interfaces.VOH "Niveau haut de DOUT (circuit numérique alimenté en 3,3 V, comme le microcontrôleur)" annotation(
    Dialog(tab = "Électrique", group = "Niveaux"));
  parameter SI.Voltage VOL = Interfaces.VOL "Niveau bas de DOUT" annotation(
    Dialog(tab = "Électrique", group = "Niveaux"));
  parameter SI.Voltage VIH = Interfaces.VIH "Seuil de reconnaissance d'une entrée haute (PD_SCK)" annotation(
    Dialog(tab = "Électrique", group = "Niveaux"));
  parameter SI.Voltage VIL = Interfaces.VIL "Seuil de reconnaissance d'une entrée basse (PD_SCK)" annotation(
    Dialog(tab = "Électrique", group = "Niveaux"));
  parameter SI.Resistance ROut = Interfaces.ROut "Résistance série de la sortie DOUT" annotation(
    Dialog(tab = "Électrique", group = "Impédances"));

  Modelica.Electrical.Analog.Interfaces.PositivePin PD_SCK "Horloge série et commande de veille (broche SCK du module), pilotée par le microcontrôleur" annotation(
    Placement(transformation(origin = {-124, 30}, extent = {{-7, -7}, {7, 7}}), iconTransformation(origin = {-124, 30}, extent = {{-7, -7}, {7, 7}})));
  Modelica.Electrical.Analog.Interfaces.PositivePin DOUT "Données série (broche DT du module), lue par le microcontrôleur" annotation(
    Placement(transformation(origin = {-124, -30}, extent = {{-7, -7}, {7, 7}}), iconTransformation(origin = {-124, -30}, extent = {{-7, -7}, {7, 7}})));
  Modelica.Electrical.Analog.Interfaces.PositivePin E_plus "Excitation du pont (+)" annotation(
    Placement(transformation(origin = {124, 45}, extent = {{-7, -7}, {7, 7}}), iconTransformation(origin = {124, 45}, extent = {{-7, -7}, {7, 7}})));
  Modelica.Electrical.Analog.Interfaces.PositivePin A_plus "Entrée différentielle du canal A (+), depuis S+ du pont" annotation(
    Placement(transformation(origin = {124, 15}, extent = {{-7, -7}, {7, 7}}), iconTransformation(origin = {124, 15}, extent = {{-7, -7}, {7, 7}})));
  Modelica.Electrical.Analog.Interfaces.NegativePin A_minus "Entrée différentielle du canal A (-), depuis S- du pont" annotation(
    Placement(transformation(origin = {124, -15}, extent = {{-7, -7}, {7, 7}}), iconTransformation(origin = {124, -15}, extent = {{-7, -7}, {7, 7}})));
  Modelica.Electrical.Analog.Interfaces.NegativePin E_minus "Excitation du pont (-), reliée à la masse du module" annotation(
    Placement(transformation(origin = {124, -45}, extent = {{-7, -7}, {7, 7}}), iconTransformation(origin = {124, -45}, extent = {{-7, -7}, {7, 7}})));
  Modelica.Electrical.Analog.Interfaces.NegativePin GND "Masse, à relier à celle du microcontrôleur" annotation(
    Placement(transformation(origin = {0, -72}, extent = {{-6, -6}, {6, 6}}), iconTransformation(origin = {0, -72}, extent = {{-6, -6}, {6, 6}})));

  // Publiques : animent l'icône et servent aux vérifications (les variables
  // protected sont absentes des résultats de simulation).
  discrete Integer code(start = 0, fixed = true) "Dernier résultat de conversion (complément à deux, 24 bits)";
  discrete Integer gain(start = 128, fixed = true) "Gain de la conversion en cours (128 ou 64 sur le canal A, 32 sur le canal B)";
  discrete Integer pulses(start = 0, fixed = true) "Impulsions PD_SCK reçues depuis que la donnée est prête";
  discrete Boolean ready(start = false, fixed = true) "Donnée prête, pas encore lue : DOUT est à 0";
  discrete Boolean poweredDown(start = false, fixed = true) "En veille (PD_SCK restée haute plus de tPowerDown)";
  SI.Voltage vIn "Tension différentielle du canal A, A+ - A-";
  SI.Voltage vRef "Tension d'excitation, E+ - E- : référence de la conversion (mesure ratiométrique)";
protected
  // Donne au nœud PD_SCK un état dynamique, ce qui rompt la dépendance mutuelle
  // entre le when de ce composant et celui du microcontrôleur (même rôle que la
  // capacité d'entrée des périphériques série) ; face aux 100 Ω du
  // microcontrôleur, 1 nF donne une montée de 0,1 µs, sans effet sur le chronogramme.
  parameter SI.Capacitance CIn = 1e-9 "Capacité d'entrée de PD_SCK";
  parameter SI.Resistance RPullDown = 1e6 "Tirage de PD_SCK vers la masse : broche débranchée ou microcontrôleur pas encore démarré = niveau bas";
  constant Integer FULL = 16777216 "2^24";
  constant Integer HALF = 8388608 "2^23 : bit de poids fort";

  Boolean sckHigh(start = false, fixed = true) "PD_SCK vue au niveau haut";
  discrete Boolean doutHigh(start = true, fixed = true) "Niveau piloté sur DOUT (repos = haut : pas de donnée prête)";
  discrete Integer shifter(start = 0, fixed = true) "Registre à décalage : le bit de poids fort sort sur DOUT à chaque front montant";
  discrete Integer nextGain(start = 128, fixed = true) "Gain de la conversion suivante, choisi par le nombre d'impulsions (25, 26 ou 27)";
  discrete SI.Time tConv(start = settlingConversions/rate, fixed = true) "Fin de la prochaine conversion";
  discrete SI.Time tSleep(start = 1e300, fixed = true) "Instant de mise en veille si PD_SCK reste haute (1e300 : rien de programmé)";
  discrete Integer rngState[2] "État du générateur de bruit (Xorshift64*)";
  discrete Real noise(start = 0, fixed = true) "Bruit tiré pour la dernière conversion, en LSB";
  discrete Real u(start = 0.5, fixed = true) "Tirage uniforme sur ]0, 1] - variable de travail de l'algorithme";

  Modelica.Electrical.Analog.Sources.ConstantVoltage excitation(V = AVDD) "Excitation du pont, entre E+ et la masse" annotation(
    Placement(visible = false, transformation(extent = {{-10, 60}, {10, 80}})));
  Modelica.Electrical.Analog.Sensors.VoltageSensor inSns "Entrée différentielle A+/A- (impédance infinie)" annotation(
    Placement(visible = false, transformation(extent = {{-10, 30}, {10, 50}})));
  Modelica.Electrical.Analog.Sensors.VoltageSensor refSns "Mesure de l'excitation, référence de la conversion" annotation(
    Placement(visible = false, transformation(extent = {{-10, 0}, {10, 20}})));
  Modelica.Electrical.Analog.Sensors.VoltageSensor sckSns "Niveau de PD_SCK" annotation(
    Placement(visible = false, transformation(extent = {{-10, -30}, {10, -10}})));
  Modelica.Electrical.Analog.Basic.Capacitor cIn(C = CIn, v(start = 0, fixed = true)) "Capacité d'entrée de PD_SCK" annotation(
    Placement(visible = false, transformation(extent = {{-50, -30}, {-30, -10}})));
  Modelica.Electrical.Analog.Basic.Resistor rPull(R = RPullDown) "Tirage de PD_SCK vers la masse" annotation(
    Placement(visible = false, transformation(extent = {{-90, -30}, {-70, -10}})));
  Modelica.Electrical.Analog.Sources.SignalVoltage doutSrc "Sortie push-pull de DOUT" annotation(
    Placement(visible = false, transformation(extent = {{-90, -70}, {-70, -50}})));
  Modelica.Electrical.Analog.Basic.Resistor rOut(R = ROut) "Résistance série de DOUT" annotation(
    Placement(visible = false, transformation(extent = {{-50, -70}, {-30, -50}})));
initial algorithm
  rngState := Modelica.Math.Random.Generators.Xorshift64star.initialState(seed, 0);
equation
  connect(excitation.p, E_plus);
  connect(excitation.n, GND);
  connect(E_minus, GND);
  connect(inSns.p, A_plus);
  connect(inSns.n, A_minus);
  connect(refSns.p, E_plus);
  connect(refSns.n, E_minus);
  connect(sckSns.p, PD_SCK);
  connect(sckSns.n, GND);
  connect(cIn.p, PD_SCK);
  connect(cIn.n, GND);
  connect(rPull.p, PD_SCK);
  connect(rPull.n, GND);
  connect(doutSrc.n, GND);
  connect(doutSrc.p, rOut.p);
  connect(rOut.n, DOUT);
  vIn = inSns.v;
  vRef = refSns.v;
  sckHigh = sckSns.v > (VIL + VIH)/2 "seuil logique médian, même approximation que le microcontrôleur";
  doutSrc.v = if doutHigh then VOH else VOL;
algorithm
  // Une section algorithm (et non des équations) : plusieurs when y
  // affectent les mêmes variables, dans l'ordre où ils sont écrits.

  // Mise à jour du registre de sortie peu avant une nouvelle donnée : si la
  // précédente n'a pas été lue, DOUT remonte brièvement, et son retour à 0
  // signale la nouvelle donnée (front descendant guetté par Pin.irq()).
  when time >= tConv - tUpdate then
    if ready and not poweredDown then
      ready := false;
      doutHigh := true;
    end if;
  end when;

  // Fin de conversion : la mesure est figée dans le registre, DOUT passe à 0.
  // Pas de mise à jour pendant une lecture en cours (bits déjà en train de sortir).
  when time >= tConv then
    if not poweredDown then
      tConv := tConv + 1/rate;
      if pulses == 0 or pulses >= 25 then
        gain := nextGain;
        if noiseLsb > 0 then
          (u, rngState) := Modelica.Math.Random.Generators.Xorshift64star.random(pre(rngState));
          noise := Modelica.Math.Distributions.Normal.quantile(u, 0, noiseLsb);
        end if;
        // Canal B (gain 32) : non câblé dans ce modèle, il lit 0 V.
        code := if gain == 32 then 0 else integer(floor(vIn*gain/vRef*FULL + noise + 0.5));
        code := max(-HALF, min(HALF - 1, code));
        shifter := if code < 0 then code + FULL else code;
        pulses := 0;
        ready := true;
        doutHigh := false;
      end if;
    end if;
  end when;

  // Front montant de PD_SCK : un bit sort sur DOUT (poids fort en tête). Les
  // impulsions 25 à 27 choisissent le gain de la conversion suivante, et DOUT
  // remonte : la donnée est consommée.
  when sckHigh then
    tSleep := time + tPowerDown;
    if not poweredDown and (ready or pulses > 0) and pulses < 27 then
      pulses := pulses + 1;
      if pulses <= 24 then
        doutHigh := shifter >= HALF;
        shifter := mod(shifter*2, FULL);
      else
        ready := false;
        doutHigh := true;
        nextGain := if pulses == 25 then 128 elseif pulses == 26 then 32 else 64;
      end if;
    end if;
  end when;

  // PD_SCK maintenue haute trop longtemps : mise en veille.
  when time >= tSleep then
    if sckHigh then
      poweredDown := true;
      ready := false;
      doutHigh := true;
    end if;
  end when;

  // Front descendant : sortie de veille, le circuit repart comme à la mise
  // sous tension (gain 128, conversions d'établissement écartées).
  when not sckHigh then
    tSleep := 1e300;
    if poweredDown then
      poweredDown := false;
      gain := 128;
      nextGain := 128;
      pulses := 0;
      tConv := time + settlingConversions/rate;
    end if;
  end when;
  annotation(
    Icon(coordinateSystem(preserveAspectRatio = true, extent = {{-100, -100}, {100, 100}}), graphics = {Rectangle(fillColor = {30, 110, 60}, fillPattern = FillPattern.Solid, extent = {{-104, 56}, {104, -56}}), Rectangle(fillColor = {30, 30, 30}, fillPattern = FillPattern.Solid, extent = {{-40, 30}, {40, -12}}), Text(textColor = {255, 255, 255}, extent = {{-38, 26}, {38, 6}}, textString = "HX711", textStyle = {TextStyle.Bold}), Text(textColor = {200, 200, 200}, extent = {{-38, 4}, {38, -10}}, textString = "24 bits"), Text(textColor = {255, 255, 255}, extent = {{-40, -18}, {40, -34}}, textString = DynamicSelect("gain 128", "gain " + String(gain))), Text(textColor = {255, 255, 255}, extent = {{-40, -36}, {40, -52}}, textString = DynamicSelect("", String(code))), Ellipse(fillColor = DynamicSelect({60, 60, 60}, if ready then {60, 210, 255} else {60, 60, 60}), fillPattern = FillPattern.Solid, lineColor = {30, 30, 30}, extent = {{-60, -38}, {-48, -50}}), Ellipse(fillColor = DynamicSelect({60, 60, 60}, if poweredDown then {255, 180, 60} else {60, 60, 60}), fillPattern = FillPattern.Solid, lineColor = {30, 30, 30}, extent = {{48, -38}, {60, -50}}), Text(textColor = {255, 255, 255}, extent = {{-98, 38}, {-66, 22}}, textString = "SCK", horizontalAlignment = TextAlignment.Left), Text(textColor = {255, 255, 255}, extent = {{-98, -22}, {-66, -38}}, textString = "DT", horizontalAlignment = TextAlignment.Left), Text(textColor = {255, 255, 255}, extent = {{66, 53}, {98, 37}}, textString = "E+", horizontalAlignment = TextAlignment.Right), Text(textColor = {255, 255, 255}, extent = {{66, 23}, {98, 7}}, textString = "A+", horizontalAlignment = TextAlignment.Right), Text(textColor = {255, 255, 255}, extent = {{66, -7}, {98, -23}}, textString = "A-", horizontalAlignment = TextAlignment.Right), Text(textColor = {255, 255, 255}, extent = {{66, -37}, {98, -53}}, textString = "E-", horizontalAlignment = TextAlignment.Right), Text(extent = {{-25, -76}, {25, -84}}, textString = "GND"), Line(points = {{-117, 30}, {-104, 30}}, color = {0, 0, 255}), Line(points = {{-117, -30}, {-104, -30}}, color = {0, 0, 255}), Line(points = {{104, 45}, {117, 45}}, color = {0, 0, 255}), Line(points = {{104, 15}, {117, 15}}, color = {0, 0, 255}), Line(points = {{104, -15}, {117, -15}}, color = {0, 0, 255}), Line(points = {{104, -45}, {117, -45}}, color = {0, 0, 255}), Line(points = {{0, -56}, {0, -66}}, color = {0, 0, 255}), Text(textColor = {0, 0, 255}, extent = {{-150, 100}, {150, 64}}, textString = "%name")}),
    Diagram(coordinateSystem(preserveAspectRatio = true, extent = {{-100, -100}, {100, 100}})),
    Documentation(info = "<html>
<p>Le <strong>HX711</strong> (Avia Semiconductor) est le convertisseur des balances électroniques : un amplificateur à gain programmable suivi d'un convertisseur analogique-numérique 24 bits, prévu pour lire directement un pont de jauges. Ce modèle en reproduit le comportement vu du microcontrôleur, d'après la fiche technique.</p>
<h4>Côté pont</h4>
<p>Le module alimente le pont par <code>E+</code>/<code>E−</code> (tension <code>AVDD</code>) et mesure la tension différentielle entre <code>A+</code> et <code>A−</code>. La conversion est <strong>ratiométrique</strong> : le résultat dépend du rapport entre la sortie du pont et son excitation, pas de la valeur de l'alimentation.</p>
<p><code>code = vIn · gain / vRef · 2<sup>24</sup></code>, arrondi et borné à [−2<sup>23</sup>, 2<sup>23</sup>−1] (pleine échelle : ±AVDD/(2·gain), soit ±17 mV à gain 128).</p>
<h4>Côté microcontrôleur</h4>
<ul>
<li>Toutes les <code>1/rate</code> secondes, une nouvelle donnée est prête : <code>DOUT</code> passe à 0. Si la précédente n'a pas été lue, <code>DOUT</code> remonte d'abord brièvement (<code>tUpdate</code>), si bien que chaque nouvelle donnée est annoncée par un front descendant.</li>
<li>Chaque front montant de <code>PD_SCK</code> fait sortir un bit sur <code>DOUT</code>, poids fort en tête. Après les 24 bits de donnée, 1 à 3 impulsions supplémentaires choisissent le gain de la conversion <em>suivante</em> : 25 impulsions → 128 (canal A), 26 → 32 (canal B), 27 → 64 (canal A). <code>DOUT</code> remonte alors à 1.</li>
<li><code>PD_SCK</code> maintenue haute plus de 60 µs met le circuit en veille. Au retour à 0, il repart comme à la mise sous tension : gain 128, et première donnée après 4 conversions (400 ms à 10 échantillons/s).</li>
</ul>
<p>Le microcontrôleur pilote donc <code>PD_SCK</code> bit par bit (<em>bit-banging</em>). Il faut que ses accès aux broches prennent du temps simulé (paramètre <code>MCU.gpioOpTime</code>, 5 µs par défaut) : sans cela, les impulsions auraient une durée nulle.</p>
<h4>Simplifications</h4>
<ul>
<li>Le canal B (entrées B+/B−, gain 32) n'est pas câblé : il lit 0 V.</li>
<li>Chaque conversion est un échantillon instantané de l'entrée (pas de moyennage sur la période), sans temps d'établissement après un changement de gain.</li>
<li>Le bruit (<code>noiseLsb</code>, écart-type en LSB) est gaussien et reproductible : la graine <code>seed</code> fixe la suite des tirages.</li>
</ul>
<p>L'icône affiche le gain et le dernier code converti. Le voyant cyan signale une donnée prête, le voyant ambre la veille.</p>
</html>"));
end Hx711;
