within MicroPythonMCU;
package Interfaces "Niveaux de tension logiques de référence (approximation RP2040, 3.3 V) utilisés par le pont électrique de MCU"
  extends Modelica.Icons.Package;

  constant Modelica.Units.SI.Voltage VOH = 3.3 "Tension de sortie logique haute";
  constant Modelica.Units.SI.Voltage VOL = 0.0 "Tension de sortie logique basse";
  constant Modelica.Units.SI.Voltage VIH = 2.0 "Seuil de reconnaissance d'une entrée logique haute (approximation)";
  constant Modelica.Units.SI.Voltage VIL = 0.8 "Seuil de reconnaissance d'une entrée logique basse (approximation)";
  constant Modelica.Units.SI.Resistance ROut = 100 "Résistance série de sortie par défaut (drive strength approximative)";
  constant Integer DISPLAY_COLS = 20 "Nombre de colonnes affichées sur l'icône du périphérique pédagogique Peripherals.Display (fidèle à un vrai afficheur caractère 20x2) - tronque les messages plus longs sur l'icône uniquement (le texte complet reste disponible dans le journal de simulation)";
  constant Integer UART_MAX_FRAME_BITS = 13 "Taille du motif de bits d'une trame série transmis par PyRuntime_sync (1 start + 9 data + 1 parité + 2 stop) - doit rester aligné sur UART_MAX_FRAME_BITS côté C (PyRuntimeImpl.c). Seul le format 8N1 (10 bits utiles) est émis en v0, cf. machine.UART";

  annotation(
    Documentation(info = "<html>
<p>Valeurs approximatives inspirées du Raspberry Pi Pico (RP2040, alimentation 3.3 V). Pas des valeurs datasheet exactes — suffisant pour la v0 (preuve de concept), à affiner si besoin plus tard.</p>
</html>"));
end Interfaces;
