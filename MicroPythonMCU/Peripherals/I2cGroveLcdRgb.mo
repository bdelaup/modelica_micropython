within MicroPythonMCU.Peripherals;

model I2cGroveLcdRgb "Écran Grove - LCD RGB Backlight (16x2) : contrôleur d'écran JHD1313 à 0x3E et driver de rétroéclairage PCA9633 à 0x62"
  extends Internal.PartialI2cDevice(addresses = "0x3E, 0x62", usePullUp = true, nOut = 4, scriptPath = Modelica.Utilities.Files.loadResource("modelica://MicroPythonMCU/Resources/Scripts/Device/grove_lcd_rgb.py"));
  extends Internal.Lcd16x2RgbIcon;
equation
  when {initial(), change(eventSeq)} then
    lcdLine1 = Internal.StringToCharCodes(line1, 16) "texte visible rendu par lines() du script";
    lcdLine2 = Internal.StringToCharCodes(line2, 16);
  end when;
  backlight = {valueOut[1], valueOut[2], valueOut[3]} "rouge, vert, bleu rendus par outputs() du script";
  annotation(
    Documentation(info = "<html>
<p>Jumeau du module <em>Grove - LCD RGB Backlight</em> de Seeed Studio : un écran caractère 16x2 dont le rétroéclairage change de couleur. Le module porte <strong>deux circuits</strong> sur le même bus I2C, d'où deux adresses pour un seul composant :</p>
<ul>
<li><code>0x3E</code> — <strong>JHD1313</strong>, contrôleur d'écran compatible HD44780 : chaque octet est précédé d'un octet de contrôle (<code>0x80</code> : commande, <code>0x40</code> : caractère). Commandes émulées : effacement, retour au début, mode d'entrée, écran allumé/éteint, décalage, configuration, position d'écriture (ligne 1 à <code>0x00</code>, ligne 2 à <code>0x40</code>).</li>
<li><code>0x62</code> — <strong>PCA9633</strong>, driver de LED à 4 voies : registres <code>MODE1</code>/<code>MODE2</code>, luminosités <code>PWM0</code>–<code>PWM3</code> (bleu, vert, rouge), gradation de groupe, <code>LEDOUT</code> ; pointeur de registre à auto-incrément.</li>
</ul>
<p>Le comportement est entièrement décrit par <code>Resources/Scripts/Device/grove_lcd_rgb.py</code>, qui suit les fiches techniques des deux circuits sans rien savoir du programme qui les pilote : un driver écrit pour le vrai module fonctionne tel quel — voir <code>Examples.I2c.GroveLcd</code>, qui exécute sans modification un driver MicroPython du commerce. Comme le vrai contrôleur, l'écran est <strong>éteint à la mise sous tension</strong> et le rétroéclairage noir : c'est au programme de l'initialiser. Un octet envoyé pendant un effacement (1,52 ms) est ignoré, avec un avertissement dans le journal — sur le vrai module, il serait perdu.</p>
<p>Les résistances de tirage du bus sont activées (<code>usePullUp = true</code>), comme sur le module réel. <code>valueOut</code> : intensités rouge, vert, bleu (0-255) et écran allumé (1/0) ; l'icône en reprend la couleur et affiche les deux lignes visibles pendant la relecture animée d'un résultat dans OMEdit.</p>
<p><em>Note matérielle :</em> les révisions récentes du module (v5) remplacent le PCA9633 par un autre driver de LED, à une autre adresse. Ce composant suit le PCA9633 à <code>0x62</code>, que cible le driver de référence ; l'adresse reste modifiable par <code>addresses</code> (le script traite <code>0x3E</code> comme l'écran et toute autre adresse comme le driver de LED).</p>
</html>"));
end I2cGroveLcdRgb;
