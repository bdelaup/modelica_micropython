within MicroPythonMCU;

model MicroBit_v2 "BBC micro:bit v2 board: nRF52833 programmable in MicroPython, real pinout and dimensions, multiplexed 5x5 LED matrix, buttons A/B, integrated sensors and USB power supply"
  extends Internal.PartialMcuSettings;
  parameter Boolean usbConnected = true "USB cable plugged in: 5 V through the regulator (the board runs without any wiring) - false to supply the board through the 3V pin" annotation(
    Dialog(tab = "Power supply", group = "USB"),
    choices(checkBox = true));
  parameter Modelica.Units.SI.Voltage VUsb = 5 "Voltage of the USB supply" annotation(
    Dialog(tab = "Power supply", group = "USB", enable = usbConnected));
  parameter Modelica.Units.SI.Resistance RUsb = 0.2 "Resistance of the USB cable and connector" annotation(
    Dialog(tab = "Power supply", group = "USB", enable = usbConnected));
  parameter Modelica.Units.SI.Voltage VTgt = 3.0 "Voltage of the 3V rail (output of the on-board regulator, high level and ADC reference of the pins)" annotation(
    Dialog(tab = "Power supply", group = "Regulator"));
  parameter Real eta(min = 0.1, max = 1) = 0.9 "Efficiency of the regulator" annotation(
    Dialog(tab = "Power supply", group = "Regulator"));
  parameter Modelica.Units.SI.Current ICore = 0.004 "Current drawn from the 3V rail by the nRF52833 while supplied (program running, pins and sensors excluded)" annotation(
    Dialog(tab = "Power supply", group = "Consumption"));
  parameter Modelica.Units.SI.Voltage VPowerOn = 1.8 "3V rail voltage above which the board starts (power-on reset)" annotation(
    Dialog(tab = "Power supply", group = "Power-on"));
  parameter Modelica.Units.SI.Voltage VPowerOff = 1.6 "3V rail voltage below which a running board stops for good (brown-out)" annotation(
    Dialog(tab = "Power supply", group = "Power-on"));
  parameter Boolean useGroundPin = true "Show the GND pin - unchecked: the board is referenced to the simulation ground (0 V), nothing to wire" annotation(
    Dialog(tab = "Electrical", group = "Supply"),
    choices(checkBox = true));
  parameter Real accelX = 0 "X axis of the accelerometer (default value when no connector is wired)" annotation(
    Dialog(tab = "Sensors", group = "Values"));
  parameter Boolean useAccelXInput = false "Wire a accelXIn connector to drive accelX from the diagram" annotation(
    Dialog(tab = "Sensors", group = "Connectors"),
    choices(checkBox = true));
  parameter Real accelY = 0 "Y axis of the accelerometer (default value when no connector is wired)" annotation(
    Dialog(tab = "Sensors", group = "Values"));
  parameter Boolean useAccelYInput = false "Wire a accelYIn connector to drive accelY from the diagram" annotation(
    Dialog(tab = "Sensors", group = "Connectors"),
    choices(checkBox = true));
  parameter Real accelZ = -9.81 "Z axis of the accelerometer (default: gravity, board lying display up) (default value when no connector is wired)" annotation(
    Dialog(tab = "Sensors", group = "Values"));
  parameter Boolean useAccelZInput = false "Wire a accelZIn connector to drive accelZ from the diagram" annotation(
    Dialog(tab = "Sensors", group = "Connectors"),
    choices(checkBox = true));
  parameter Real magX = 0 "X axis of the magnetometer/compass (default value when no connector is wired)" annotation(
    Dialog(tab = "Sensors", group = "Values"));
  parameter Boolean useMagXInput = false "Wire a magXIn connector to drive magX from the diagram" annotation(
    Dialog(tab = "Sensors", group = "Connectors"),
    choices(checkBox = true));
  parameter Real magY = 50 "Y axis of the magnetometer/compass (default: field pointing along +Y) (default value when no connector is wired)" annotation(
    Dialog(tab = "Sensors", group = "Values"));
  parameter Boolean useMagYInput = false "Wire a magYIn connector to drive magY from the diagram" annotation(
    Dialog(tab = "Sensors", group = "Connectors"),
    choices(checkBox = true));
  parameter Real magZ = 0 "Z axis of the magnetometer/compass (default value when no connector is wired)" annotation(
    Dialog(tab = "Sensors", group = "Values"));
  parameter Boolean useMagZInput = false "Wire a magZIn connector to drive magZ from the diagram" annotation(
    Dialog(tab = "Sensors", group = "Connectors"),
    choices(checkBox = true));
  parameter Real temp = 27 "Temperature read by microbit.temperature() (default value when no connector is wired)" annotation(
    Dialog(tab = "Sensors", group = "Values"));
  parameter Boolean useTempInput = false "Wire a tempIn connector to drive temp from the diagram" annotation(
    Dialog(tab = "Sensors", group = "Connectors"),
    choices(checkBox = true));
  parameter Real light = 100 "Light level 0-255 read by display.read_light_level() (default value when no connector is wired)" annotation(
    Dialog(tab = "Sensors", group = "Values"));
  parameter Boolean useLightInput = false "Wire a lightIn connector to drive light from the diagram" annotation(
    Dialog(tab = "Sensors", group = "Connectors"),
    choices(checkBox = true));
  Modelica.Electrical.Analog.Interfaces.PositivePin P0 "GPIO 0, edge connector (microbit.pin0, analog input (pin0.read_analog()))" annotation(
    Placement(transformation(origin = {-330, 300}, extent = {{-6, -6}, {6, 6}}), iconTransformation(origin = {-140, -152.8}, extent = {{-4, -4}, {4, 4}})));
  Modelica.Electrical.Analog.Interfaces.PositivePin P1 "GPIO 1, edge connector (microbit.pin1, analog input (pin1.read_analog()))" annotation(
    Placement(transformation(origin = {-330, 274}, extent = {{-6, -6}, {6, 6}}), iconTransformation(origin = {-70, -152.8}, extent = {{-4, -4}, {4, 4}})));
  Modelica.Electrical.Analog.Interfaces.PositivePin P2 "GPIO 2, edge connector (microbit.pin2, analog input (pin2.read_analog()))" annotation(
    Placement(transformation(origin = {-330, 248}, extent = {{-6, -6}, {6, 6}}), iconTransformation(origin = {10, -152.8}, extent = {{-4, -4}, {4, 4}})));
  Modelica.Electrical.Analog.Interfaces.PositivePin P3 "GPIO 3, edge connector (microbit.pin3, analog input (pin3.read_analog()))" annotation(
    Placement(transformation(origin = {-330, 222}, extent = {{-6, -6}, {6, 6}}), iconTransformation(origin = {-160, -152.8}, extent = {{-4, -4}, {4, 4}})));
  Modelica.Electrical.Analog.Interfaces.PositivePin P4 "GPIO 4, edge connector (microbit.pin4, analog input (pin4.read_analog()))" annotation(
    Placement(transformation(origin = {-330, 196}, extent = {{-6, -6}, {6, 6}}), iconTransformation(origin = {-120, -152.8}, extent = {{-4, -4}, {4, 4}})));
  Modelica.Electrical.Analog.Interfaces.PositivePin P5 "GPIO 5, edge connector (microbit.pin5)" annotation(
    Placement(transformation(origin = {-330, 170}, extent = {{-6, -6}, {6, 6}}), iconTransformation(origin = {-110, -152.8}, extent = {{-4, -4}, {4, 4}})));
  Modelica.Electrical.Analog.Interfaces.PositivePin P6 "GPIO 6, edge connector (microbit.pin6)" annotation(
    Placement(transformation(origin = {-330, 144}, extent = {{-6, -6}, {6, 6}}), iconTransformation(origin = {-100, -152.8}, extent = {{-4, -4}, {4, 4}})));
  Modelica.Electrical.Analog.Interfaces.PositivePin P7 "GPIO 7, edge connector (microbit.pin7)" annotation(
    Placement(transformation(origin = {-330, 118}, extent = {{-6, -6}, {6, 6}}), iconTransformation(origin = {-90, -152.8}, extent = {{-4, -4}, {4, 4}})));
  Modelica.Electrical.Analog.Interfaces.PositivePin P8 "GPIO 8, edge connector (microbit.pin8)" annotation(
    Placement(transformation(origin = {-330, 92}, extent = {{-6, -6}, {6, 6}}), iconTransformation(origin = {-50, -152.8}, extent = {{-4, -4}, {4, 4}})));
  Modelica.Electrical.Analog.Interfaces.PositivePin P9 "GPIO 9, edge connector (microbit.pin9)" annotation(
    Placement(transformation(origin = {-330, 66}, extent = {{-6, -6}, {6, 6}}), iconTransformation(origin = {-40, -152.8}, extent = {{-4, -4}, {4, 4}})));
  Modelica.Electrical.Analog.Interfaces.PositivePin P10 "GPIO 10, edge connector (microbit.pin10, analog input (pin10.read_analog()))" annotation(
    Placement(transformation(origin = {-330, 40}, extent = {{-6, -6}, {6, 6}}), iconTransformation(origin = {-30, -152.8}, extent = {{-4, -4}, {4, 4}})));
  Modelica.Electrical.Analog.Interfaces.PositivePin P11 "GPIO 11, edge connector (microbit.pin11)" annotation(
    Placement(transformation(origin = {-330, 14}, extent = {{-6, -6}, {6, 6}}), iconTransformation(origin = {-20, -152.8}, extent = {{-4, -4}, {4, 4}})));
  Modelica.Electrical.Analog.Interfaces.PositivePin P12 "GPIO 12, edge connector (microbit.pin12)" annotation(
    Placement(transformation(origin = {-330, -12}, extent = {{-6, -6}, {6, 6}}), iconTransformation(origin = {-10, -152.8}, extent = {{-4, -4}, {4, 4}})));
  Modelica.Electrical.Analog.Interfaces.PositivePin P13 "GPIO 13, edge connector (microbit.pin13)" annotation(
    Placement(transformation(origin = {-330, -38}, extent = {{-6, -6}, {6, 6}}), iconTransformation(origin = {30, -152.8}, extent = {{-4, -4}, {4, 4}})));
  Modelica.Electrical.Analog.Interfaces.PositivePin P14 "GPIO 14, edge connector (microbit.pin14)" annotation(
    Placement(transformation(origin = {-330, -64}, extent = {{-6, -6}, {6, 6}}), iconTransformation(origin = {40, -152.8}, extent = {{-4, -4}, {4, 4}})));
  Modelica.Electrical.Analog.Interfaces.PositivePin P15 "GPIO 15, edge connector (microbit.pin15)" annotation(
    Placement(transformation(origin = {-330, -90}, extent = {{-6, -6}, {6, 6}}), iconTransformation(origin = {50, -152.8}, extent = {{-4, -4}, {4, 4}})));
  Modelica.Electrical.Analog.Interfaces.PositivePin P16 "GPIO 16, edge connector (microbit.pin16)" annotation(
    Placement(transformation(origin = {-330, -116}, extent = {{-6, -6}, {6, 6}}), iconTransformation(origin = {60, -152.8}, extent = {{-4, -4}, {4, 4}})));
  Modelica.Electrical.Analog.Interfaces.PositivePin P19 "GPIO 19, edge connector (microbit.pin19)" annotation(
    Placement(transformation(origin = {-330, -142}, extent = {{-6, -6}, {6, 6}}), iconTransformation(origin = {120, -152.8}, extent = {{-4, -4}, {4, 4}})));
  Modelica.Electrical.Analog.Interfaces.PositivePin P20 "GPIO 20, edge connector (microbit.pin20)" annotation(
    Placement(transformation(origin = {-330, -168}, extent = {{-6, -6}, {6, 6}}), iconTransformation(origin = {130, -152.8}, extent = {{-4, -4}, {4, 4}})));
  Modelica.Electrical.Analog.Interfaces.PositivePin P_3V "3V supply of the edge connector: output of the on-board regulator (3.0 V rail)" annotation(
    Placement(transformation(origin = {-330, -190}, extent = {{-6, -6}, {6, 6}}), iconTransformation(origin = {100, -152.8}, extent = {{-4, -4}, {4, 4}})));
  Modelica.Electrical.Analog.Interfaces.NegativePin GND if useGroundPin "Common reference (ground) - shown when useGroundPin is checked, otherwise the board is referenced to the simulation ground (0 V)" annotation(
    Placement(transformation(origin = {-330, -230}, extent = {{-6, -6}, {6, 6}}), iconTransformation(origin = {150, -152.8}, extent = {{-4, -4}, {4, 4}})));
  Modelica.Blocks.Interfaces.BooleanInput buttonA "Button A (P5): true while pressed - wire a boolean signal or source; pressed = pin to GND, 10 kOhm pull-up otherwise" annotation(
    Placement(transformation(origin = {-330, -290}, extent = {{-6, -6}, {6, 6}}), iconTransformation(origin = {-216.7, 0}, extent = {{-5, -5}, {5, 5}})));
  Modelica.Blocks.Interfaces.BooleanInput buttonB "Button B (P11): true while pressed - same as buttonA" annotation(
    Placement(transformation(origin = {-330, -320}, extent = {{-6, -6}, {6, 6}}), iconTransformation(origin = {216.7, 0}, extent = {{-5, -5}, {5, 5}}, rotation = 180)));
  Internal.McuCore core(final nPins = 32, final pinIds = {0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 19, 20, 21, 22, 23, 24, 25, 26, 27, 28, 29, 30, 31, 32, 33}, final pinCaps = {7, 7, 7, 7, 7, 3, 3, 3, 3, 3, 7, 3, 3, 3, 3, 3, 3, 3, 3, 1, 1, 1, 1, 1, 4, 4, 4, 4, 4, 4, 4, 4}, final boardProfile = "microbit", final instanceName = boardName, final ICore = ICore, final VPowerOn = VPowerOn, final VPowerOff = VPowerOff, final scriptPath = scriptPath, final addScriptDirToPath = addScriptDirToPath, final libraryPath = libraryPath, final fsEnabled = fsEnabled, final fsSource = fsSource, final fsWorkspace = fsWorkspace, final fsOpenExplorer = fsOpenExplorer, final tickPeriod = tickPeriod, final gpioOpTime = gpioOpTime, final hangWarningTime = hangWarningTime, final debugEnabled = debugEnabled, final debugPort = debugPort, final VOL = VOL, final VIH = VIH, final VIL = VIL, final ROut = ROut, final RPullUp = RPullUp, final RPullDown = RPullDown, final GOff = GOff) "The nRF52833: pin[1..19] = P0-P16, P19, P20 (edge), pin[20..24] = matrix rows ROW1-ROW5 (internal), pin[25..32] = accelerometer X/Y/Z, compass X/Y/Z, temperature, light (internal)" annotation(
    Placement(transformation(origin = {-110, 40}, extent = {{-70, -70}, {70, 70}})));
  Internal.Rt6150 regulator(VOut = VTgt, eta = eta) "Buck-boost regulator USB -> 3V rail (RT6150)" annotation(
    Placement(transformation(origin = {160, 140}, extent = {{-20, -20}, {20, 20}})));
  Modelica.Electrical.Analog.Sources.ConstantVoltage usbSupply(V = VUsb) if usbConnected "USB supply (5 V)" annotation(
    Placement(transformation(origin = {200, 240}, extent = {{-10, -10}, {10, 10}}, rotation = 270)));
  Modelica.Electrical.Analog.Basic.Resistor usbCable(R = RUsb) if usbConnected "Resistance of the USB cable" annotation(
    Placement(transformation(origin = {240, 240}, extent = {{-10, -10}, {10, 10}})));
  Modelica.Units.SI.Voltage vRail = P_3V.v - core.gnd.v "Voltage of the 3V rail";
  MicroPythonMCU.Peripherals.LED led_0_0(IMax = 0.0004) "Matrix LED, column 0, row 0 (anode on row 1, cathode on column 1)" annotation(
    Placement(transformation(origin = {40, 200}, extent = {{-10, -10}, {10, 10}})));
  MicroPythonMCU.Peripherals.LED led_0_1(IMax = 0.0004) "Matrix LED, column 0, row 1 (anode on row 2, cathode on column 1)" annotation(
    Placement(transformation(origin = {40, 164}, extent = {{-10, -10}, {10, 10}})));
  MicroPythonMCU.Peripherals.LED led_0_2(IMax = 0.0004) "Matrix LED, column 0, row 2 (anode on row 3, cathode on column 1)" annotation(
    Placement(transformation(origin = {40, 128}, extent = {{-10, -10}, {10, 10}})));
  MicroPythonMCU.Peripherals.LED led_0_3(IMax = 0.0004) "Matrix LED, column 0, row 3 (anode on row 4, cathode on column 1)" annotation(
    Placement(transformation(origin = {40, 92}, extent = {{-10, -10}, {10, 10}})));
  MicroPythonMCU.Peripherals.LED led_0_4(IMax = 0.0004) "Matrix LED, column 0, row 4 (anode on row 5, cathode on column 1)" annotation(
    Placement(transformation(origin = {40, 56}, extent = {{-10, -10}, {10, 10}})));
  MicroPythonMCU.Peripherals.LED led_1_0(IMax = 0.0004) "Matrix LED, column 1, row 0 (anode on row 1, cathode on column 2)" annotation(
    Placement(transformation(origin = {76, 200}, extent = {{-10, -10}, {10, 10}})));
  MicroPythonMCU.Peripherals.LED led_1_1(IMax = 0.0004) "Matrix LED, column 1, row 1 (anode on row 2, cathode on column 2)" annotation(
    Placement(transformation(origin = {76, 164}, extent = {{-10, -10}, {10, 10}})));
  MicroPythonMCU.Peripherals.LED led_1_2(IMax = 0.0004) "Matrix LED, column 1, row 2 (anode on row 3, cathode on column 2)" annotation(
    Placement(transformation(origin = {76, 128}, extent = {{-10, -10}, {10, 10}})));
  MicroPythonMCU.Peripherals.LED led_1_3(IMax = 0.0004) "Matrix LED, column 1, row 3 (anode on row 4, cathode on column 2)" annotation(
    Placement(transformation(origin = {76, 92}, extent = {{-10, -10}, {10, 10}})));
  MicroPythonMCU.Peripherals.LED led_1_4(IMax = 0.0004) "Matrix LED, column 1, row 4 (anode on row 5, cathode on column 2)" annotation(
    Placement(transformation(origin = {76, 56}, extent = {{-10, -10}, {10, 10}})));
  MicroPythonMCU.Peripherals.LED led_2_0(IMax = 0.0004) "Matrix LED, column 2, row 0 (anode on row 1, cathode on column 3)" annotation(
    Placement(transformation(origin = {112, 200}, extent = {{-10, -10}, {10, 10}})));
  MicroPythonMCU.Peripherals.LED led_2_1(IMax = 0.0004) "Matrix LED, column 2, row 1 (anode on row 2, cathode on column 3)" annotation(
    Placement(transformation(origin = {112, 164}, extent = {{-10, -10}, {10, 10}})));
  MicroPythonMCU.Peripherals.LED led_2_2(IMax = 0.0004) "Matrix LED, column 2, row 2 (anode on row 3, cathode on column 3)" annotation(
    Placement(transformation(origin = {112, 128}, extent = {{-10, -10}, {10, 10}})));
  MicroPythonMCU.Peripherals.LED led_2_3(IMax = 0.0004) "Matrix LED, column 2, row 3 (anode on row 4, cathode on column 3)" annotation(
    Placement(transformation(origin = {112, 92}, extent = {{-10, -10}, {10, 10}})));
  MicroPythonMCU.Peripherals.LED led_2_4(IMax = 0.0004) "Matrix LED, column 2, row 4 (anode on row 5, cathode on column 3)" annotation(
    Placement(transformation(origin = {112, 56}, extent = {{-10, -10}, {10, 10}})));
  MicroPythonMCU.Peripherals.LED led_3_0(IMax = 0.0004) "Matrix LED, column 3, row 0 (anode on row 1, cathode on column 4)" annotation(
    Placement(transformation(origin = {148, 200}, extent = {{-10, -10}, {10, 10}})));
  MicroPythonMCU.Peripherals.LED led_3_1(IMax = 0.0004) "Matrix LED, column 3, row 1 (anode on row 2, cathode on column 4)" annotation(
    Placement(transformation(origin = {148, 164}, extent = {{-10, -10}, {10, 10}})));
  MicroPythonMCU.Peripherals.LED led_3_2(IMax = 0.0004) "Matrix LED, column 3, row 2 (anode on row 3, cathode on column 4)" annotation(
    Placement(transformation(origin = {148, 128}, extent = {{-10, -10}, {10, 10}})));
  MicroPythonMCU.Peripherals.LED led_3_3(IMax = 0.0004) "Matrix LED, column 3, row 3 (anode on row 4, cathode on column 4)" annotation(
    Placement(transformation(origin = {148, 92}, extent = {{-10, -10}, {10, 10}})));
  MicroPythonMCU.Peripherals.LED led_3_4(IMax = 0.0004) "Matrix LED, column 3, row 4 (anode on row 5, cathode on column 4)" annotation(
    Placement(transformation(origin = {148, 56}, extent = {{-10, -10}, {10, 10}})));
  MicroPythonMCU.Peripherals.LED led_4_0(IMax = 0.0004) "Matrix LED, column 4, row 0 (anode on row 1, cathode on column 5)" annotation(
    Placement(transformation(origin = {184, 200}, extent = {{-10, -10}, {10, 10}})));
  MicroPythonMCU.Peripherals.LED led_4_1(IMax = 0.0004) "Matrix LED, column 4, row 1 (anode on row 2, cathode on column 5)" annotation(
    Placement(transformation(origin = {184, 164}, extent = {{-10, -10}, {10, 10}})));
  MicroPythonMCU.Peripherals.LED led_4_2(IMax = 0.0004) "Matrix LED, column 4, row 2 (anode on row 3, cathode on column 5)" annotation(
    Placement(transformation(origin = {184, 128}, extent = {{-10, -10}, {10, 10}})));
  MicroPythonMCU.Peripherals.LED led_4_3(IMax = 0.0004) "Matrix LED, column 4, row 3 (anode on row 4, cathode on column 5)" annotation(
    Placement(transformation(origin = {184, 92}, extent = {{-10, -10}, {10, 10}})));
  MicroPythonMCU.Peripherals.LED led_4_4(IMax = 0.0004) "Matrix LED, column 4, row 4 (anode on row 5, cathode on column 5)" annotation(
    Placement(transformation(origin = {184, 56}, extent = {{-10, -10}, {10, 10}})));
