within MicroPythonMCU.Examples.I2c;

model GroveLcd "Grove LCD RGB screen driven by an off-the-shelf MicroPython driver, run without modification"
  extends Modelica.Icons.Example;
  MCU mcu(scriptPath = Modelica.Utilities.Files.loadResource("modelica://MicroPythonMCU/Resources/Scripts/MCU/i2c_grove_lcd_rgb.py")) "scriptPath = Resources/Scripts/MCU/i2c_grove_lcd_rgb.py - main program, which imports the driver driver_grove_lcd_rgb.py placed next to it ((c) 2019 Christophe Gueneau, unchanged)" annotation(
    Placement(transformation(origin = {-90, 0}, extent = {{-50, -50}, {50, 50}})));
  MicroPythonMCU.Peripherals.I2cGroveLcdRgb lcd "16x2 screen with RGB backlight (JHD1313 at 0x3E, PCA9633 at 0x62), carrying the pull-ups of the bus" annotation(
    Placement(transformation(origin = {50, 0}, extent = {{-50, -50}, {50, 50}})));
  Modelica.Electrical.Analog.Basic.Ground ground annotation(
    Placement(transformation(origin = {-25, -80}, extent = {{-10, -10}, {10, 10}})));
equation
// Driver pinout: I2C(scl=Pin(4), sda=Pin(5))
  connect(mcu.GP4, lcd.SCL) annotation(
    Line(points = {{-59, 25}, {-35, 25}, {-35, -17}, {-12, -17}}, color = {0, 0, 255}));
  connect(mcu.GP5, lcd.SDA) annotation(
    Line(points = {{-59, 10}, {-45, 10}, {-45, 17}, {-12, 17}}, color = {0, 0, 255}));
  connect(mcu.GND, ground.p) annotation(
    Line(points = {{-90, -39}, {-90, -70}, {-25, -70}}, color = {0, 0, 255}));
  connect(lcd.GND, ground.p) annotation(
    Line(points = {{50, -36}, {50, -70}, {-25, -70}}, color = {0, 0, 255}));
  annotation(
    Diagram(coordinateSystem(extent = {{-160, -100}, {120, 80}})),
    experiment(StopTime = 3.5, Interval = 1e-4),
    Documentation(info = "<html>
<p>The microcontroller runs an <strong>existing MicroPython driver</strong> for the <em>Grove - LCD RGB Backlight</em> screen (<code>Scripts/MCU/driver_grove_lcd_rgb.py</code>, © 2019 Christophe Gueneau), whose class <code>GroveLcd_RGB</code> has undergone <strong>no modification</strong>. As on the real board, the driver is a module placed next to the main program (<code>Scripts/MCU/i2c_grove_lcd_rgb.py</code>), which imports it with <code>from driver_grove_lcd_rgb import GroveLcd_RGB</code> — importable thanks to <code>mcu.addScriptDirToPath</code>, enabled by default. The driver creates its bus with <code>I2C(scl=Pin(4), sda=Pin(5), freq=20000)</code>, initialises the screen (<em>function set</em> sequence, display on, clear), then loops: \"hello World\" on line 1 from column 2, and red, green, blue backlight, 500 ms each.</p>
<p>This demonstrates the <strong>digital twin</strong> approach: the same code runs on the real board and in the simulation. The <code>I2cGroveLcdRgb</code> component does not know this driver; it emulates the two chips of the module from their datasheets, based on the bytes actually decoded on the bus.</p>
<p>To watch during the animated replay: the text and colour of the <code>lcd</code> icon; <code>mcu.GP4.v</code> (SCL) and <code>mcu.GP5.v</code> (SDA), which show the frames at 20 kHz (one character = 3 bytes, about 1.5 ms); the simulation log, which lists each write received by the screen with its address and bytes.</p>
</html>"));
end GroveLcd;
