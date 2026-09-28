within MicroPythonMCU.Examples.Gpio;

model LedChaser "Two-way LED chaser: one LED (Peripherals.LED) per pin GP0-GP7, laid out in a ring around the microcontroller, lit one at a time in the order GP0->GP3 (left) then GP7->GP4 (right), then the other way round"
  extends Modelica.Icons.Example;
  MCU mcu(scriptPath = Modelica.Utilities.Files.loadResource("modelica://MicroPythonMCU/Resources/Scripts/MCU/led_chaser.py")) "scriptPath = Resources/Scripts/MCU/led_chaser.py" annotation(
    Placement(transformation(origin = {0, 0}, extent = {{-50, -50}, {50, 50}})));
  Modelica.Electrical.Analog.Basic.Ground ground annotation(
    Placement(transformation(origin = {0, -110}, extent = {{-15, -15}, {15, 15}})));
  Modelica.Electrical.Analog.Basic.Resistor r0(R = 330) "limits the current of led0 (GP0)" annotation(
    Placement(transformation(origin = {-90, 60}, extent = {{-15, -15}, {15, 15}})));
  Modelica.Electrical.Analog.Basic.Resistor r1(R = 330) "limits the current of led1 (GP1)" annotation(
    Placement(transformation(origin = {-90, 20}, extent = {{-15, -15}, {15, 15}})));
  Modelica.Electrical.Analog.Basic.Resistor r2(R = 330) "limits the current of led2 (GP2)" annotation(
    Placement(transformation(origin = {-90, -20}, extent = {{-15, -15}, {15, 15}})));
  Modelica.Electrical.Analog.Basic.Resistor r3(R = 330) "limits the current of led3 (GP3)" annotation(
    Placement(transformation(origin = {-90, -60}, extent = {{-15, -15}, {15, 15}})));
  Modelica.Electrical.Analog.Basic.Resistor r4(R = 330) "limits the current of led4 (GP4)" annotation(
    Placement(transformation(origin = {90, 60}, extent = {{-15, -15}, {15, 15}})));
  Modelica.Electrical.Analog.Basic.Resistor r5(R = 330) "limits the current of led5 (GP5)" annotation(
    Placement(transformation(origin = {90, 20}, extent = {{-15, -15}, {15, 15}})));
  Modelica.Electrical.Analog.Basic.Resistor r6(R = 330) "limits the current of led6 (GP6)" annotation(
    Placement(transformation(origin = {90, -20}, extent = {{-15, -15}, {15, 15}})));
  Modelica.Electrical.Analog.Basic.Resistor r7(R = 330) "limits the current of led7 (GP7)" annotation(
    Placement(transformation(origin = {90, -60}, extent = {{-15, -15}, {15, 15}})));
  MicroPythonMCU.Peripherals.LED led0 "GP0, top left" annotation(
    Placement(transformation(origin = {-140, 60}, extent = {{-15, 15}, {15, -15}}, rotation = -180)));
  MicroPythonMCU.Peripherals.LED led1 "GP1, left" annotation(
    Placement(transformation(origin = {-140, 20}, extent = {{-15, 15}, {15, -15}}, rotation = -180)));
  MicroPythonMCU.Peripherals.LED led2 "GP2, left" annotation(
    Placement(transformation(origin = {-140, -20}, extent = {{-15, 15}, {15, -15}}, rotation = -180)));
  MicroPythonMCU.Peripherals.LED led3 "GP3, bottom left" annotation(
    Placement(transformation(origin = {-140, -60}, extent = {{-15, 15}, {15, -15}}, rotation = -180)));
  MicroPythonMCU.Peripherals.LED led4 "GP4, top right" annotation(
    Placement(transformation(origin = {140, 60}, extent = {{-15, -15}, {15, 15}})));
  MicroPythonMCU.Peripherals.LED led5 "GP5, right" annotation(
    Placement(transformation(origin = {140, 20}, extent = {{-15, -15}, {15, 15}})));
  MicroPythonMCU.Peripherals.LED led6 "GP6, right" annotation(
    Placement(transformation(origin = {140, -20}, extent = {{-15, -15}, {15, 15}})));
  MicroPythonMCU.Peripherals.LED led7 "GP7, bottom right" annotation(
    Placement(transformation(origin = {140, -60}, extent = {{-15, -15}, {15, 15}})));
