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
  Integer newCode[nCols](each start = 32, each fixed = true) "ASCII codes of the last received message, truncated or padded with spaces to nCols";
equation
  when change(displayLink.seq) then
    newCode = Internal.StringToCharCodes(displayLink.payload, nCols);
    filled = min(pre(filled) + 1, nLines);
    // Not full yet: the message takes the first free line, the others keep their text.
    // Full: every line takes the text of the line below it, the message takes the last line.
    // min(i, nLines - 1) keeps the unused index of the "full" branch in range.
    for i in 1:nLines loop
      for j in 1:nCols loop
        textCode[(i - 1)*nCols + j] = if pre(filled) < nLines then (if i == pre(filled) + 1 then newCode[j] else pre(textCode[(i - 1)*nCols + j])) else (if i < nLines then pre(textCode[min(i, nLines - 1)*nCols + j]) else newCode[j]);
      end for;
    end for;
    if logReceived then
      Modelica.Utilities.Streams.print("[DISPLAY] t=" + String(time) + " s - " + getInstanceName() + " received: \"" + displayLink.payload + "\"");
    end if;
  end when;
  annotation(
    Documentation(info = "<html>
<p>Base class of <code>Peripherals.Display4x32</code> and <code>Peripherals.Display8x32</code>: the logic only. It is extended by the generated icon classes (<code>Internal.TextIcon4x32</code>, <code>Internal.TextIcon8x32</code>), which the displays extend in turn: the names used by a <code>DynamicSelect</code> are resolved in the class that carries the icon, so <code>textCode</code> must be in scope there.</p>
<p>At each message (<code>change(displayLink.seq)</code>, i.e. each <code>machine.Display(0).write()</code>): while the screen is not full, the message is written on the first free line, under the last written one; once all <code>nLines</code> lines are written, every line moves up by one and the message takes the last line, like a terminal. The text is converted into ASCII codes over <code>Interfaces.TEXT_DISPLAY_COLS</code> columns by <code>Internal.StringToCharCodes</code> from <code>displayLink.payload</code> (the 20-column <code>displayLink.charCode</code> of <code>Peripherals.Display</code> is not used): a longer message is truncated on the icon, the full text stays in the simulation log when <code>logReceived</code> is true.</p>
<p>The screen starts empty: nothing is taken at <code>initial()</code>, unlike <code>Peripherals.Display</code>.</p>
</html>"));
end PartialTextDisplay;
