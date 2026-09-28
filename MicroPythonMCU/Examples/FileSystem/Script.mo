within MicroPythonMCU.Examples.FileSystem;

model Script "Système de fichiers et script : boot.py de la flash, puis le script fs_script.py à la place de main.py"
  extends Boot(mcu(scriptPath = Modelica.Utilities.Files.loadResource("modelica://MicroPythonMCU/Resources/Scripts/MCU/fs_script.py")));
  annotation(
    experiment(StopTime = 0.5, Interval = 0.001),
    Documentation(info = "<html>
<p>Scénario de vérification 27 (cf. <code>requirements.md</code>, décision « Système de fichiers ») : même montage et même image de flash que <code>Examples.FileSystem.Boot</code>, mais <code>scriptPath</code> est renseigné. Le microcontrôleur exécute alors <code>boot.py</code> de la flash, puis le script <code>fs_script.py</code> <strong>à la place</strong> de <code>main.py</code> — comme Thonny qui exécute le script ouvert sur une carte déjà démarrée.</p>
<p>Le script vérifie que <code>boot.py</code> a bien créé <code>/data</code> et que <code>main.py</code> n'a pas tourné (<code>/data</code> vide), écrit puis relit <code>/data/notes.txt</code>, et allume <code>led1</code> (<code>GP1</code>) si tout est conforme.</p>
</html>"));
end Script;
