within MicroPythonMCU.Internal.Functions;
function DisplayMessageCount "Number of messages in a payload of the display link (messages separated by line feeds)"
  input String payload;
  output Integer n = Modelica.Utilities.Strings.count(payload, "\n") + 1;
  annotation(
    Documentation(info = "<html>
<p>A sync point publishes on <code>Display0.payload</code> every message written since the previous one, separated by line feeds (several <code>write()</code> without <code>sleep()</code> in between, or a text of several lines). The empty payload counts as one empty message. See <code>Internal.Functions.DisplayMessage</code>.</p>
</html>"));
end DisplayMessageCount;
