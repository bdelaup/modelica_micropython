within MicroPythonMCU;

model RPi_Pico "Raspberry Pi Pico board: RP2040 programmable in MicroPython, real pinout and dimensions, power supply through USB, VBUS or VSYS and the on-board 3.3 V regulator"
  extends Internal.PartialMcuSettings;
  parameter Boolean usbConnected = true "USB cable plugged in: 5 V on VBUS (the board runs without any wiring) - false to supply the board through VBUS or VSYS" annotation(
    Dialog(tab = "Power supply", group = "USB"),
    choices(checkBox = true));
  parameter Modelica.Units.SI.Voltage VUsb = 5 "Voltage of the USB supply" annotation(
    Dialog(tab = "Power supply", group = "USB", enable = usbConnected));
  parameter Modelica.Units.SI.Resistance RUsb = 0.2 "Resistance of the USB cable and connector" annotation(
    Dialog(tab = "Power supply", group = "USB", enable = usbConnected));
  parameter Real eta(min = 0.1, max = 1) = 0.9 "Efficiency of the 3.3 V regulator" annotation(
    Dialog(tab = "Power supply", group = "Regulator"));
  parameter Modelica.Units.SI.Current ICore = 0.02 "Current drawn from the 3.3 V rail by the RP2040 and the flash while supplied (program running, pins excluded)" annotation(
    Dialog(tab = "Power supply", group = "Consumption"));
  parameter Modelica.Units.SI.Voltage VPowerOn = 1.8 "3.3 V rail voltage above which the RP2040 starts (power-on reset)" annotation(
    Dialog(tab = "Power supply", group = "Power-on"));
  parameter Modelica.Units.SI.Voltage VPowerOff = 1.6 "3.3 V rail voltage below which a running RP2040 stops for good (brown-out)" annotation(
    Dialog(tab = "Power supply", group = "Power-on"));
  parameter Modelica.Units.NonSI.Temperature_degC dieTemperature = 27 "Temperature of the RP2040, read by machine.ADC(4)" annotation(
    Dialog(tab = "Power supply", group = "Temperature sensor"));
  Modelica.Electrical.Analog.Interfaces.PositivePin GP0 "GPIO 0, physical pin 1 (machine.Pin(0))" annotation(
    Placement(transformation(origin = {-300, 230}, extent = {{-6, -6}, {6, 6}}), iconTransformation(origin = {-90, 190}, extent = {{-5, -5}, {5, 5}})));
  Modelica.Electrical.Analog.Interfaces.PositivePin GP1 "GPIO 1, physical pin 2 (machine.Pin(1))" annotation(
    Placement(transformation(origin = {-300, 212}, extent = {{-6, -6}, {6, 6}}), iconTransformation(origin = {-90, 170}, extent = {{-5, -5}, {5, 5}})));
  Modelica.Electrical.Analog.Interfaces.NegativePin GND_3 "Ground, physical pin 3 (all the GND pins and AGND are connected together)" annotation(
    Placement(transformation(origin = {-140, -250}, extent = {{-6, -6}, {6, 6}}), iconTransformation(origin = {-90, 150}, extent = {{-5, -5}, {5, 5}})));
  Modelica.Electrical.Analog.Interfaces.PositivePin GP2 "GPIO 2, physical pin 4 (machine.Pin(2))" annotation(
    Placement(transformation(origin = {-300, 194}, extent = {{-6, -6}, {6, 6}}), iconTransformation(origin = {-90, 130}, extent = {{-5, -5}, {5, 5}})));
  Modelica.Electrical.Analog.Interfaces.PositivePin GP3 "GPIO 3, physical pin 5 (machine.Pin(3))" annotation(
    Placement(transformation(origin = {-300, 176}, extent = {{-6, -6}, {6, 6}}), iconTransformation(origin = {-90, 110}, extent = {{-5, -5}, {5, 5}})));
  Modelica.Electrical.Analog.Interfaces.PositivePin GP4 "GPIO 4, physical pin 6 (machine.Pin(4))" annotation(
    Placement(transformation(origin = {-300, 158}, extent = {{-6, -6}, {6, 6}}), iconTransformation(origin = {-90, 90}, extent = {{-5, -5}, {5, 5}})));
  Modelica.Electrical.Analog.Interfaces.PositivePin GP5 "GPIO 5, physical pin 7 (machine.Pin(5))" annotation(
    Placement(transformation(origin = {-300, 140}, extent = {{-6, -6}, {6, 6}}), iconTransformation(origin = {-90, 70}, extent = {{-5, -5}, {5, 5}})));
  Modelica.Electrical.Analog.Interfaces.NegativePin GND_8 "Ground, physical pin 8 (all the GND pins and AGND are connected together)" annotation(
    Placement(transformation(origin = {-90, -250}, extent = {{-6, -6}, {6, 6}}), iconTransformation(origin = {-90, 50}, extent = {{-5, -5}, {5, 5}})));
  Modelica.Electrical.Analog.Interfaces.PositivePin GP6 "GPIO 6, physical pin 9 (machine.Pin(6))" annotation(
    Placement(transformation(origin = {-300, 122}, extent = {{-6, -6}, {6, 6}}), iconTransformation(origin = {-90, 30}, extent = {{-5, -5}, {5, 5}})));
  Modelica.Electrical.Analog.Interfaces.PositivePin GP7 "GPIO 7, physical pin 10 (machine.Pin(7))" annotation(
    Placement(transformation(origin = {-300, 104}, extent = {{-6, -6}, {6, 6}}), iconTransformation(origin = {-90, 10}, extent = {{-5, -5}, {5, 5}})));
  Modelica.Electrical.Analog.Interfaces.PositivePin GP8 "GPIO 8, physical pin 11 (machine.Pin(8))" annotation(
    Placement(transformation(origin = {-300, 86}, extent = {{-6, -6}, {6, 6}}), iconTransformation(origin = {-90, -10}, extent = {{-5, -5}, {5, 5}})));
  Modelica.Electrical.Analog.Interfaces.PositivePin GP9 "GPIO 9, physical pin 12 (machine.Pin(9))" annotation(
    Placement(transformation(origin = {-300, 68}, extent = {{-6, -6}, {6, 6}}), iconTransformation(origin = {-90, -30}, extent = {{-5, -5}, {5, 5}})));
  Modelica.Electrical.Analog.Interfaces.NegativePin GND_13 "Ground, physical pin 13 (all the GND pins and AGND are connected together)" annotation(
    Placement(transformation(origin = {-40, -250}, extent = {{-6, -6}, {6, 6}}), iconTransformation(origin = {-90, -50}, extent = {{-5, -5}, {5, 5}})));
  Modelica.Electrical.Analog.Interfaces.PositivePin GP10 "GPIO 10, physical pin 14 (machine.Pin(10))" annotation(
    Placement(transformation(origin = {-300, 50}, extent = {{-6, -6}, {6, 6}}), iconTransformation(origin = {-90, -70}, extent = {{-5, -5}, {5, 5}})));
  Modelica.Electrical.Analog.Interfaces.PositivePin GP11 "GPIO 11, physical pin 15 (machine.Pin(11))" annotation(
    Placement(transformation(origin = {-300, 32}, extent = {{-6, -6}, {6, 6}}), iconTransformation(origin = {-90, -90}, extent = {{-5, -5}, {5, 5}})));
  Modelica.Electrical.Analog.Interfaces.PositivePin GP12 "GPIO 12, physical pin 16 (machine.Pin(12))" annotation(
    Placement(transformation(origin = {-300, 14}, extent = {{-6, -6}, {6, 6}}), iconTransformation(origin = {-90, -110}, extent = {{-5, -5}, {5, 5}})));
  Modelica.Electrical.Analog.Interfaces.PositivePin GP13 "GPIO 13, physical pin 17 (machine.Pin(13))" annotation(
    Placement(transformation(origin = {-300, -4}, extent = {{-6, -6}, {6, 6}}), iconTransformation(origin = {-90, -130}, extent = {{-5, -5}, {5, 5}})));
  Modelica.Electrical.Analog.Interfaces.NegativePin GND_18 "Ground, physical pin 18 (all the GND pins and AGND are connected together)" annotation(
    Placement(transformation(origin = {10, -250}, extent = {{-6, -6}, {6, 6}}), iconTransformation(origin = {-90, -150}, extent = {{-5, -5}, {5, 5}})));
  Modelica.Electrical.Analog.Interfaces.PositivePin GP14 "GPIO 14, physical pin 19 (machine.Pin(14))" annotation(
    Placement(transformation(origin = {-300, -22}, extent = {{-6, -6}, {6, 6}}), iconTransformation(origin = {-90, -170}, extent = {{-5, -5}, {5, 5}})));
  Modelica.Electrical.Analog.Interfaces.PositivePin GP15 "GPIO 15, physical pin 20 (machine.Pin(15))" annotation(
    Placement(transformation(origin = {-300, -40}, extent = {{-6, -6}, {6, 6}}), iconTransformation(origin = {-90, -190}, extent = {{-5, -5}, {5, 5}})));
  Modelica.Electrical.Analog.Interfaces.PositivePin VBUS "Micro-USB input voltage, physical pin 40: 5 V from the USB connector when usbConnected, otherwise free (an external 5 V supply can be connected here)" annotation(
    Placement(transformation(origin = {300, 220}, extent = {{-6, -6}, {6, 6}}), iconTransformation(origin = {90, 190}, extent = {{-5, -5}, {5, 5}})));
  Modelica.Electrical.Analog.Interfaces.PositivePin VSYS "Main system input, physical pin 39: 1.8 to 5.5 V, supplied from VBUS through a Schottky diode, or directly from a battery" annotation(
    Placement(transformation(origin = {300, 170}, extent = {{-6, -6}, {6, 6}}), iconTransformation(origin = {90, 170}, extent = {{-5, -5}, {5, 5}})));
  Modelica.Electrical.Analog.Interfaces.NegativePin GND_38 "Ground, physical pin 38 (all the GND pins and AGND are connected together)" annotation(
    Placement(transformation(origin = {60, -250}, extent = {{-6, -6}, {6, 6}}), iconTransformation(origin = {90, 150}, extent = {{-5, -5}, {5, 5}})));
  Modelica.Electrical.Analog.Interfaces.PositivePin V3V3_EN "Enable of the 3.3 V regulator (3V3_EN), physical pin 37: pulled up to VSYS by 100 kOhm, to ground to switch the regulator off" annotation(
    Placement(transformation(origin = {300, 120}, extent = {{-6, -6}, {6, 6}}), iconTransformation(origin = {90, 130}, extent = {{-5, -5}, {5, 5}})));
  Modelica.Electrical.Analog.Interfaces.PositivePin V3V3 "3.3 V output of the regulator (3V3(OUT)), physical pin 36: supplies external circuits (keep the load under 300 mA)" annotation(
    Placement(transformation(origin = {300, 60}, extent = {{-6, -6}, {6, 6}}), iconTransformation(origin = {90, 110}, extent = {{-5, -5}, {5, 5}})));
  Modelica.Electrical.Analog.Interfaces.PositivePin ADC_VREF "ADC reference voltage, physical pin 35: 3V3 filtered through 200 Ohm on the board; can be driven by an external reference" annotation(
    Placement(transformation(origin = {300, 10}, extent = {{-6, -6}, {6, 6}}), iconTransformation(origin = {90, 90}, extent = {{-5, -5}, {5, 5}})));
  Modelica.Electrical.Analog.Interfaces.PositivePin GP28 "GPIO 28, physical pin 34 (machine.Pin(28), machine.ADC(2))" annotation(
    Placement(transformation(origin = {-300, -220}, extent = {{-6, -6}, {6, 6}}), iconTransformation(origin = {90, 70}, extent = {{-5, -5}, {5, 5}})));
  Modelica.Electrical.Analog.Interfaces.NegativePin AGND "Analog ground of the ADC, physical pin 33 (connected to GND)" annotation(
    Placement(transformation(origin = {210, -250}, extent = {{-6, -6}, {6, 6}}), iconTransformation(origin = {90, 50}, extent = {{-5, -5}, {5, 5}})));
  Modelica.Electrical.Analog.Interfaces.PositivePin GP27 "GPIO 27, physical pin 32 (machine.Pin(27), machine.ADC(1))" annotation(
    Placement(transformation(origin = {-300, -202}, extent = {{-6, -6}, {6, 6}}), iconTransformation(origin = {90, 30}, extent = {{-5, -5}, {5, 5}})));
  Modelica.Electrical.Analog.Interfaces.PositivePin GP26 "GPIO 26, physical pin 31 (machine.Pin(26), machine.ADC(0))" annotation(
    Placement(transformation(origin = {-300, -184}, extent = {{-6, -6}, {6, 6}}), iconTransformation(origin = {90, 10}, extent = {{-5, -5}, {5, 5}})));
  Modelica.Electrical.Analog.Interfaces.PositivePin RUN "RP2040 enable, physical pin 30: internal pull-up to 3V3; to ground, the RP2040 is held in reset (the program stops for good, a restart is not simulated)" annotation(
    Placement(transformation(origin = {300, -60}, extent = {{-6, -6}, {6, 6}}), iconTransformation(origin = {90, -10}, extent = {{-5, -5}, {5, 5}})));
  Modelica.Electrical.Analog.Interfaces.PositivePin GP22 "GPIO 22, physical pin 29 (machine.Pin(22))" annotation(
    Placement(transformation(origin = {-300, -166}, extent = {{-6, -6}, {6, 6}}), iconTransformation(origin = {90, -30}, extent = {{-5, -5}, {5, 5}})));
  Modelica.Electrical.Analog.Interfaces.NegativePin GND_28 "Ground, physical pin 28 (all the GND pins and AGND are connected together)" annotation(
    Placement(transformation(origin = {110, -250}, extent = {{-6, -6}, {6, 6}}), iconTransformation(origin = {90, -50}, extent = {{-5, -5}, {5, 5}})));
  Modelica.Electrical.Analog.Interfaces.PositivePin GP21 "GPIO 21, physical pin 27 (machine.Pin(21))" annotation(
    Placement(transformation(origin = {-300, -148}, extent = {{-6, -6}, {6, 6}}), iconTransformation(origin = {90, -70}, extent = {{-5, -5}, {5, 5}})));
  Modelica.Electrical.Analog.Interfaces.PositivePin GP20 "GPIO 20, physical pin 26 (machine.Pin(20))" annotation(
    Placement(transformation(origin = {-300, -130}, extent = {{-6, -6}, {6, 6}}), iconTransformation(origin = {90, -90}, extent = {{-5, -5}, {5, 5}})));
  Modelica.Electrical.Analog.Interfaces.PositivePin GP19 "GPIO 19, physical pin 25 (machine.Pin(19))" annotation(
    Placement(transformation(origin = {-300, -112}, extent = {{-6, -6}, {6, 6}}), iconTransformation(origin = {90, -110}, extent = {{-5, -5}, {5, 5}})));
  Modelica.Electrical.Analog.Interfaces.PositivePin GP18 "GPIO 18, physical pin 24 (machine.Pin(18))" annotation(
    Placement(transformation(origin = {-300, -94}, extent = {{-6, -6}, {6, 6}}), iconTransformation(origin = {90, -130}, extent = {{-5, -5}, {5, 5}})));
  Modelica.Electrical.Analog.Interfaces.NegativePin GND_23 "Ground, physical pin 23 (all the GND pins and AGND are connected together)" annotation(
    Placement(transformation(origin = {160, -250}, extent = {{-6, -6}, {6, 6}}), iconTransformation(origin = {90, -150}, extent = {{-5, -5}, {5, 5}})));
  Modelica.Electrical.Analog.Interfaces.PositivePin GP17 "GPIO 17, physical pin 22 (machine.Pin(17))" annotation(
    Placement(transformation(origin = {-300, -76}, extent = {{-6, -6}, {6, 6}}), iconTransformation(origin = {90, -170}, extent = {{-5, -5}, {5, 5}})));
  Modelica.Electrical.Analog.Interfaces.PositivePin GP16 "GPIO 16, physical pin 21 (machine.Pin(16))" annotation(
    Placement(transformation(origin = {-300, -58}, extent = {{-6, -6}, {6, 6}}), iconTransformation(origin = {90, -190}, extent = {{-5, -5}, {5, 5}})));
  Interfaces.DisplayLinkOutput Display0 "Logical link to an educational display peripheral (machine.Display(0).write()) - not on the real board: simplified causal link, see requirements.md decision \"Périphérique d'affichage pédagogique\"" annotation(
    Placement(transformation(origin = {300, -120}, extent = {{-6, -6}, {6, 6}}), iconTransformation(origin = {60, 210}, extent = {{-5, -5}, {5, 5}}, rotation = 90)));
  Internal.McuCore core(final nPins = 30, final pinIds = {i for i in 0:29}, final pinCaps = {3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 1, 1, 1, 7, 7, 7, 5}, final boardProfile = "pico", final instanceName = boardName, final hasTempSensor = true, final dieTemperature = dieTemperature, final ICore = ICore, final VPowerOn = VPowerOn, final VPowerOff = VPowerOff, final scriptPath = scriptPath, final addScriptDirToPath = addScriptDirToPath, final libraryPath = libraryPath, final fsEnabled = fsEnabled, final fsSource = fsSource, final fsWorkspace = fsWorkspace, final fsOpenExplorer = fsOpenExplorer, final tickPeriod = tickPeriod, final gpioOpTime = gpioOpTime, final hangWarningTime = hangWarningTime, final debugEnabled = debugEnabled, final debugPort = debugPort, final VOL = VOL, final VIH = VIH, final VIL = VIL, final ROut = ROut, final ledSeriesR = ledSeriesR, final RPullUp = RPullUp, final RPullDown = RPullDown, final GOff = GOff) "The RP2040: pin[i] = GPIO i-1 (GP0-GP22, GP23 power-save, GP24 VBUS sense, GP25 LED, GP26-GP28, GP29 VSYS/3)" annotation(
    Placement(transformation(origin = {-120, -20}, extent = {{-70, -70}, {70, 70}})));
  Internal.Rt6150 regulator(eta = eta) "Buck-boost regulator VSYS -> 3.3 V (RT6150B)" annotation(
    Placement(transformation(origin = {176, 120}, extent = {{-20, -20}, {20, 20}})));
  MicroPythonMCU.Peripherals.LED builtinLed "On-board LED (GPIO25)" annotation(
    Placement(transformation(origin = {-110, -170}, extent = {{-10, -10}, {10, 10}})));
  Modelica.Units.SI.Voltage vRail = V3V3.v - core.gnd.v "Voltage of the 3.3 V rail (3V3(OUT))";
  Modelica.Units.SI.Voltage vSys = VSYS.v - core.gnd.v "Voltage of VSYS";
  Modelica.Units.SI.Current iSys = regulator.iIn "Current drawn from VSYS by the regulator";
