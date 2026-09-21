within MicroPythonMCU.Internal;
function StringToCharCodes "Convertit les n premiers caracteres de s en codes ASCII (0-255), complete par des espaces (32) si s est plus court - utilitaire partage (independant de PyRuntime) pour l'affichage caractere par caractere sur Peripherals.Display, cf. requirements.md decision Periphérique d'affichage pédagogique"
  input String s;
  input Integer n;
  output Integer codes[n];
  external "C" string_to_char_codes(s, n, codes) annotation(
    Include = "#include \"StringToCharCodes.c\"",
    IncludeDirectory = "modelica://MicroPythonMCU/Resources/Include");
end StringToCharCodes;
