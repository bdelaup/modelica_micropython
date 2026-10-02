within MicroPythonMCU.Interfaces;
connector DisplayLinkOutput "Causal logical output of the educational display link (MCU side): no real voltage/current, see the decision \"Périphérique d'affichage pédagogique\" in requirements.md"
  output Integer seq "Incremented at each machine.Display.write() - used as the edge-detection trigger (change(seq)) on the receiver side, more reliable than a String comparison";
  output String payload "Last text sent by write() (sample-and-hold until the next write)";
  output Integer charCode[DISPLAY_COLS] "ASCII codes of the first DISPLAY_COLS characters of payload (space = 32 if payload is shorter) - lets the icon of a Peripherals.Display show the text actually received through DynamicSelect, unlike payload (a String), which is never stored in the simulation results, see Internal.StringToCharCodes";
  annotation(
    Icon(coordinateSystem(preserveAspectRatio = true, extent = {{-100, -100}, {100, 100}}), graphics = {Polygon(points = {{-100, 50}, {0, 0}, {-100, -50}, {-100, 50}}, lineColor = {28, 108, 200}, fillColor = {255, 255, 255}, fillPattern = FillPattern.Solid)}),
    Documentation(info = "<html>
<p>Causal connector (output) of the educational display link exposed by <code>MCU</code>. It does not stand for a real electrical pin: the link is modelled as a logical message delivered instantly at the sync point, not as a bit-by-bit serial waveform - a deliberate simplification, see <code>requirements.md</code>.</p>
</html>"));
end DisplayLinkOutput;
