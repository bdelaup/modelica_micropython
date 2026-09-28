within MicroPythonMCU.Examples.I2c;

model NoPullUp "Same bus as MultiDevice, without any pull-up resistor: the lines stay low and the master raises OSError(ETIMEDOUT)"
  // Extends MultiDevice: same schematic, only the pull-ups are removed and the
  // microcontroller program changes (it expects the error instead of the exchanges).
  extends MultiDevice(mcu(scriptPath = Modelica.Utilities.Files.loadResource("modelica://MicroPythonMCU/Resources/Scripts/MCU/i2c_nopullup.py")), e1(usePullUp = false), e2(usePullUp = false));
  annotation(
    experiment(StopTime = 0.003, Interval = 1e-6),
    Documentation(info = "<html>
<p>Same as <code>Examples.I2c.MultiDevice</code>, but <strong>no</strong> component carries the pull-up resistors (<code>usePullUp = false</code> everywhere). This is the most frequent wiring mistake on a real I2C bus.</p>
<p>With open drain, nobody ever forces a line high: when released, SDA and SCL stay low. The master notices it as soon as it checks that the bus is free before the START: <code>writeto()</code> raises <code>OSError(ETIMEDOUT)</code> and <code>scan()</code> finds nobody. The program (<code>Scripts/MCU/i2c_nopullup.py</code>) lights <code>GP7</code> if it does observe these two symptoms.</p>
<p>Plot <code>mcu.GP4.v</code> and <code>mcu.GP5.v</code> and compare with <code>MultiDevice</code>: here both lines stay at 0 V from start to end. The internal pull-ups of the RP2040 are not modelled (too weak for a real bus), see <code>requirements.md</code>.</p>
</html>"));
end NoPullUp;
