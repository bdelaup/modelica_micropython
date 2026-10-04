within MicroPythonMCU.Interfaces;

type BitOrder = enumeration(
    LsbFirst "Least significant bit first (UART)",
    MsbFirst "Most significant bit first (I2C, HX711, most SPI devices)")
  "Order in which the bits of a byte or word are sent"
  annotation(
    Documentation(info = "<html>
<p>Bit order of a decoded channel of <code>Peripherals.Analyzers.LogicAnalyzer</code>. A UART sends the least significant bit first; a synchronous link (HX711, SPI) usually the most significant one. I2C is always MSB first and has no setting.</p>
</html>"));