protected
  final parameter String boardName = getInstanceName() "Instance name of the board, given to the core (log prefix, name of the copy of the flash): getInstanceName() written in the modifier of core would return the name of the core";
  Modelica.Electrical.Analog.Sources.ConstantVoltage usbSupply(V = VUsb) if usbConnected "USB supply (5 V)" annotation(
    Placement(transformation(origin = {40, 200}, extent = {{-10, -10}, {10, 10}}, rotation = 270)));
  Modelica.Electrical.Analog.Basic.Resistor usbCable(R = RUsb) if usbConnected "Resistance of the USB cable" annotation(
    Placement(transformation(origin = {70, 220}, extent = {{-10, -10}, {10, 10}})));
  Modelica.Electrical.Analog.Ideal.IdealDiode schottky(Vknee = 0.3, Ron = 0.2, Goff = 1e-7) "Schottky diode from VBUS to VSYS (MBR120)" annotation(
    Placement(transformation(origin = {200, 200}, extent = {{-10, -10}, {10, 10}}, rotation = 270)));
  Modelica.Electrical.Analog.Basic.Resistor vbusSenseTop(R = 5.6e3) "VBUS sense divider, top (to GPIO24)" annotation(
    Placement(transformation(origin = {120, 190}, extent = {{-10, -10}, {10, 10}}, rotation = 270)));
  Modelica.Electrical.Analog.Basic.Resistor vbusSenseBottom(R = 10e3) "VBUS sense divider, bottom" annotation(
    Placement(transformation(origin = {120, 150}, extent = {{-10, -10}, {10, 10}}, rotation = 270)));
  Modelica.Electrical.Analog.Basic.Resistor vsysSenseTop(R = 200e3) "VSYS/3 divider, top (to GPIO29, ADC(3))" annotation(
    Placement(transformation(origin = {240, 150}, extent = {{-10, -10}, {10, 10}}, rotation = 270)));
  Modelica.Electrical.Analog.Basic.Resistor vsysSenseBottom(R = 100e3) "VSYS/3 divider, bottom" annotation(
    Placement(transformation(origin = {240, 110}, extent = {{-10, -10}, {10, 10}}, rotation = 270)));
  Modelica.Electrical.Analog.Basic.Resistor enPullUp(R = 100e3) "Pull-up of 3V3_EN to VSYS" annotation(
    Placement(transformation(origin = {270, 150}, extent = {{-10, -10}, {10, 10}}, rotation = 270)));
  Modelica.Electrical.Analog.Basic.Resistor vrefFilter(R = 200) "ADC_VREF filter from 3V3" annotation(
    Placement(transformation(origin = {240, 30}, extent = {{-10, -10}, {10, 10}}, rotation = 270)));
  Modelica.Electrical.Analog.Basic.Resistor ledResistor(R = ledSeriesR) "Series resistance of the on-board LED" annotation(
    Placement(transformation(origin = {-150, -170}, extent = {{-10, -10}, {10, 10}})));
