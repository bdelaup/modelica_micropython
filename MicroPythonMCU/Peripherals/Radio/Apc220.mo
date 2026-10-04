within MicroPythonMCU.Peripherals.Radio;

model Apc220 "Radio module set up like an APC220 (433 MHz band transceiver): only the settings of its datasheet"
  extends Internal.PartialRadioModem(
    final baudrate = serialRate,
    final dataBits = 8,
    final parity = serialParity,
    final stopBits = 1,
    final fCarrier = 1e3*frequency,
    final channelWidth = 200e3,
    final airBaudrate = rfDataRate,
    final halfDuplex = true,
    final txBufferSize = 256,
    final rxBufferSize = 256,
    final txDelay = 0.005,
    final rxDelay = 0.001);

  parameter Integer frequency(min = 418000, max = 455000) = 434000 "RF frequency, in kHz (418000 to 455000, 1 kHz step) - both modules must use the same" annotation(
    Dialog(group = "APC220 settings"),
    choices(choice = 418000 "418 MHz (lowest)", choice = 433000 "433 MHz", choice = 434000 "434 MHz (factory setting)", choice = 435000 "435 MHz", choice = 445000 "445 MHz", choice = 455000 "455 MHz (highest)"));
  parameter Integer rfDataRate = 9600 "RF data rate (air), in bit/s - both modules must use the same" annotation(
    Dialog(group = "APC220 settings"),
    choices(choice = 2400 "2400 bps", choice = 4800 "4800 bps", choice = 9600 "9600 bps (factory setting)", choice = 19200 "19200 bps"));
  parameter Integer power(min = 0, max = 9) = 9 "Output power level, 0 to 9 (9 = 20 mW) - no effect yet: distance and attenuation are not modelled" annotation(
    Dialog(group = "APC220 settings"),
    choices(choice = 0 "0 (lowest)", choice = 1 "1", choice = 2 "2", choice = 3 "3", choice = 4 "4", choice = 5 "5", choice = 6 "6", choice = 7 "7", choice = 8 "8", choice = 9 "9 (20 mW, factory setting)"));
  parameter Integer serialRate = 9600 "Series rate: speed of the serial link with the microcontroller, in baud - give the same to machine.UART" annotation(
    Dialog(group = "APC220 settings"),
    choices(choice = 1200 "1200 bps", choice = 2400 "2400 bps", choice = 4800 "4800 bps", choice = 9600 "9600 bps (factory setting)", choice = 19200 "19200 bps", choice = 38400 "38400 bps", choice = 57600 "57600 bps"));
  parameter Interfaces.UartParity serialParity = Interfaces.UartParity.None "Series parity (None = Disable, factory setting) - 8 data bits, 1 stop bit" annotation(
    Dialog(group = "APC220 settings"));
initial equation
  assert(rfDataRate == 2400 or rfDataRate == 4800 or rfDataRate == 9600 or rfDataRate == 19200, "Apc220: RF data rate " + String(rfDataRate) + " bps not offered by the module (2400, 4800, 9600 or 19200)");
  assert(serialRate == 1200 or serialRate == 2400 or serialRate == 4800 or serialRate == 9600 or serialRate == 19200 or serialRate == 38400 or serialRate == 57600, "Apc220: series rate " + String(serialRate) + " bps not offered by the module (1200 to 57600)");
  assert(frequency >= 418000 and frequency <= 455000, "Apc220: RF frequency " + String(frequency) + " kHz out of the band of the module (418000 to 455000 kHz)");
  annotation(
    Icon(graphics = {Text(textColor = {255, 255, 255}, extent = {{-80, 32}, {70, 6}}, textString = "APC220", textStyle = {TextStyle.Bold}), Text(textColor = {200, 230, 220}, extent = {{-70, 2}, {70, -14}}, textString = "%rfDataRate bps")}),
    Documentation(info = "<html>
<p>Transparent radio module set up like an <strong>APC220</strong>: its dialog only shows the settings written on its datasheet and in its configuration tool — RF frequency (kHz), RF data rate, output power, series rate, series parity — with the factory settings by default (434 MHz, 9600 bit/s on air, power 9, 9600 baud, no parity). Give <code>machine.UART</code> the same speed as <code>serialRate</code>, 8 bits, 1 stop bit, and the same parity.</p>
<p>Fixed, as on the real module: 8 data bits and 1 stop bit on the UART, 256-byte buffers, half duplex (the module does not hear while it transmits). Fixed by assumption (not given by the datasheet): fixed delays of 5 ms (UART to air) and 1 ms (air to UART), channel width 200 kHz.</p>
<p><strong>Modulation</strong>: a real APC220 always uses GFSK, close to <code>FSK</code>. The <code>modulation</code> parameter remains changeable for teaching purposes only, to draw the same frames in OOK, ASK or BPSK; two modules must use the same one to hear each other.</p>
<p><code>power</code> has no effect yet: distance, attenuation and noise are not modelled (see the limits in the user guide).</p>
</html>"));
end Apc220;
