within MicroPythonMCU.Interfaces;

connector RadioAirOutput "Causal logical output of the micro:bit radio air link (RadioAir side): carries the id of the radio network, no real voltage - the packets themselves travel between the C radio engines, see RadioAir"
  output Integer networkId "Id of the radio network formed by the air link the board is wired to - boards whose antennas share this id hear each other";
  annotation(
    Icon(coordinateSystem(preserveAspectRatio = true, extent = {{-100, -100}, {100, 100}}), graphics = {Polygon(points = {{-100, 50}, {0, 0}, {-100, -50}, {-100, 50}}, lineColor = {160, 90, 0}, fillColor = {255, 255, 255}, fillPattern = FillPattern.Solid)}),
    Documentation(info = "<html>
<p>Causal connector (output) of the logical radio air link, on the <code>antenna</code> port of a <code>Peripherals.Radio.RadioAir</code>. It does not stand for a real electrical pin: the radio packets are exchanged between the C engines of the boards at the sync points, this link only carries the id of the network, i.e. the topology of the diagram (which boards hear each other) - a deliberate simplification, see <code>RadioAir</code> and <code>requirements.md</code>.</p>
</html>"));
end RadioAirOutput;
