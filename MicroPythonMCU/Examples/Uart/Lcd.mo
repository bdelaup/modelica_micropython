within MicroPythonMCU.Examples.Uart;

model Lcd "The microcontroller writes two lines to a 20x2 display through a real serial link; the display shows them on its icon with scrolling"
  extends Modelica.Icons.Example;
  MCU mcu(scriptPath = Modelica.Utilities.Files.loadResource("modelica://MicroPythonMCU/Resources/Scripts/MCU/uart_lcd.py")) "scriptPath = Resources/Scripts/MCU/uart_lcd.py" annotation(
    Placement(transformation(origin = {-90, 0}, extent = {{-50, -50}, {50, 50}})));
  MicroPythonMCU.Peripherals.UartLcd20x2 lcd(baudrate = 9600) "Shows the lines received on its RX pin" annotation(
    Placement(transformation(origin = {40, 0}, extent = {{-40, -40}, {40, 40}})));
  Modelica.Electrical.Analog.Basic.Ground ground annotation(
    Placement(transformation(origin = {-25, -80}, extent = {{-10, -10}, {10, 10}})));
equation
// Serial link: GP5 (TX) goes down to RX, TX comes back up to GP4 (RX).
// The display never transmits, but its TX pin stays connected - as on a
// real serial module, where both wires are present even if one is unused.
  connect(mcu.GP5, lcd.RX) annotation(
    Line(points = {{-59, 10}, {-34, 10}, {-34, -13.6}, {-9.6, -13.6}}, color = {0, 0, 255}));
  connect(lcd.TX, mcu.GP4) annotation(
    Line(points = {{-9.6, 13.6}, {-34, 13.6}, {-34, 25}, {-59, 25}}, color = {0, 0, 255}));
  connect(mcu.GND, ground.p) annotation(
    Line(points = {{-90, -39}, {-90, -70}, {-25, -70}}, color = {0, 0, 255}));
  connect(lcd.GND, ground.p) annotation(
    Line(points = {{40, -28.8}, {40, -70}, {-25, -70}}, color = {0, 0, 255}));
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
