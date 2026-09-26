within MicroPythonMCU.Peripherals;

model I2cGenericDevice "Périphérique I2C esclave dont tout le comportement vient d'un script Python, sans créer de classe dédiée"
  extends Internal.PartialI2cDevice(scriptPath = Modelica.Utilities.Files.loadResource("modelica://MicroPythonMCU/Resources/Scripts/Device/i2c_generic.py"));
  annotation(
    Documentation(info = "<html>
<p>Le composant à poser dans un schéma quand le périphérique à simuler ne correspond à aucun modèle fourni. Il suffit de régler <code>addresses</code> et de désigner un script : le script par défaut, <code>Resources/Scripts/Device/i2c_generic.py</code>, est un gabarit commenté (un petit banc de registres) à copier et adapter.</p>
<p>Dès que le même périphérique revient dans plusieurs schémas, il vaut mieux en faire une classe : hériter de <code>Internal.PartialI2cDevice</code> et fixer <code>addresses</code>, <code>scriptPath</code> et <code>usePullUp</code> tient en quelques lignes — c'est ainsi que sont écrits <code>I2cEchoDevice</code> et <code>I2cGroveLcdRgb</code>.</p>
</html>"));
end I2cGenericDevice;
