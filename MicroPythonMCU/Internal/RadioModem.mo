within MicroPythonMCU.Internal;

class RadioModem "External Object wrapping the state of a transparent radio modem (serial and radio frames, buffers, delays) - see requirements.md, decision \"Liaison radio modulée\""
  extends ExternalObject;

  function constructor
    input Real baudrate "Speed of the serial link with the microcontroller (baud)";
    input Integer dataBits "Number of data bits of the serial link (5 to 8)";
    input Integer parity "Parity of the serial link, machine.UART convention: -1 = none, 0 = even, 1 = odd";
    input Integer stopBits "Number of stop bits of the serial link (1 or 2)";
    input Real airBaudrate "Air data rate (bit/s), radio frame 8N1";
    input Integer txBufferSize "Size of the transmit buffer (UART -> air), in bytes";
    input Integer rxBufferSize "Size of the receive buffer (air -> UART), in bytes";
    input Real txDelay "Fixed delay between the reception of a byte on the UART and its transmission on air (s)";
    input Real rxDelay "Fixed delay between the reception of a byte on air and its transmission on the UART (s)";
    input Boolean halfDuplex "The module is deaf while it transmits";
    input String instanceName "Component name, prefixed to the log messages";
    output RadioModem modem;
    // Library annotation: -lwinpthread links winpthread dynamically, otherwise ModelicaError crashes
    // the simulation under OpenModelica/Windows (see requirements.md, decision
    // "Comportement en cas d'exception non geree dans le script").
    external "C" modem = RadioModem_new(baudrate, dataBits, parity, stopBits, airBaudrate, txBufferSize, rxBufferSize, txDelay, rxDelay, halfDuplex, instanceName) annotation(
      Include = "#include \"RadioModemImpl.c\"",
      Library = "-lwinpthread",
      IncludeDirectory = "modelica://MicroPythonMCU/Resources/Include");
  end constructor;

  function destructor
    input RadioModem modem;
    external "C" RadioModem_destroy(modem) annotation(
      Include = "#include \"RadioModemImpl.c\"",
      Library = "-lwinpthread",
      IncludeDirectory = "modelica://MicroPythonMCU/Resources/Include");
  end destructor;

  annotation(
    Documentation(info = "<html>
<p>Neither Python nor thread: the modem only moves bytes between two serial engines (<code>Resources/Include/uartcore.c</code>, the one of the microcontroller and of the serial devices), one on the microcontroller side and one on the air side, through two time-stamped buffers. The destructor writes a one-line summary in the log (bytes passed, bytes lost and why).</p>
</html>"));
end RadioModem;
