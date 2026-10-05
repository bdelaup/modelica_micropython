within MicroPythonMCU.Internal;

class LogicAnalyzerCapture "External Object of Peripherals.Analyzers.LogicAnalyzer: recording of the logic levels of its channels (VCD file) and decoded frames (text file) - see requirements.md, decision \"Analyseur logique\""
  extends ExternalObject;

  function constructor
    input String fileName "Base name of the files written in the simulation folder (.vcd, .txt); empty string = instanceName";
    input String instanceName "Component name (default file name, log messages)";
    input String channelNames "Names of the 8 channels, separated by commas; empty names: CH0, CH1...";
    input Integer kinds[8] "Kind of each channel: Integer(Interfaces.ChannelKind), 1 = Off ... 5 = SyncData";
    input Real baudrates[8] "UART channels: speed";
    input Integer dataBits[8] "UART channels: data bits (5-8)";
    input Integer parities[8] "UART channels: -1 none, 0 even, 1 odd (machine.UART convention)";
    input Integer stopBits[8] "UART channels: 1 or 2";
    input Integer msbFirst[8] "UART and synchronous channels: 1 = most significant bit first";
    input Integer clocks[8] "I2cSda and SyncData channels: clock channel (0-7)";
    input Integer clockFalling[8] "SyncData channels: 1 = data read on the falling edge of the clock";
    input Integer wordBits[8] "SyncData channels: bits per word";
    input Integer signedWords[8] "SyncData channels: 1 = two's complement words";
    input Boolean writeVcd "Write <base>.vcd";
    input Boolean writePulseViewSession "Write <base>.pvs next to the VCD file: PulseView session with its protocol decoders set up from the channels";
    input Boolean openPulseView "Open the VCD file in PulseView at the end of the simulation";
    input String pulseViewPath "Path of the PulseView executable: absolute, or relative to the simulation folder (URIs resolved by the caller); empty string = automatic search";
    input String pulseViewLocal "Automatic search: pulseview.exe of the portable copy placed next to the library by get_pulseview.cmd (absolute path, may not exist)";
    input Boolean writeText "Write <base>.txt (decoded frames, ASCII timing diagram)";
    input Boolean openText "Open the text file in Notepad at the end of the simulation";
    input Integer textFlags[5] "Text file sections and options (0/1): hex dump, timing diagram, bit labels, split frames, compress silences";
    input Real textSilence "Silence not drawn in the timing diagram; 0 = automatic";
    input Real textResolution "Duration of one column of the timing diagram; 0 = automatic";
    input Integer textWidth "Columns of the timing diagram per line";
    output LogicAnalyzerCapture an;
    // Library annotation: -lwinpthread links winpthread dynamically, otherwise ModelicaError crashes
    // the simulation under OpenModelica/Windows (see requirements.md, decision
    // "Comportement en cas d'exception non geree dans le script").
    external "C" an = LogicAnalyzer_new(fileName, instanceName, channelNames, kinds, baudrates, dataBits, parities, stopBits, msbFirst, clocks, clockFalling, wordBits, signedWords, writeVcd, writePulseViewSession, openPulseView, pulseViewPath, pulseViewLocal, writeText, openText, textFlags, textSilence, textResolution, textWidth) annotation(
      Include = "#include \"AnalyzerImpl.c\"",
      Library = "-lwinpthread",
      IncludeDirectory = "modelica://MicroPythonMCU/Resources/Include");
  end constructor;

  function destructor
    input LogicAnalyzerCapture an;
    external "C" LogicAnalyzer_destroy(an) annotation(
      Include = "#include \"AnalyzerImpl.c\"",
      Library = "-lwinpthread",
      IncludeDirectory = "modelica://MicroPythonMCU/Resources/Include");
  end destructor;

  annotation(
    Documentation(info = "<html>
<p>No Python, no thread: the probe writes the levels it is given into a VCD file and keeps them in memory; at the end of the simulation, the destructor closes the VCD file, decodes the channels and writes the text file, then opens them in PulseView and Notepad if requested.</p>
</html>"));
end LogicAnalyzerCapture;
