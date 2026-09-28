within MicroPythonMCU.Peripherals;

model I2cGroveLcdRgb "Grove - LCD RGB Backlight screen (16x2): JHD1313 display controller at 0x3E and PCA9633 backlight driver at 0x62"
  extends Internal.PartialI2cDevice(addresses = "0x3E, 0x62", usePullUp = true, nOut = 4, scriptPath = Modelica.Utilities.Files.loadResource("modelica://MicroPythonMCU/Resources/Scripts/Device/grove_lcd_rgb.py"));
  extends Internal.Lcd16x2RgbIcon;
equation
  when {initial(), change(eventSeq)} then
    lcdLine1 = Internal.StringToCharCodes(line1, 16) "visible text returned by lines() of the script";
    lcdLine2 = Internal.StringToCharCodes(line2, 16);
  end when;
  backlight = {valueOut[1], valueOut[2], valueOut[3]} "red, green, blue returned by outputs() of the script";
  annotation(
    Documentation(info = "<html>
<p>Twin of the Seeed Studio <em>Grove - LCD RGB Backlight</em> module: a 16x2 character screen whose backlight changes colour. The module carries <strong>two chips</strong> on the same I2C bus, hence two addresses for a single component:</p>
<ul>
<li><code>0x3E</code> — <strong>JHD1313</strong>, HD44780-compatible display controller: each byte is preceded by a control byte (<code>0x80</code>: command, <code>0x40</code>: character). Emulated commands: clear, return home, entry mode, display on/off, shift, function set, write position (line 1 at <code>0x00</code>, line 2 at <code>0x40</code>).</li>
<li><code>0x62</code> — <strong>PCA9633</strong>, 4-channel LED driver: <code>MODE1</code>/<code>MODE2</code> registers, <code>PWM0</code>–<code>PWM3</code> brightnesses (blue, green, red), group dimming, <code>LEDOUT</code>; auto-increment register pointer.</li>
</ul>
<p>The behaviour is entirely described by <code>Resources/Scripts/Device/grove_lcd_rgb.py</code>, which follows the datasheets of both chips without knowing anything about the program driving them: a driver written for the real module works unchanged — see <code>Examples.I2c.GroveLcd</code>, which runs an off-the-shelf MicroPython driver without modification. Like the real controller, the screen is <strong>off at power-up</strong> and the backlight black: the program has to initialise them. A byte sent during a clear (1.52 ms) is ignored, with a warning in the log — on the real module, it would be lost.</p>
<p>The pull-up resistors of the bus are enabled (<code>usePullUp = true</code>), as on the real module. <code>valueOut</code>: red, green, blue intensities (0-255) and screen on (1/0); the icon takes this colour and shows the two visible lines while replaying a result with animation in OMEdit.</p>
<p><em>Hardware note:</em> recent revisions of the module (v5) replace the PCA9633 with another LED driver, at another address. This component follows the PCA9633 at <code>0x62</code>, which the reference driver targets; the address can still be changed through <code>addresses</code> (the script treats <code>0x3E</code> as the screen and any other address as the LED driver).</p>
</html>"));
end I2cGroveLcdRgb;
