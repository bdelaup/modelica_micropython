within MicroPythonMCU;

model XIAO_rp2040 "Seeed Studio XIAO RP2040 standard board with real pad-to-GPIO mapping, USB/5 V supply and active-low RGB LED"
  extends Internal.Boards.PartialUsbBoard(redeclare Internal.Boards.McuCore core(final nPins = 14, final pinIds = {26, 27, 28, 29, 6, 7, 0, 1, 2, 4, 3, 16, 17, 25}, final pinCaps = {7, 7, 7, 7, 3, 3, 3, 3, 3, 3, 3, 1, 1, 1}, final boardProfile = "pico", final hasTempSensor = true, final dieTemperature = dieTemperature) "RP2040 core: external D0-D10 pads plus internal RGB LED GPIOs" annotation(
    Placement(transformation(origin = {-45, 0}, extent = {{-45, -45}, {45, 45}}))));
  parameter Modelica.Units.NonSI.Temperature_degC dieTemperature = 27 "RP2040 die temperature, read by machine.ADC(4)" annotation(
    Dialog(tab = "Power supply", group = "Temperature sensor"));
  parameter Modelica.Units.SI.Resistance ledSeriesR = 330 "Series resistance of each active-low RGB LED channel" annotation(
    Dialog(tab = "Electrical", group = "On-board LEDs"));
  parameter Modelica.Units.SI.Resistance powerLedSeriesR = 1000 "Series resistance of the green power LED" annotation(
    Dialog(tab = "Electrical", group = "On-board LEDs"));
  Modelica.Electrical.Analog.Interfaces.PositivePin D0 "XIAO D0, RP2040 GPIO26 (machine.Pin(26), ADC(0))" annotation(
    Placement(transformation(origin = {-300, 140}, extent = {{-6, -6}, {6, 6}}), iconTransformation(origin = {-80, 60}, extent = {{-5, -5}, {5, 5}})));
  Modelica.Electrical.Analog.Interfaces.PositivePin D1 "XIAO D1, RP2040 GPIO27 (machine.Pin(27), ADC(1))" annotation(
    Placement(transformation(origin = {-300, 112}, extent = {{-6, -6}, {6, 6}}), iconTransformation(origin = {-80, 40}, extent = {{-5, -5}, {5, 5}})));
  Modelica.Electrical.Analog.Interfaces.PositivePin D2 "XIAO D2, RP2040 GPIO28 (machine.Pin(28), ADC(2))" annotation(
    Placement(transformation(origin = {-300, 84}, extent = {{-6, -6}, {6, 6}}), iconTransformation(origin = {-80, 20}, extent = {{-5, -5}, {5, 5}})));
  Modelica.Electrical.Analog.Interfaces.PositivePin D3 "XIAO D3, RP2040 GPIO29 (machine.Pin(29), ADC(3))" annotation(
    Placement(transformation(origin = {-300, 56}, extent = {{-6, -6}, {6, 6}}), iconTransformation(origin = {-80, 0}, extent = {{-5, -5}, {5, 5}})));
  Modelica.Electrical.Analog.Interfaces.PositivePin D4 "XIAO D4, RP2040 GPIO6 (machine.Pin(6))" annotation(
    Placement(transformation(origin = {-300, 28}, extent = {{-6, -6}, {6, 6}}), iconTransformation(origin = {-80, -20}, extent = {{-5, -5}, {5, 5}})));
  Modelica.Electrical.Analog.Interfaces.PositivePin D5 "XIAO D5, RP2040 GPIO7 (machine.Pin(7))" annotation(
    Placement(transformation(origin = {-300, 0}, extent = {{-6, -6}, {6, 6}}), iconTransformation(origin = {-80, -40}, extent = {{-5, -5}, {5, 5}})));
  Modelica.Electrical.Analog.Interfaces.PositivePin D6 "XIAO D6, RP2040 GPIO0 (machine.Pin(0))" annotation(
    Placement(transformation(origin = {-300, -28}, extent = {{-6, -6}, {6, 6}}), iconTransformation(origin = {-80, -60}, extent = {{-5, -5}, {5, 5}})));
  Modelica.Electrical.Analog.Interfaces.PositivePin V5 "5 V USB-C input/output (do not drive externally while usbConnected is true)" annotation(
    Placement(transformation(origin = {300, 78}, extent = {{-6, -6}, {6, 6}}), iconTransformation(origin = {80, 60}, extent = {{-5, -5}, {5, 5}})));
  Modelica.Electrical.Analog.Interfaces.NegativePin GND "Ground" annotation(
    Placement(transformation(origin = {300, 46}, extent = {{-6, -6}, {6, 6}}), iconTransformation(origin = {80, 40}, extent = {{-5, -5}, {5, 5}})));
  Modelica.Electrical.Analog.Interfaces.PositivePin V3V3 "3.3 V regulated output for external circuits" annotation(
    Placement(transformation(origin = {300, 110}, extent = {{-6, -6}, {6, 6}}), iconTransformation(origin = {80, 20}, extent = {{-5, -5}, {5, 5}})));
  Modelica.Electrical.Analog.Interfaces.PositivePin D10 "XIAO D10, RP2040 GPIO3 (machine.Pin(3))" annotation(
    Placement(transformation(origin = {-300, -140}, extent = {{-6, -6}, {6, 6}}), iconTransformation(origin = {80, 0}, extent = {{-5, -5}, {5, 5}})));
  Modelica.Electrical.Analog.Interfaces.PositivePin D9 "XIAO D9, RP2040 GPIO4 (machine.Pin(4))" annotation(
    Placement(transformation(origin = {-300, -112}, extent = {{-6, -6}, {6, 6}}), iconTransformation(origin = {80, -20}, extent = {{-5, -5}, {5, 5}})));
  Modelica.Electrical.Analog.Interfaces.PositivePin D8 "XIAO D8, RP2040 GPIO2 (machine.Pin(2))" annotation(
    Placement(transformation(origin = {-300, -84}, extent = {{-6, -6}, {6, 6}}), iconTransformation(origin = {80, -40}, extent = {{-5, -5}, {5, 5}})));
  Modelica.Electrical.Analog.Interfaces.PositivePin D7 "XIAO D7, RP2040 GPIO1 (machine.Pin(1))" annotation(
    Placement(transformation(origin = {-300, -56}, extent = {{-6, -6}, {6, 6}}), iconTransformation(origin = {80, -60}, extent = {{-5, -5}, {5, 5}})));
  Interfaces.DisplayLinkOutput Display0 "Educational logical display link, not on the real board" annotation(
    Placement(transformation(origin = {300, 140}, extent = {{-6, -6}, {6, 6}}), iconTransformation(origin = {58, 84}, extent = {{-5, -5}, {5, 5}}, rotation = 90)));
  Internal.Boards.Rt6150 regulator(eta = eta) "Averaged 5 V to 3.3 V buck-boost regulator" annotation(
    Placement(transformation(origin = {120, 20}, extent = {{-20, -20}, {20, 20}})));
  Modelica.Electrical.Analog.Sources.ConstantVoltage usbSupply(V = VUsb) if usbConnected "USB-C 5 V supply" annotation(
    Placement(transformation(origin = {230, 0}, extent = {{-10, -10}, {10, 10}}, rotation = 270)));
  Modelica.Electrical.Analog.Basic.Resistor usbCable(R = RUsb) if usbConnected "USB cable and connector resistance" annotation(
    Placement(transformation(origin = {260, 10}, extent = {{-10, -10}, {10, 10}})));
  Modelica.Electrical.Analog.Basic.Resistor powerLedResistor(R = powerLedSeriesR) "Power LED current limiter" annotation(
    Placement(transformation(origin = {30, 85}, extent = {{-10, -10}, {10, 10}})));
  MicroPythonMCU.Peripherals.LED powerLed(colorOn = {0, 255, 0}, colorOff = {0, 35, 0}, IMax = 0.002) "On-board green power LED" annotation(
    Placement(transformation(origin = {60, 85}, extent = {{-10, -10}, {10, 10}})));
  Internal.Boards.XiaoRgbLed rgbLed(RSeries = ledSeriesR) "Single on-board RGB LED package" annotation(
    Placement(transformation(origin = {-150, 70}, extent = {{-10, -10}, {10, 10}})));
  Modelica.Units.SI.Voltage vRail = V3V3.v - core.gnd.v "Regulated 3.3 V rail";
  Modelica.Units.SI.Voltage vInput = V5.v - core.gnd.v "5 V input rail";
  Modelica.Units.SI.Current iInput = regulator.iIn "Current drawn by the regulator from the 5 V input";
