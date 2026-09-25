within MicroPythonMCU.Peripherals;

model Display "Afficheur pédagogique 20x2 : texte reçu affiché sur l'icône (défilement 2 lignes) et dans le journal"
  // Porte l'icône 20x2 et les deux tableaux de codes ASCII, partagés avec Peripherals.UartLcd20x2.
  extends Internal.TwoLineTextIcon;
  Interfaces.DisplayLinkInput displayLink "A câbler sur MCU.Display0 (connect(mcu.Display0, display.displayLink))" annotation(
    Placement(transformation(origin = {-108, 0}, extent = {{-8, -8}, {8, 8}})));
equation
  when {initial(), change(displayLink.seq)} then
    line2CharCode = pre(line1CharCode) "l'ancienne ligne 1 (message precedent) devient la ligne 2";
    line1CharCode = displayLink.charCode "le nouveau message occupe la ligne 1";
    Modelica.Utilities.Streams.print("[DISPLAY] t=" + String(time) + " s - affichage reçoit : \"" + displayLink.payload + "\"");
  end when;
  annotation(
    Icon(coordinateSystem(preserveAspectRatio = true, extent = {{-100, -100}, {100, 100}}), graphics = {Text(extent = {{-150, -62}, {150, -92}}, textColor = {0, 0, 255}, textString = "%name")}),
    Diagram(coordinateSystem(preserveAspectRatio = true, extent = {{-100, -100}, {100, 100}})),
    Documentation(info = "<html>
<p>Périphérique d'affichage pédagogique, fidèle à un afficheur caractère 20×2 : à câbler via <code>connect(mcu.Display0, display.displayLink)</code> (connecteur logique causal <code>Interfaces.DisplayLinkInput</code>, pas électrique - cf. <code>requirements.md</code>, décision « Périphérique d'affichage pédagogique »). Optionnel : à brancher ou non dans un circuit selon le besoin pédagogique, comme n'importe quel autre périphérique de <code>Peripherals</code>.</p>
<p>Comportement à chaque réception (<code>change(displayLink.seq)</code>) : (a) une ligne dans le journal de simulation via <code>Modelica.Utilities.Streams.print</code>, avec le texte reçu et l'horodatage ; (b) <b>défilement à deux lignes</b> : l'ancien contenu de la ligne 1 (<code>pre(displayLink.charCode)</code>, capturé juste avant la mise à jour) devient la ligne 2 (<code>line2CharCode</code>), et le nouveau message occupe la ligne 1 (<code>displayLink.charCode</code>, affiché directement) - comme un vrai afficheur qui décale son historique. Écran fixe vert clair (pas de variation lumineuse : le texte lui-même suffit à indiquer l'activité, cf. décision utilisateur).</p>
<p><b>Comment le texte contourne la limitation des <code>String</code></b> : une variable <code>String</code> n'est jamais écrite dans les résultats de simulation (<code>.mat</code>/<code>.csv</code>, vérifié empiriquement lors de ce chantier), donc un <code>DynamicSelect</code> directement sur <code>payload</code> ne pourrait jamais s'animer. Contournement : <code>Internal.StringToCharCodes</code> (fonction <code>external \"C\"</code> partagée, indépendante de <code>PyRuntime</code>) convertit chaque <code>payload</code> en un tableau <code>Integer charCode[Interfaces.DISPLAY_COLS]</code> (codes ASCII, complété par des espaces) — un <code>Integer</code>, contrairement à un <code>String</code>, EST stocké dans les résultats comme n'importe quelle autre grandeur numérique. Chaque colonne de l'icône (20 par ligne, 2 lignes) reconstruit son caractère via un <code>if/elseif</code> sur son <code>charCode[i]</code> (même principe qu'une interpolation de couleur par <code>DynamicSelect</code>, appliqué à une <code>String</code> plutôt qu'à un <code>Integer[3]</code> RGB). Comparaison par <b>tolérance</b> (<code>abs(charCode[i] - code) &lt; 0.5</code>) plutôt qu'égalité exacte (<code>==</code>) : la relecture/le défilement temporel dans OMEdit reconstruit la valeur par interpolation d'une trajectoire stockée en double précision (même un <code>Integer</code> du modèle est stocké comme un nombre à virgule flottante dans le <code>.mat</code>) — une égalité exacte contre une valeur bruitée de quelques 1e-6 autour de l'entier attendu échouait par intermittence, causant un scintillement visible même sur un message stable ; la tolérance absorbe ce bruit sans ambiguïté puisque les codes ASCII sont toujours espacés d'au moins 1. Jeu de caractères supporté : espace, chiffres, lettres majuscules/minuscules, ponctuation courante (<code>! ' , - . ?</code>) — un caractère hors de cet ensemble s'affiche comme un espace. <code>Interfaces.DISPLAY_COLS</code> (20) : au-delà, le message est tronqué sur l'icône uniquement (le texte complet reste disponible intégralement dans le journal de simulation).</p>
</html>"));
end Display;