equation
  connect(GP0, core.pin[1]) annotation(
    Line(points = {{-300, 230}, {-230, 230}, {-230, -20}, {-197, -20}}, color = {0, 0, 255}));
  connect(GP1, core.pin[2]) annotation(
    Line(points = {{-300, 212}, {-230, 212}, {-230, -20}, {-197, -20}}, color = {0, 0, 255}));
  connect(GP2, core.pin[3]) annotation(
    Line(points = {{-300, 194}, {-230, 194}, {-230, -20}, {-197, -20}}, color = {0, 0, 255}));
  connect(GP3, core.pin[4]) annotation(
    Line(points = {{-300, 176}, {-230, 176}, {-230, -20}, {-197, -20}}, color = {0, 0, 255}));
  connect(GP4, core.pin[5]) annotation(
    Line(points = {{-300, 158}, {-230, 158}, {-230, -20}, {-197, -20}}, color = {0, 0, 255}));
  connect(GP5, core.pin[6]) annotation(
    Line(points = {{-300, 140}, {-230, 140}, {-230, -20}, {-197, -20}}, color = {0, 0, 255}));
  connect(GP6, core.pin[7]) annotation(
    Line(points = {{-300, 122}, {-230, 122}, {-230, -20}, {-197, -20}}, color = {0, 0, 255}));
  connect(GP7, core.pin[8]) annotation(
    Line(points = {{-300, 104}, {-230, 104}, {-230, -20}, {-197, -20}}, color = {0, 0, 255}));
  connect(GP8, core.pin[9]) annotation(
    Line(points = {{-300, 86}, {-230, 86}, {-230, -20}, {-197, -20}}, color = {0, 0, 255}));
  connect(GP9, core.pin[10]) annotation(
    Line(points = {{-300, 68}, {-230, 68}, {-230, -20}, {-197, -20}}, color = {0, 0, 255}));
  connect(GP10, core.pin[11]) annotation(
    Line(points = {{-300, 50}, {-230, 50}, {-230, -20}, {-197, -20}}, color = {0, 0, 255}));
  connect(GP11, core.pin[12]) annotation(
    Line(points = {{-300, 32}, {-230, 32}, {-230, -20}, {-197, -20}}, color = {0, 0, 255}));
  connect(GP12, core.pin[13]) annotation(
    Line(points = {{-300, 14}, {-230, 14}, {-230, -20}, {-197, -20}}, color = {0, 0, 255}));
  connect(GP13, core.pin[14]) annotation(
    Line(points = {{-300, -4}, {-230, -4}, {-230, -20}, {-197, -20}}, color = {0, 0, 255}));
  connect(GP14, core.pin[15]) annotation(
    Line(points = {{-300, -22}, {-230, -22}, {-230, -20}, {-197, -20}}, color = {0, 0, 255}));
  connect(GP15, core.pin[16]) annotation(
    Line(points = {{-300, -40}, {-230, -40}, {-230, -20}, {-197, -20}}, color = {0, 0, 255}));
  connect(GP16, core.pin[17]) annotation(
    Line(points = {{-300, -58}, {-230, -58}, {-230, -20}, {-197, -20}}, color = {0, 0, 255}));
  connect(GP17, core.pin[18]) annotation(
    Line(points = {{-300, -76}, {-230, -76}, {-230, -20}, {-197, -20}}, color = {0, 0, 255}));
  connect(GP18, core.pin[19]) annotation(
    Line(points = {{-300, -94}, {-230, -94}, {-230, -20}, {-197, -20}}, color = {0, 0, 255}));
  connect(GP19, core.pin[20]) annotation(
    Line(points = {{-300, -112}, {-230, -112}, {-230, -20}, {-197, -20}}, color = {0, 0, 255}));
  connect(GP20, core.pin[21]) annotation(
    Line(points = {{-300, -130}, {-230, -130}, {-230, -20}, {-197, -20}}, color = {0, 0, 255}));
  connect(GP21, core.pin[22]) annotation(
    Line(points = {{-300, -148}, {-230, -148}, {-230, -20}, {-197, -20}}, color = {0, 0, 255}));
  connect(GP22, core.pin[23]) annotation(
    Line(points = {{-300, -166}, {-230, -166}, {-230, -20}, {-197, -20}}, color = {0, 0, 255}));
  connect(GP26, core.pin[27]) annotation(
    Line(points = {{-300, -184}, {-230, -184}, {-230, -20}, {-197, -20}}, color = {0, 0, 255}));
  connect(GP27, core.pin[28]) annotation(
    Line(points = {{-300, -202}, {-230, -202}, {-230, -20}, {-197, -20}}, color = {0, 0, 255}));
  connect(GP28, core.pin[29]) annotation(
    Line(points = {{-300, -220}, {-230, -220}, {-230, -20}, {-197, -20}}, color = {0, 0, 255}));
  connect(GND_3, core.gnd) annotation(
    Line(points = {{-140, -250}, {-140, -230}, {-120, -230}, {-120, -97}}, color = {90, 90, 90}, thickness = 0.5));
  connect(GND_8, core.gnd) annotation(
    Line(points = {{-90, -250}, {-90, -230}, {-120, -230}, {-120, -97}}, color = {90, 90, 90}, thickness = 0.5));
  connect(GND_13, core.gnd) annotation(
    Line(points = {{-40, -250}, {-40, -230}, {-120, -230}, {-120, -97}}, color = {90, 90, 90}, thickness = 0.5));
  connect(GND_18, core.gnd) annotation(
    Line(points = {{10, -250}, {10, -230}, {-120, -230}, {-120, -97}}, color = {90, 90, 90}, thickness = 0.5));
  connect(GND_38, core.gnd) annotation(
    Line(points = {{60, -250}, {60, -230}, {-120, -230}, {-120, -97}}, color = {90, 90, 90}, thickness = 0.5));
  connect(GND_28, core.gnd) annotation(
    Line(points = {{110, -250}, {110, -230}, {-120, -230}, {-120, -97}}, color = {90, 90, 90}, thickness = 0.5));
  connect(GND_23, core.gnd) annotation(
    Line(points = {{160, -250}, {160, -230}, {-120, -230}, {-120, -97}}, color = {90, 90, 90}, thickness = 0.5));
  connect(AGND, core.gnd) annotation(
    Line(points = {{210, -250}, {210, -230}, {-120, -230}, {-120, -97}}, color = {90, 90, 90}, thickness = 0.5));
  connect(usbSupply.p, usbCable.p) annotation(
    Line(points = {{40, 210}, {40, 220}, {60, 220}}, color = {230, 120, 0}, thickness = 0.75));
  connect(usbCable.n, VBUS) annotation(
    Line(points = {{80, 220}, {300, 220}}, color = {230, 120, 0}, thickness = 0.75));
  connect(usbSupply.n, core.gnd) annotation(
    Line(points = {{40, 190}, {40, -230}, {-120, -230}}, color = {90, 90, 90}, thickness = 0.5));
  connect(VBUS, schottky.p) annotation(
    Line(points = {{300, 220}, {200, 220}, {200, 210}}, color = {230, 120, 0}, thickness = 0.75));
  connect(schottky.n, VSYS) annotation(
    Line(points = {{200, 190}, {200, 170}, {300, 170}}, color = {160, 80, 0}, thickness = 0.75));
  connect(VBUS, vbusSenseTop.p) annotation(
    Line(points = {{300, 220}, {120, 220}, {120, 200}}, color = {230, 120, 0}, thickness = 0.75));
  connect(vbusSenseTop.n, vbusSenseBottom.p) annotation(
    Line(points = {{120, 180}, {120, 160}}, color = {0, 150, 0}, thickness = 0.5));
  connect(vbusSenseBottom.n, core.gnd) annotation(
    Line(points = {{120, 140}, {120, -230}, {-120, -230}}, color = {90, 90, 90}, thickness = 0.5));
  connect(vbusSenseTop.n, core.pin[25]) annotation(
    Line(points = {{120, 180}, {90, 180}, {-215, 180}, {-215, -20}, {-197, -20}}, color = {0, 150, 0}, thickness = 0.5));
  connect(VSYS, vsysSenseTop.p) annotation(
    Line(points = {{300, 170}, {240, 170}, {240, 160}}, color = {160, 80, 0}, thickness = 0.75));
  connect(vsysSenseTop.n, vsysSenseBottom.p) annotation(
    Line(points = {{240, 140}, {240, 120}}, color = {0, 150, 0}, thickness = 0.5));
  connect(vsysSenseBottom.n, core.gnd) annotation(
    Line(points = {{240, 100}, {240, -230}, {-120, -230}}, color = {90, 90, 90}, thickness = 0.5));
  connect(vsysSenseTop.n, core.pin[30]) annotation(
    Line(points = {{240, 140}, {255, 140}, {255, 80}, {-215, 80}, {-215, -20}, {-197, -20}}, color = {0, 150, 0}, thickness = 0.5));
  connect(VSYS, enPullUp.p) annotation(
    Line(points = {{300, 170}, {270, 170}, {270, 160}}, color = {160, 80, 0}, thickness = 0.75));
  connect(enPullUp.n, V3V3_EN) annotation(
    Line(points = {{270, 140}, {270, 120}, {300, 120}}, color = {150, 0, 200}, thickness = 0.5));
  connect(V3V3_EN, regulator.en) annotation(
    Line(points = {{300, 120}, {280, 120}, {280, 90}, {164, 90}, {164, 100}}, color = {150, 0, 200}, thickness = 0.5));
  connect(VSYS, regulator.vin) annotation(
    Line(points = {{300, 170}, {138, 170}, {138, 120}, {156, 120}}, color = {160, 80, 0}, thickness = 0.75));
  connect(regulator.gnd, core.gnd) annotation(
    Line(points = {{176, 100}, {176, -230}, {-120, -230}}, color = {90, 90, 90}, thickness = 0.5));
  connect(regulator.vout, V3V3) annotation(
    Line(points = {{196, 120}, {203, 120}, {203, 60}, {300, 60}}, color = {220, 0, 0}, thickness = 0.75));
  connect(V3V3, core.vdd) annotation(
    Line(points = {{300, 60}, {-120, 60}, {-120, 57}}, color = {220, 0, 0}, thickness = 0.75));
  connect(V3V3, vrefFilter.p) annotation(
    Line(points = {{300, 60}, {240, 60}, {240, 40}}, color = {220, 0, 0}, thickness = 0.75));
  connect(vrefFilter.n, ADC_VREF) annotation(
    Line(points = {{240, 20}, {240, 10}, {300, 10}}, color = {0, 150, 0}, thickness = 0.5));
  connect(ADC_VREF, core.vref) annotation(
    Line(points = {{300, 10}, {285, 10}, {285, 70}, {-162, 70}, {-162, 57}}, color = {0, 150, 0}, thickness = 0.5));
  connect(RUN, core.run) annotation(
    Line(points = {{300, -60}, {-43, -60}, {-43, -62}}, color = {150, 0, 200}, thickness = 0.5));
  connect(core.Display0, Display0) annotation(
    Line(points = {{-43, 22}, {20, 22}, {20, -120}, {300, -120}}, color = {28, 108, 200}, thickness = 0.5));
  connect(core.pin[26], ledResistor.p) annotation(
    Line(points = {{-197, -20}, {-215, -20}, {-215, -170}, {-160, -170}}, color = {0, 0, 255}));
  connect(ledResistor.n, builtinLed.p) annotation(
    Line(points = {{-140, -170}, {-120, -170}}, color = {0, 0, 255}));
  connect(builtinLed.n, core.gnd) annotation(
    Line(points = {{-100, -170}, {-100, -230}, {-120, -230}}, color = {90, 90, 90}, thickness = 0.5));
