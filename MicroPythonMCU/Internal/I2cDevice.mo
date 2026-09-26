within MicroPythonMCU.Internal;

class I2cDevice "External Object encapsulant l'état d'un périphérique I2C esclave (décodage du bus, script Python) - cf. requirements.md, décision « Bus I2C électrique en drain ouvert »"
  extends ExternalObject;

  function constructor
    input String addresses "Adresse(s) sur 7 bits, ex. \"0x42\" ou \"0x3E, 0x62\" - hexadécimal ou décimal, au plus 4 (Modelica n'a pas de littéraux hexadécimaux, d'où une chaîne)";
    input String scriptPath "Chemin du script .py qui décrit le comportement du périphérique (on_write / on_read / outputs / lines)";
    input String pythonHome "Distribution Python embarquée (Resources/PythonRuntime) - sert à démarrer CPython si aucun autre composant ne l'a encore fait";
    input String instanceName "Nom du composant, préfixé aux print() du script";
    output I2cDevice dev;
    external "C" dev = I2cDevice_new(addresses, scriptPath, pythonHome, instanceName) annotation(
      Include = "#include \"I2cDeviceImpl.c\"",
      IncludeDirectory = "modelica://MicroPythonMCU/Resources/Include",
      Library = "python312",
      LibraryDirectory = "modelica://MicroPythonMCU/Resources/Library/win64");
  end constructor;

  function destructor
    input I2cDevice dev;
    external "C" I2cDevice_destroy(dev) annotation(
      Include = "#include \"I2cDeviceImpl.c\"",
      IncludeDirectory = "modelica://MicroPythonMCU/Resources/Include",
      Library = "python312",
      LibraryDirectory = "modelica://MicroPythonMCU/Resources/Library/win64");
  end destructor;

  annotation(
    Documentation(info = "<html>
<p>Pas de thread worker, comme <code>Internal.UartDevice</code> : un périphérique réagit sans jamais se suspendre. Ses gestionnaires Python s'exécutent sur le thread Modelica, dans l'interpréteur partagé avec le microcontrôleur, chacun dans un espace de noms qui lui est propre (<code>Resources/Include/devscript.c</code>, partagé avec les périphériques série).</p>
</html>"));
end I2cDevice;
