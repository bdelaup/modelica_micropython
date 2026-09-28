within MicroPythonMCU;
package Peripherals "Components that can be connected to MCU: LED, educational display, serial (UART) devices, I2C peripherals, weighing chain"
  extends Modelica.Icons.Package;

  annotation(
    Documentation(info = "<html>
<p>Everything here can be placed in a schematic next to an <code>MCU</code>:</p>
<ul>
<li>generic electrical components, wired to a <code>GPx</code> pin like any circuit (<code>LED</code>);</li>
<li>an educational peripheral driven by a logical message rather than by <code>Modelica.Electrical.Analog</code> (<code>Display</code>, wired to <code>MCU.Display0</code> through the causal connectors of <code>Interfaces</code>) — see <code>requirements.md</code>, decision \"Périphérique d'affichage pédagogique\";</li>
<li>serial devices connected electrically to two pins (<code>Uart*</code>), whose behaviour comes from a command table or a Python script;</li>
<li>I2C slave peripherals on an open-drain bus (<code>I2c*</code>), whose behaviour comes from a Python script;</li>
<li>the weighing chain (<code>Weighing</code>), pure Modelica.</li>
</ul>
<p>The base classes of the serial and I2C devices, which cannot be instantiated, live in <code>Internal</code>.</p>
</html>"));
end Peripherals;
