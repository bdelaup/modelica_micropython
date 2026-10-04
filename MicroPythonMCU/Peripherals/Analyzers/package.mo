within MicroPythonMCU.Peripherals;
package Analyzers "Measuring instruments: logic analyser probe (decoded frames in a text file, VCD for PulseView)"
  extends Modelica.Icons.Package;

  annotation(
    Documentation(info = "<html>
<p>Instruments that <strong>observe</strong> lines of the circuit without ever driving them, like the probes of a real logic analyser: their inputs have a very high impedance (1 GΩ to ground), the circuit behaves the same with or without them.</p>
<p><code>LogicAnalyzer</code> records the logic level of up to 8 lines and decodes them (UART, I2C, synchronous serial): a text file with the bytes in hexadecimal + ASCII and an ASCII timing diagram, and a VCD file for PulseView (free, with its own protocol decoders) or GTKWave.</p>
<p>See <code>requirements.md</code>, decision \"Analyseur logique\".</p>
</html>"));
end Analyzers;
