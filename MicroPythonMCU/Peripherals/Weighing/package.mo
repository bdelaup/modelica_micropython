within MicroPythonMCU.Peripherals;
package Weighing "Chaîne de pesée : corps d'épreuve, pont de jauges de déformation, convertisseur HX711"
  extends Modelica.Icons.Package;

  annotation(
    Documentation(info = "<html>
<p>Les maillons d'une balance électronique, de la force à la mesure numérique lue par le microcontrôleur :</p>
<p><code>Force</code> (source standard <code>Modelica.Mechanics.Translational.Sources.Force</code>, le poids) → <code>LoadCell</code> (corps d'épreuve : la force le déforme) → <code>WheatstoneBridge</code> (quatre jauges collées sur le corps d'épreuve : la déformation déséquilibre le pont) → <code>Hx711</code> (amplificateur et convertisseur 24 bits) → <code>MCU</code> (lecture par un driver MicroPython, broches PD_SCK et DOUT).</p>
<p>Exemples : <code>Examples.Weighing.Hx711Read</code> (lectures brutes, gain, veille) et <code>Examples.Weighing.KitchenScale</code> (balance de cuisine complète, écran I2C et bouton de tare).</p>
</html>"));
end Weighing;
