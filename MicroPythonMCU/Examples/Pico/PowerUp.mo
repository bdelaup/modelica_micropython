within MicroPythonMCU.Examples.Pico;

model PowerUp "Raspberry Pi Pico on a ramping VSYS: delayed start at power-on, program stopped when the supply falls"
  extends Modelica.Icons.Example;
  RPi_Pico pico(usbConnected = false, scriptPath = Modelica.Utilities.Files.loadResource("modelica://MicroPythonMCU/Resources/Scripts/MCU/pico_power.py")) "no USB cable: supplied through VSYS" annotation(
    Placement(transformation(origin = {12, 0}, extent = {{-40, -84}, {40, 108}})));
  Modelica.Electrical.Analog.Basic.Ground ground annotation(
    Placement(transformation(origin = {-50, -110}, extent = {{-10, -10}, {10, 10}})));
  Modelica.Electrical.Analog.Sources.TableVoltage supply(table = [0, 0; 0.2, 0; 0.5, 3.0; 1.5, 3.0; 1.6, 1.0; 2, 1.0]) "VSYS: 0 V, ramp to 3 V between 0.2 s and 0.5 s, drop to 1 V between 1.5 s and 1.6 s" annotation(
    Placement(transformation(origin = {80, 30}, extent = {{-10, -10}, {10, 10}}, rotation = -90)));
  Modelica.Electrical.Analog.Basic.Resistor r15(R = 330) "limits the current of led15" annotation(
    Placement(transformation(origin = {-60, -76}, extent = {{10, -10}, {-10, 10}})));
  MicroPythonMCU.Peripherals.LED led15 "GP15 (physical pin 20)" annotation(
    Placement(transformation(origin = {-90, -76}, extent = {{10, -10}, {-10, 10}})));
equation
  connect(supply.p, pico.VSYS) annotation(
    Line(points = {{80, 40}, {80, 68}, {49, 68}}, color = {0, 0, 255}));
  connect(supply.n, pico.GND_38) annotation(
    Line(points = {{80, 20}, {80, 0}, {64, 0}, {64, 60}, {49, 60}}, color = {0, 0, 255}));
  connect(pico.GP15, r15.p) annotation(
    Line(points = {{-25, -76}, {-50, -76}}, color = {0, 0, 255}));
  connect(r15.n, led15.p) annotation(
    Line(points = {{-70, -76}, {-80, -76}}, color = {0, 0, 255}));
  connect(led15.n, ground.p) annotation(
    Line(points = {{-100, -76}, {-110, -76}, {-110, -100}, {-50, -100}}, color = {0, 0, 255}));
  connect(pico.GND_18, ground.p) annotation(
    Line(points = {{-25, -60}, {-36, -60}, {-36, -100}, {-50, -100}}, color = {0, 0, 255}));
  annotation(
    Diagram(coordinateSystem(extent = {{-140, -130}, {110, 110}})),
    experiment(StopTime = 2, Interval = 0.0005, StartTime = 0, Tolerance = 1e-06),
    Documentation(info = "<html>
<p>VSYS rises from 0 to 3 V between 0.2 s and 0.5 s, then falls to 1 V between 1.5 s and 1.6 s. Expected result: the regulator starts when VSYS reaches its undervoltage lockout (1.8 V, at 0.38 s): the 3.3 V rail (<code>pico.vRail</code>) appears and the program starts at that instant — the log prints <code>ticks_ms() = 0</code> there, with the simulated time of the start. GP15 then toggles every 100 ms. When VSYS falls below 1.7 V (at about 1.565 s), the regulator stops, the rail collapses, the program is stopped for good with a warning in the log, and GP15 stays at 0 V.</p>
</html>"));
end PowerUp;