// GPIO23 (core.pin[24]): power-save mode of the regulator, no electrical effect in the averaged model (Internal.Rt6150)
  annotation(
    Icon(coordinateSystem(preserveAspectRatio = true, extent = {{-100, -210}, {100, 270}}, initialScale = 0.2), graphics = {Rectangle(lineColor = {0, 90, 40}, fillColor = {0, 120, 60}, fillPattern = FillPattern.Solid, extent = {{-82.7, 200.8}, {82.7, -200.8}}, radius = 6), Rectangle(lineColor = {110, 110, 110}, fillColor = {200, 200, 200}, fillPattern = FillPattern.Solid, extent = {{-31.5, 211}, {31.5, 166.9}}), Polygon(visible = usbConnected, lineColor = {200, 140, 0}, fillColor = {255, 210, 0}, fillPattern = FillPattern.Solid, points = {{4.5, 206}, {-6, 189.5}, {0, 189.5}, {-4.5, 173}, {7.5, 194}, {1.5, 194}, {6, 206}}), Ellipse(lineColor = {230, 190, 60}, lineThickness = 0.75, fillColor = {0, 80, 35}, fillPattern = FillPattern.Solid, extent = {{-53.2, -176.8}, {-36.6, -193.4}}), Ellipse(lineColor = {230, 190, 60}, lineThickness = 0.75, fillColor = {0, 80, 35}, fillPattern = FillPattern.Solid, extent = {{-53.2, 193.4}, {-36.6, 176.8}}), Ellipse(lineColor = {230, 190, 60}, lineThickness = 0.75, fillColor = {0, 80, 35}, fillPattern = FillPattern.Solid, extent = {{36.6, -176.8}, {53.2, -193.4}}), Ellipse(lineColor = {230, 190, 60}, lineThickness = 0.75, fillColor = {0, 80, 35}, fillPattern = FillPattern.Solid, extent = {{36.6, 193.4}, {53.2, 176.8}}), Ellipse(lineColor = {200, 160, 40}, fillColor = {230, 190, 60}, fillPattern = FillPattern.Solid, extent = {{-77, 197}, {-63, 183}}), Ellipse(lineColor = {200, 160, 40}, fillColor = {230, 190, 60}, fillPattern = FillPattern.Solid, extent = {{63, 197}, {77, 183}}), Ellipse(lineColor = {200, 160, 40}, fillColor = {230, 190, 60}, fillPattern = FillPattern.Solid, extent = {{-77, 177}, {-63, 163}}), Ellipse(lineColor = {200, 160, 40}, fillColor = {230, 190, 60}, fillPattern = FillPattern.Solid, extent = {{63, 177}, {77, 163}}), Ellipse(lineColor = {200, 160, 40}, fillColor = {230, 190, 60}, fillPattern = FillPattern.Solid, extent = {{-77, 157}, {-63, 143}}), Ellipse(lineColor = {200, 160, 40}, fillColor = {230, 190, 60}, fillPattern = FillPattern.Solid, extent = {{63, 157}, {77, 143}}), Ellipse(lineColor = {200, 160, 40}, fillColor = {230, 190, 60}, fillPattern = FillPattern.Solid, extent = {{-77, 137}, {-63, 123}}), Ellipse(lineColor = {200, 160, 40}, fillColor = {230, 190, 60}, fillPattern = FillPattern.Solid, extent = {{63, 137}, {77, 123}}), Ellipse(lineColor = {200, 160, 40}, fillColor = {230, 190, 60}, fillPattern = FillPattern.Solid, extent = {{-77, 117}, {-63, 103}}), Ellipse(lineColor = {200, 160, 40}, fillColor = {230, 190, 60}, fillPattern = FillPattern.Solid, extent = {{63, 117}, {77, 103}}), Ellipse(lineColor = {200, 160, 40}, fillColor = {230, 190, 60}, fillPattern = FillPattern.Solid, extent = {{-77, 97}, {-63, 83}}), Ellipse(lineColor = {200, 160, 40}, fillColor = {230, 190, 60}, fillPattern = FillPattern.Solid, extent = {{63, 97}, {77, 83}}), Ellipse(lineColor = {200, 160, 40}, fillColor = {230, 190, 60}, fillPattern = FillPattern.Solid, extent = {{-77, 77}, {-63, 63}}), Ellipse(lineColor = {200, 160, 40}, fillColor = {230, 190, 60}, fillPattern = FillPattern.Solid, extent = {{63, 77}, {77, 63}}), Ellipse(lineColor = {200, 160, 40}, fillColor = {230, 190, 60}, fillPattern = FillPattern.Solid, extent = {{-77, 57}, {-63, 43}}), Ellipse(lineColor = {200, 160, 40}, fillColor = {230, 190, 60}, fillPattern = FillPattern.Solid, extent = {{63, 57}, {77, 43}}), Ellipse(lineColor = {200, 160, 40}, fillColor = {230, 190, 60}, fillPattern = FillPattern.Solid, extent = {{-77, 37}, {-63, 23}}), Ellipse(lineColor = {200, 160, 40}, fillColor = {230, 190, 60}, fillPattern = FillPattern.Solid, extent = {{63, 37}, {77, 23}}), Ellipse(lineColor = {200, 160, 40}, fillColor = {230, 190, 60}, fillPattern = FillPattern.Solid, extent = {{-77, 17}, {-63, 3}}), Ellipse(lineColor = {200, 160, 40}, fillColor = {230, 190, 60}, fillPattern = FillPattern.Solid, extent = {{63, 17}, {77, 3}}), Ellipse(lineColor = {200, 160, 40}, fillColor = {230, 190, 60}, fillPattern = FillPattern.Solid, extent = {{-77, -3}, {-63, -17}}), Ellipse(lineColor = {200, 160, 40}, fillColor = {230, 190, 60}, fillPattern = FillPattern.Solid, extent = {{63, -3}, {77, -17}}), Ellipse(lineColor = {200, 160, 40}, fillColor = {230, 190, 60}, fillPattern = FillPattern.Solid, extent = {{-77, -23}, {-63, -37}}), Ellipse(lineColor = {200, 160, 40}, fillColor = {230, 190, 60}, fillPattern = FillPattern.Solid, extent = {{63, -23}, {77, -37}}), Ellipse(lineColor = {200, 160, 40}, fillColor = {230, 190, 60}, fillPattern = FillPattern.Solid, extent = {{-77, -43}, {-63, -57}}), Ellipse(lineColor = {200, 160, 40}, fillColor = {230, 190, 60}, fillPattern = FillPattern.Solid, extent = {{63, -43}, {77, -57}}), Ellipse(lineColor = {200, 160, 40}, fillColor = {230, 190, 60}, fillPattern = FillPattern.Solid, extent = {{-77, -63}, {-63, -77}}), Ellipse(lineColor = {200, 160, 40}, fillColor = {230, 190, 60}, fillPattern = FillPattern.Solid, extent = {{63, -63}, {77, -77}}), Ellipse(lineColor = {200, 160, 40}, fillColor = {230, 190, 60}, fillPattern = FillPattern.Solid, extent = {{-77, -83}, {-63, -97}}), Ellipse(lineColor = {200, 160, 40}, fillColor = {230, 190, 60}, fillPattern = FillPattern.Solid, extent = {{63, -83}, {77, -97}}), Ellipse(lineColor = {200, 160, 40}, fillColor = {230, 190, 60}, fillPattern = FillPattern.Solid, extent = {{-77, -103}, {-63, -117}}), Ellipse(lineColor = {200, 160, 40}, fillColor = {230, 190, 60}, fillPattern = FillPattern.Solid, extent = {{63, -103}, {77, -117}}), Ellipse(lineColor = {200, 160, 40}, fillColor = {230, 190, 60}, fillPattern = FillPattern.Solid, extent = {{-77, -123}, {-63, -137}}), Ellipse(lineColor = {200, 160, 40}, fillColor = {230, 190, 60}, fillPattern = FillPattern.Solid, extent = {{63, -123}, {77, -137}}), Ellipse(lineColor = {200, 160, 40}, fillColor = {230, 190, 60}, fillPattern = FillPattern.Solid, extent = {{-77, -143}, {-63, -157}}), Ellipse(lineColor = {200, 160, 40}, fillColor = {230, 190, 60}, fillPattern = FillPattern.Solid, extent = {{63, -143}, {77, -157}}), Ellipse(lineColor = {200, 160, 40}, fillColor = {230, 190, 60}, fillPattern = FillPattern.Solid, extent = {{-77, -163}, {-63, -177}}), Ellipse(lineColor = {200, 160, 40}, fillColor = {230, 190, 60}, fillPattern = FillPattern.Solid, extent = {{63, -163}, {77, -177}}), Ellipse(lineColor = {200, 160, 40}, fillColor = {230, 190, 60}, fillPattern = FillPattern.Solid, extent = {{-77, -183}, {-63, -197}}), Ellipse(lineColor = {200, 160, 40}, fillColor = {230, 190, 60}, fillPattern = FillPattern.Solid, extent = {{63, -183}, {77, -197}}), Rectangle(lineColor = {20, 20, 20}, fillColor = {40, 40, 40}, fillPattern = FillPattern.Solid, extent = {{-27.55, 57.55}, {27.55, 2.45}}), Text(textColor = {220, 220, 220}, extent = {{-23.55, 40}, {23.55, 20}}, textString = "RP2040"), Rectangle(lineColor = {20, 20, 20}, fillColor = {40, 40, 40}, fillPattern = FillPattern.Solid, extent = {{-18, -40}, {18, -70}}), Ellipse(lineColor = {180, 180, 180}, fillColor = {245, 245, 245}, fillPattern = FillPattern.Solid, extent = {{-14, 130}, {14, 102}}), Ellipse(fillColor = DynamicSelect({40, 90, 40}, {integer(40 + min(1, max(0, builtinLed.mean.y)/builtinLed.IMax)*(-40)), integer(90 + min(1, max(0, builtinLed.mean.y)/builtinLed.IMax)*130), integer(40 + min(1, max(0, builtinLed.mean.y)/builtinLed.IMax)*(-40))}), fillPattern = FillPattern.Solid, extent = {{-38, 160}, {-26, 148}}), Text(textColor = {255, 255, 255}, extent = {{-42, 146}, {-22, 138}}, textString = "LED"), Text(textColor = {255, 255, 255}, extent = {{-40, -100}, {40, -130}}, textString = "Pico", textStyle = {TextStyle.Bold}), Text(textColor = {255, 255, 255}, extent = {{-40, -132}, {40, -146}}, textString = "Raspberry Pi"), Text(textColor = {255, 255, 255}, extent = {{-60, 196}, {-14, 184}}, textString = "GP0", horizontalAlignment = TextAlignment.Left), Text(textColor = {255, 255, 255}, extent = {{-60, 176}, {-14, 164}}, textString = "GP1", horizontalAlignment = TextAlignment.Left), Text(textColor = {255, 255, 255}, extent = {{-60, 156}, {-14, 144}}, textString = "GND", horizontalAlignment = TextAlignment.Left), Text(textColor = {255, 255, 255}, extent = {{-60, 136}, {-14, 124}}, textString = "GP2", horizontalAlignment = TextAlignment.Left), Text(textColor = {255, 255, 255}, extent = {{-60, 116}, {-14, 104}}, textString = "GP3", horizontalAlignment = TextAlignment.Left), Text(textColor = {255, 255, 255}, extent = {{-60, 96}, {-14, 84}}, textString = "GP4", horizontalAlignment = TextAlignment.Left), Text(textColor = {255, 255, 255}, extent = {{-60, 76}, {-14, 64}}, textString = "GP5", horizontalAlignment = TextAlignment.Left), Text(textColor = {255, 255, 255}, extent = {{-60, 56}, {-14, 44}}, textString = "GND", horizontalAlignment = TextAlignment.Left), Text(textColor = {255, 255, 255}, extent = {{-60, 36}, {-14, 24}}, textString = "GP6", horizontalAlignment = TextAlignment.Left), Text(textColor = {255, 255, 255}, extent = {{-60, 16}, {-14, 4}}, textString = "GP7", horizontalAlignment = TextAlignment.Left), Text(textColor = {255, 255, 255}, extent = {{-60, -4}, {-14, -16}}, textString = "GP8", horizontalAlignment = TextAlignment.Left), Text(textColor = {255, 255, 255}, extent = {{-60, -24}, {-14, -36}}, textString = "GP9", horizontalAlignment = TextAlignment.Left), Text(textColor = {255, 255, 255}, extent = {{-60, -44}, {-14, -56}}, textString = "GND", horizontalAlignment = TextAlignment.Left), Text(textColor = {255, 255, 255}, extent = {{-60, -64}, {-14, -76}}, textString = "GP10", horizontalAlignment = TextAlignment.Left), Text(textColor = {255, 255, 255}, extent = {{-60, -84}, {-14, -96}}, textString = "GP11", horizontalAlignment = TextAlignment.Left), Text(textColor = {255, 255, 255}, extent = {{-60, -104}, {-14, -116}}, textString = "GP12", horizontalAlignment = TextAlignment.Left), Text(textColor = {255, 255, 255}, extent = {{-60, -124}, {-14, -136}}, textString = "GP13", horizontalAlignment = TextAlignment.Left), Text(textColor = {255, 255, 255}, extent = {{-60, -144}, {-14, -156}}, textString = "GND", horizontalAlignment = TextAlignment.Left), Text(textColor = {255, 255, 255}, extent = {{-60, -164}, {-14, -176}}, textString = "GP14", horizontalAlignment = TextAlignment.Left), Text(textColor = {255, 255, 255}, extent = {{-60, -184}, {-14, -196}}, textString = "GP15", horizontalAlignment = TextAlignment.Left), Text(textColor = {255, 255, 255}, extent = {{14, 196}, {60, 184}}, textString = "VBUS", horizontalAlignment = TextAlignment.Right), Text(textColor = {255, 255, 255}, extent = {{14, 176}, {60, 164}}, textString = "VSYS", horizontalAlignment = TextAlignment.Right), Text(textColor = {255, 255, 255}, extent = {{14, 156}, {60, 144}}, textString = "GND", horizontalAlignment = TextAlignment.Right), Text(textColor = {255, 255, 255}, extent = {{14, 136}, {60, 124}}, textString = "3V3_EN", horizontalAlignment = TextAlignment.Right), Text(textColor = {255, 255, 255}, extent = {{14, 116}, {60, 104}}, textString = "3V3(OUT)", horizontalAlignment = TextAlignment.Right), Text(textColor = {255, 255, 255}, extent = {{14, 96}, {60, 84}}, textString = "ADC_VREF", horizontalAlignment = TextAlignment.Right), Text(textColor = {255, 255, 255}, extent = {{14, 76}, {60, 64}}, textString = "GP28", horizontalAlignment = TextAlignment.Right), Text(textColor = {255, 255, 255}, extent = {{14, 56}, {60, 44}}, textString = "AGND", horizontalAlignment = TextAlignment.Right), Text(textColor = {255, 255, 255}, extent = {{14, 36}, {60, 24}}, textString = "GP27", horizontalAlignment = TextAlignment.Right), Text(textColor = {255, 255, 255}, extent = {{14, 16}, {60, 4}}, textString = "GP26", horizontalAlignment = TextAlignment.Right), Text(textColor = {255, 255, 255}, extent = {{14, -4}, {60, -16}}, textString = "RUN", horizontalAlignment = TextAlignment.Right), Text(textColor = {255, 255, 255}, extent = {{14, -24}, {60, -36}}, textString = "GP22", horizontalAlignment = TextAlignment.Right), Text(textColor = {255, 255, 255}, extent = {{14, -44}, {60, -56}}, textString = "GND", horizontalAlignment = TextAlignment.Right), Text(textColor = {255, 255, 255}, extent = {{14, -64}, {60, -76}}, textString = "GP21", horizontalAlignment = TextAlignment.Right), Text(textColor = {255, 255, 255}, extent = {{14, -84}, {60, -96}}, textString = "GP20", horizontalAlignment = TextAlignment.Right), Text(textColor = {255, 255, 255}, extent = {{14, -104}, {60, -116}}, textString = "GP19", horizontalAlignment = TextAlignment.Right), Text(textColor = {255, 255, 255}, extent = {{14, -124}, {60, -136}}, textString = "GP18", horizontalAlignment = TextAlignment.Right), Text(textColor = {255, 255, 255}, extent = {{14, -144}, {60, -156}}, textString = "GND", horizontalAlignment = TextAlignment.Right), Text(textColor = {255, 255, 255}, extent = {{14, -164}, {60, -176}}, textString = "GP17", horizontalAlignment = TextAlignment.Right), Text(textColor = {255, 255, 255}, extent = {{14, -184}, {60, -196}}, textString = "GP16", horizontalAlignment = TextAlignment.Right), Text(textColor = {28, 108, 200}, extent = {{34, 230}, {86, 220}}, textString = "DISPLAY"), Text(textColor = {0, 0, 255}, extent = {{-150, 262}, {150, 242}}, textString = "%name")}),
    Diagram(coordinateSystem(preserveAspectRatio = true, extent = {{-320, -270}, {320, 260}}), graphics = {Rectangle(lineColor = {200, 200, 200}, fillColor = {235, 242, 255}, fillPattern = FillPattern.Solid, extent = {{-314, 250}, {-206, -234}}, radius = 4), Rectangle(lineColor = {200, 200, 200}, fillColor = {242, 242, 242}, fillPattern = FillPattern.Solid, extent = {{-200, 62}, {-40, -104}}, radius = 4), Rectangle(lineColor = {200, 200, 200}, fillColor = {255, 243, 228}, fillPattern = FillPattern.Solid, extent = {{22, 250}, {316, -2}}, radius = 4), Rectangle(lineColor = {200, 200, 200}, fillColor = {238, 238, 238}, fillPattern = FillPattern.Solid, extent = {{-200, -238}, {280, -266}}, radius = 4), Text(textColor = {90, 90, 90}, extent = {{-310, 248}, {-210, 240}}, textString = "GPIO", horizontalAlignment = TextAlignment.Left), Text(textColor = {90, 90, 90}, extent = {{-196, 60}, {-44, 52}}, textString = "RP2040 core", horizontalAlignment = TextAlignment.Left), Text(textColor = {90, 90, 90}, extent = {{26, 248}, {312, 240}}, textString = "Power supply: USB, VBUS, VSYS, regulator, 3V3", horizontalAlignment = TextAlignment.Left), Text(textColor = {90, 90, 90}, extent = {{80, -257}, {276, -265}}, textString = "Ground (GND pins, AGND)", horizontalAlignment = TextAlignment.Right)}),
    Documentation(info = "<html>
<p>Replica of the <b>Raspberry Pi Pico</b> board (RP2040): real pinout (40 pins, viewed from above, USB connector at the top) and real dimensions (21 x 51 mm, 2.54 mm pitch, rows 17.78 mm apart), and its <b>power supply</b>. It contains the same programmable core as <code>MCU</code> (<code>Internal.McuCore</code>: Python program, <code>machine</code> API, sync point), wired to the power components of the board — see the internal diagram. The pins are supplied by the 3.3 V rail of the board, and the program only runs while the board is supplied.</p>
<h4>Power supply</h4>
<ul>
<li><code>usbConnected</code> (true by default, lightning bolt on the USB connector of the icon): the USB cable supplies 5 V on <code>VBUS</code> — the board runs without wiring anything, like a Pico plugged into the computer.</li>
<li><code>VBUS</code> feeds <code>VSYS</code> through a Schottky diode (about 0.3 V). <code>VSYS</code> (1.8 to 5.5 V) can also be supplied directly, typically by a battery, with <code>usbConnected = false</code>.</li>
<li>The buck-boost regulator (<code>Internal.Rt6150</code>, averaged model: efficiency <code>eta</code>, undervoltage lockout) makes the 3.3 V rail from <code>VSYS</code>; <code>3V3_EN</code> (pulled up to <code>VSYS</code>) switches it off when grounded. The rail supplies the RP2040 and the flash (<code>ICore</code>), the pins (high level and pull-ups: the current of an LED on a pin is drawn from it) and the <code>3V3(OUT)</code> pin for external circuits.</li>
<li><code>ADC_VREF</code> = 3V3 filtered through 200 Ohm: it is the reference of <code>machine.ADC</code>.</li>
<li>Internal sensing, as on the board: <code>Pin(24)</code> reads the presence of <code>VBUS</code>, <code>ADC(3)</code> (GPIO29) reads <code>VSYS/3</code>, <code>ADC(4)</code> reads the temperature sensor (<code>dieTemperature</code>).</li>
</ul>
<p><b>Power-on and power loss</b>: the program (<code>boot.py</code>/<code>main.py</code> or the script) starts the first time the 3.3 V rail exceeds <code>VPowerOn</code> with <code>RUN</code> high, and <code>time.ticks_ms()</code> counts from this instant. If the rail falls below <code>VPowerOff</code> or <code>RUN</code> is grounded afterwards, the program is stopped for good (warning in the log) and the pins are released; a restart when the supply comes back is <b>not simulated</b>.</p>
<h4>Differences with <code>MCU</code></h4>
<ul>
<li>All the pins of the board: <code>GP0</code>-<code>GP22</code>, <code>GP26</code>-<code>GP28</code>; ADC only on <code>GP26</code>-<code>GP28</code> (<code>ADC(0)</code>-<code>ADC(2)</code>), as on the RP2040.</li>
<li>UART and I2C follow the pin multiplexing of the RP2040 (e.g. <code>UART(0)</code>: TX on GP0, 12, 16 or 28) and the default pins of the rp2 port; <code>UART(0)</code> and <code>UART(1)</code> (and <code>I2C(0)</code>/<code>I2C(1)</code>) are both accepted, but only one at a time (single engine in the simulation). <code>SoftI2C</code> accepts any pins.</li>
<li>The on-board LED (<code>Pin(25)</code> or <code>Pin(\"LED\")</code>) is drawn at its real place on the icon.</li>
</ul>
<p>The <code>Display0</code> logical link to the educational displays is kept (top of the icon), although it does not exist on the real board. See <code>requirements.md</code>, decision \"Carte Raspberry Pi Pico et alimentation\".</p>
</html>"));
end RPi_Pico;
