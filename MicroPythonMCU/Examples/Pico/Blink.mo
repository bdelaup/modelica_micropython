within MicroPythonMCU.Examples.Pico;

model Blink "Raspberry Pi Pico supplied by USB: on-board LED and external LED on GP15, VSYS and temperature read by the ADC"
  extends Modelica.Icons.Example;
  RPi_Pico pico(scriptPath = Modelica.Utilities.Files.loadResource("modelica://MicroPythonMCU/Resources/Scripts/MCU/pico_blink.py")) "USB cable plugged in (default): nothing to wire for the supply" annotation(
    Placement(transformation(origin = {16, 0}, extent = {{-40, -84}, {40, 108}})));
  Modelica.Electrical.Analog.Basic.Ground ground annotation(
    Placement(transformation(origin = {-50, -110}, extent = {{-10, -10}, {10, 10}})));
  Modelica.Electrical.Analog.Basic.Resistor r15(R = 330) "limits the current of led15" annotation(
    Placement(transformation(origin = {-60, -76}, extent = {{10, -10}, {-10, 10}})));
  MicroPythonMCU.Peripherals.LED led15 "GP15 (physical pin 20)" annotation(
    Placement(transformation(origin = {-90, -76}, extent = {{10, -10}, {-10, 10}})));
equation
  connect(pico.GP15, r15.p) annotation(
    Line(points = {{-21, -76}, {-50, -76}}, color = {0, 0, 255}));
  connect(r15.n, led15.p) annotation(
    Line(points = {{-70, -76}, {-80, -76}}, color = {0, 0, 255}));
  connect(led15.n, ground.p) annotation(
    Line(points = {{-100, -76}, {-110, -76}, {-110, -100}, {-50, -100}}, color = {0, 0, 255}));
  connect(pico.GND_18, ground.p) annotation(
    Line(points = {{-21, -60}, {-36, -60}, {-36, -100}, {-50, -100}}, color = {0, 0, 255}));
  annotation(
    Diagram(coordinateSystem(extent = {{-140, -130}, {80, 110}})),
    experiment(StopTime = 4.5, Interval = 0.001, StartTime = 0, Tolerance = 1e-06),
    Documentation(info = "<html>
<p>The Pico is supplied by its USB cable (<code>usbConnected</code>, default): 5 V on <code>VBUS</code>, about 4.7 V on <code>VSYS</code> after the Schottky diode, 3.3 V on the rail. Expected result: <code>pico.GP15.v</code> is a 0 V / ≈3 V square wave with a 2 s period, in phase with the on-board LED (icon); the log prints VSYS ≈ 4.7 V (read on <code>ADC(3)</code>) and 27 °C (<code>ADC(4)</code>, <code>dieTemperature</code>).</p>
</html>"));
end Blink;
