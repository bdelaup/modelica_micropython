within MicroPythonMCU.Interfaces;

function uartBitLevel "Niveau logique à émettre pour le bit d'index bitIdx d'une trame série déjà sérialisée"
  input Real bitIdx "Index du bit en cours d'émission, c'est-à-dire floor(phase) calculé par l'appelant ; < -0.5 = hors trame";
  input Integer numBits "Nombre de bits utiles de la trame (10 en 8N1)";
  input Real bits[UART_MAX_FRAME_BITS] "Motif de bits sérialisé côté C (start + données poids faible en tête + stop), 0.0 ou 1.0";
  output Boolean level "Niveau à émettre sur la ligne ; hors trame et au-delà du dernier bit utile : niveau de repos (haut)";
protected
  Integer idx "Index 1-based dans bits[] ; +1.5 plutôt que +1 pour rester juste même si bitIdx portait une erreur d'arrondi";
algorithm
  idx := integer(bitIdx + 1.5);
  level := if bitIdx < -0.5 or bitIdx > numBits - 0.5 or idx < 1 or idx > UART_MAX_FRAME_BITS then true else bits[idx] > 0.5;
  annotation(
    Documentation(info = "<html>
<p>Sélection du bit courant d'une trame série, factorisée entre l'émission du microcontrôleur (<code>MCU</code>, <code>machine.UART</code>) et celle des périphériques série externes (<code>Internal.PartialUartDevice</code>) — cf. <code>requirements.md</code>, décisions « UART électrique réel » et « Périphériques UART externes ».</p>
<p><strong>L'appelant garde <code>floor()</code> chez lui</strong> : <code>bitIdx</code> doit être calculé par une équation <code>floor(phase)</code> dans le modèle appelant, car c'est <code>floor</code> qui engendre l'événement Modelica à chaque front de bit. Cette fonction ne fait que lire le motif, elle ne crée aucun événement.</p>
<p>Étant une fonction (section <code>algorithm</code>), elle peut indexer <code>bits[]</code> par une variable — ce qu'une équation ne permet pas raisonnablement, d'où la chaîne de <code>if</code>/<code>elseif</code> explicite qu'elle remplace.</p>
</html>"));
end uartBitLevel;
