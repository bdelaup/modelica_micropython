within MicroPythonMCU.Internal;
function ResolvePath "Résout une URI (modelica://..., file://...) en chemin de fichier, et rend tout autre chemin tel quel (relatif : résolu plus tard depuis le dossier de simulation) - loadResource échoue sur une chaîne vide ou un chemin simple, d'où ce tri, cf. requirements.md décision Système de fichiers"
  input String path;
  output String resolved;
algorithm
  if Modelica.Utilities.Strings.find(path, "://") > 0 then
    resolved := Modelica.Utilities.Files.loadResource(path);
  else
    resolved := path;
  end if;
end ResolvePath;
