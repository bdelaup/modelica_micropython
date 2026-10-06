within MicroPythonMCU.Internal;
function DisplayMessage "Message i (1 = the oldest) of a payload of the display link (messages separated by line feeds)"
  input String payload;
  input Integer i "1 to Internal.DisplayMessageCount(payload)";
  output String message;
protected
  Integer first = 1 "Index of the first character of message i";
  Integer last "Index of the line feed that ends message i, or length + 1";
algorithm
  for m in 1:i - 1 loop
    first := Modelica.Utilities.Strings.find(payload, "\n", first) + 1;
  end for;
  last := Modelica.Utilities.Strings.find(payload, "\n", first);
  if last == 0 then
    last := Modelica.Utilities.Strings.length(payload) + 1;
  end if;
  message := if last > first then Modelica.Utilities.Strings.substring(payload, first, last - 1) else "";
end DisplayMessage;
