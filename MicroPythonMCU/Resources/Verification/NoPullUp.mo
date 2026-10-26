model NoPullUp "Same bus as MultiDevice, without the bus pull-up resistors: the internal pull-ups alone are too weak at 400 kHz and the master raises OSError(ETIMEDOUT)"
  // Same schematic as MultiDevice: only the pull-ups are removed and the
  // microcontroller program changes (it expects the error instead of the exchanges).
  extends Modelica.Icons.Example;
  MicroPythonMCU.MCU mcu(scriptPath = Modelica.Utilities.Files.loadResource("modelica://MicroPythonMCU/Resources/Scripts/MCU/i2c_nopullup.py")) "scriptPath = Resources/Scripts/MCU/i2c_nopullup.py" annotation(
    Placement(transformation(origin = {-90, 0}, extent = {{-20, -20}, {20, 20}})));
  MicroPythonMCU.Peripherals.I2cEchoDevice e1(addresses = "0x10", usePullUp = false) "Echo at address 0x10 - no pull-up resistors" annotation(
    Placement(transformation(origin = {40, 60}, extent = {{-20, -20}, {20, 20}})));
  MicroPythonMCU.Peripherals.I2cEchoDevice e2(addresses = "0x11", usePullUp = false) "Echo at address 0x11 - no pull-up resistors either" annotation(
    Placement(transformation(origin = {40, 0}, extent = {{-20, -20}, {20, 20}})));
  MicroPythonMCU.Peripherals.I2cEchoDevice e3(addresses = "0x12") "Echo at address 0x12 - no pull-ups" annotation(
    Placement(transformation(origin = {40, -60}, extent = {{-20, -20}, {20, 20}})));
  Modelica.Electrical.Analog.Basic.Ground ground annotation(
    Placement(transformation(origin = {-24, -100}, extent = {{-10, -10}, {10, 10}})));
  Modelica.Electrical.Analog.Basic.Resistor r7(R = 330) "limits the current of led7 (GP7)" annotation(
    Placement(transformation(origin = {-74, -64}, extent = {{-10, -10}, {10, 10}})));
  MicroPythonMCU.Peripherals.LED led7 "GP7: lights up if the program observed the expected error" annotation(
    Placement(transformation(origin = {-48, -64}, extent = {{-10, -10}, {10, 10}})));
equation
// SDA (GP5): a single wire, shared by the three peripherals
  connect(mcu.GP5, e1.SDA) annotation(
    Line(points = {{-78, 4}, {-20, 4}, {-20, 66}, {18, 66}}, color = {0, 0, 255}));
  connect(mcu.GP5, e2.SDA) annotation(
    Line(points = {{-78, 4}, {-20, 4}, {-20, 6}, {18, 6}}, color = {0, 0, 255}));
  connect(mcu.GP5, e3.SDA) annotation(
    Line(points = {{-78, 4}, {-20, 4}, {-20, -54}, {18, -54}}, color = {0, 0, 255}));
// SCL (GP4): same
  connect(mcu.GP4, e1.SCL) annotation(
    Line(points = {{-78, 10}, {-36, 10}, {-36, 54}, {18, 54}}, color = {0, 0, 255}));
  connect(mcu.GP4, e2.SCL) annotation(
    Line(points = {{-78, 10}, {-36, 10}, {-36, -6}, {18, -6}}, color = {0, 0, 255}));
  connect(mcu.GP4, e3.SCL) annotation(
    Line(points = {{-78, 10}, {-36, 10}, {-36, -66}, {18, -66}}, color = {0, 0, 255}));
  connect(mcu.GND, ground.p) annotation(
    Line(points = {{-90, -14}, {-90, -86}, {-24, -86}, {-24, -90}}, color = {0, 0, 255}));
  connect(e1.GND, ground.p) annotation(
    Line(points = {{40, 48}, {40, 42}, {70, 42}, {70, -86}, {-24, -86}, {-24, -90}}, color = {0, 0, 255}));
  connect(e2.GND, ground.p) annotation(
    Line(points = {{40, -12}, {40, -18}, {70, -18}, {70, -86}, {-24, -86}, {-24, -90}}, color = {0, 0, 255}));
  connect(e3.GND, ground.p) annotation(
    Line(points = {{40, -72}, {40, -86}, {-24, -86}, {-24, -90}}, color = {0, 0, 255}));
  connect(r7.n, led7.p) annotation(
    Line(points = {{-64, -64}, {-58, -64}}, color = {0, 0, 255}));
  connect(r7.p, mcu.GP7) annotation(
    Line(points = {{-84, -64}, {-88, -64}, {-88, -42}, {-50, -42}, {-50, -10}, {-78, -10}}, color = {0, 0, 255}));
  connect(led7.n, ground.p) annotation(
    Line(points = {{-38, -64}, {-34, -64}, {-34, -80}, {-24, -80}, {-24, -90}}, color = {0, 0, 255}));
  annotation(
    Diagram(coordinateSystem(extent = {{-160, -120}, {120, 100}})),
    experiment(StopTime = 0.003, Interval = 1e-6, StartTime = 0, Tolerance = 1e-06),
    Documentation(info = "<html>
<p>Same as <code>Examples.I2c.MultiDevice</code>, but <strong>no</strong> component carries the pull-up resistors (<code>usePullUp = false</code> everywhere). This is the most frequent wiring mistake on a real I2C bus.</p>
<p>With open drain, nobody drives a line high: only the pull-up resistors bring it back. Here only the internal pull-ups of the microcontroller remain, which <code>I2C()</code> switches on as on the Pico (<code>mcu.RPullUp</code>, 50 kΩ). At rest the lines do reach 3.3 V, but far too slowly: 50 kΩ against the 30 pF of the three peripherals is a time constant of 1.5 µs, whereas at 400 kHz SCL must be high a quarter of a period (0.625 µs) after being released. The master finds it still low: <code>writeto()</code> raises <code>OSError(ETIMEDOUT)</code> and <code>scan()</code> finds nobody. The program (<code>Scripts/MCU/i2c_nopullup.py</code>) lights <code>GP7</code> if it does observe these two symptoms.</p>
<p>Plot <code>mcu.GP4.v</code> and <code>mcu.GP5.v</code> and compare with <code>Examples.I2c.MultiDevice</code>: the rising edges are slow exponentials that never reach the threshold in time. The internal pull-ups would be enough at a much lower clock frequency, but a real bus is never designed that way, see <code>requirements.md</code>, decision \"Tirages internes\".</p>
</html>"));
end NoPullUp;
