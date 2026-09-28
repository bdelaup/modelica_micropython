within MicroPythonMCU.Peripherals;

model UartGenericDevice "External serial device entirely described by its parameters, without creating a dedicated class"
  extends Internal.PartialUartDevice(scriptPath = Modelica.Utilities.Files.loadResource("modelica://MicroPythonMCU/Resources/Scripts/Device/generic.py"));
  annotation(
    Documentation(info = "<html>
<p>The component to place in a schematic when the device to simulate matches none of the derived models supplied and does not justify writing one. Everything is set in the parameter dialog: the command table, the periodic transmission, the exchanged quantities.</p>
<p>As soon as the same configuration comes back in several schematics, it is better to turn it into a class: extending <code>Internal.PartialUartDevice</code> and setting the parameters takes a few lines, and the device gets its own name, icon and documentation — this is how <code>UartEchoDevice</code>, <code>UartTemperatureSensor</code>, <code>UartGpsModule</code> and <code>UartLcd20x2</code> are written.</p>
</html>"));
end UartGenericDevice;