equation
  connect(mcu.GND, ground.p) annotation(
    Line(points = {{0, -39}, {0, -95}}, color = {0, 0, 255}));
  connect(mcu.GP0, r0.n) annotation(
    Line(points = {{-31, 25}, {-31, 60}, {-75, 60}}, color = {0, 0, 255}));
  connect(r0.p, led0.p) annotation(
    Line(points = {{-105, 60}, {-125, 60}}, color = {0, 0, 255}));
  connect(led0.n, ground.p) annotation(
    Line(points = {{-155, 60}, {-155, -95}, {0, -95}}, color = {0, 0, 255}));
  connect(mcu.GP1, r1.n) annotation(
    Line(points = {{-31, 10}, {-31, 20}, {-75, 20}}, color = {0, 0, 255}));
  connect(r1.p, led1.p) annotation(
    Line(points = {{-105, 20}, {-125, 20}}, color = {0, 0, 255}));
  connect(led1.n, ground.p) annotation(
    Line(points = {{-155, 20}, {-155, -95}, {0, -95}}, color = {0, 0, 255}));
  connect(mcu.GP2, r2.n) annotation(
    Line(points = {{-31, -10}, {-31, -20}, {-75, -20}}, color = {0, 0, 255}));
  connect(r2.p, led2.p) annotation(
    Line(points = {{-105, -20}, {-125, -20}}, color = {0, 0, 255}));
  connect(led2.n, ground.p) annotation(
    Line(points = {{-155, -20}, {-155, -95}, {0, -95}}, color = {0, 0, 255}));
  connect(mcu.GP3, r3.n) annotation(
    Line(points = {{-31, -25}, {-31, -60}, {-75, -60}}, color = {0, 0, 255}));
  connect(r3.p, led3.p) annotation(
    Line(points = {{-105, -60}, {-125, -60}}, color = {0, 0, 255}));
  connect(led3.n, ground.p) annotation(
    Line(points = {{-155, -60}, {-155, -95}, {0, -95}}, color = {0, 0, 255}));
  connect(mcu.GP4, r4.p) annotation(
    Line(points = {{31, 25}, {31, 60}, {75, 60}}, color = {0, 0, 255}));
  connect(r4.n, led4.p) annotation(
    Line(points = {{105, 60}, {125, 60}}, color = {0, 0, 255}));
  connect(led4.n, ground.p) annotation(
    Line(points = {{155, 60}, {155, -95}, {0, -95}}, color = {0, 0, 255}));
  connect(mcu.GP5, r5.p) annotation(
    Line(points = {{31, 10}, {31, 20}, {75, 20}}, color = {0, 0, 255}));
  connect(r5.n, led5.p) annotation(
    Line(points = {{105, 20}, {125, 20}}, color = {0, 0, 255}));
  connect(led5.n, ground.p) annotation(
    Line(points = {{145, 20}, {145, -95}, {0, -95}}, color = {0, 0, 255}));
  connect(mcu.GP6, r6.p) annotation(
    Line(points = {{31, -10}, {31, -20}, {75, -20}}, color = {0, 0, 255}));
  connect(r6.n, led6.p) annotation(
    Line(points = {{105, -20}, {125, -20}}, color = {0, 0, 255}));
  connect(led6.n, ground.p) annotation(
    Line(points = {{155, -20}, {155, -95}, {0, -95}}, color = {0, 0, 255}));
  connect(mcu.GP7, r7.p) annotation(
    Line(points = {{31, -25}, {31, -60}, {75, -60}}, color = {0, 0, 255}));
  connect(r7.n, led7.p) annotation(
    Line(points = {{105, -60}, {125, -60}}, color = {0, 0, 255}));
  connect(led7.n, ground.p) annotation(
    Line(points = {{145, -60}, {145, -95}, {0, -95}}, color = {0, 0, 255}));
  annotation(
    Diagram(coordinateSystem(extent = {{-200, -140}, {200, 100}})),
    experiment(StopTime = 4.5, Interval = 0.001),
    Documentation(info = "<html>
<p>Demonstrator (outside the verification scenarios of <code>requirements.md</code>): eight <code>Peripherals.LED</code>, one per pin <code>GP0</code>-<code>GP7</code>, laid out in a ring around <code>mcu</code> (left column <code>GP0</code>→<code>GP3</code> from top to bottom, right column <code>GP4</code>→<code>GP7</code> from top to bottom). The script <code>led_chaser.py</code> lights a single LED at a time and makes it run along this ring (0,1,2,3,7,6,5,4 then back) — when replaying the animation of a simulation result in OMEdit, each LED lights up briefly in turn.</p>
</html>"));
end LedChaser;
