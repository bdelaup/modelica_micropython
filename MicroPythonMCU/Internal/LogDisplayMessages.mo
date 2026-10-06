within MicroPythonMCU.Internal;
impure function LogDisplayMessages "Writes the k last messages of a payload of the display link in the simulation log, one line each, and returns k - to be assigned to a variable, so that the call survives the initialization"
  input Integer k "Number of messages to log, the last ones of payload";
  input String prefix "Start of each log line";
  input String payload;
  output Integer logged = k;
protected
  Integer n = Internal.DisplayMessageCount(payload);
algorithm
  for m in max(n - k + 1, 1):n loop
    Modelica.Utilities.Streams.print(prefix + "\"" + Internal.DisplayMessage(payload, m) + "\"");
  end for;
  annotation(
    Documentation(info = "<html>
<p>Shared by the displays (<code>Peripherals.Display</code>, <code>Internal.PartialTextDisplay</code>), at <code>initial()</code> as well as at each <code>change(displayLink.seq)</code>.</p>
<p>Why a function with an output: in a <code>when {initial(), change(...)}</code>, OpenModelica (checked with 1.24.4 and 1.27.1) keeps the assignments of the <code>initial()</code> branch but drops a bare call to <code>Modelica.Utilities.Streams.print</code> (a call without result); a message written by the program before its first <code>sleep()</code> (t = 0, first sync point, during the initialization) was then missing from the log. Assigning the result keeps the call.</p>
</html>"));
end LogDisplayMessages;
