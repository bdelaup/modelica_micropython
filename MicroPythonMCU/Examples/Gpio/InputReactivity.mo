within MicroPythonMCU.Examples.Gpio;

model InputReactivity "Verification scenario no. 3: GP1 (input) toggles during a sleep(3600), the script must react without waiting for the end of the sleep"
  extends Modelica.Icons.Example;
  MCU mcu(scriptPath = Modelica.Utilities.Files.loadResource("modelica://MicroPythonMCU/Resources/Verification/input_reactive.py"), tickPeriod = 60) "scriptPath = Verification/input_reactive.py" annotation(
    Placement(transformation(origin = {0, 0}, extent = {{-50, -50}, {50, 50}})));
  Modelica.Electrical.Analog.Basic.Ground ground annotation(
    Placement(transformation(origin = {0, -100}, extent = {{-15, -15}, {15, 15}})));
  Modelica.Electrical.Analog.Basic.Resistor led(R = 1000) "Load simulating an LED on GP0" annotation(
    Placement(transformation(origin = {-70, 25}, extent = {{-15, -15}, {15, 15}})));
  Modelica.Electrical.Analog.Sources.SignalVoltage btnSrc "Drives GP1 from outside" annotation(
    Placement(transformation(origin = {-120, 10}, extent = {{15, -15}, {-15, 15}})));
  Modelica.Blocks.Sources.Step btnStep(height = 3.3, offset = 0, startTime = 10) "Toggles GP1 at t=10 s, while the script sleeps" annotation(
    Placement(transformation(origin = {-164, 36}, extent = {{-15, -15}, {15, 15}})));
equation
  connect(mcu.GND, ground.p) annotation(
    Line(points = {{0, -39}, {0, -85}}, color = {0, 0, 255}));
  connect(mcu.GP0, led.n) annotation(
    Line(points = {{-31, 25}, {-55, 25}}, color = {0, 0, 255}));
  connect(led.p, ground.p) annotation(
    Line(points = {{-85, 25}, {-85, -85}, {0, -85}}, color = {0, 0, 255}));
  connect(btnStep.y, btnSrc.v) annotation(
    Line(points = {{-147.5, 36}, {-147.5, 36.5}, {-120, 36.5}, {-120, 28}}, color = {0, 0, 127}));
  connect(mcu.GP1, btnSrc.p) annotation(
    Line(points = {{-31, 10}, {-105, 10}}, color = {0, 0, 255}));
  connect(btnSrc.n, ground.p) annotation(
    Line(points = {{-135, 10}, {-135, -85}, {0, -85}}, color = {0, 0, 255}));
  annotation(
    Diagram(coordinateSystem(extent = {{-200, 60}, {80, -120}})),
    experiment(StopTime = 60, Interval = 0.01),
    Documentation(info = "<html>
<p>Expected result: <code>mcu.GP0.v</code> stays low until t≈10 s then goes high shortly after (not at t=3600 s, the nominal deadline of the sleep) - the simulation log shows \"woken up, GP1 = 1\".</p>
</html>"));
end InputReactivity;
