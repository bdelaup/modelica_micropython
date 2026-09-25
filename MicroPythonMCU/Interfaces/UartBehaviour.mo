within MicroPythonMCU.Interfaces;

type UartBehaviour = enumeration(
    Table "Table de commandes (paramétré)",
    Script "Script Python (gestionnaires)")
  "Origine du comportement d'un périphérique série externe (Internal.PartialUartDevice)"
  annotation(
    Documentation(info = "<html>
<p>Sélecteur explicite plutôt qu'une règle de précédence implicite entre <code>commandTable</code> et <code>scriptPath</code> : OMEdit rend une énumération sous forme de liste déroulante, et les <code>Dialog(enable = ...)</code> du modèle grisent le groupe de paramètres devenu hors sujet. L'ambiguïté « les deux sont remplis » ne peut donc pas se produire.</p>
<p><code>Script</code> est déclaré dès maintenant pour figer le dialogue de paramètres et l'interface externe C, mais le choisir lève pour l'instant une erreur explicite — cf. <code>requirements.md</code>, phase 2 de la décision « Périphériques UART externes connectables ».</p>
</html>"));
