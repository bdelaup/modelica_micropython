within MicroPythonMCU.Internal;

partial model PartialUsbBoard "Common base of the boards supplied through USB (RPi_Pico, MicroBit_v2): the USB supply parameters are written here once - each board keeps its own supply chain (pins, components, wiring), whose placement and topology are board-specific"
  extends PartialBoard;
  parameter Boolean usbConnected = true "USB cable plugged in: 5 V through the USB connector (the board runs without any wiring) - false to supply the board through its supply pin" annotation(
    Dialog(tab = "Power supply", group = "USB"),
    choices(checkBox = true));
  parameter Modelica.Units.SI.Voltage VUsb = 5 "Voltage of the USB supply" annotation(
    Dialog(tab = "Power supply", group = "USB", enable = usbConnected));
  parameter Modelica.Units.SI.Resistance RUsb = 0.2 "Resistance of the USB cable and connector" annotation(
    Dialog(tab = "Power supply", group = "USB", enable = usbConnected));
  parameter Real eta(min = 0.1, max = 1) = 0.9 "Efficiency of the regulator" annotation(
    Dialog(tab = "Power supply", group = "Regulator"));
  annotation(
    Icon(coordinateSystem(preserveAspectRatio = true, extent = {{-100, -100}, {100, 100}}, initialScale = 0.2), graphics = {Rectangle(lineColor = {20, 20, 20}, fillColor = {60, 60, 60}, fillPattern = FillPattern.Solid, extent = {{-55, 65}, {55, -65}}), Text(textColor = {230, 230, 230}, extent = {{-40, 10}, {40, -10}}, textString = "USB board")}),
    Documentation(info = "<html>
<p>Common base of the USB-supplied boards <code>RPi_Pico</code> and <code>MicroBit_v2</code>, on top of <code>PartialBoard</code>: only the USB supply parameters are shared (<code>usbConnected</code>, <code>VUsb</code>, <code>RUsb</code>, <code>eta</code>), because the supply chains really differ - the Pico exposes <code>VBUS</code>/<code>VSYS</code> as public pins with the Schottky between them, the micro:bit feeds its regulator from the USB rail and exposes <code>3V</code> only. The conditional components (<code>usbSupply</code>, <code>usbCable</code>) and their wiring stay in each board: their placement cannot be changed by inheritance, and so does the drawn routing of their wires.</p>
</html>"));
end PartialUsbBoard;
