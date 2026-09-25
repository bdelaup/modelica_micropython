within MicroPythonMCU.Internal;

class UartDevice "External Object encapsulant l'état d'un périphérique série externe (files TX/RX, décodage, table de commandes ou script Python, échéances) - cf. requirements.md, décision « Périphériques UART externes connectables »"
  extends ExternalObject;

  function constructor
    input Real baudrate "Débit de la liaison (bauds) - borné à [50, 115200] côté C, garde-fou contre une tempête d'événements Modelica";
    input String commandTable "Table compacte « CMD=>REPONSE|CMD=>REPONSE » ; « | » et « => » sont réservés. {vN} substitue valueIn[N] dans une réponse, {oN} capture un nombre de la commande vers valueOut[N]";
    input String terminator "Caractère de fin de commande ; seul le premier caractère est retenu, ce qui permet de l'écrire \"\\n\" plutôt qu'un code numérique";
    input Real responseDelay "Délai entre la reconnaissance d'une commande et le début de la réponse (s)";
    input Boolean respondEnabled "Répondre aux commandes reconnues dans commandTable (mode Table)";
    input Boolean echoEnabled "Renvoyer tel quel chaque octet reçu (mode Table)";
    input Boolean periodicEnabled "Émettre spontanément periodicTemplate toutes les period secondes (mode Table ; en mode Script, c'est la présence de on_tick() qui en décide)";
    input Real period "Période d'émission spontanée (s)";
    input String periodicTemplate "Gabarit de la trame émise périodiquement ({vN} substitués)";
    input Real valueOutStart "Valeur initiale de valueOut, avant toute capture";
    input Integer mode "1 = table de commandes paramétrée, 2 = script Python";
    input String scriptPath "Chemin du script .py du périphérique (mode 2 uniquement)";
    input String pythonHome "Distribution Python embarquée (Resources/PythonRuntime) - sert à démarrer CPython si aucun microcontrôleur ne l'a encore fait";
    input String instanceName "Nom du composant, préfixé aux print() du script";
    output UartDevice dev;
    external "C" dev = UartDevice_new(baudrate, commandTable, terminator, responseDelay, respondEnabled, echoEnabled, periodicEnabled, period, periodicTemplate, valueOutStart, mode, scriptPath, pythonHome, instanceName) annotation(
      Include = "#include \"UartDeviceImpl.c\"",
      IncludeDirectory = "modelica://MicroPythonMCU/Resources/Include",
      Library = "python312",
      LibraryDirectory = "modelica://MicroPythonMCU/Resources/Library/win64");
  end constructor;

  function destructor
    input UartDevice dev;
    external "C" UartDevice_destroy(dev) annotation(
      Include = "#include \"UartDeviceImpl.c\"",
      IncludeDirectory = "modelica://MicroPythonMCU/Resources/Include",
      Library = "python312",
      LibraryDirectory = "modelica://MicroPythonMCU/Resources/Library/win64");
  end destructor;

  annotation(
    Documentation(info = "<html>
<p>Pas de thread worker, contrairement à <code>Internal.PyRuntime</code> : un périphérique réagit sans jamais se suspendre. En mode Table aucun code Python n'est exécuté ; en mode Script, les gestionnaires du script s'exécutent sur le thread Modelica, dans l'interpréteur partagé avec le microcontrôleur. Le moteur bit/octet est <em>exactement</em> celui du microcontrôleur (<code>Resources/Include/uartcore.c</code>), partagé et non dupliqué.</p>
</html>"));
end UartDevice;
