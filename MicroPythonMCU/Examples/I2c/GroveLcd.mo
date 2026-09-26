within MicroPythonMCU.Examples.I2c;

model GroveLcd "Écran Grove LCD RGB piloté par un driver MicroPython du commerce, exécuté sans modification"
  extends Modelica.Icons.Example;
  MCU mcu(scriptPath = Modelica.Utilities.Files.loadResource("modelica://MicroPythonMCU/Resources/Scripts/MCU/i2c_grove_lcd_rgb.py")) "scriptPath = Resources/Scripts/MCU/i2c_grove_lcd_rgb.py - programme principal, qui importe le driver driver_grove_lcd_rgb.py posé à côté ((c) 2019 Christophe Gueneau, tel quel)" annotation(
    Placement(transformation(origin = {-90, 0}, extent = {{-50, -50}, {50, 50}})));
  MicroPythonMCU.Peripherals.I2cGroveLcdRgb lcd "Écran 16x2 à rétroéclairage RGB (JHD1313 à 0x3E, PCA9633 à 0x62), porteur des tirages du bus" annotation(
    Placement(transformation(origin = {50, 0}, extent = {{-50, -50}, {50, 50}})));
  Modelica.Electrical.Analog.Basic.Ground ground annotation(
    Placement(transformation(origin = {-25, -80}, extent = {{-10, -10}, {10, 10}})));
equation
// Brochage du driver : I2C(scl=Pin(4), sda=Pin(5))
  connect(mcu.GP4, lcd.SCL) annotation(
    Line(points = {{-59, 25}, {-35, 25}, {-35, -17}, {-12, -17}}, color = {0, 0, 255}));
  connect(mcu.GP5, lcd.SDA) annotation(
    Line(points = {{-59, 10}, {-45, 10}, {-45, 17}, {-12, 17}}, color = {0, 0, 255}));
  connect(mcu.GND, ground.p) annotation(
    Line(points = {{-90, -39}, {-90, -70}, {-25, -70}}, color = {0, 0, 255}));
  connect(lcd.GND, ground.p) annotation(
    Line(points = {{50, -36}, {50, -70}, {-25, -70}}, color = {0, 0, 255}));
  annotation(
    Diagram(coordinateSystem(extent = {{-160, -100}, {120, 80}})),
    experiment(StopTime = 3.5, Interval = 1e-4),
    Documentation(info = "<html>
<p>Le microcontrôleur exécute un <strong>driver MicroPython existant</strong> pour l'écran <em>Grove - LCD RGB Backlight</em> (<code>Scripts/MCU/driver_grove_lcd_rgb.py</code>, © 2019 Christophe Gueneau), dont la classe <code>GroveLcd_RGB</code> n'a subi <strong>aucune modification</strong>. Comme sur la carte réelle, le driver est un module posé à côté du programme principal (<code>Scripts/MCU/i2c_grove_lcd_rgb.py</code>), qui l'importe par <code>from driver_grove_lcd_rgb import GroveLcd_RGB</code> — importable grâce à <code>mcu.addScriptDirToPath</code>, actif par défaut. Le driver crée son bus par <code>I2C(scl=Pin(4), sda=Pin(5), freq=20000)</code>, initialise l'écran (séquence de <em>function set</em>, allumage, effacement), puis boucle : « hello World » en ligne 1 à partir de la colonne 2, et rétroéclairage rouge, vert, bleu, 500 ms chacun.</p>
<p>C'est la démonstration de la démarche <strong>jumeau numérique</strong> : le même code tourne sur la carte réelle et dans la simulation. Le composant <code>I2cGroveLcdRgb</code> ne connaît pas ce driver ; il émule les deux circuits du module d'après leurs fiches techniques, à partir des octets réellement décodés sur le bus.</p>
<p>À observer pendant la relecture animée : le texte et la couleur de l'icône de <code>lcd</code> ; <code>mcu.GP4.v</code> (SCL) et <code>mcu.GP5.v</code> (SDA), qui montrent les trames à 20 kHz (un caractère = 3 octets, environ 1,5 ms) ; le journal de simulation, qui liste chaque écriture reçue par l'écran avec son adresse et ses octets.</p>
</html>"));
end GroveLcd;
