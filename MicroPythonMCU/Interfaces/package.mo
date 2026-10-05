within MicroPythonMCU;
package Interfaces "Reference logic voltage levels (RP2040 approximation, 3.3 V) used by the electrical bridge of MCU"
  extends Modelica.Icons.Package;

  constant Modelica.Units.SI.Voltage VOH = 3.3 "Logic high output voltage";
  constant Modelica.Units.SI.Voltage VOL = 0.0 "Logic low output voltage";
  constant Modelica.Units.SI.Voltage VIH = 2.0 "Threshold above which a logic input reads high (approximation)";
  constant Modelica.Units.SI.Voltage VIL = 0.8 "Threshold below which a logic input reads low (approximation)";
  constant Modelica.Units.SI.Resistance ROut = 100 "Default output series resistance (approximate drive strength)";
  constant Modelica.Units.SI.Resistance RPull = 50e3 "Default internal pull resistor, up or down (RP2040: 50 to 80 kOhm)";
  constant Modelica.Units.SI.Conductance GOff = 1e-9 "Default leakage of a pin not driving its line (input, released line): 1 GOhm, a real high impedance";
  constant Integer DISPLAY_COLS = 20 "Number of columns shown on the icon of the educational peripheral Peripherals.Display (true to a real 20x2 character display) - truncates longer messages on the icon only (the full text remains available in the simulation log)";
  constant Integer TEXT_DISPLAY_COLS = 32 "Number of columns of the large text screens Peripherals.Display4x32 and Display8x32 - longer messages are truncated on the icon only (the full text remains available in the simulation log); the generated icons (make_text_icons.py) assume this value";
  constant Integer UART_DEV_MAX_VALUES = 4 "Number of real quantities an external serial device can exchange with the rest of the model ({v1}..{v4} substituted in a transmitted frame, {o1}..{o4} captured from a received frame) - must stay aligned with UARTDEV_MAX_VALUES on the C side (Resources/Include/uartdevice/uartdevice_core.h)";
  constant Integer I2C_DEV_MAX_VALUES = 4 "Number of real quantities an external I2C peripheral can exchange with the rest of the model (argument v of its Python handlers, return value of outputs()) - must stay aligned with I2CDEV_MAX_VALUES on the C side (Resources/Include/i2cdevice/i2cdevice_core.h)";

  annotation(
    Documentation(info = "<html>
<p>Approximate values inspired by the Raspberry Pi Pico (RP2040, 3.3 V supply). Not exact datasheet values — enough for the intended use, to be refined later if needed.</p>
</html>"));
end Interfaces;
