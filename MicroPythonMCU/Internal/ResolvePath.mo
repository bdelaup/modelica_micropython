within MicroPythonMCU.Internal;
function ResolvePath "Resolves a URI (modelica://..., file://...) into a file path, and returns any other path unchanged (relative: resolved later from the simulation folder) - loadResource fails on an empty string or a plain path, hence this sorting, see requirements.md decision Système de fichiers"
  input String path;
  output String resolved;
algorithm
  if Modelica.Utilities.Strings.find(path, "://") > 0 then
    resolved := Modelica.Utilities.Files.loadResource(path);
  else
    resolved := path;
  end if;
end ResolvePath;
