within MicroPythonMCU.Peripherals;

model I2cEchoDevice "Périphérique I2C de test : relit au maître ce qu'il vient de lui écrire"
  extends Internal.PartialI2cDevice(addresses = "0x42", nOut = 3, scriptPath = Modelica.Utilities.Files.loadResource("modelica://MicroPythonMCU/Resources/Scripts/Device/i2c_echo.py"));
  annotation(
    Icon(graphics = {Text(textColor = {255, 255, 255}, extent = {{-90, -22}, {90, -40}}, textString = "ECHO", textStyle = {TextStyle.Bold})}),
  Documentation(info = "<html>
<p>Le composant de test du bus I2C, pendant de <code>UartEchoDevice</code>. Son script (<code>Resources/Scripts/Device/i2c_echo.py</code>) mémorise les octets de la dernière phase d'écriture et les renvoie tels quels quand le maître lit — plusieurs fois de suite si le maître en demande davantage.</p>
<p>Il sert à valider une chaîne complète avant d'y brancher le périphérique définitif : trames de plusieurs octets, lecture de registre derrière un START répété (<code>readfrom_mem</code>), plusieurs périphériques à des adresses différentes sur le même bus (changer <code>addresses</code>), et fonctionnement avec ou sans résistances de tirage (<code>usePullUp</code>).</p>
<p><code>valueOut</code> : nombre de phases d'écriture reçues, nombre total d'octets reçus, premier octet de la dernière écriture (-1 tant que rien n'a été reçu).</p>
</html>"));
end I2cEchoDevice;