equation
  connect(D0, core.pin[1]) annotation(
    Line(points = {{-300, 140}, {-220, 140}, {-220, 0}, {-94.5, 0}}, color = {0, 0, 255}));
  connect(D1, core.pin[2]) annotation(
    Line(points = {{-300, 112}, {-226, 112}, {-226, 0}, {-94.5, 0}}, color = {0, 0, 255}));
  connect(D2, core.pin[3]) annotation(
    Line(points = {{-300, 84}, {-232, 84}, {-232, 0}, {-94.5, 0}}, color = {0, 0, 255}));
  connect(D3, core.pin[4]) annotation(
    Line(points = {{-300, 56}, {-238, 56}, {-238, 0}, {-94.5, 0}}, color = {0, 0, 255}));
  connect(D4, core.pin[5]) annotation(
    Line(points = {{-300, 28}, {-244, 28}, {-244, 0}, {-94.5, 0}}, color = {0, 0, 255}));
  connect(D5, core.pin[6]) annotation(
    Line(points = {{-300, 0}, {-250, 0}, {-250, 0}, {-94.5, 0}}, color = {0, 0, 255}));
  connect(D6, core.pin[7]) annotation(
    Line(points = {{-300, -28}, {-244, -28}, {-244, 0}, {-94.5, 0}}, color = {0, 0, 255}));
  connect(D7, core.pin[8]) annotation(
    Line(points = {{-300, -56}, {-238, -56}, {-238, 0}, {-94.5, 0}}, color = {0, 0, 255}));
  connect(D8, core.pin[9]) annotation(
    Line(points = {{-300, -84}, {-232, -84}, {-232, 0}, {-94.5, 0}}, color = {0, 0, 255}));
  connect(D9, core.pin[10]) annotation(
    Line(points = {{-300, -112}, {-226, -112}, {-226, 0}, {-94.5, 0}}, color = {0, 0, 255}));
  connect(D10, core.pin[11]) annotation(
    Line(points = {{-300, -140}, {-220, -140}, {-220, 0}, {-94.5, 0}}, color = {0, 0, 255}));
  connect(GND, core.gnd) annotation(
    Line(points = {{300, 46}, {280, 46}, {280, -75}, {-45, -75}, {-45, -49.5}}, color = {90, 90, 90}));
  connect(V3V3, core.vdd) annotation(
    Line(points = {{300, 110}, {-45, 110}, {-45, 49.5}}, color = {220, 0, 0}));
  connect(V3V3, core.vref) annotation(
    Line(points = {{300, 110}, {-72, 110}, {-72, 49.5}}, color = {0, 150, 0}));
  connect(V3V3, regulator.vout) annotation(
    Line(points = {{300, 110}, {160, 110}, {160, 20}, {140, 20}}, color = {220, 0, 0}));
  connect(V3V3, powerLedResistor.p) annotation(
    Line(points = {{300, 110}, {20, 110}, {20, 85}}, color = {220, 0, 0}));
  connect(V3V3, rgbLed.vcc) annotation(
    Line(points = {{300, 110}, {-153, 110}, {-153, 79}}, color = {220, 0, 0}));
  connect(V5, regulator.vin) annotation(
    Line(points = {{300, 78}, {100, 78}, {100, 20}}, color = {160, 80, 0}));
  connect(V5, regulator.en) annotation(
    Line(points = {{300, 78}, {90, 78}, {90, -10}, {108, -10}, {108, 0}}, color = {150, 0, 200}));
  connect(usbSupply.p, usbCable.p) annotation(
    Line(points = {{230, 10}, {250, 10}}, color = {230, 120, 0}));
  connect(usbCable.n, V5) annotation(
    Line(points = {{270, 10}, {270, 78}, {300, 78}}, color = {230, 120, 0}));
  connect(powerLedResistor.n, powerLed.p) annotation(
    Line(points = {{40, 85}, {50, 85}}, color = {220, 0, 0}));
  connect(usbSupply.n, core.gnd) annotation(
    Line(points = {{230, -10}, {230, -75}, {-45, -75}, {-45, -49.5}}, color = {90, 90, 90}));
  connect(powerLed.n, core.gnd) annotation(
    Line(points = {{70, 85}, {70, -75}, {-45, -75}, {-45, -49.5}}, color = {90, 90, 90}));
  connect(regulator.gnd, core.gnd) annotation(
    Line(points = {{120, 0}, {120, -75}, {-45, -75}, {-45, -49.5}}, color = {90, 90, 90}));
  connect(rgbLed.redPin, core.pin[13]) annotation(
    Line(points = {{-141, 73.5}, {-102, 73.5}, {-102, 0}, {-94.5, 0}}, color = {0, 0, 255}));
  connect(rgbLed.greenPin, core.pin[12]) annotation(
    Line(points = {{-141, 70}, {-112, 70}, {-112, 0}, {-94.5, 0}}, color = {0, 0, 255}));
  connect(rgbLed.bluePin, core.pin[14]) annotation(
    Line(points = {{-141, 66.5}, {-122, 66.5}, {-122, 0}, {-94.5, 0}}, color = {0, 0, 255}));
  connect(core.Display0, Display0) annotation(
    Line(points = {{4.5, 27}, {10, 27}, {10, 140}, {300, 140}}, color = {28, 108, 200}));
  annotation(
    Icon(coordinateSystem(preserveAspectRatio = true, extent = {{-100, -110}, {100, 110}}, initialScale = 0.2), graphics = {Rectangle(lineColor = {20, 40, 35}, fillColor = {0, 115, 70}, fillPattern = FillPattern.Solid, extent = {{-70, 83}, {70, -83}}, radius = 4), Rectangle(lineColor = {110, 110, 110}, fillColor = {190, 190, 190}, fillPattern = FillPattern.Solid, extent = {{-33, 100}, {33, 72}}, radius = 3), Polygon(visible = usbConnected, lineColor = {200, 140, 0}, fillColor = {255, 210, 0}, fillPattern = FillPattern.Solid, points = {{4, 92}, {-6, 82}, {0, 82}, {-4, 77}, {7, 86}, {1, 86}}), Rectangle(lineColor = {20, 20, 20}, fillColor = {45, 45, 45}, fillPattern = FillPattern.Solid, extent = {{-24, 30}, {24, -18}}), Text(textColor = {230, 230, 230}, extent = {{-21, 12}, {21, -2}}, textString = "RP2040", fontSize = 7), Ellipse(lineColor = {80, 80, 80}, fillColor = DynamicSelect({0, 35, 0}, {0, integer(35 + 220*min(1, max(0, powerLed.mean.y)/powerLed.IMax)), 0}), fillPattern = FillPattern.Solid, extent = {{42, 63}, {52, 53}}), Text(textColor = {255, 255, 255}, extent = {{34, 50}, {60, 42}}, textString = "PWR", fontSize = 7), Ellipse(lineColor = {120, 120, 120}, fillColor = {85, 85, 85}, fillPattern = FillPattern.Solid, extent = {{-52, -47}, {-36, -63}}), Text(textColor = {230, 230, 230}, extent = {{-59, -39}, {-29, -45}}, textString = "RESET", fontSize = 6), Ellipse(lineColor = {120, 120, 120}, fillColor = {85, 85, 85}, fillPattern = FillPattern.Solid, extent = {{36, -47}, {52, -63}}), Text(textColor = {230, 230, 230}, extent = {{29, -39}, {59, -45}}, textString = "BOOT", fontSize = 6), Ellipse(lineColor = {80, 80, 80}, fillColor = DynamicSelect({30, 30, 30}, {integer(12 + 243*min(1, max(0, rgbLed.red.mean.y)/rgbLed.IMax)), integer(12 + 243*min(1, max(0, rgbLed.green.mean.y)/rgbLed.IMax)), integer(12 + 243*min(1, max(0, rgbLed.blue.mean.y)/rgbLed.IMax))}), fillPattern = FillPattern.Solid, extent = {{-12, -20}, {12, -44}}), Text(textColor = {255, 255, 255}, extent = {{-35, -66}, {35, -77}}, textString = "XIAO RP2040", textStyle = {TextStyle.Bold}, fontSize = 7), Text(textColor = {0, 0, 255}, extent = {{-120, 137}, {120, 120}}, textString = "%name"), Text(textColor = {255, 255, 255}, extent = {{-65, 67}, {-6, 53}}, textString = "D0 / GPIO26", horizontalAlignment = TextAlignment.Left, fontSize = 8), Text(textColor = {255, 255, 255}, extent = {{-65, 47}, {-6, 33}}, textString = "D1 / GPIO27", horizontalAlignment = TextAlignment.Left, fontSize = 8), Text(textColor = {255, 255, 255}, extent = {{-65, 27}, {-6, 13}}, textString = "D2 / GPIO28", horizontalAlignment = TextAlignment.Left, fontSize = 8), Text(textColor = {255, 255, 255}, extent = {{-65, 7}, {-6, -7}}, textString = "D3 / GPIO29", horizontalAlignment = TextAlignment.Left, fontSize = 8), Text(textColor = {255, 255, 255}, extent = {{-65, -13}, {-6, -27}}, textString = "D4 / GPIO6", horizontalAlignment = TextAlignment.Left, fontSize = 8), Text(textColor = {255, 255, 255}, extent = {{-65, -33}, {-6, -47}}, textString = "D5 / GPIO7", horizontalAlignment = TextAlignment.Left, fontSize = 8), Text(textColor = {255, 255, 255}, extent = {{-65, -53}, {-6, -67}}, textString = "D6 / GPIO0", horizontalAlignment = TextAlignment.Left, fontSize = 8), Text(textColor = {255, 255, 255}, extent = {{6, 67}, {65, 53}}, textString = "5V", horizontalAlignment = TextAlignment.Right, fontSize = 8), Text(textColor = {255, 255, 255}, extent = {{6, 47}, {65, 33}}, textString = "GND", horizontalAlignment = TextAlignment.Right, fontSize = 8), Text(textColor = {255, 255, 255}, extent = {{6, 27}, {65, 13}}, textString = "3V3", horizontalAlignment = TextAlignment.Right, fontSize = 8), Text(textColor = {255, 255, 255}, extent = {{6, 7}, {65, -7}}, textString = "D10 / GPIO3", horizontalAlignment = TextAlignment.Right, fontSize = 8), Text(textColor = {255, 255, 255}, extent = {{6, -13}, {65, -27}}, textString = "D9 / GPIO4", horizontalAlignment = TextAlignment.Right, fontSize = 8), Text(textColor = {255, 255, 255}, extent = {{6, -33}, {65, -47}}, textString = "D8 / GPIO2", horizontalAlignment = TextAlignment.Right, fontSize = 8), Text(textColor = {255, 255, 255}, extent = {{6, -53}, {65, -67}}, textString = "D7 / GPIO1", horizontalAlignment = TextAlignment.Right, fontSize = 8)}),
    Diagram(coordinateSystem(preserveAspectRatio = true, extent = {{-330, -175}, {330, 190}}), graphics = {Rectangle(lineColor = {205, 205, 205}, fillColor = {235, 242, 255}, fillPattern = FillPattern.Solid, extent = {{-320, 165}, {-190, -165}}, radius = 4), Rectangle(lineColor = {205, 205, 205}, fillColor = {242, 242, 242}, fillPattern = FillPattern.Solid, extent = {{-170, 125}, {5, -60}}, radius = 4), Rectangle(lineColor = {205, 205, 205}, fillColor = {255, 243, 228}, fillPattern = FillPattern.Solid, extent = {{15, 125}, {285, -90}}, radius = 4), Text(textColor = {90, 90, 90}, extent = {{-315, 160}, {-195, 146}}, textString = "XIAO pads"), Text(textColor = {90, 90, 90}, extent = {{-165, -40}, {0, -54}}, textString = "RP2040 core and RGB LED"), Text(textColor = {90, 90, 90}, extent = {{20, -78}, {170, -89}}, textString = "USB / 3.3 V supply and LEDs")}),
    Documentation(info = "<html>
<p>Replica of the <b>Seeed Studio XIAO RP2040</b> standard board (not the XIAO RP2040 Plus): 21 x 17.8 mm, USB-C and 14 edge pads. The board contains the shared RP2040 programmable core, a 3.3 V regulator, its power LED and the active-low RGB user LED. The BOOT and RESET buttons are drawn but not simulated.</p>
<h4>Pinout</h4>
<p>The schematic and icon show both the XIAO pad names (<code>D0</code>...<code>D10</code>) and the RP2040 GPIO numbers. In a script, keep using the real GPIO identifiers: <code>D0 = machine.Pin(26)</code>, <code>D1 = Pin(27)</code>, <code>D2 = Pin(28)</code>, <code>D3 = Pin(29)</code>, <code>D4 = Pin(6)</code>, <code>D5 = Pin(7)</code>, <code>D6 = Pin(0)</code>, <code>D7 = Pin(1)</code>, <code>D8 = Pin(2)</code>, <code>D9 = Pin(4)</code>, <code>D10 = Pin(3)</code>. D0-D3 are the four ADC inputs (<code>ADC(0)</code>...<code>ADC(3)</code>).</p>
<p>UART and I2C use the RP2040 <code>rp2</code> pin multiplexing. For example, the default <code>UART(0)</code> uses GPIO0/GPIO1 (D6/D7), and <code>I2C(1)</code> uses SCL GPIO7/SDA GPIO6 (D5/D4). GPIOs not exposed on the standard XIAO are rejected, even though they exist in the RP2040 silicon.</p>
<h4>Power</h4>
<p><code>usbConnected</code> (true by default) powers the 5 V input from USB-C. With USB disconnected, an external 5 V supply can be connected to <code>V5</code>. The averaged regulator supplies the RP2040, the pins and the <code>V3V3</code> output at 3.3 V. This is a simplified electrical model, not a component-level replica of the regulator. Do not connect an external 5 V supply while the USB source is enabled.</p>
<p>One on-board RGB LED package is driven by GPIO17 (red), GPIO16 (green) and GPIO25 (blue); all three channels are <b>active low</b>, as on the board. The power LED is connected to the 3.3 V rail and lights when the board is powered. The core starts on power-up and stops permanently below <code>VPowerOff</code>; a restart after power loss is not simulated.</p>
<p><code>Display0</code> is the educational logical display link also found on the other boards; it is not a physical XIAO connector. See <code>requirements.md</code>, decision \"Seeed Studio XIAO RP2040\".</p>
</html>"));
end XIAO_rp2040;
