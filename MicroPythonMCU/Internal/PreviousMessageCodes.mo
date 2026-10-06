within MicroPythonMCU.Internal;
function PreviousMessageCodes "ASCII codes of line 2 of a 20x2 display after k new messages: the message before the last when k >= 2, otherwise the former line 1"
  input Integer formerLine1[:] "Line 1 before the new messages";
  input String payload "Messages separated by line feeds";
  input Integer k "Number of new messages, the last ones of payload";
  output Integer codes[size(formerLine1, 1)];
algorithm
  if k >= 2 then
    codes := Internal.StringToCharCodes(Internal.DisplayMessage(payload, Internal.DisplayMessageCount(payload) - 1), size(formerLine1, 1));
  else
    codes := formerLine1;
  end if;
end PreviousMessageCodes;
