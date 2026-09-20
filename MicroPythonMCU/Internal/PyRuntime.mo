within MicroPythonMCU.Internal;
class PyRuntime "External Object encapsulant l'interpréteur CPython qui exécute le script utilisateur (jalon M3 : exécution synchrone unique, pas encore de thread/sleep - cf. requirements.md)"
  extends ExternalObject;

  function constructor
    input String scriptPath "Chemin vers le script .py de l'utilisateur";
    input String pythonHome "Chemin vers la distribution Python embarquée (Resources/PythonRuntime)";
    input Boolean addScriptDirToPath "Ajoute le dossier de scriptPath au chemin de recherche des modules Python";
    input String libraryPath "Optionnel (chaine vide = desactive) : fichier .py d'une bibliotheque partagee - son dossier est ajoute au chemin de recherche";
    output PyRuntime handle;
    external "C" handle = PyRuntime_new(scriptPath, pythonHome, addScriptDirToPath, libraryPath) annotation(
      Include = "#include \"PyRuntimeImpl.c\"",
      IncludeDirectory = "modelica://MicroPythonMCU/Resources/Include",
      Library = "python312",
      LibraryDirectory = "modelica://MicroPythonMCU/Resources/Library/win64");
  end constructor;

  function destructor
    input PyRuntime handle;
    external "C" PyRuntime_destroy(handle) annotation(
      Include = "#include \"PyRuntimeImpl.c\"",
      IncludeDirectory = "modelica://MicroPythonMCU/Resources/Include",
      Library = "python312",
      LibraryDirectory = "modelica://MicroPythonMCU/Resources/Library/win64");
  end destructor;
end PyRuntime;
