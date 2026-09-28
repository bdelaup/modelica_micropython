within MicroPythonMCU.Examples.FileSystem;

model Script "File system and script: boot.py of the flash, then the script fs_script.py instead of main.py"
  extends Boot(mcu(scriptPath = Modelica.Utilities.Files.loadResource("modelica://MicroPythonMCU/Resources/Scripts/MCU/fs_script.py")));
  annotation(
    experiment(StopTime = 0.5, Interval = 0.001),
    Documentation(info = "<html>
<p>Verification scenario 27 (see <code>requirements.md</code>, decision \"Système de fichiers\"): same circuit and same flash image as <code>Examples.FileSystem.Boot</code>, but <code>scriptPath</code> is set. The microcontroller then runs <code>boot.py</code> from the flash, then the script <code>fs_script.py</code> <strong>instead of</strong> <code>main.py</code> — like Thonny running the open script on an already booted board.</p>
<p>The script checks that <code>boot.py</code> did create <code>/data</code> and that <code>main.py</code> did not run (<code>/data</code> empty), writes then reads back <code>/data/notes.txt</code>, and lights <code>led1</code> (<code>GP1</code>) if everything is as expected.</p>
</html>"));
end Script;
