within MicroPythonMCU.Internal;

class UartDevice "External Object wrapping the state of an external serial device (TX/RX queues, decoding, command table or Python script, deadlines) - see requirements.md, decision \"Périphériques UART externes connectables\""
  extends ExternalObject;

  function constructor
    input Real baudrate "Link speed (baud) - clamped to [50, 115200] on the C side, a safeguard against a storm of Modelica events";
    input Integer dataBits "Number of data bits (5 to 8)";
    input Integer parity "Parity, machine.UART convention: -1 = none, 0 = even, 1 = odd";
    input Integer stopBits "Number of stop bits (1 or 2)";
    input String commandTable "Compact table \"CMD=>REPLY|CMD=>REPLY\"; \"|\" and \"=>\" are reserved. {vN} substitutes valueIn[N] in a reply, {oN} captures a number of the command into valueOut[N]";
    input String terminator "End-of-command character; only the first character is kept, so that it can be written \"\\n\" rather than as a numeric code";
    input Real responseDelay "Delay between the recognition of a command and the start of the reply (s)";
    input Boolean respondEnabled "Reply to the commands recognised in commandTable (Table mode)";
    input Boolean echoEnabled "Send back every received byte unchanged (Table mode)";
    input Boolean periodicEnabled "Spontaneously transmit periodicTemplate every period seconds (Table mode; in Script mode, the presence of on_tick() decides)";
    input Real period "Period of the spontaneous transmission (s)";
    input String periodicTemplate "Template of the periodically transmitted frame ({vN} substituted)";
    input Real valueOutStart "Initial value of valueOut, before any capture";
    input Integer mode "1 = command table set by parameters, 2 = Python script";
    input String scriptPath "Path of the device's .py script (mode 2 only)";
    input String pythonHome "Embedded Python distribution (Resources/PythonRuntime) - used to start CPython if no microcontroller has done it yet";
    input String instanceName "Component name, prefixed to the script's print() output";
    output UartDevice dev;
    // Library annotation: -lwinpthread links winpthread dynamically, otherwise ModelicaError crashes
    // the simulation under OpenModelica/Windows (see requirements.md, decision
    // "Comportement en cas d'exception non geree dans le script").
    external "C" dev = UartDevice_new(baudrate, dataBits, parity, stopBits, commandTable, terminator, responseDelay, respondEnabled, echoEnabled, periodicEnabled, period, periodicTemplate, valueOutStart, mode, scriptPath, pythonHome, instanceName) annotation(
      Include = "#include \"UartDeviceImpl.c\"",
      Library = "-lwinpthread",
      IncludeDirectory = "modelica://MicroPythonMCU/Resources/Include");
  end constructor;

  function destructor
    input UartDevice dev;
    external "C" UartDevice_destroy(dev) annotation(
      Include = "#include \"UartDeviceImpl.c\"",
      Library = "-lwinpthread",
      IncludeDirectory = "modelica://MicroPythonMCU/Resources/Include");
  end destructor;

  annotation(
    Documentation(info = "<html>
<p>No worker thread, unlike <code>Internal.PyRuntime</code>: a device reacts without ever suspending itself. In Table mode no Python code runs; in Script mode, the script's handlers run on the Modelica thread, in the interpreter shared with the microcontroller. The bit/byte engine is <em>exactly</em> the microcontroller's one (<code>Resources/Include/uartcore.c</code>), shared and not duplicated.</p>
</html>"));
end UartDevice;
