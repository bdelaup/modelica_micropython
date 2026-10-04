within MicroPythonMCU.Interfaces;

type ChannelKind = enumeration(
    Off "Not recorded (no threshold-crossing function)",
    Logic "Logic level only (also the kind of a clock channel)",
    Uart "Serial link (UART) decoded with the format of the channel",
    I2cSda "SDA line of an I2C bus, its SCL line on clockChannel",
    SyncData "Data of a synchronous serial link (HX711, simplified SPI), its clock on clockChannel")
  "Kind of a channel of the logic analyser probe"
  annotation(
    Documentation(info = "<html>
<p>Kind of a channel of <code>Peripherals.Analyzers.LogicAnalyzer</code>. Every channel that is not <code>Off</code> is recorded (VCD file) and drawn in the timing diagram of the text file; a decoded channel (<code>Uart</code>, <code>I2cSda</code>, <code>SyncData</code>) also shows its bits and bytes under its waveform, and its bytes in the hexadecimal section.</p>
<p>A clock line (SCL of an I2C bus, PD_SCK of an HX711, SCK of an SPI link) is a plain <code>Logic</code> channel: it is the data channel that names its clock channel (<code>clockChannel</code>), so that several buses can share the probe without ambiguity.</p>
</html>"));
