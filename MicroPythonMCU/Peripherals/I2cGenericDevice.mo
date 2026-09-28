within MicroPythonMCU.Peripherals;

model I2cGenericDevice "I2C slave peripheral whose whole behaviour comes from a Python script, without creating a dedicated class"
  extends Internal.PartialI2cDevice(scriptPath = Modelica.Utilities.Files.loadResource("modelica://MicroPythonMCU/Resources/Scripts/Device/i2c_generic.py"));
  annotation(
    Documentation(info = "<html>
<p>The component to place in a schematic when the peripheral to simulate matches none of the supplied models. Set <code>addresses</code> and designate a script: the default script, <code>Resources/Scripts/Device/i2c_generic.py</code>, is a commented template (a small register bank) to copy and adapt.</p>
<p>As soon as the same peripheral comes back in several schematics, it is better to turn it into a class: extending <code>Internal.PartialI2cDevice</code> and setting <code>addresses</code>, <code>scriptPath</code> and <code>usePullUp</code> takes a few lines — this is how <code>I2cEchoDevice</code> and <code>I2cGroveLcdRgb</code> are written.</p>
</html>"));
end I2cGenericDevice;
