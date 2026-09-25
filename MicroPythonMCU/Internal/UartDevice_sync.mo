within MicroPythonMCU.Internal;

impure function UartDevice_sync "Point de synchro d'un périphérique série externe : fait avancer émission et réception, livre les lignes reçues, arme les émissions, et renvoie la prochaine échéance"
  input UartDevice dev;
  input Real currentTime;
  input Boolean rxLevel "Niveau logique lu sur la broche de réception (tension seuillée côté Modelica)";
  input Real valueIn[Interfaces.UART_DEV_MAX_VALUES] "Grandeurs venues du modèle, substituées par {vN} dans les trames émises";
  output Real valueOut[Interfaces.UART_DEV_MAX_VALUES] "Grandeurs capturées par {oN} dans les trames reçues (maintenues entre deux trames)";
  output Boolean txActive "Une trame est en cours d'émission";
  output Real txStart "Instant du front de start de la trame en cours";
  output Integer txNumBits "Nombre de bits utiles de la trame (10 en 8N1)";
  output Real txBits[Interfaces.UART_MAX_FRAME_BITS] "Motif de bits déjà sérialisé côté C : Modelica n'a qu'à le rejouer dans le temps";
  output Boolean rxBusy "Une trame est en cours de réception (témoin d'activité de l'icône)";
  output Integer eventSeq "Incrémenté à chaque ligne reçue et à chaque charge utile émise - déclencheur d'edge-detection change(eventSeq), motif de Display0.seq";
  output String lastRx "Dernière ligne complète reçue (journal, afficheur)";
  output String lastTx "Dernière charge utile émise (journal)";
  output Real nextWakeTime "Plus proche échéance : fin de trame, échantillon de réception, réponse armée ou tick périodique";
  external "C" UartDevice_sync(dev, currentTime, rxLevel, valueIn, valueOut, txActive, txStart, txNumBits, txBits, rxBusy, eventSeq, lastRx, lastTx, nextWakeTime) annotation(
    Include = "#include \"UartDeviceImpl.c\"",
    IncludeDirectory = "modelica://MicroPythonMCU/Resources/Include",
    Library = "python312",
    LibraryDirectory = "modelica://MicroPythonMCU/Resources/Library/win64");
  annotation(
    Documentation(info = "<html>
<p><code>impure</code> : la fonction porte l'état du périphérique et ne renvoie pas la même chose pour les mêmes arguments — comme <code>PyRuntime_sync</code>. Elle n'est appelée que depuis un <code>when</code>, jamais sur une évaluation d'essai du solveur.</p>
<p>Rappelée plusieurs fois au même instant simulé (Modelica itère sur les événements), elle ne refait rien : toutes ses étapes sont pilotées par échéances ou consomment ce qu'elles traitent.</p>
</html>"));
end UartDevice_sync;
