within MicroPythonMCU.Examples.Uart;

model Lcd "The microcontroller writes two lines to a 20x2 display through a real serial link; the display shows them on its icon with scrolling"
  extends Modelica.Icons.Example;
  MCU mcu(scriptPath = Modelica.Utilities.Files.loadResource("modelica://MicroPythonMCU/Resources/Scripts/MCU/uart_lcd.py")) "scriptPath = Resources/Scripts/MCU/uart_lcd.py" annotation(
    Placement(transformation(origin = {-90, 0}, extent = {{-20, -20}, {20, 20}})));
  MicroPythonMCU.Peripherals.UartLcd20x2 lcd(baudrate = 9600) "Shows the lines received on its RX pin" annotation(
    Placement(transformation(origin = {40, 0}, extent = {{-20, -20}, {20, 20}})));
  Modelica.Electrical.Analog.Basic.Ground ground annotation(
    Placement(transformation(origin = {-24, -80}, extent = {{-10, -10}, {10, 10}})));
equation
// Serial link: GP5 (TX) goes down to RX. The display never transmits, it has
// no TX pin: GP4, the RX pin required by machine.UART, stays unconnected.
  connect(mcu.GP5, lcd.RX) annotation(
    Line(points = {{-78, 4}, {-34, 4}, {-34, -6}, {18, -6}}, color = {0, 0, 255}));
  connect(mcu.GND, ground.p) annotation(
    Line(points = {{-90, -14}, {-90, -66}, {-24, -66}, {-24, -70}}, color = {0, 0, 255}));
  connect(lcd.GND, ground.p) annotation(
    Line(points = {{40, -12}, {40, -66}, {-24, -66}, {-24, -70}}, color = {0, 0, 255}));
  annotation(
    Diagram(coordinateSystem(extent = {{-160, -100}, {120, 80}})),
    experiment(StopTime = 0.2, Interval = 1e-5),
    Documentation(info = "<html>
<p>To be compared directly with <code>Examples.Display.Demo</code>, which shows the same kind of text through the <strong>logical</strong> link <code>machine.Display</code>. The visual result is identical, the path is not at all:</p>
<ul>
<li><code>Display.Demo</code>: the message is delivered in one block at the sync point, with no duration nor voltage. Handy, but nothing to probe.</li>
<li><code>Uart.Lcd</code>: the text goes through a real wire, one character every 1.04 ms at 9600 baud. Plotting <code>mcu.GP5.v</code> shows each character leaving bit by bit, and the line feed is what triggers the display.</li>
</ul>
<p>Setting the baud rate of the display to a value other than the microcontroller's makes wrong characters appear on the screen — the exact symptom of a configuration mismatch on a real circuit, reproduced here without hardware.</p>
</html>"));
end Lcd;
