within MicroPythonMCU.Internal;

partial model PartialTextDisplay "Behaviour of the large text screens: each message received through displayLink is written under the last written line, the screen scrolls up once full"
  parameter Integer nLines(min = 1) "Number of lines of the screen - fixed by the extending display, consistent with its generated icon";
  parameter Boolean logReceived = true "Also write each received message in the simulation log (turn off when several displays share the same link, to avoid duplicate lines)";
  constant Integer nCols = Interfaces.TEXT_DISPLAY_COLS "Number of columns";
  Interfaces.DisplayLinkInput displayLink(seq(start = 0, fixed = true)) "To be connected to MCU.Display0 (connect(mcu.Display0, display.displayLink))" annotation(
    Placement(transformation(origin = {-110, 0}, extent = {{-5, -5}, {5, 5}})));
  Integer textCode[nLines*nCols](each start = 32, each fixed = true) "ASCII codes shown on the icon, line after line: line i, column j at index (i - 1)*nCols + j";
  Integer filled(start = 0, fixed = true) "Number of lines written so far (at most nLines)";
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
    (textCode, filled) = Internal.ScrollText({pre(textCode[i]) for i in 1:nLines*nCols}, pre(filled), displayLink.payload, nNew, nLines, nCols);
    logged = Internal.LogDisplayMessages(if logReceived then nNew else 0, "[DISPLAY] t=" + String(time) + " s - " + getInstanceName() + " received: ", displayLink.payload);
  end when;
  annotation(
    Documentation(info = "<html>
<p>Base class of <code>Peripherals.Display4x32</code> and <code>Peripherals.Display8x32</code>: the logic only. It is extended by the generated icon classes (<code>Internal.TextIcon4x32</code>, <code>Internal.TextIcon8x32</code>), which the displays extend in turn: the names used by a <code>DynamicSelect</code> are resolved in the class that carries the icon, so <code>textCode</code> must be in scope there.</p>
<p>At each message (<code>change(displayLink.seq)</code>, i.e. each line sent by <code>machine.Display(0).write()</code>, or <code>initial()</code> for a message written by the program before its first <code>sleep()</code>, during the initialization; several messages of the same instant arrive together, one per line of <code>displayLink.payload</code>, and are written in turn by <code>Internal.ScrollText</code>): while the screen is not full, the message is written on the first free line, under the last written one; once all <code>nLines</code> lines are written, every line moves up by one and the message takes the last line, like a terminal. The text is converted into ASCII codes over <code>Interfaces.TEXT_DISPLAY_COLS</code> columns by <code>Internal.StringToCharCodes</code> from each message of <code>displayLink.payload</code> (the 20-column <code>displayLink.charCode</code> of <code>Peripherals.Display</code> is not used): a longer message is truncated on the icon, the full text stays in the simulation log when <code>logReceived</code> is true.</p>
<p>The screen starts empty: at <code>initial()</code>, it takes a message only if the program has already written one (<code>nNew</code> &gt; 0).</p>
</html>"));
end PartialTextDisplay;
