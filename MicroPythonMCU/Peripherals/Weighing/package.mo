within MicroPythonMCU.Peripherals;
package Weighing "Weighing chain: load cell body, strain gauge bridge, HX711 converter"
  extends Modelica.Icons.Package;

  annotation(
    Documentation(info = "<html>
<p>The links of an electronic scale, from the force to the digital measurement read by the microcontroller:</p>
<p><code>Force</code> (standard source <code>Modelica.Mechanics.Translational.Sources.Force</code>, the weight) → <code>LoadCell</code> (load cell body: the force deforms it) → <code>WheatstoneBridge</code> (four gauges bonded to the load cell body: the strain unbalances the bridge) → <code>Hx711</code> (24-bit amplifier and converter) → <code>MCU</code> (read by a MicroPython driver, PD_SCK and DOUT pins).</p>
<p>Examples: <code>Examples.Weighing.Hx711Read</code> (raw readings, gain, power-down) and <code>Examples.Weighing.KitchenScale</code> (complete kitchen scale, I2C screen and tare button).</p>
</html>"));
end Weighing;
