within MicroPythonMCU.Examples.I2c;

model NoPullUp "Same bus as MultiDevice, without the bus pull-up resistors: the internal pull-ups alone are too weak at 400 kHz and the master raises OSError(ETIMEDOUT)"
  // Extends MultiDevice: same schematic, only the pull-ups are removed and the
  // microcontroller program changes (it expects the error instead of the exchanges).
  extends MultiDevice(mcu(scriptPath = Modelica.Utilities.Files.loadResource("modelica://MicroPythonMCU/Resources/Scripts/MCU/i2c_nopullup.py")), e1(usePullUp = false), e2(usePullUp = false));
  annotation(
    experiment(StopTime = 0.003, Interval = 1e-6),
    Documentation(info = "<html>
<p>Same as <code>Examples.I2c.MultiDevice</code>, but <strong>no</strong> component carries the pull-up resistors (<code>usePullUp = false</code> everywhere). This is the most frequent wiring mistake on a real I2C bus.</p>
<p>With open drain, nobody drives a line high: only the pull-up resistors bring it back. Here only the internal pull-ups of the microcontroller remain, which <code>I2C()</code> switches on as on the Pico (<code>mcu.RPullUp</code>, 50 kΩ). At rest the lines do reach 3.3 V, but far too slowly: 50 kΩ against the 30 pF of the three peripherals is a time constant of 1.5 µs, whereas at 400 kHz SCL must be high a quarter of a period (0.625 µs) after being released. The master finds it still low: <code>writeto()</code> raises <code>OSError(ETIMEDOUT)</code> and <code>scan()</code> finds nobody. The program (<code>Scripts/MCU/i2c_nopullup.py</code>) lights <code>GP7</code> if it does observe these two symptoms.</p>
<p>Plot <code>mcu.GP4.v</code> and <code>mcu.GP5.v</code> and compare with <code>MultiDevice</code>: the rising edges are slow exponentials that never reach the threshold in time. The internal pull-ups would be enough at a much lower clock frequency, but a real bus is never designed that way, see <code>requirements.md</code>, decision \"Tirages internes\".</p>
</html>"));
end NoPullUp;
