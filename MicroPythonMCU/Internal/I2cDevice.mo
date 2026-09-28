within MicroPythonMCU.Internal;

class I2cDevice "External Object wrapping the state of an I2C slave peripheral (bus decoding, Python script) - see requirements.md, decision \"Bus I2C électrique en drain ouvert\""
  extends ExternalObject;

  function constructor
    input String addresses "7-bit address(es), e.g. \"0x42\" or \"0x3E, 0x62\" - hexadecimal or decimal, at most 4 (Modelica has no hexadecimal literals, hence a string)";
    input String scriptPath "Path of the .py script describing the behaviour of the peripheral (on_write / on_read / outputs / lines)";
    input String pythonHome "Embedded Python distribution (Resources/PythonRuntime) - used to start CPython if no other component has done it yet";
    input String instanceName "Component name, prefixed to the script's print() output";
    output I2cDevice dev;
    // Library annotation: -lwinpthread links winpthread dynamically, otherwise ModelicaError crashes
    // the simulation under OpenModelica/Windows (see requirements.md, decision
    // "Comportement en cas d'exception non geree dans le script").
    external "C" dev = I2cDevice_new(addresses, scriptPath, pythonHome, instanceName) annotation(
      Include = "#include \"I2cDeviceImpl.c\"",
      Library = "-lwinpthread",
      IncludeDirectory = "modelica://MicroPythonMCU/Resources/Include");
  end constructor;

  function destructor
    input I2cDevice dev;
    external "C" I2cDevice_destroy(dev) annotation(
      Include = "#include \"I2cDeviceImpl.c\"",
      Library = "-lwinpthread",
      IncludeDirectory = "modelica://MicroPythonMCU/Resources/Include");
  end destructor;

  annotation(
    Documentation(info = "<html>
<p>No worker thread, like <code>Internal.UartDevice</code>: a peripheral reacts without ever suspending itself. Its Python handlers run on the Modelica thread, in the interpreter shared with the microcontroller, each one in its own namespace (<code>Resources/Include/devscript.c</code>, shared with the serial devices).</p>
</html>"));
end I2cDevice;
