within MicroPythonMCU.Internal;

impure function I2cDevice_sync "Point de synchro d'un périphérique I2C esclave : interprète le front de SCL ou de SDA qui vient de se produire, appelle le script aux bons moments, et renvoie l'état de sa sortie SDA"
  input I2cDevice dev;
  input Real currentTime;
  input Boolean sclLevel "Niveau logique lu sur SCL (tension seuillée côté Modelica)";
  input Boolean sdaLevel "Niveau logique lu sur SDA";
  input Real valueIn[Interfaces.I2C_DEV_MAX_VALUES] "Grandeurs venues du modèle, transmises aux gestionnaires du script (argument v)";
  output Real valueOut[Interfaces.I2C_DEV_MAX_VALUES] "Grandeurs rendues par outputs() (maintenues entre deux appels)";
  output Boolean sdaDriveLow "Le périphérique tire SDA à la masse (acquittement, ou bit à 0 d'un octet lu par le maître)";
  output Boolean busy "Une phase adressée à ce périphérique est en cours (témoin d'activité de l'icône)";
  output Integer eventSeq "Incrémenté à chaque phase d'écriture ou de lecture close - déclencheur change(eventSeq)";
  output String lastEvent "Résumé de la dernière phase close, ex. « ecriture 0x3E : 80 01 » (journal)";
  output String line1 "Première ligne rendue par lines() (afficheurs)";
  output String line2 "Seconde ligne rendue par lines()";
  external "C" I2cDevice_sync(dev, currentTime, sclLevel, sdaLevel, valueIn, valueOut, sdaDriveLow, busy, eventSeq, lastEvent, line1, line2) annotation(
    Include = "#include \"I2cDeviceImpl.c\"",
    IncludeDirectory = "modelica://MicroPythonMCU/Resources/Include",
    Library = "python312",
    LibraryDirectory = "modelica://MicroPythonMCU/Resources/Library/win64");
  annotation(
    Documentation(info = "<html>
<p><code>impure</code> : la fonction porte l'état du périphérique — comme <code>UartDevice_sync</code>. Elle n'est appelée que depuis un <code>when</code> déclenché par un front de SCL ou de SDA, jamais sur une évaluation d'essai du solveur.</p>
<p>Rappelée plusieurs fois au même instant avec les mêmes niveaux (itérations d'événements de Modelica), elle ne fait rien : il n'y a pas de nouveau front à interpréter.</p>
</html>"));
end I2cDevice_sync;
