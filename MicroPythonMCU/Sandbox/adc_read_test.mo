within MicroPythonMCU.Sandbox;

model adc_read_test
  MCU mcu(scriptPath = "D:/benoit/OneDrive - LYCEE Jules Haag/modelica_micropython3/MicroPythonMCU/Sandbox/adc_read_test.py")  annotation(
    Placement(transformation(origin = {-21, 35}, extent = {{-31, -31}, {31, 31}})));
  Modelica.Electrical.Analog.Basic.Ground ground annotation(
    Placement(transformation(origin = {-32, -34}, extent = {{-10, -10}, {10, 10}})));
  Modelica.Electrical.Analog.Sources.RampVoltage rampVoltage(V = 5, duration = 10)  annotation(
    Placement(transformation(origin = {-78, 40}, extent = {{-10, -10}, {10, 10}}, rotation = -90)));
equation
  connect(rampVoltage.n, ground.p) annotation(
    Line(points = {{-78, 30}, {-78, -16}, {-32, -16}, {-32, -24}}, color = {0, 0, 255}));
  connect(mcu.GND, ground.p) annotation(
    Line(points = {{-20, 10}, {-20, -12}, {-32, -12}, {-32, -24}}, color = {0, 0, 255}));
  connect(rampVoltage.p, mcu.GP0) annotation(
    Line(points = {{-78, 50}, {-78, 54}, {-46, 54}, {-46, 50}, {-40, 50}}, color = {0, 0, 255}));
end adc_read_test;
