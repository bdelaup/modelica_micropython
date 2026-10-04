within MicroPythonMCU.Interfaces;

type ClockEdge = enumeration(
    Rising "Data read when the clock rises",
    Falling "Data read when the clock falls (HX711: the data is valid before the falling edge)")
  "Edge of the clock on which the data of a synchronous link is read"
  annotation(
    Documentation(info = "<html>
<p>Sampling edge of a <code>SyncData</code> channel of <code>Peripherals.Analyzers.LogicAnalyzer</code>: the data line is read at this edge of its clock channel. An HX711 changes DOUT on the rising edge of PD_SCK, its data is read on the falling edge; SPI in mode 0 is read on the rising edge.</p>
</html>"));
