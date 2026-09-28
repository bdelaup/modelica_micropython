within MicroPythonMCU.Interfaces;

type UartBehaviour = enumeration(
    Table "Command table (parameters)",
    Script "Python script (handlers)")
  "Origin of the behaviour of an external serial device (Internal.PartialUartDevice)"
  annotation(
    Documentation(info = "<html>
<p>Explicit selector rather than an implicit precedence rule between <code>commandTable</code> and <code>scriptPath</code>: OMEdit renders an enumeration as a drop-down list, and the <code>Dialog(enable = ...)</code> of the model grey out the group of parameters that no longer applies. The ambiguous case \"both are filled in\" therefore cannot happen.</p>
<p><code>Table</code>: the device answers according to <code>commandTable</code>, <code>echoEnabled</code> and <code>periodicTemplate</code>. <code>Script</code>: the Python script <code>scriptPath</code> describes the behaviour through its handlers (<code>on_receive</code>, <code>on_tick</code>, <code>outputs</code>) — see <code>requirements.md</code>, decision \"Périphériques UART externes connectables\".</p>
</html>"));