protected
  final parameter String boardName = getInstanceName() "Instance name of the board, given to the core (log prefix, name of the copy of the flash)";
  Modelica.Blocks.Interfaces.RealInput accelXIn(unit = "m/s2") if useAccelXInput "X axis of the accelerometer from the diagram (overrides the parameter)" annotation(
    Placement(transformation(origin = {330, -60}, extent = {{-6, -6}, {6, 6}}), iconTransformation(origin = {0, 0}, extent = {{-5, -5}, {5, 5}}, visible = false)));
  Modelica.Blocks.Interfaces.RealInput accelYIn(unit = "m/s2") if useAccelYInput "Y axis of the accelerometer from the diagram (overrides the parameter)" annotation(
    Placement(transformation(origin = {330, -100}, extent = {{-6, -6}, {6, 6}}), iconTransformation(origin = {0, 0}, extent = {{-5, -5}, {5, 5}}, visible = false)));
  Modelica.Blocks.Interfaces.RealInput accelZIn(unit = "m/s2") if useAccelZInput "Z axis of the accelerometer (default: gravity, board lying display up) from the diagram (overrides the parameter)" annotation(
    Placement(transformation(origin = {330, -140}, extent = {{-6, -6}, {6, 6}}), iconTransformation(origin = {0, 0}, extent = {{-5, -5}, {5, 5}}, visible = false)));
  Modelica.Blocks.Interfaces.RealInput magXIn(unit = "uT") if useMagXInput "X axis of the magnetometer/compass from the diagram (overrides the parameter)" annotation(
    Placement(transformation(origin = {330, -180}, extent = {{-6, -6}, {6, 6}}), iconTransformation(origin = {0, 0}, extent = {{-5, -5}, {5, 5}}, visible = false)));
  Modelica.Blocks.Interfaces.RealInput magYIn(unit = "uT") if useMagYInput "Y axis of the magnetometer/compass (default: field pointing along +Y) from the diagram (overrides the parameter)" annotation(
    Placement(transformation(origin = {330, -220}, extent = {{-6, -6}, {6, 6}}), iconTransformation(origin = {0, 0}, extent = {{-5, -5}, {5, 5}}, visible = false)));
  Modelica.Blocks.Interfaces.RealInput magZIn(unit = "uT") if useMagZInput "Z axis of the magnetometer/compass from the diagram (overrides the parameter)" annotation(
    Placement(transformation(origin = {330, -260}, extent = {{-6, -6}, {6, 6}}), iconTransformation(origin = {0, 0}, extent = {{-5, -5}, {5, 5}}, visible = false)));
  Modelica.Blocks.Interfaces.RealInput tempIn(unit = "degC") if useTempInput "Temperature read by microbit.temperature() from the diagram (overrides the parameter)" annotation(
    Placement(transformation(origin = {330, -300}, extent = {{-6, -6}, {6, 6}}), iconTransformation(origin = {0, 0}, extent = {{-5, -5}, {5, 5}}, visible = false)));
  Modelica.Blocks.Interfaces.RealInput lightIn if useLightInput "Light level 0-255 read by display.read_light_level() from the diagram (overrides the parameter)" annotation(
    Placement(transformation(origin = {330, -340}, extent = {{-6, -6}, {6, 6}}), iconTransformation(origin = {0, 0}, extent = {{-5, -5}, {5, 5}}, visible = false)));
  Modelica.Electrical.Analog.Basic.Resistor pullBtnA(R = 10000) "External 10 kOhm pull-up of button A to 3V" annotation(
    Placement(transformation(origin = {-160, -270}, extent = {{-10, -10}, {10, 10}}, rotation = 90)));
  Modelica.Electrical.Analog.Ideal.IdealClosingSwitch switchA(Goff = 1e-9) "Button A: to GND while pressed" annotation(
    Placement(transformation(origin = {-60, -270}, extent = {{-10, -10}, {10, 10}})));
  Modelica.Electrical.Analog.Basic.Resistor pullBtnB(R = 10000) "External 10 kOhm pull-up of button B to 3V" annotation(
    Placement(transformation(origin = {-160, -300}, extent = {{-10, -10}, {10, 10}}, rotation = 90)));
  Modelica.Electrical.Analog.Ideal.IdealClosingSwitch switchB(Goff = 1e-9) "Button B: to GND while pressed" annotation(
    Placement(transformation(origin = {-60, -300}, extent = {{-10, -10}, {10, 10}})));
  Modelica.Electrical.Analog.Basic.Resistor pullI2cScl(R = 4700) "External 4.7 kOhm pull-up of P19 (I2C SCL)" annotation(
    Placement(transformation(origin = {-160, -170}, extent = {{-10, -10}, {10, 10}}, rotation = 90)));
  Modelica.Electrical.Analog.Basic.Resistor pullI2cSda(R = 4700) "External 4.7 kOhm pull-up of P20 (I2C SDA)" annotation(
    Placement(transformation(origin = {-160, -200}, extent = {{-10, -10}, {10, 10}}, rotation = 90)));
  Modelica.Electrical.Analog.Basic.Resistor pullRing0(R = 10e6) "External 10 MOhm pull-up of P0 (touch ring)" annotation(
    Placement(transformation(origin = {-230, 160}, extent = {{-10, -10}, {10, 10}}, rotation = 90)));
  Modelica.Electrical.Analog.Basic.Resistor pullRing1(R = 10e6) "External 10 MOhm pull-up of P1 (touch ring)" annotation(
    Placement(transformation(origin = {-230, 120}, extent = {{-10, -10}, {10, 10}}, rotation = 90)));
  Modelica.Electrical.Analog.Basic.Resistor pullRing2(R = 10e6) "External 10 MOhm pull-up of P2 (touch ring)" annotation(
    Placement(transformation(origin = {-230, 80}, extent = {{-10, -10}, {10, 10}}, rotation = 90)));
  Modelica.Electrical.Analog.Sources.SignalVoltage sensor_accelX "Integrated sensor X axis of the accelerometer, as seen by the ADC" annotation(
    Placement(transformation(origin = {260, -60}, extent = {{-10, -10}, {10, 10}})));
  Modelica.Blocks.Sources.Constant const_accelX(k = 0) if not useAccelXInput "Constant value of the sensor when no connector is wired" annotation(
    Placement(visible = false));
  Modelica.Blocks.Interfaces.RealInput internal_accelX "accelX internal node" annotation(
    Placement(visible = false));
  Modelica.Electrical.Analog.Sources.SignalVoltage sensor_accelY "Integrated sensor Y axis of the accelerometer, as seen by the ADC" annotation(
    Placement(transformation(origin = {260, -100}, extent = {{-10, -10}, {10, 10}})));
  Modelica.Blocks.Sources.Constant const_accelY(k = 0) if not useAccelYInput "Constant value of the sensor when no connector is wired" annotation(
    Placement(visible = false));
  Modelica.Blocks.Interfaces.RealInput internal_accelY "accelY internal node" annotation(
    Placement(visible = false));
  Modelica.Electrical.Analog.Sources.SignalVoltage sensor_accelZ "Integrated sensor Z axis of the accelerometer (default: gravity, board lying display up), as seen by the ADC" annotation(
    Placement(transformation(origin = {260, -140}, extent = {{-10, -10}, {10, 10}})));
  Modelica.Blocks.Sources.Constant const_accelZ(k = -9.81) if not useAccelZInput "Constant value of the sensor when no connector is wired" annotation(
    Placement(visible = false));
  Modelica.Blocks.Interfaces.RealInput internal_accelZ "accelZ internal node" annotation(
    Placement(visible = false));
  Modelica.Electrical.Analog.Sources.SignalVoltage sensor_magX "Integrated sensor X axis of the magnetometer/compass, as seen by the ADC" annotation(
    Placement(transformation(origin = {260, -180}, extent = {{-10, -10}, {10, 10}})));
  Modelica.Blocks.Sources.Constant const_magX(k = 0) if not useMagXInput "Constant value of the sensor when no connector is wired" annotation(
    Placement(visible = false));
  Modelica.Blocks.Interfaces.RealInput internal_magX "magX internal node" annotation(
    Placement(visible = false));
  Modelica.Electrical.Analog.Sources.SignalVoltage sensor_magY "Integrated sensor Y axis of the magnetometer/compass (default: field pointing along +Y), as seen by the ADC" annotation(
    Placement(transformation(origin = {260, -220}, extent = {{-10, -10}, {10, 10}})));
  Modelica.Blocks.Sources.Constant const_magY(k = 50) if not useMagYInput "Constant value of the sensor when no connector is wired" annotation(
    Placement(visible = false));
  Modelica.Blocks.Interfaces.RealInput internal_magY "magY internal node" annotation(
    Placement(visible = false));
  Modelica.Electrical.Analog.Sources.SignalVoltage sensor_magZ "Integrated sensor Z axis of the magnetometer/compass, as seen by the ADC" annotation(
    Placement(transformation(origin = {260, -260}, extent = {{-10, -10}, {10, 10}})));
  Modelica.Blocks.Sources.Constant const_magZ(k = 0) if not useMagZInput "Constant value of the sensor when no connector is wired" annotation(
    Placement(visible = false));
  Modelica.Blocks.Interfaces.RealInput internal_magZ "magZ internal node" annotation(
    Placement(visible = false));
  Modelica.Electrical.Analog.Sources.SignalVoltage sensor_temp "Integrated sensor Temperature read by microbit.temperature(), as seen by the ADC" annotation(
    Placement(transformation(origin = {260, -300}, extent = {{-10, -10}, {10, 10}})));
  Modelica.Blocks.Sources.Constant const_temp(k = 27) if not useTempInput "Constant value of the sensor when no connector is wired" annotation(
    Placement(visible = false));
  Modelica.Blocks.Interfaces.RealInput internal_temp "temp internal node" annotation(
    Placement(visible = false));
  Modelica.Electrical.Analog.Sources.SignalVoltage sensor_light "Integrated sensor Light level 0-255 read by display.read_light_level(), as seen by the ADC" annotation(
    Placement(transformation(origin = {260, -340}, extent = {{-10, -10}, {10, 10}})));
  Modelica.Blocks.Sources.Constant const_light(k = 100) if not useLightInput "Constant value of the sensor when no connector is wired" annotation(
    Placement(visible = false));
  Modelica.Blocks.Interfaces.RealInput internal_light "light internal node" annotation(
    Placement(visible = false));
