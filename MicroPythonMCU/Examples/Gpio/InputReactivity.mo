within MicroPythonMCU.Examples.Gpio;

model InputReactivity "Verification scenario no. 3: GP1 (input) toggles during a sleep(3600), the script must react without waiting for the end of the sleep"
  extends Modelica.Icons.Example;
  MCU mcu(scriptPath = Modelica.Utilities.Files.loadResource("modelica://MicroPythonMCU/Resources/Verification/input_reactive.py"), tickPeriod = 60) "scriptPath = Verification/input_reactive.py" annotation(
    Placement(transformation(origin = {0, 0}, extent = {{-20, -20}, {20, 20}})));
  Modelica.Electrical.Analog.Basic.Ground ground annotation(
    Placement(transformation(origin = {0, -70}, extent = {{-10, -10}, {10, 10}})));
  Modelica.Electrical.Analog.Basic.Resistor led(R = 1000) "Load simulating an LED on GP0" annotation(
    Placement(transformation(origin = {-48, 18}, extent = {{-10, -10}, {10, 10}})));
  Modelica.Electrical.Analog.Sources.SignalVoltage btnSrc "Drives GP1 from outside" annotation(
    Placement(transformation(origin = {-84, 8}, extent = {{10, -10}, {-10, 10}})));
  Modelica.Blocks.Sources.Step btnStep(height = 3.3, offset = 0, startTime = 10) "Toggles GP1 at t=10 s, while the script sleeps" annotation(
    Placement(transformation(origin = {-114, 26}, extent = {{-10, -10}, {10, 10}})));
equation
  connect(mcu.GND, ground.p) annotation(
    Line(points = {{0, -14}, {0, -60}}, color = {0, 0, 255}));
  connect(mcu.GP0, led.n) annotation(
    Line(points = {{-12, 10}, {-24, 10}, {-24, 18}, {-38, 18}}, color = {0, 0, 255}));
  connect(led.p, ground.p) annotation(
    Line(points = {{-58, 18}, {-60, 18}, {-60, -56}, {0, -56}, {0, -60}}, color = {0, 0, 255}));
  connect(btnStep.y, btnSrc.v) annotation(
    Line(points = {{-103, 26}, {-84, 26}, {-84, 20}}, color = {0, 0, 127}));
  connect(mcu.GP1, btnSrc.p) annotation(
    Line(points = {{-12, 4}, {-52, 4}, {-52, 8}, {-74, 8}}, color = {0, 0, 255}));
  connect(btnSrc.n, ground.p) annotation(
    Line(points = {{-94, 8}, {-98, 8}, {-98, -56}, {0, -56}, {0, -60}}, color = {0, 0, 255}));
  annotation(
    Diagram(coordinateSystem(extent = {{-140, 42}, {56, -84}})),
    experiment(StopTime = 60, Interval = 0.01),
    Documentation(info = "<html>
<p>Expected result: <code>mcu.GP0.v</code> stays low until t≈10 s then goes high shortly after (not at t=3600 s, the nominal deadline of the sleep) - the simulation log shows \"woken up, GP1 = 1\".</p>
</html>"));
end InputReactivity;
