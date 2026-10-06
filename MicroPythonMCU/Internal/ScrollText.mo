within MicroPythonMCU.Internal;
function ScrollText "Writes the k last messages of a payload on a large text screen, one line each: under the last written line, then scrolling up once the screen is full"
  input Integer textIn[:] "ASCII codes shown, line after line: line i, column j at index (i - 1)*nCols + j";
  input Integer filledIn "Number of lines written so far (at most nLines)";
  input String payload "Messages separated by line feeds";
  input Integer k "Number of new messages, the last ones of payload";
  input Integer nLines;
  input Integer nCols;
  output Integer text[size(textIn, 1)] = textIn;
  output Integer filled = filledIn;
protected
  Integer n = Internal.DisplayMessageCount(payload);
  Integer codes[nCols];
algorithm
  for m in max(n - k + 1, 1):n loop
    codes := Internal.StringToCharCodes(Internal.DisplayMessage(payload, m), nCols);
    if filled < nLines then
      // Not full yet: the message takes the first free line, the others keep their text.
      text[filled*nCols + 1:(filled + 1)*nCols] := codes;
      filled := filled + 1;
    else
      // Full: every line takes the text of the line below it, the message takes the last line.
      text[1:(nLines - 1)*nCols] := text[nCols + 1:nLines*nCols];
      text[(nLines - 1)*nCols + 1:nLines*nCols] := codes;
    end if;
  end for;
end ScrollText;