equation
  connect(core.pin[20], led_0_0.p) annotation(
    Line(points = {{-181.5, 40}, {30, 40}, {30, 200}}, color = {0, 0, 255}));
  connect(core.pin[20], led_1_0.p) annotation(
    Line(points = {{-181.5, 40}, {66, 40}, {66, 200}}, color = {0, 0, 255}));
  connect(core.pin[20], led_2_0.p) annotation(
    Line(points = {{-181.5, 40}, {102, 40}, {102, 200}}, color = {0, 0, 255}));
  connect(core.pin[20], led_3_0.p) annotation(
    Line(points = {{-181.5, 40}, {138, 40}, {138, 200}}, color = {0, 0, 255}));
  connect(core.pin[20], led_4_0.p) annotation(
    Line(points = {{-181.5, 40}, {174, 40}, {174, 200}}, color = {0, 0, 255}));
  connect(core.pin[21], led_0_1.p) annotation(
    Line(points = {{-181.5, 40}, {30, 40}, {30, 164}}, color = {0, 0, 255}));
  connect(core.pin[21], led_1_1.p) annotation(
    Line(points = {{-181.5, 40}, {66, 40}, {66, 164}}, color = {0, 0, 255}));
  connect(core.pin[21], led_2_1.p) annotation(
    Line(points = {{-181.5, 40}, {102, 40}, {102, 164}}, color = {0, 0, 255}));
  connect(core.pin[21], led_3_1.p) annotation(
    Line(points = {{-181.5, 40}, {138, 40}, {138, 164}}, color = {0, 0, 255}));
  connect(core.pin[21], led_4_1.p) annotation(
    Line(points = {{-181.5, 40}, {174, 40}, {174, 164}}, color = {0, 0, 255}));
  connect(core.pin[22], led_0_2.p) annotation(
    Line(points = {{-181.5, 40}, {30, 40}, {30, 128}}, color = {0, 0, 255}));
  connect(core.pin[22], led_1_2.p) annotation(
    Line(points = {{-181.5, 40}, {66, 40}, {66, 128}}, color = {0, 0, 255}));
  connect(core.pin[22], led_2_2.p) annotation(
    Line(points = {{-181.5, 40}, {102, 40}, {102, 128}}, color = {0, 0, 255}));
  connect(core.pin[22], led_3_2.p) annotation(
    Line(points = {{-181.5, 40}, {138, 40}, {138, 128}}, color = {0, 0, 255}));
  connect(core.pin[22], led_4_2.p) annotation(
    Line(points = {{-181.5, 40}, {174, 40}, {174, 128}}, color = {0, 0, 255}));
  connect(core.pin[23], led_0_3.p) annotation(
    Line(points = {{-181.5, 40}, {30, 40}, {30, 92}}, color = {0, 0, 255}));
  connect(core.pin[23], led_1_3.p) annotation(
    Line(points = {{-181.5, 40}, {66, 40}, {66, 92}}, color = {0, 0, 255}));
  connect(core.pin[23], led_2_3.p) annotation(
    Line(points = {{-181.5, 40}, {102, 40}, {102, 92}}, color = {0, 0, 255}));
  connect(core.pin[23], led_3_3.p) annotation(
    Line(points = {{-181.5, 40}, {138, 40}, {138, 92}}, color = {0, 0, 255}));
  connect(core.pin[23], led_4_3.p) annotation(
    Line(points = {{-181.5, 40}, {174, 40}, {174, 92}}, color = {0, 0, 255}));
  connect(core.pin[24], led_0_4.p) annotation(
    Line(points = {{-181.5, 40}, {30, 40}, {30, 56}}, color = {0, 0, 255}));
  connect(core.pin[24], led_1_4.p) annotation(
    Line(points = {{-181.5, 40}, {66, 40}, {66, 56}}, color = {0, 0, 255}));
  connect(core.pin[24], led_2_4.p) annotation(
    Line(points = {{-181.5, 40}, {102, 40}, {102, 56}}, color = {0, 0, 255}));
  connect(core.pin[24], led_3_4.p) annotation(
    Line(points = {{-181.5, 40}, {138, 40}, {138, 56}}, color = {0, 0, 255}));
  connect(core.pin[24], led_4_4.p) annotation(
    Line(points = {{-181.5, 40}, {174, 40}, {174, 56}}, color = {0, 0, 255}));
  connect(led_0_0.n, core.pin[5]) annotation(
    Line(points = {{50, 200}, {260, 200}, {260, -64}}, color = {0, 0, 255}));
  connect(led_0_1.n, core.pin[5]) annotation(
    Line(points = {{50, 164}, {260, 164}, {260, -64}}, color = {0, 0, 255}));
  connect(led_0_2.n, core.pin[5]) annotation(
    Line(points = {{50, 128}, {260, 128}, {260, -64}}, color = {0, 0, 255}));
  connect(led_0_3.n, core.pin[5]) annotation(
    Line(points = {{50, 92}, {260, 92}, {260, -64}}, color = {0, 0, 255}));
  connect(led_0_4.n, core.pin[5]) annotation(
    Line(points = {{50, 56}, {260, 56}, {260, -64}}, color = {0, 0, 255}));
  connect(led_1_0.n, core.pin[8]) annotation(
    Line(points = {{86, 200}, {260, 200}, {260, -90}}, color = {0, 0, 255}));
  connect(led_1_1.n, core.pin[8]) annotation(
    Line(points = {{86, 164}, {260, 164}, {260, -90}}, color = {0, 0, 255}));
  connect(led_1_2.n, core.pin[8]) annotation(
    Line(points = {{86, 128}, {260, 128}, {260, -90}}, color = {0, 0, 255}));
  connect(led_1_3.n, core.pin[8]) annotation(
    Line(points = {{86, 92}, {260, 92}, {260, -90}}, color = {0, 0, 255}));
  connect(led_1_4.n, core.pin[8]) annotation(
    Line(points = {{86, 56}, {260, 56}, {260, -90}}, color = {0, 0, 255}));
  connect(led_2_0.n, core.pin[4]) annotation(
    Line(points = {{122, 200}, {260, 200}, {260, -116}}, color = {0, 0, 255}));
  connect(led_2_1.n, core.pin[4]) annotation(
    Line(points = {{122, 164}, {260, 164}, {260, -116}}, color = {0, 0, 255}));
  connect(led_2_2.n, core.pin[4]) annotation(
    Line(points = {{122, 128}, {260, 128}, {260, -116}}, color = {0, 0, 255}));
  connect(led_2_3.n, core.pin[4]) annotation(
    Line(points = {{122, 92}, {260, 92}, {260, -116}}, color = {0, 0, 255}));
  connect(led_2_4.n, core.pin[4]) annotation(
    Line(points = {{122, 56}, {260, 56}, {260, -116}}, color = {0, 0, 255}));
  connect(led_3_0.n, core.pin[7]) annotation(
    Line(points = {{158, 200}, {260, 200}, {260, -142}}, color = {0, 0, 255}));
  connect(led_3_1.n, core.pin[7]) annotation(
    Line(points = {{158, 164}, {260, 164}, {260, -142}}, color = {0, 0, 255}));
  connect(led_3_2.n, core.pin[7]) annotation(
    Line(points = {{158, 128}, {260, 128}, {260, -142}}, color = {0, 0, 255}));
  connect(led_3_3.n, core.pin[7]) annotation(
    Line(points = {{158, 92}, {260, 92}, {260, -142}}, color = {0, 0, 255}));
  connect(led_3_4.n, core.pin[7]) annotation(
    Line(points = {{158, 56}, {260, 56}, {260, -142}}, color = {0, 0, 255}));
  connect(led_4_0.n, core.pin[11]) annotation(
    Line(points = {{194, 200}, {260, 200}, {260, -168}}, color = {0, 0, 255}));
  connect(led_4_1.n, core.pin[11]) annotation(
    Line(points = {{194, 164}, {260, 164}, {260, -168}}, color = {0, 0, 255}));
  connect(led_4_2.n, core.pin[11]) annotation(
    Line(points = {{194, 128}, {260, 128}, {260, -168}}, color = {0, 0, 255}));
  connect(led_4_3.n, core.pin[11]) annotation(
    Line(points = {{194, 92}, {260, 92}, {260, -168}}, color = {0, 0, 255}));
  connect(led_4_4.n, core.pin[11]) annotation(
    Line(points = {{194, 56}, {260, 56}, {260, -168}}, color = {0, 0, 255}));
  connect(P0, core.pin[1]) annotation(
    Line(points = {{-330, 300}, {-240, 300}, {-181.5, 40}}, color = {0, 0, 255}));
  connect(P1, core.pin[2]) annotation(
    Line(points = {{-330, 274}, {-240, 274}, {-181.5, 40}}, color = {0, 0, 255}));
  connect(P2, core.pin[3]) annotation(
    Line(points = {{-330, 248}, {-240, 248}, {-181.5, 40}}, color = {0, 0, 255}));
  connect(P3, core.pin[4]) annotation(
    Line(points = {{-330, 222}, {-240, 222}, {-181.5, 40}}, color = {0, 0, 255}));
  connect(P4, core.pin[5]) annotation(
    Line(points = {{-330, 196}, {-240, 196}, {-181.5, 40}}, color = {0, 0, 255}));
  connect(P5, core.pin[6]) annotation(
    Line(points = {{-330, 170}, {-240, 170}, {-181.5, 40}}, color = {0, 0, 255}));
  connect(P6, core.pin[7]) annotation(
    Line(points = {{-330, 144}, {-240, 144}, {-181.5, 40}}, color = {0, 0, 255}));
  connect(P7, core.pin[8]) annotation(
    Line(points = {{-330, 118}, {-240, 118}, {-181.5, 40}}, color = {0, 0, 255}));
  connect(P8, core.pin[9]) annotation(
    Line(points = {{-330, 92}, {-240, 92}, {-181.5, 40}}, color = {0, 0, 255}));
  connect(P9, core.pin[10]) annotation(
    Line(points = {{-330, 66}, {-240, 66}, {-181.5, 40}}, color = {0, 0, 255}));
  connect(P10, core.pin[11]) annotation(
    Line(points = {{-330, 40}, {-240, 40}, {-181.5, 40}}, color = {0, 0, 255}));
  connect(P11, core.pin[12]) annotation(
    Line(points = {{-330, 14}, {-240, 14}, {-181.5, 40}}, color = {0, 0, 255}));
  connect(P12, core.pin[13]) annotation(
    Line(points = {{-330, -12}, {-240, -12}, {-181.5, 40}}, color = {0, 0, 255}));
  connect(P13, core.pin[14]) annotation(
    Line(points = {{-330, -38}, {-240, -38}, {-181.5, 40}}, color = {0, 0, 255}));
  connect(P14, core.pin[15]) annotation(
    Line(points = {{-330, -64}, {-240, -64}, {-181.5, 40}}, color = {0, 0, 255}));
  connect(P15, core.pin[16]) annotation(
    Line(points = {{-330, -90}, {-240, -90}, {-181.5, 40}}, color = {0, 0, 255}));
  connect(P16, core.pin[17]) annotation(
    Line(points = {{-330, -116}, {-240, -116}, {-181.5, 40}}, color = {0, 0, 255}));
  connect(P19, core.pin[18]) annotation(
    Line(points = {{-330, -142}, {-240, -142}, {-181.5, 40}}, color = {0, 0, 255}));
  connect(P20, core.pin[19]) annotation(
    Line(points = {{-330, -168}, {-240, -168}, {-181.5, 40}}, color = {0, 0, 255}));
  connect(usbSupply.p, usbCable.p) annotation(
    Line(points = {{200, 250}, {230, 250}, {230, 240}}, color = {230, 120, 0}));
  connect(usbCable.n, regulator.vin) annotation(
    Line(points = {{250, 240}, {120, 240}, {120, 140}}, color = {230, 120, 0}));
  connect(usbSupply.n, core.gnd) annotation(
    Line(points = {{200, 230}, {200, -250}, {-110, -250}}, color = {0, 0, 255}));
  connect(regulator.vout, P_3V) annotation(
    Line(points = {{180, 140}, {280, 140}, {280, -190}, {-330, -190}}, color = {220, 0, 0}));
  connect(regulator.gnd, core.gnd) annotation(
    Line(points = {{140, 120}, {140, -250}, {-110, -250}}, color = {0, 0, 255}));
  connect(regulator.en, regulator.vin) annotation(
    Line(points = {{128, 120}, {128, 90}, {160, 90}, {160, 140}}, color = {220, 0, 0}));
  connect(P_3V, core.vdd) annotation(
    Line(points = {{-330, -190}, {-110, -190}, {-110, 111.5}}, color = {220, 0, 0}));
  connect(P_3V, core.vref) annotation(
    Line(points = {{-330, -190}, {-149, -190}, {-149, 111.5}}, color = {0, 150, 0}));
  connect(GND, core.gnd) annotation(
    Line(points = {{-330, -230}, {-110, -230}, {-110, -250}}, color = {0, 0, 255}));
  connect(P_3V, pullBtnA.p) annotation(
    Line(points = {{-330, -190}, {-160, -190}, {-160, -260}}, color = {220, 0, 0}));
  connect(pullBtnA.n, P5) annotation(
    Line(points = {{-160, -260}, {-330, -260}, {-330, 170}}, color = {0, 0, 255}));
  connect(buttonA, switchA.control) annotation(
    Line(points = {{-330, -290}, {-70, -290}, {-70, -250}}, color = {150, 0, 200}));
  connect(switchA.p, P5) annotation(
    Line(points = {{-70, -270}, {-330, -270}, {-330, 170}}, color = {0, 0, 255}));
  connect(switchA.n, core.gnd) annotation(
    Line(points = {{-50, -270}, {-50, -250}, {-110, -250}}, color = {0, 0, 255}));
  connect(P_3V, pullBtnB.p) annotation(
    Line(points = {{-330, -190}, {-160, -190}, {-160, -290}}, color = {220, 0, 0}));
  connect(pullBtnB.n, P11) annotation(
    Line(points = {{-160, -290}, {-330, -290}, {-330, 14}}, color = {0, 0, 255}));
  connect(buttonB, switchB.control) annotation(
    Line(points = {{-330, -320}, {-70, -320}, {-70, -280}}, color = {150, 0, 200}));
  connect(switchB.p, P11) annotation(
    Line(points = {{-70, -300}, {-330, -300}, {-330, 14}}, color = {0, 0, 255}));
  connect(switchB.n, core.gnd) annotation(
    Line(points = {{-50, -300}, {-50, -250}, {-110, -250}}, color = {0, 0, 255}));
  connect(P_3V, pullI2cScl.p) annotation(
    Line(points = {{-330, -190}, {-160, -190}, {-160, -160}}, color = {220, 0, 0}));
  connect(pullI2cScl.n, P19) annotation(
    Line(points = {{-160, -180}, {-330, -180}, {-330, -142}}, color = {0, 0, 255}));
  connect(P_3V, pullI2cSda.p) annotation(
    Line(points = {{-330, -190}, {-160, -190}, {-160, -190}}, color = {220, 0, 0}));
  connect(pullI2cSda.n, P20) annotation(
    Line(points = {{-160, -210}, {-330, -210}, {-330, -168}}, color = {0, 0, 255}));
  connect(P_3V, pullRing0.p) annotation(
    Line(points = {{-330, -190}, {-230, -190}, {-230, 170}}, color = {220, 0, 0}));
  connect(pullRing0.n, P0) annotation(
    Line(points = {{-230, 150}, {-330, 150}, {-330, 300}}, color = {0, 0, 255}));
  connect(P_3V, pullRing1.p) annotation(
    Line(points = {{-330, -190}, {-230, -190}, {-230, 130}}, color = {220, 0, 0}));
  connect(pullRing1.n, P1) annotation(
    Line(points = {{-230, 110}, {-330, 110}, {-330, 274}}, color = {0, 0, 255}));
  connect(P_3V, pullRing2.p) annotation(
    Line(points = {{-330, -190}, {-230, -190}, {-230, 90}}, color = {220, 0, 0}));
  connect(pullRing2.n, P2) annotation(
    Line(points = {{-230, 70}, {-330, 70}, {-330, 248}}, color = {0, 0, 255}));
  connect(sensor_accelX.p, core.pin[25]) annotation(
    Line(points = {{250, -60}, {-200, -60}, {-181.5, 40}}, color = {0, 150, 0}));
  connect(sensor_accelX.n, core.gnd) annotation(
    Line(points = {{270, -60}, {270, -250}, {-110, -250}}, color = {0, 0, 255}));
  connect(sensor_accelY.p, core.pin[26]) annotation(
    Line(points = {{250, -100}, {-170, -100}, {-181.5, 40}}, color = {0, 150, 0}));
  connect(sensor_accelY.n, core.gnd) annotation(
    Line(points = {{270, -100}, {270, -250}, {-110, -250}}, color = {0, 0, 255}));
  connect(sensor_accelZ.p, core.pin[27]) annotation(
    Line(points = {{250, -140}, {-140, -140}, {-181.5, 40}}, color = {0, 150, 0}));
  connect(sensor_accelZ.n, core.gnd) annotation(
    Line(points = {{270, -140}, {270, -250}, {-110, -250}}, color = {0, 0, 255}));
  connect(sensor_magX.p, core.pin[28]) annotation(
    Line(points = {{250, -180}, {-110, -180}, {-181.5, 40}}, color = {0, 150, 0}));
  connect(sensor_magX.n, core.gnd) annotation(
    Line(points = {{270, -180}, {270, -250}, {-110, -250}}, color = {0, 0, 255}));
  connect(sensor_magY.p, core.pin[29]) annotation(
    Line(points = {{250, -220}, {-80, -220}, {-181.5, 40}}, color = {0, 150, 0}));
  connect(sensor_magY.n, core.gnd) annotation(
    Line(points = {{270, -220}, {270, -250}, {-110, -250}}, color = {0, 0, 255}));
  connect(sensor_magZ.p, core.pin[30]) annotation(
    Line(points = {{250, -260}, {-50, -260}, {-181.5, 40}}, color = {0, 150, 0}));
  connect(sensor_magZ.n, core.gnd) annotation(
    Line(points = {{270, -260}, {270, -250}, {-110, -250}}, color = {0, 0, 255}));
  connect(sensor_temp.p, core.pin[31]) annotation(
    Line(points = {{250, -300}, {-20, -300}, {-181.5, 40}}, color = {0, 150, 0}));
  connect(sensor_temp.n, core.gnd) annotation(
    Line(points = {{270, -300}, {270, -250}, {-110, -250}}, color = {0, 0, 255}));
  connect(sensor_light.p, core.pin[32]) annotation(
    Line(points = {{250, -340}, {10, -340}, {-181.5, 40}}, color = {0, 150, 0}));
  connect(sensor_light.n, core.gnd) annotation(
    Line(points = {{270, -340}, {270, -250}, {-110, -250}}, color = {0, 0, 255}));
  if useAccelXInput then
    connect(accelXIn, internal_accelX);
  else
    connect(const_accelX.y, internal_accelX);
  end if;
  sensor_accelX.v = vRail*(0.5 + internal_accelX/39.24);
  if useAccelYInput then
    connect(accelYIn, internal_accelY);
  else
    connect(const_accelY.y, internal_accelY);
  end if;
  sensor_accelY.v = vRail*(0.5 + internal_accelY/39.24);
  if useAccelZInput then
    connect(accelZIn, internal_accelZ);
  else
    connect(const_accelZ.y, internal_accelZ);
  end if;
  sensor_accelZ.v = vRail*(0.5 + internal_accelZ/39.24);
  if useMagXInput then
    connect(magXIn, internal_magX);
  else
    connect(const_magX.y, internal_magX);
  end if;
  sensor_magX.v = vRail*(0.5 + internal_magX/400);
  if useMagYInput then
    connect(magYIn, internal_magY);
  else
    connect(const_magY.y, internal_magY);
  end if;
  sensor_magY.v = vRail*(0.5 + internal_magY/400);
  if useMagZInput then
    connect(magZIn, internal_magZ);
  else
    connect(const_magZ.y, internal_magZ);
  end if;
  sensor_magZ.v = vRail*(0.5 + internal_magZ/400);
  if useTempInput then
    connect(tempIn, internal_temp);
  else
    connect(const_temp.y, internal_temp);
  end if;
  sensor_temp.v = vRail*((internal_temp + 20)/100);
  if useLightInput then
    connect(lightIn, internal_light);
  else
    connect(const_light.y, internal_light);
  end if;
  sensor_light.v = vRail*(internal_light/255);
  annotation(
    Icon(coordinateSystem(preserveAspectRatio = true, extent = {{-230, -210}, {230, 210}}, initialScale = 0.2), graphics = {Rectangle(lineColor = {0, 90, 40}, fillColor = {0, 120, 60}, fillPattern = FillPattern.Solid, extent = {{-204.7, 169.3}, {204.7, -169.3}}, radius = 6), Rectangle(lineColor = {200, 160, 40}, fillColor = {230, 190, 60}, fillPattern = FillPattern.Solid, extent = {{-174.3, -137.8}, {-165.7, -166.2}}), Rectangle(lineColor = {200, 160, 40}, fillColor = {230, 190, 60}, fillPattern = FillPattern.Solid, extent = {{-164.3, -137.8}, {-155.7, -166.2}}), Text( textColor = {255, 255, 255}, extent = {{-165, -120.9}, {-155, -135.8}}, textString = "3", fontSize = 9), Ellipse(lineColor = {200, 160, 40}, fillColor = {230, 190, 60}, fillPattern = FillPattern.Solid, extent = {{-155.7, -137.9}, {-124.3, -169.3}}), Ellipse(lineColor = {20, 20, 20}, fillColor = {25, 25, 25}, fillPattern = FillPattern.Solid, extent = {{-151.8, -141.8}, {-128.2, -165.4}}), Rectangle(lineColor = {25, 25, 25}, fillColor = {25, 25, 25}, fillPattern = FillPattern.Solid, extent = {{-153.4, -118.9}, {-126.6, -137.8}}), Text(textColor = {255, 255, 255}, extent = {{-150.4, -121.9}, {-129.6, -134.8}}, textString = "0", fontSize = 10), Rectangle(lineColor = {200, 160, 40}, fillColor = {230, 190, 60}, fillPattern = FillPattern.Solid, extent = {{-124.3, -137.8}, {-115.7, -166.2}}), Text( textColor = {255, 255, 255}, extent = {{-125, -120.9}, {-115, -135.8}}, textString = "4", fontSize = 9), Rectangle(lineColor = {200, 160, 40}, fillColor = {230, 190, 60}, fillPattern = FillPattern.Solid, extent = {{-114.3, -137.8}, {-105.7, -166.2}}), Text( textColor = {255, 255, 255}, extent = {{-115, -120.9}, {-105, -135.8}}, textString = "5", fontSize = 9), Rectangle(lineColor = {200, 160, 40}, fillColor = {230, 190, 60}, fillPattern = FillPattern.Solid, extent = {{-104.3, -137.8}, {-95.7, -166.2}}), Text( textColor = {255, 255, 255}, extent = {{-105, -120.9}, {-95, -135.8}}, textString = "6", fontSize = 9), Rectangle(lineColor = {200, 160, 40}, fillColor = {230, 190, 60}, fillPattern = FillPattern.Solid, extent = {{-94.3, -137.8}, {-85.7, -166.2}}), Text( textColor = {255, 255, 255}, extent = {{-95, -120.9}, {-85, -135.8}}, textString = "7", fontSize = 9), Ellipse(lineColor = {200, 160, 40}, fillColor = {230, 190, 60}, fillPattern = FillPattern.Solid, extent = {{-85.7, -137.9}, {-54.3, -169.3}}), Ellipse(lineColor = {20, 20, 20}, fillColor = {25, 25, 25}, fillPattern = FillPattern.Solid, extent = {{-81.8, -141.8}, {-58.2, -165.4}}), Rectangle(lineColor = {25, 25, 25}, fillColor = {25, 25, 25}, fillPattern = FillPattern.Solid, extent = {{-83.4, -118.9}, {-56.6, -137.8}}), Text(textColor = {255, 255, 255}, extent = {{-80.4, -121.9}, {-59.6, -134.8}}, textString = "1", fontSize = 10), Rectangle(lineColor = {200, 160, 40}, fillColor = {230, 190, 60}, fillPattern = FillPattern.Solid, extent = {{-54.3, -137.8}, {-45.7, -166.2}}), Text( textColor = {255, 255, 255}, extent = {{-55, -120.9}, {-45, -135.8}}, textString = "8", fontSize = 9), Rectangle(lineColor = {200, 160, 40}, fillColor = {230, 190, 60}, fillPattern = FillPattern.Solid, extent = {{-44.3, -137.8}, {-35.7, -166.2}}), Text( textColor = {255, 255, 255}, extent = {{-45, -120.9}, {-35, -135.8}}, textString = "9", fontSize = 9), Rectangle(lineColor = {200, 160, 40}, fillColor = {230, 190, 60}, fillPattern = FillPattern.Solid, extent = {{-34.3, -137.8}, {-25.7, -166.2}}), Text( textColor = {255, 255, 255}, extent = {{-35, -120.9}, {-25, -135.8}}, textString = "10", fontSize = 9), Rectangle(lineColor = {200, 160, 40}, fillColor = {230, 190, 60}, fillPattern = FillPattern.Solid, extent = {{-24.3, -137.8}, {-15.7, -166.2}}), Text( textColor = {255, 255, 255}, extent = {{-25, -120.9}, {-15, -135.8}}, textString = "11", fontSize = 9), Rectangle(lineColor = {200, 160, 40}, fillColor = {230, 190, 60}, fillPattern = FillPattern.Solid, extent = {{-14.3, -137.8}, {-5.7, -166.2}}), Text( textColor = {255, 255, 255}, extent = {{-15, -120.9}, {-5, -135.8}}, textString = "12", fontSize = 9), Ellipse(lineColor = {200, 160, 40}, fillColor = {230, 190, 60}, fillPattern = FillPattern.Solid, extent = {{-5.7, -137.9}, {25.7, -169.3}}), Ellipse(lineColor = {20, 20, 20}, fillColor = {25, 25, 25}, fillPattern = FillPattern.Solid, extent = {{-1.8, -141.8}, {21.8, -165.4}}), Rectangle(lineColor = {25, 25, 25}, fillColor = {25, 25, 25}, fillPattern = FillPattern.Solid, extent = {{-3.4, -118.9}, {23.4, -137.8}}), Text(textColor = {255, 255, 255}, extent = {{-0.4, -121.9}, {20.4, -134.8}}, textString = "2", fontSize = 10), Rectangle(lineColor = {200, 160, 40}, fillColor = {230, 190, 60}, fillPattern = FillPattern.Solid, extent = {{25.7, -137.8}, {34.3, -166.2}}), Text( textColor = {255, 255, 255}, extent = {{25, -120.9}, {35, -135.8}}, textString = "13", fontSize = 9), Rectangle(lineColor = {200, 160, 40}, fillColor = {230, 190, 60}, fillPattern = FillPattern.Solid, extent = {{35.7, -137.8}, {44.3, -166.2}}), Text( textColor = {255, 255, 255}, extent = {{35, -120.9}, {45, -135.8}}, textString = "14", fontSize = 9), Rectangle(lineColor = {200, 160, 40}, fillColor = {230, 190, 60}, fillPattern = FillPattern.Solid, extent = {{45.7, -137.8}, {54.3, -166.2}}), Text( textColor = {255, 255, 255}, extent = {{45, -120.9}, {55, -135.8}}, textString = "15", fontSize = 9), Rectangle(lineColor = {200, 160, 40}, fillColor = {230, 190, 60}, fillPattern = FillPattern.Solid, extent = {{55.7, -137.8}, {64.3, -166.2}}), Text( textColor = {255, 255, 255}, extent = {{55, -120.9}, {65, -135.8}}, textString = "16", fontSize = 9), Rectangle(lineColor = {200, 160, 40}, fillColor = {230, 190, 60}, fillPattern = FillPattern.Solid, extent = {{65.7, -137.8}, {74.3, -166.2}}), Rectangle(lineColor = {200, 160, 40}, fillColor = {230, 190, 60}, fillPattern = FillPattern.Solid, extent = {{75.7, -137.8}, {84.3, -166.2}}), Ellipse(lineColor = {200, 160, 40}, fillColor = {230, 190, 60}, fillPattern = FillPattern.Solid, extent = {{84.3, -137.9}, {115.7, -169.3}}), Ellipse(lineColor = {20, 20, 20}, fillColor = {25, 25, 25}, fillPattern = FillPattern.Solid, extent = {{88.2, -141.8}, {111.8, -165.4}}), Rectangle(lineColor = {25, 25, 25}, fillColor = {25, 25, 25}, fillPattern = FillPattern.Solid, extent = {{84.25, -118.9}, {115.75, -137.8}}), Text(textColor = {255, 255, 255}, extent = {{87.25, -121.9}, {112.75, -134.8}}, textString = "3V", fontSize = 10), Rectangle(lineColor = {200, 160, 40}, fillColor = {230, 190, 60}, fillPattern = FillPattern.Solid, extent = {{115.7, -137.8}, {124.3, -166.2}}), Text( textColor = {255, 255, 255}, extent = {{115, -120.9}, {125, -135.8}}, textString = "19", fontSize = 9), Rectangle(lineColor = {200, 160, 40}, fillColor = {230, 190, 60}, fillPattern = FillPattern.Solid, extent = {{125.7, -137.8}, {134.3, -166.2}}), Text( textColor = {255, 255, 255}, extent = {{125, -120.9}, {135, -135.8}}, textString = "20", fontSize = 9), Ellipse(lineColor = {200, 160, 40}, fillColor = {230, 190, 60}, fillPattern = FillPattern.Solid, extent = {{134.3, -137.9}, {165.7, -169.3}}), Ellipse(lineColor = {20, 20, 20}, fillColor = {25, 25, 25}, fillPattern = FillPattern.Solid, extent = {{138.2, -141.8}, {161.8, -165.4}}), Rectangle(lineColor = {25, 25, 25}, fillColor = {25, 25, 25}, fillPattern = FillPattern.Solid, extent = {{134.25, -118.9}, {165.75, -137.8}}), Text(textColor = {255, 255, 255}, extent = {{137.25, -121.9}, {162.75, -134.8}}, textString = "GND", fontSize = 10), Rectangle(lineColor = {200, 160, 40}, fillColor = {230, 190, 60}, fillPattern = FillPattern.Solid, extent = {{165.7, -137.8}, {174.3, -166.2}}), Rectangle(lineColor = {110, 110, 110}, fillColor = {200, 200, 200}, fillPattern = FillPattern.Solid, extent = {{-147.65, 166.9}, {-88.55, 123.6}}), Rectangle(lineColor = {60, 60, 60}, fillColor = {70, 70, 70}, fillPattern = FillPattern.Solid, extent = {{-133.8, 166.9}, {-102.4, 157.5}}), Polygon(visible = usbConnected, lineColor = {200, 140, 0}, fillColor = {255, 210, 0}, fillPattern = FillPattern.Solid, points = {{-114.2, 155.1}, {-123.3, 140.8}, {-118.1, 140.8}, {-122, 126.5}, {-111.6, 144.7}, {-116.8, 144.7}, {-112.9, 155.1}, {-114.2, 155.1}}), Rectangle(lineColor = {25, 25, 25}, fillColor = {25, 25, 25}, fillPattern = FillPattern.Solid, extent = {{-76.3, 84.2}, {-55.9, 63.8}}, radius = 2), Ellipse(lineColor = {60, 60, 60}, fillColor = DynamicSelect({80, 10, 10}, {integer(80 + min(1, max(0, led_0_0.mean.y)/led_0_0.IMax)*175), integer(10 + min(1, max(0, led_0_0.mean.y)/led_0_0.IMax)*50), integer(10 + min(1, max(0, led_0_0.mean.y)/led_0_0.IMax)*40)}), fillPattern = FillPattern.Solid, extent = {{-73.2, 81.1}, {-59, 66.9}}), Rectangle(lineColor = {25, 25, 25}, fillColor = {25, 25, 25}, fillPattern = FillPattern.Solid, extent = {{-76.3, 51.1}, {-55.9, 30.7}}, radius = 2), Ellipse(lineColor = {60, 60, 60}, fillColor = DynamicSelect({80, 10, 10}, {integer(80 + min(1, max(0, led_0_1.mean.y)/led_0_1.IMax)*175), integer(10 + min(1, max(0, led_0_1.mean.y)/led_0_1.IMax)*50), integer(10 + min(1, max(0, led_0_1.mean.y)/led_0_1.IMax)*40)}), fillPattern = FillPattern.Solid, extent = {{-73.2, 48}, {-59, 33.8}}), Rectangle(lineColor = {25, 25, 25}, fillColor = {25, 25, 25}, fillPattern = FillPattern.Solid, extent = {{-76.3, 18}, {-55.9, -2.4}}, radius = 2), Ellipse(lineColor = {60, 60, 60}, fillColor = DynamicSelect({80, 10, 10}, {integer(80 + min(1, max(0, led_0_2.mean.y)/led_0_2.IMax)*175), integer(10 + min(1, max(0, led_0_2.mean.y)/led_0_2.IMax)*50), integer(10 + min(1, max(0, led_0_2.mean.y)/led_0_2.IMax)*40)}), fillPattern = FillPattern.Solid, extent = {{-73.2, 14.9}, {-59, 0.7}}), Rectangle(lineColor = {25, 25, 25}, fillColor = {25, 25, 25}, fillPattern = FillPattern.Solid, extent = {{-76.3, -15.1}, {-55.9, -35.5}}, radius = 2), Ellipse(lineColor = {60, 60, 60}, fillColor = DynamicSelect({80, 10, 10}, {integer(80 + min(1, max(0, led_0_3.mean.y)/led_0_3.IMax)*175), integer(10 + min(1, max(0, led_0_3.mean.y)/led_0_3.IMax)*50), integer(10 + min(1, max(0, led_0_3.mean.y)/led_0_3.IMax)*40)}), fillPattern = FillPattern.Solid, extent = {{-73.2, -18.2}, {-59, -32.4}}), Rectangle(lineColor = {25, 25, 25}, fillColor = {25, 25, 25}, fillPattern = FillPattern.Solid, extent = {{-76.3, -48.2}, {-55.9, -68.6}}, radius = 2), Ellipse(lineColor = {60, 60, 60}, fillColor = DynamicSelect({80, 10, 10}, {integer(80 + min(1, max(0, led_0_4.mean.y)/led_0_4.IMax)*175), integer(10 + min(1, max(0, led_0_4.mean.y)/led_0_4.IMax)*50), integer(10 + min(1, max(0, led_0_4.mean.y)/led_0_4.IMax)*40)}), fillPattern = FillPattern.Solid, extent = {{-73.2, -51.3}, {-59, -65.5}}), Rectangle(lineColor = {25, 25, 25}, fillColor = {25, 25, 25}, fillPattern = FillPattern.Solid, extent = {{-43.2, 84.2}, {-22.8, 63.8}}, radius = 2), Ellipse(lineColor = {60, 60, 60}, fillColor = DynamicSelect({80, 10, 10}, {integer(80 + min(1, max(0, led_1_0.mean.y)/led_1_0.IMax)*175), integer(10 + min(1, max(0, led_1_0.mean.y)/led_1_0.IMax)*50), integer(10 + min(1, max(0, led_1_0.mean.y)/led_1_0.IMax)*40)}), fillPattern = FillPattern.Solid, extent = {{-40.1, 81.1}, {-25.9, 66.9}}), Rectangle(lineColor = {25, 25, 25}, fillColor = {25, 25, 25}, fillPattern = FillPattern.Solid, extent = {{-43.2, 51.1}, {-22.8, 30.7}}, radius = 2), Ellipse(lineColor = {60, 60, 60}, fillColor = DynamicSelect({80, 10, 10}, {integer(80 + min(1, max(0, led_1_1.mean.y)/led_1_1.IMax)*175), integer(10 + min(1, max(0, led_1_1.mean.y)/led_1_1.IMax)*50), integer(10 + min(1, max(0, led_1_1.mean.y)/led_1_1.IMax)*40)}), fillPattern = FillPattern.Solid, extent = {{-40.1, 48}, {-25.9, 33.8}}), Rectangle(lineColor = {25, 25, 25}, fillColor = {25, 25, 25}, fillPattern = FillPattern.Solid, extent = {{-43.2, 18}, {-22.8, -2.4}}, radius = 2), Ellipse(lineColor = {60, 60, 60}, fillColor = DynamicSelect({80, 10, 10}, {integer(80 + min(1, max(0, led_1_2.mean.y)/led_1_2.IMax)*175), integer(10 + min(1, max(0, led_1_2.mean.y)/led_1_2.IMax)*50), integer(10 + min(1, max(0, led_1_2.mean.y)/led_1_2.IMax)*40)}), fillPattern = FillPattern.Solid, extent = {{-40.1, 14.9}, {-25.9, 0.7}}), Rectangle(lineColor = {25, 25, 25}, fillColor = {25, 25, 25}, fillPattern = FillPattern.Solid, extent = {{-43.2, -15.1}, {-22.8, -35.5}}, radius = 2), Ellipse(lineColor = {60, 60, 60}, fillColor = DynamicSelect({80, 10, 10}, {integer(80 + min(1, max(0, led_1_3.mean.y)/led_1_3.IMax)*175), integer(10 + min(1, max(0, led_1_3.mean.y)/led_1_3.IMax)*50), integer(10 + min(1, max(0, led_1_3.mean.y)/led_1_3.IMax)*40)}), fillPattern = FillPattern.Solid, extent = {{-40.1, -18.2}, {-25.9, -32.4}}), Rectangle(lineColor = {25, 25, 25}, fillColor = {25, 25, 25}, fillPattern = FillPattern.Solid, extent = {{-43.2, -48.2}, {-22.8, -68.6}}, radius = 2), Ellipse(lineColor = {60, 60, 60}, fillColor = DynamicSelect({80, 10, 10}, {integer(80 + min(1, max(0, led_1_4.mean.y)/led_1_4.IMax)*175), integer(10 + min(1, max(0, led_1_4.mean.y)/led_1_4.IMax)*50), integer(10 + min(1, max(0, led_1_4.mean.y)/led_1_4.IMax)*40)}), fillPattern = FillPattern.Solid, extent = {{-40.1, -51.3}, {-25.9, -65.5}}), Rectangle(lineColor = {25, 25, 25}, fillColor = {25, 25, 25}, fillPattern = FillPattern.Solid, extent = {{-10.1, 84.2}, {10.3, 63.8}}, radius = 2), Ellipse(lineColor = {60, 60, 60}, fillColor = DynamicSelect({80, 10, 10}, {integer(80 + min(1, max(0, led_2_0.mean.y)/led_2_0.IMax)*175), integer(10 + min(1, max(0, led_2_0.mean.y)/led_2_0.IMax)*50), integer(10 + min(1, max(0, led_2_0.mean.y)/led_2_0.IMax)*40)}), fillPattern = FillPattern.Solid, extent = {{-7, 81.1}, {7.2, 66.9}}), Rectangle(lineColor = {25, 25, 25}, fillColor = {25, 25, 25}, fillPattern = FillPattern.Solid, extent = {{-10.1, 51.1}, {10.3, 30.7}}, radius = 2), Ellipse(lineColor = {60, 60, 60}, fillColor = DynamicSelect({80, 10, 10}, {integer(80 + min(1, max(0, led_2_1.mean.y)/led_2_1.IMax)*175), integer(10 + min(1, max(0, led_2_1.mean.y)/led_2_1.IMax)*50), integer(10 + min(1, max(0, led_2_1.mean.y)/led_2_1.IMax)*40)}), fillPattern = FillPattern.Solid, extent = {{-7, 48}, {7.2, 33.8}}), Rectangle(lineColor = {25, 25, 25}, fillColor = {25, 25, 25}, fillPattern = FillPattern.Solid, extent = {{-10.1, 18}, {10.3, -2.4}}, radius = 2), Ellipse(lineColor = {60, 60, 60}, fillColor = DynamicSelect({80, 10, 10}, {integer(80 + min(1, max(0, led_2_2.mean.y)/led_2_2.IMax)*175), integer(10 + min(1, max(0, led_2_2.mean.y)/led_2_2.IMax)*50), integer(10 + min(1, max(0, led_2_2.mean.y)/led_2_2.IMax)*40)}), fillPattern = FillPattern.Solid, extent = {{-7, 14.9}, {7.2, 0.7}}), Rectangle(lineColor = {25, 25, 25}, fillColor = {25, 25, 25}, fillPattern = FillPattern.Solid, extent = {{-10.1, -15.1}, {10.3, -35.5}}, radius = 2), Ellipse(lineColor = {60, 60, 60}, fillColor = DynamicSelect({80, 10, 10}, {integer(80 + min(1, max(0, led_2_3.mean.y)/led_2_3.IMax)*175), integer(10 + min(1, max(0, led_2_3.mean.y)/led_2_3.IMax)*50), integer(10 + min(1, max(0, led_2_3.mean.y)/led_2_3.IMax)*40)}), fillPattern = FillPattern.Solid, extent = {{-7, -18.2}, {7.2, -32.4}}), Rectangle(lineColor = {25, 25, 25}, fillColor = {25, 25, 25}, fillPattern = FillPattern.Solid, extent = {{-10.1, -48.2}, {10.3, -68.6}}, radius = 2), Ellipse(lineColor = {60, 60, 60}, fillColor = DynamicSelect({80, 10, 10}, {integer(80 + min(1, max(0, led_2_4.mean.y)/led_2_4.IMax)*175), integer(10 + min(1, max(0, led_2_4.mean.y)/led_2_4.IMax)*50), integer(10 + min(1, max(0, led_2_4.mean.y)/led_2_4.IMax)*40)}), fillPattern = FillPattern.Solid, extent = {{-7, -51.3}, {7.2, -65.5}}), Rectangle(lineColor = {25, 25, 25}, fillColor = {25, 25, 25}, fillPattern = FillPattern.Solid, extent = {{23, 84.2}, {43.4, 63.8}}, radius = 2), Ellipse(lineColor = {60, 60, 60}, fillColor = DynamicSelect({80, 10, 10}, {integer(80 + min(1, max(0, led_3_0.mean.y)/led_3_0.IMax)*175), integer(10 + min(1, max(0, led_3_0.mean.y)/led_3_0.IMax)*50), integer(10 + min(1, max(0, led_3_0.mean.y)/led_3_0.IMax)*40)}), fillPattern = FillPattern.Solid, extent = {{26.1, 81.1}, {40.3, 66.9}}), Rectangle(lineColor = {25, 25, 25}, fillColor = {25, 25, 25}, fillPattern = FillPattern.Solid, extent = {{23, 51.1}, {43.4, 30.7}}, radius = 2), Ellipse(lineColor = {60, 60, 60}, fillColor = DynamicSelect({80, 10, 10}, {integer(80 + min(1, max(0, led_3_1.mean.y)/led_3_1.IMax)*175), integer(10 + min(1, max(0, led_3_1.mean.y)/led_3_1.IMax)*50), integer(10 + min(1, max(0, led_3_1.mean.y)/led_3_1.IMax)*40)}), fillPattern = FillPattern.Solid, extent = {{26.1, 48}, {40.3, 33.8}}), Rectangle(lineColor = {25, 25, 25}, fillColor = {25, 25, 25}, fillPattern = FillPattern.Solid, extent = {{23, 18}, {43.4, -2.4}}, radius = 2), Ellipse(lineColor = {60, 60, 60}, fillColor = DynamicSelect({80, 10, 10}, {integer(80 + min(1, max(0, led_3_2.mean.y)/led_3_2.IMax)*175), integer(10 + min(1, max(0, led_3_2.mean.y)/led_3_2.IMax)*50), integer(10 + min(1, max(0, led_3_2.mean.y)/led_3_2.IMax)*40)}), fillPattern = FillPattern.Solid, extent = {{26.1, 14.9}, {40.3, 0.7}}), Rectangle(lineColor = {25, 25, 25}, fillColor = {25, 25, 25}, fillPattern = FillPattern.Solid, extent = {{23, -15.1}, {43.4, -35.5}}, radius = 2), Ellipse(lineColor = {60, 60, 60}, fillColor = DynamicSelect({80, 10, 10}, {integer(80 + min(1, max(0, led_3_3.mean.y)/led_3_3.IMax)*175), integer(10 + min(1, max(0, led_3_3.mean.y)/led_3_3.IMax)*50), integer(10 + min(1, max(0, led_3_3.mean.y)/led_3_3.IMax)*40)}), fillPattern = FillPattern.Solid, extent = {{26.1, -18.2}, {40.3, -32.4}}), Rectangle(lineColor = {25, 25, 25}, fillColor = {25, 25, 25}, fillPattern = FillPattern.Solid, extent = {{23, -48.2}, {43.4, -68.6}}, radius = 2), Ellipse(lineColor = {60, 60, 60}, fillColor = DynamicSelect({80, 10, 10}, {integer(80 + min(1, max(0, led_3_4.mean.y)/led_3_4.IMax)*175), integer(10 + min(1, max(0, led_3_4.mean.y)/led_3_4.IMax)*50), integer(10 + min(1, max(0, led_3_4.mean.y)/led_3_4.IMax)*40)}), fillPattern = FillPattern.Solid, extent = {{26.1, -51.3}, {40.3, -65.5}}), Rectangle(lineColor = {25, 25, 25}, fillColor = {25, 25, 25}, fillPattern = FillPattern.Solid, extent = {{56.1, 84.2}, {76.5, 63.8}}, radius = 2), Ellipse(lineColor = {60, 60, 60}, fillColor = DynamicSelect({80, 10, 10}, {integer(80 + min(1, max(0, led_4_0.mean.y)/led_4_0.IMax)*175), integer(10 + min(1, max(0, led_4_0.mean.y)/led_4_0.IMax)*50), integer(10 + min(1, max(0, led_4_0.mean.y)/led_4_0.IMax)*40)}), fillPattern = FillPattern.Solid, extent = {{59.2, 81.1}, {73.4, 66.9}}), Rectangle(lineColor = {25, 25, 25}, fillColor = {25, 25, 25}, fillPattern = FillPattern.Solid, extent = {{56.1, 51.1}, {76.5, 30.7}}, radius = 2), Ellipse(lineColor = {60, 60, 60}, fillColor = DynamicSelect({80, 10, 10}, {integer(80 + min(1, max(0, led_4_1.mean.y)/led_4_1.IMax)*175), integer(10 + min(1, max(0, led_4_1.mean.y)/led_4_1.IMax)*50), integer(10 + min(1, max(0, led_4_1.mean.y)/led_4_1.IMax)*40)}), fillPattern = FillPattern.Solid, extent = {{59.2, 48}, {73.4, 33.8}}), Rectangle(lineColor = {25, 25, 25}, fillColor = {25, 25, 25}, fillPattern = FillPattern.Solid, extent = {{56.1, 18}, {76.5, -2.4}}, radius = 2), Ellipse(lineColor = {60, 60, 60}, fillColor = DynamicSelect({80, 10, 10}, {integer(80 + min(1, max(0, led_4_2.mean.y)/led_4_2.IMax)*175), integer(10 + min(1, max(0, led_4_2.mean.y)/led_4_2.IMax)*50), integer(10 + min(1, max(0, led_4_2.mean.y)/led_4_2.IMax)*40)}), fillPattern = FillPattern.Solid, extent = {{59.2, 14.9}, {73.4, 0.7}}), Rectangle(lineColor = {25, 25, 25}, fillColor = {25, 25, 25}, fillPattern = FillPattern.Solid, extent = {{56.1, -15.1}, {76.5, -35.5}}, radius = 2), Ellipse(lineColor = {60, 60, 60}, fillColor = DynamicSelect({80, 10, 10}, {integer(80 + min(1, max(0, led_4_3.mean.y)/led_4_3.IMax)*175), integer(10 + min(1, max(0, led_4_3.mean.y)/led_4_3.IMax)*50), integer(10 + min(1, max(0, led_4_3.mean.y)/led_4_3.IMax)*40)}), fillPattern = FillPattern.Solid, extent = {{59.2, -18.2}, {73.4, -32.4}}), Rectangle(lineColor = {25, 25, 25}, fillColor = {25, 25, 25}, fillPattern = FillPattern.Solid, extent = {{56.1, -48.2}, {76.5, -68.6}}, radius = 2), Ellipse(lineColor = {60, 60, 60}, fillColor = DynamicSelect({80, 10, 10}, {integer(80 + min(1, max(0, led_4_4.mean.y)/led_4_4.IMax)*175), integer(10 + min(1, max(0, led_4_4.mean.y)/led_4_4.IMax)*50), integer(10 + min(1, max(0, led_4_4.mean.y)/led_4_4.IMax)*40)}), fillPattern = FillPattern.Solid, extent = {{59.2, -51.3}, {73.4, -65.5}}), Ellipse(lineColor = {255, 255, 255}, fillColor = {255, 255, 255}, fillPattern = FillPattern.Solid, extent = {{-216.5, 39.4}, {-153.5, -23.6}}), Ellipse(lineColor = {30, 30, 30}, fillColor = {180, 180, 180}, fillPattern = FillPattern.Solid, extent = {{-212.6, 35.5}, {-157.4, -19.7}}), Text( extent = {{-195, 17.9}, {-175, -2.1}}, textString = "A", fontSize = 18), Ellipse(lineColor = {255, 255, 255}, fillColor = {255, 255, 255}, fillPattern = FillPattern.Solid, extent = {{153.5, 39.4}, {216.5, -23.6}}), Ellipse(lineColor = {30, 30, 30}, fillColor = {180, 180, 180}, fillPattern = FillPattern.Solid, extent = {{157.4, 35.5}, {212.6, -19.7}}), Text( extent = {{175, 17.9}, {195, -2.1}}, textString = "B", fontSize = 18), Rectangle(origin = {130, 2},lineColor = {20, 20, 20}, fillColor = {40, 40, 40}, fillPattern = FillPattern.Solid, extent = {{-27.55, -55.15}, {27.55, -110.25}}), Text(origin = {130, 4},textColor = {220, 220, 220}, extent = {{-23.55, -74.7}, {23.55, -90.7}}, textString = "nRF52833"), Ellipse(lineColor = {60, 60, 60}, fillColor = {200, 200, 200}, fillPattern = FillPattern.Solid, extent = {{140.2, 159}, {159, 140.2}}), Text(origin = {0, 4},textColor = {230, 190, 60}, extent = {{-74, 141}, {74, 115}}, textString = "micro:bit", fontSize = 22, textStyle = {TextStyle.Bold}), Text(textColor = {28, 108, 200}, extent = {{-30, 111.3}, {30, 97.3}}, textString = "v2"), Text(textColor = {0, 0, 255}, extent = {{-150, 191.3}, {150, 173.3}}, textString = "%name")}),
    Diagram(coordinateSystem(preserveAspectRatio = true, extent = {{-340, -460}, {340, 330}}), graphics = {Rectangle(lineColor = {200, 200, 200}, fillColor = {235, 242, 255}, fillPattern = FillPattern.Solid, extent = {{-334, 320}, {-246, -340}}, radius = 4), Rectangle(lineColor = {200, 200, 200}, fillColor = {242, 242, 242}, fillPattern = FillPattern.Solid, extent = {{-60, 260}, {240, -150}}, radius = 4), Rectangle(lineColor = {200, 200, 200}, fillColor = {255, 243, 228}, fillPattern = FillPattern.Solid, extent = {{120, 270}, {334, 60}}, radius = 4), Rectangle(lineColor = {200, 200, 200}, fillColor = {255, 242, 252}, fillPattern = FillPattern.Solid, extent = {{-200, -160}, {334, -450}}, radius = 4), Rectangle(lineColor = {200, 200, 200}, fillColor = {238, 238, 238}, fillPattern = FillPattern.Solid, extent = {{-240, -244}, {300, -266}}, radius = 4), Text(textColor = {90, 90, 90}, extent = {{-330, 318}, {-250, 310}}, textString = "Edge connector (P0-P20, 3V, GND)", horizontalAlignment = TextAlignment.Left), Text(textColor = {90, 90, 90}, extent = {{-56, 258}, {236, 250}}, textString = "LED matrix (5x5, multiplexed)", horizontalAlignment = TextAlignment.Left), Text(textColor = {90, 90, 90}, extent = {{124, 268}, {330, 260}}, textString = "Power supply: USB, regulator, 3V rail", horizontalAlignment = TextAlignment.Left), Text(textColor = {90, 90, 90}, extent = {{-196, -162}, {330, -170}}, textString = "Buttons, pull resistors, sensors", horizontalAlignment = TextAlignment.Left), Text(textColor = {90, 90, 90}, extent = {{-236, -246}, {296, -254}}, textString = "Ground", horizontalAlignment = TextAlignment.Left)}),
    Documentation(info = "Light level 0-255 read by display.read_light_level()"));
end MicroBit_v2;
