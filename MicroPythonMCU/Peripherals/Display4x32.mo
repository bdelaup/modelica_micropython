within MicroPythonMCU.Peripherals;

model Display4x32 "Large educational 4x32 text screen: each message received from machine.Display(0) is written under the last line, the screen scrolls once full"
  // The generated icon extends Internal.PartialTextDisplay (behaviour): see make_text_icons.py
  extends Internal.TextIcon4x32;
  annotation(
    Documentation(info = "<html>
<p>Large version of <code>Peripherals.Display</code>: 4 lines of 32 characters. To be connected like it, with <code>connect(mcu.Display0, display.displayLink)</code> (causal logical link, not electrical); several displays may share the same <code>Display0</code>.</p>
<p>Each <code>machine.Display(0).write(text)</code> of the script is written on the first free line, under the last written one; once the 4 lines are written, the text scrolls up by one line and the new message takes the bottom line, like a terminal. A message longer than 32 characters is truncated on the icon; the full text remains in the simulation log (parameter <code>logReceived</code>). The screen starts empty. Details: <code>Internal.TextIcon4x32</code> (generated icon), which extends <code>Internal.PartialTextDisplay</code> (behaviour).</p>
<p>Example: <code>Examples.Display.Large</code>.</p>
</html>"));
end Display4x32;
