within MicroPythonMCU.Internal;
function StringToCharCodes "Converts the first n characters of s into ASCII codes (0-255), padded with spaces (32) if s is shorter - shared helper (independent of PyRuntime) for the character-by-character display on Peripherals.Display, see requirements.md decision Périphérique d'affichage pédagogique"
  input String s;
  input Integer n;
  output Integer codes[n];
  // Library annotation: -lwinpthread links winpthread dynamically, otherwise ModelicaError crashes
  // the simulation under OpenModelica/Windows (see requirements.md, decision
  // "Comportement en cas d'exception non geree dans le script").
  external "C" string_to_char_codes(s, n, codes) annotation(
    Include = "#include \"StringToCharCodes.c\"",
    Library = "-lwinpthread",
    IncludeDirectory = "modelica://MicroPythonMCU/Resources/Include");
end StringToCharCodes;
