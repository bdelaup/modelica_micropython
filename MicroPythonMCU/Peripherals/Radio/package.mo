within MicroPythonMCU.Peripherals;
package Radio "Radio link: transparent radio modems connected to the UART of the microcontroller, modulated signal drawn"
  extends Modelica.Icons.Package;

  annotation(
    Documentation(info = "<html>
<p>Transparent radio modems: each one is connected to the UART of an <code>MCU</code> (<code>machine.UART</code>, pins <code>TX</code>/<code>RX</code>/<code>GND</code>) and to the other module(s) by <strong>one</strong> antenna wire. What one microcontroller writes on its UART comes out of the UART of the other, after the buffers, the fixed delays and the radio frame at the air data rate.</p>
<ul>
<li><code>RadioModem</code>: every setting adjustable (serial link, modulation, channel, air data rate, duplex, buffers, delays);</li>
<li><code>Apc220</code>: set up like an APC220 module, with the settings of its datasheet only.</li>
</ul>
<p>The receiver decodes the radio frame through a masked synchronisation (the antenna wire carries the bit being transmitted); the modulated signal <code>sTx</code> (OOK, ASK, FSK or BPSK) is drawn with a scaled carrier. Examples: <code>Examples.Radio</code>.</p>
</html>"));
end Radio;
