within MicroPythonMCU.Interfaces;

type Modulation = enumeration(
    OOK "On-off keying: carrier present for a 1, absent for a 0 (simplest amplitude shift keying)",
    ASK "Amplitude shift keying: full amplitude for a 1, reduced amplitude (askLowAmplitude) for a 0",
    FSK "Frequency shift keying: one frequency for a 0, another for a 1 (the APC220 uses GFSK, a filtered FSK)",
    BPSK "Binary phase shift keying: the carrier is inverted (phase 180 degrees) for a 0")
  "Modulation of a radio module"
  annotation(
    Documentation(info = "<html>
<p>Modulation of a radio module of <code>Peripherals.Radio</code>. It sets how the drawn signal <code>sTx</code> carries the bits of the radio frame:</p>
<ul>
<li><code>OOK</code>: the carrier is transmitted for a 1 and cut for a 0;</li>
<li><code>ASK</code>: the carrier is transmitted at full amplitude for a 1 and at the reduced amplitude <code>askLowAmplitude</code> for a 0;</li>
<li><code>FSK</code>: the carrier is at <code>fDisplay - deltaFDisplay</code> for a 0 and <code>fDisplay + deltaFDisplay</code> for a 1, with a continuous phase;</li>
<li><code>BPSK</code>: the carrier is transmitted for both values, inverted for a 0.</li>
</ul>
<p>A receiver only hears a transmitter that uses the same modulation (and the same carrier frequency, within the channel width).</p>
</html>"));
