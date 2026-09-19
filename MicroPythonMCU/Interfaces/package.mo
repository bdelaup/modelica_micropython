within MicroPythonMCU;
package Interfaces "Niveaux de tension logiques de référence (approximation RP2040, 3.3 V) utilisés par le pont électrique de MCU"
  extends Modelica.Icons.Package;

  constant Modelica.Units.SI.Voltage VOH = 3.3 "Tension de sortie logique haute";
  constant Modelica.Units.SI.Voltage VOL = 0.0 "Tension de sortie logique basse";
  constant Modelica.Units.SI.Voltage VIH = 2.0 "Seuil de reconnaissance d'une entrée logique haute (approximation)";
  constant Modelica.Units.SI.Voltage VIL = 0.8 "Seuil de reconnaissance d'une entrée logique basse (approximation)";
  constant Modelica.Units.SI.Resistance ROut = 100 "Résistance série de sortie par défaut (drive strength approximative)";

  annotation(
    Documentation(info = "<html>
<p>Valeurs approximatives inspirées du Raspberry Pi Pico (RP2040, alimentation 3.3 V). Pas des valeurs datasheet exactes — suffisant pour la v0 (preuve de concept), à affiner si besoin plus tard.</p>
</html>"));
end Interfaces;
