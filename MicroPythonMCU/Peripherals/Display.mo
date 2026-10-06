within MicroPythonMCU.Peripherals;

model Display "Educational 20x2 display: received text shown on the icon (2-line scrolling) and in the log"
  // Carries the 20x2 icon and the two arrays of ASCII codes, shared with Peripherals.UartLcd20x2.
  extends Internal.TwoLineTextIcon;
  Interfaces.DisplayLinkInput displayLink(seq(start = 0, fixed = true)) "To be connected to MCU.Display0 (connect(mcu.Display0, display.displayLink))" annotation(
    Placement(transformation(origin = {-110, 0}, extent = {{-5, -5}, {5, 5}})));
protected
  discrete Integer nNew(start = 0, fixed = true) "Messages received at this instant (several write() without sleep() in between are published together, one per line of payload)";
  discrete Integer logged(start = 0, fixed = true) "Result of Internal.LogDisplayMessages, kept only so that the log call survives the initialization";
equation
  // initial(): a write() of the program before its first sleep() happens during the
  // initialization (first sync point of the core), where change() sees nothing - seq
  // then already differs from its start value 0.
  when {initial(), change(displayLink.seq)} then
    nNew = min(displayLink.seq - pre(displayLink.seq), Internal.DisplayMessageCount(displayLink.payload));
    // {pre(x[i]) for i in ...} rather than pre(x): OpenModelica 1.27.1 compiles pre() of a whole
    // array passed to a function as the CURRENT value of the array (checked in the generated code).
    line2CharCode = Internal.PreviousMessageCodes({pre(line1CharCode[i]) for i in 1:Interfaces.DISPLAY_COLS}, displayLink.payload, nNew) "the previous message (former line 1, or the one before the last when several arrive together) goes to line 2";
    line1CharCode = displayLink.charCode "the last message takes line 1";
    logged = Internal.LogDisplayMessages(nNew, "[DISPLAY] t=" + String(time) + " s - display received: ", displayLink.payload);
  end when;
  annotation(
    Icon(coordinateSystem(preserveAspectRatio = true, extent = {{-100, -100}, {100, 100}}, initialScale = 0.2), graphics = {Text(extent = {{-150, -60}, {150, -80}}, textColor = {0, 0, 255}, textString = "%name")}),
    Diagram(coordinateSystem(preserveAspectRatio = true, extent = {{-100, -100}, {100, 100}})),
    Documentation(info = "<html>
<p>Educational display peripheral, true to a 20×2 character display: to be connected with <code>connect(mcu.Display0, display.displayLink)</code> (causal logical connector <code>Interfaces.DisplayLinkInput</code>, not electrical - see <code>requirements.md</code>, decision \"Périphérique d'affichage pédagogique\"). Optional: connect it in a circuit or not, as the teaching needs require, like any other peripheral of <code>Peripherals</code>.</p>
<p>Behaviour at each reception (<code>change(displayLink.seq)</code>, or <code>initial()</code> for a message written by the program before its first <code>sleep()</code>, during the initialization): (a) a line in the simulation log through <code>Modelica.Utilities.Streams.print</code>, with the received text and the time stamp; (b) <b>two-line scrolling</b>: the former content of line 1 (<code>pre(displayLink.charCode)</code>, captured just before the update) becomes line 2 (<code>line2CharCode</code>), and the new message takes line 1 (<code>displayLink.charCode</code>, shown directly) - like a real display shifting its history. Fixed light-green screen (no brightness variation: the text itself is enough to show the activity, a user decision).</p>
<p><b>How the text works around the limitation of <code>String</code></b>: a <code>String</code> variable is never written to the simulation results (<code>.mat</code>/<code>.csv</code>, checked empirically), so a <code>DynamicSelect</code> directly on <code>payload</code> could never animate. Workaround: <code>Internal.StringToCharCodes</code> (shared <code>external \"C\"</code> function, independent of <code>PyRuntime</code>) converts each <code>payload</code> into an array <code>Integer charCode[Interfaces.DISPLAY_COLS]</code> (ASCII codes, padded with spaces) — an <code>Integer</code>, unlike a <code>String</code>, IS stored in the results like any other numeric quantity. Each column of the icon (20 per line, 2 lines) rebuilds its character through an <code>if/elseif</code> on its <code>charCode[i]</code> (same principle as a colour interpolation through <code>DynamicSelect</code>, applied to a <code>String</code> rather than to an RGB <code>Integer[3]</code>). Comparison with a <b>tolerance</b> (<code>abs(charCode[i] - code) &lt; 0.5</code>) rather than exact equality (<code>==</code>): replay/time scrolling in OMEdit rebuilds the value by interpolating a trajectory stored in double precision (even an <code>Integer</code> of the model is stored as a floating-point number in the <code>.mat</code> file) — an exact equality against a value off by a few 1e-6 around the expected integer failed intermittently, causing visible flicker even on a steady message; the tolerance absorbs this noise without ambiguity since ASCII codes are always at least 1 apart. Supported character set: space, digits, upper/lower-case letters, common punctuation (<code>! ' , - . ?</code>) — a character outside this set is shown as a space. <code>Interfaces.DISPLAY_COLS</code> (20): beyond it, the message is truncated on the icon only (the full text remains available in the simulation log).</p>
</html>"));
end Display;

