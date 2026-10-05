within MicroPythonMCU.Examples.Pico;

model Battery "Raspberry Pi Pico supplied by two AA cells on VSYS: current drawn from the battery"
  extends Modelica.Icons.Example;
  RPi_Pico pico(usbConnected = false, scriptPath = Modelica.Utilities.Files.loadResource("modelica://MicroPythonMCU/Resources/Scripts/MCU/pico_blink.py")) "no USB cable: supplied through VSYS" annotation(
    Placement(transformation(origin = {8, 0}, extent = {{-40, -84}, {40, 108}})));
  Modelica.Electrical.Analog.Basic.Ground ground annotation(
    Placement(transformation(origin = {-50, -110}, extent = {{-10, -10}, {10, 10}})));
  Modelica.Electrical.Analog.Sources.ConstantVoltage cells(V = 3.0) "two AA cells in series" annotation(
    Placement(transformation(origin = {136, 30}, extent = {{-10, -10}, {10, 10}}, rotation = -90)));
  Modelica.Electrical.Analog.Basic.Resistor rInternal(R = 0.3) "internal resistance of the cells" annotation(
    Placement(transformation(origin = {116, 68}, extent = {{10, -10}, {-10, 10}})));
  Modelica.Electrical.Analog.Sensors.CurrentSensor iBattery "current delivered by the battery" annotation(
    Placement(transformation(origin = {92, 68}, extent = {{10, -10}, {-10, 10}})));
  Modelica.Electrical.Analog.Basic.Resistor r15(R = 330) "limits the current of led15" annotation(
    Placement(transformation(origin = {-60, -76}, extent = {{10, -10}, {-10, 10}})));
  MicroPythonMCU.Peripherals.LED led15 "GP15 (physical pin 20)" annotation(
    Placement(transformation(origin = {-90, -76}, extent = {{10, -10}, {-10, 10}})));
equation
  connect(cells.p, rInternal.p) annotation(
    Line(points = {{136, 40}, {136, 68}, {126, 68}}, color = {0, 0, 255}));
  connect(rInternal.n, iBattery.p) annotation(
    Line(points = {{106, 68}, {102, 68}}, color = {0, 0, 255}));
  connect(iBattery.n, pico.VSYS) annotation(
    Line(points = {{82, 68}, {45, 68}}, color = {0, 0, 255}));
  connect(cells.n, pico.GND_38) annotation(
    Line(points = {{136, 20}, {136, 0}, {70, 0}, {70, 60}, {45, 60}}, color = {0, 0, 255}));
  connect(pico.GP15, r15.p) annotation(
    Line(points = {{-29, -76}, {-50, -76}}, color = {0, 0, 255}));
  connect(r15.n, led15.p) annotation(
    Line(points = {{-70, -76}, {-80, -76}}, color = {0, 0, 255}));
  connect(led15.n, ground.p) annotation(
    Line(points = {{-100, -76}, {-110, -76}, {-110, -100}, {-50, -100}}, color = {0, 0, 255}));
  connect(pico.GND_18, ground.p) annotation(
    Line(points = {{-29, -60}, {-36, -60}, {-36, -100}, {-50, -100}}, color = {0, 0, 255}));
  annotation(
    Diagram(coordinateSystem(extent = {{-120, -120}, {160, 120}})),
    experiment(StopTime = 4.5, Interval = 0.001, StartTime = 0, Tolerance = 1e-06),
    Documentation(info = "<html>
<p>Without the USB cable (<code>usbConnected = false</code>), the Pico is supplied by two AA cells (3 V, 0.3 Ω) on <code>VSYS</code>; the regulator makes the 3.3 V rail from it (buck-boost: VSYS may be below 3.3 V). Expected result: the same blinking as <code>Blink</code>, the log prints VSYS ≈ 3 V. <code>iBattery.i</code> (also <code>pico.iSys</code>) is about 25 mA while the LED is off — RP2040 and flash, 20 mA under 3.3 V, divided by the efficiency (0.9) and by VSYS — and rises by about 6 mA while the LEDs (on-board and GP15, lit together) are on: the current of the pins is drawn from the 3.3 V rail.</p>
</html>"));
end Battery;
