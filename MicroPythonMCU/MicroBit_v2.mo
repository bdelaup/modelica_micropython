within MicroPythonMCU;

model MicroBit_v2 "BBC micro:bit v2 board: nRF52833 programmable in MicroPython, real pinout and dimensions, multiplexed 5x5 LED matrix, buttons A/B, integrated sensors and USB power supply"
  extends Internal.PartialUsbBoard(ICore = 0.004, redeclare Internal.McuCoreRadio core(final nPins = 32, final pinIds = {0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 19, 20, 21, 22, 23, 24, 25, 26, 27, 28, 29, 30, 31, 32, 33}, final pinCaps = {7, 7, 7, 7, 7, 3, 3, 3, 3, 3, 7, 3, 3, 3, 3, 3, 3, 3, 3, 1, 1, 1, 1, 1, 4, 4, 4, 4, 4, 4, 4, 4}, final boardProfile = "microbit", final useRadio = useRadio) "The nRF52833: pin[1..19] = P0-P16, P19, P20 (edge), pin[20..24] = matrix rows ROW1-ROW5 (internal), pin[25..32] = accelerometer X/Y/Z, compass X/Y/Z, temperature, light (internal)" annotation(
    Placement(transformation(origin = {-110, 40}, extent = {{-70, -70}, {70, 70}}))));
  type InputSource = MicroPythonMCU.Interfaces.InputSource "Source of each button and integrated sensor value (alias of the shared type, so that existing models keep writing MicroBit_v2.InputSource.Connector)";
  parameter Modelica.Units.SI.Voltage VTgt = 3.0 "Voltage of the 3V rail (output of the on-board regulator, high level and ADC reference of the pins)" annotation(
    Dialog(tab = "Power supply", group = "Regulator"));
  parameter Boolean useGroundPin = true "Show the GND pin - unchecked: the board is referenced to the simulation ground (0 V), nothing to wire" annotation(
    Dialog(tab = "Pins", group = "Supply"),
    choices(checkBox = true));
  parameter Boolean useRadio = false "On-board 2.4 GHz radio (microbit.radio): shows the Antenna port, to wire to the antenna of a Peripherals.Radio.RadioAir - the boards sharing the same air hear each other, radio.on() fails with an explicit error while unwired" annotation(
    Dialog(tab = "Pins", group = "Radio"),
    choices(checkBox = true));
  parameter InputSource accelXSource = InputSource.Constant "How accelX is driven: constant parameter, time table, or connector wired from the diagram" annotation(
    Dialog(tab = "Sensors", group = "Accelerometer"));
  parameter Real accelX = 0 "X axis of the accelerometer, constant value (m/s2)" annotation(
    Dialog(tab = "Sensors", group = "Accelerometer", enable = accelXSource == InputSource.Constant));
  parameter Real accelXTable[:, 2] = {{0, 0}, {0.5, 0}, {1, 5}, {1.5, 0}, {5, 0}} "Time table of accelX (column 1 = time in s, column 2 = value in m/s2)" annotation(
    Dialog(tab = "Sensors", group = "Accelerometer", enable = accelXSource == InputSource.Table));
  parameter InputSource accelYSource = InputSource.Constant "How accelY is driven: constant parameter, time table, or connector wired from the diagram" annotation(
    Dialog(tab = "Sensors", group = "Accelerometer"));
  parameter Real accelY = 0 "Y axis of the accelerometer, constant value (m/s2)" annotation(
    Dialog(tab = "Sensors", group = "Accelerometer", enable = accelYSource == InputSource.Constant));
  parameter Real accelYTable[:, 2] = {{0, 0}} "Time table of accelY (column 1 = time in s, column 2 = value in m/s2)" annotation(
    Dialog(tab = "Sensors", group = "Accelerometer", enable = accelYSource == InputSource.Table));
  parameter InputSource accelZSource = InputSource.Constant "How accelZ is driven: constant parameter, time table, or connector wired from the diagram" annotation(
    Dialog(tab = "Sensors", group = "Accelerometer"));
  parameter Real accelZ = -9.81 "Z axis of the accelerometer (default: gravity, board lying display up), constant value (m/s2)" annotation(
    Dialog(tab = "Sensors", group = "Accelerometer", enable = accelZSource == InputSource.Constant));
  parameter Real accelZTable[:, 2] = {{0, -9.81}} "Time table of accelZ (column 1 = time in s, column 2 = value in m/s2)" annotation(
    Dialog(tab = "Sensors", group = "Accelerometer", enable = accelZSource == InputSource.Table));
  parameter InputSource magXSource = InputSource.Constant "How magX is driven: constant parameter, time table, or connector wired from the diagram" annotation(
    Dialog(tab = "Sensors", group = "Magnetometer/compass"));
  parameter Real magX = 0 "X axis of the magnetometer/compass, constant value (uT)" annotation(
    Dialog(tab = "Sensors", group = "Magnetometer/compass", enable = magXSource == InputSource.Constant));
  parameter Real magXTable[:, 2] = {{0, 0}} "Time table of magX (column 1 = time in s, column 2 = value in uT)" annotation(
    Dialog(tab = "Sensors", group = "Magnetometer/compass", enable = magXSource == InputSource.Table));
  parameter InputSource magYSource = InputSource.Constant "How magY is driven: constant parameter, time table, or connector wired from the diagram" annotation(
    Dialog(tab = "Sensors", group = "Magnetometer/compass"));
  parameter Real magY = 50 "Y axis of the magnetometer/compass (default: field pointing along +Y), constant value (uT)" annotation(
    Dialog(tab = "Sensors", group = "Magnetometer/compass", enable = magYSource == InputSource.Constant));
  parameter Real magYTable[:, 2] = {{0, 50}} "Time table of magY (column 1 = time in s, column 2 = value in uT)" annotation(
    Dialog(tab = "Sensors", group = "Magnetometer/compass", enable = magYSource == InputSource.Table));
  parameter InputSource magZSource = InputSource.Constant "How magZ is driven: constant parameter, time table, or connector wired from the diagram" annotation(
    Dialog(tab = "Sensors", group = "Magnetometer/compass"));
  parameter Real magZ = 0 "Z axis of the magnetometer/compass, constant value (uT)" annotation(
    Dialog(tab = "Sensors", group = "Magnetometer/compass", enable = magZSource == InputSource.Constant));
  parameter Real magZTable[:, 2] = {{0, 0}} "Time table of magZ (column 1 = time in s, column 2 = value in uT)" annotation(
    Dialog(tab = "Sensors", group = "Magnetometer/compass", enable = magZSource == InputSource.Table));
  parameter InputSource tempSource = InputSource.Constant "How temp is driven: constant parameter, time table, or connector wired from the diagram" annotation(
    Dialog(tab = "Sensors", group = "Temperature"));
  parameter Real temp = 27 "Temperature read by microbit.temperature(), constant value (degC)" annotation(
    Dialog(tab = "Sensors", group = "Temperature", enable = tempSource == InputSource.Constant));
  parameter Real tempTable[:, 2] = {{0, 27}, {10, 35}} "Time table of temp (column 1 = time in s, column 2 = value in degC)" annotation(
    Dialog(tab = "Sensors", group = "Temperature", enable = tempSource == InputSource.Table));
  parameter InputSource lightSource = InputSource.Constant "How light is driven: constant parameter, time table, or connector wired from the diagram" annotation(
    Dialog(tab = "Sensors", group = "Light"));
  parameter Real light = 100 "Light level 0-255 read by display.read_light_level(), constant value (1)" annotation(
    Dialog(tab = "Sensors", group = "Light", enable = lightSource == InputSource.Constant));
  parameter Real lightTable[:, 2] = {{0, 200}, {5, 50}} "Time table of light (column 1 = time in s, column 2 = value in 1)" annotation(
    Dialog(tab = "Sensors", group = "Light", enable = lightSource == InputSource.Table));
  parameter InputSource buttonASource = InputSource.Connector "How button A is driven: connector wired from the diagram, time table, or constant state" annotation(
    Dialog(tab = "Buttons", group = "Button A"));
  parameter Boolean buttonAPressed = false "State of button A in constant mode (true = pressed)" annotation(
    Dialog(tab = "Buttons", group = "Button A", enable = buttonASource == InputSource.Constant),
    choices(checkBox = true));
  parameter Real buttonATable[:, 2] = {{0, 0}, {1, 0}, {2, 1}, {3, 0}, {4, 0}, {5, 1}, {6, 0}} "Time table of button A (column 1 = time in s, column 2 = 0 released / 1 pressed)" annotation(
    Dialog(tab = "Buttons", group = "Button A", enable = buttonASource == InputSource.Table));
  parameter InputSource buttonBSource = InputSource.Connector "How button B is driven: connector wired from the diagram, time table, or constant state" annotation(
    Dialog(tab = "Buttons", group = "Button B"));
  parameter Boolean buttonBPressed = false "State of button B in constant mode (true = pressed)" annotation(
    Dialog(tab = "Buttons", group = "Button B", enable = buttonBSource == InputSource.Constant),
    choices(checkBox = true));
  parameter Real buttonBTable[:, 2] = {{0, 0}, {2.5, 0}, {3, 1}, {4, 0}} "Time table of button B (column 1 = time in s, column 2 = 0 released / 1 pressed)" annotation(
    Dialog(tab = "Buttons", group = "Button B", enable = buttonBSource == InputSource.Table));
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
  Modelica.Blocks.Interfaces.BooleanInput buttonA if buttonASource == InputSource.Connector "Button A (P5): true while pressed - wire a boolean signal or source; pressed = pin to GND, 10 kOhm pull-up otherwise" annotation(
    Placement(transformation(origin = {-330, -300}, extent = {{-6, -6}, {6, 6}}), iconTransformation(origin = {-216.7, 0}, extent = {{-5, -5}, {5, 5}})));
  Modelica.Blocks.Interfaces.BooleanInput buttonB if buttonBSource == InputSource.Connector "Button B (P11): true while pressed - same as buttonA" annotation(
    Placement(transformation(origin = {-330, -330}, extent = {{-6, -6}, {6, 6}}), iconTransformation(origin = {216.7, 0}, extent = {{-5, -5}, {5, 5}}, rotation = 180)));
  Interfaces.RadioAirInput Antenna if useRadio "Antenna of the on-board 2.4 GHz radio (microbit.radio): wire it to the antenna of a Peripherals.Radio.RadioAir - the boards sharing the same air hear each other" annotation(
    Placement(transformation(origin = {330, 300}, extent = {{-10, -10}, {10, 10}}), iconTransformation(origin = {140, 183.3}, extent = {{-10, -10}, {10, 10}}, rotation = 270)));
  Modelica.Blocks.Interfaces.RealInput accelXIn(unit = "m/s2") if accelXSource == InputSource.Connector "X axis of the accelerometer from the diagram" annotation(
    Placement(transformation(origin = {330, -60}, extent = {{-6, -6}, {6, 6}}), iconTransformation(origin = {212.7, 125}, extent = {{-10, -10}, {10, 10}}, rotation = 180)));
  Modelica.Blocks.Interfaces.RealInput accelYIn(unit = "m/s2") if accelYSource == InputSource.Connector "Y axis of the accelerometer from the diagram" annotation(
    Placement(transformation(origin = {330, -100}, extent = {{-6, -6}, {6, 6}}), iconTransformation(origin = {212.7, 90}, extent = {{-10, -10}, {10, 10}}, rotation = 180)));
  Modelica.Blocks.Interfaces.RealInput accelZIn(unit = "m/s2") if accelZSource == InputSource.Connector "Z axis of the accelerometer (default: gravity, board lying display up) from the diagram" annotation(
    Placement(transformation(origin = {330, -140}, extent = {{-6, -6}, {6, 6}}), iconTransformation(origin = {212.7, 55}, extent = {{-10, -10}, {10, 10}}, rotation = 180)));
  Modelica.Blocks.Interfaces.RealInput magXIn(unit = "uT") if magXSource == InputSource.Connector "X axis of the magnetometer/compass from the diagram" annotation(
    Placement(transformation(origin = {330, -180}, extent = {{-6, -6}, {6, 6}}), iconTransformation(origin = {-212.7, 125}, extent = {{-10, -10}, {10, 10}})));
  Modelica.Blocks.Interfaces.RealInput magYIn(unit = "uT") if magYSource == InputSource.Connector "Y axis of the magnetometer/compass (default: field pointing along +Y) from the diagram" annotation(
    Placement(transformation(origin = {330, -220}, extent = {{-6, -6}, {6, 6}}), iconTransformation(origin = {-212.7, 90}, extent = {{-10, -10}, {10, 10}})));
  Modelica.Blocks.Interfaces.RealInput magZIn(unit = "uT") if magZSource == InputSource.Connector "Z axis of the magnetometer/compass from the diagram" annotation(
    Placement(transformation(origin = {330, -260}, extent = {{-6, -6}, {6, 6}}), iconTransformation(origin = {-212.7, 55}, extent = {{-10, -10}, {10, 10}})));
  Modelica.Blocks.Interfaces.RealInput tempIn(unit = "degC") if tempSource == InputSource.Connector "Temperature read by microbit.temperature() from the diagram" annotation(
    Placement(transformation(origin = {330, -300}, extent = {{-6, -6}, {6, 6}}), iconTransformation(origin = {-35, 183.3}, extent = {{-10, -10}, {10, 10}}, rotation = 270)));
  Modelica.Blocks.Interfaces.RealInput lightIn if lightSource == InputSource.Connector "Light level 0-255 read by display.read_light_level() from the diagram" annotation(
    Placement(transformation(origin = {330, -340}, extent = {{-6, -6}, {6, 6}}), iconTransformation(origin = {35, 183.3}, extent = {{-10, -10}, {10, 10}}, rotation = 270)));
  Internal.Rt6150 regulator(VOut = VTgt, eta = eta) "Buck-boost regulator USB -> 3V rail (RT6150)" annotation(
    Placement(transformation(origin = {240, 195}, extent = {{-20, -20}, {20, 20}}, rotation = 270)));
  Modelica.Electrical.Analog.Sources.ConstantVoltage usbSupply(V = VUsb) if usbConnected "USB supply (5 V)" annotation(
    Placement(transformation(origin = {240, 300}, extent = {{-10, -10}, {10, 10}}, rotation = 270)));
  Modelica.Electrical.Analog.Basic.Resistor usbCable(R = RUsb) if usbConnected "Resistance of the USB cable" annotation(
    Placement(transformation(origin = {240, 250}, extent = {{-10, -10}, {10, 10}}, rotation = 270)));
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
  Modelica.Electrical.Analog.Basic.Resistor pullBtnA(R = 10000) "External 10 kOhm pull-up of button A to 3V" annotation(
    Placement(transformation(origin = {-160, -280}, extent = {{-10, -10}, {10, 10}}, rotation = 90)));
  Modelica.Electrical.Analog.Ideal.IdealClosingSwitch switchA(Goff = 1e-9) "Button A: to GND while pressed" annotation(
    Placement(transformation(origin = {-60, -280}, extent = {{-10, -10}, {10, 10}})));
  Modelica.Electrical.Analog.Basic.Resistor pullBtnB(R = 10000) "External 10 kOhm pull-up of button B to 3V" annotation(
    Placement(transformation(origin = {-160, -315}, extent = {{-10, -10}, {10, 10}}, rotation = 90)));
  Modelica.Electrical.Analog.Ideal.IdealClosingSwitch switchB(Goff = 1e-9) "Button B: to GND while pressed" annotation(
    Placement(transformation(origin = {-60, -315}, extent = {{-10, -10}, {10, 10}})));
  Modelica.Electrical.Analog.Basic.Resistor pullI2cScl(R = 4700) "External 4.7 kOhm pull-up of P19 (I2C SCL)" annotation(
    Placement(transformation(origin = {-140, -170}, extent = {{-10, -10}, {10, 10}}, rotation = 90)));
  Modelica.Electrical.Analog.Basic.Resistor pullI2cSda(R = 4700) "External 4.7 kOhm pull-up of P20 (I2C SDA)" annotation(
    Placement(transformation(origin = {-140, -200}, extent = {{-10, -10}, {10, 10}}, rotation = 90)));
  Modelica.Electrical.Analog.Basic.Resistor pullRing0(R = 10e6) "External 10 MOhm pull-up of P0 (touch ring)" annotation(
    Placement(transformation(origin = {-220, 120}, extent = {{-10, -10}, {10, 10}})));
  Modelica.Electrical.Analog.Basic.Resistor pullRing1(R = 10e6) "External 10 MOhm pull-up of P1 (touch ring)" annotation(
    Placement(transformation(origin = {-220, 90}, extent = {{-10, -10}, {10, 10}})));
  Modelica.Electrical.Analog.Basic.Resistor pullRing2(R = 10e6) "External 10 MOhm pull-up of P2 (touch ring)" annotation(
    Placement(transformation(origin = {-220, 60}, extent = {{-10, -10}, {10, 10}})));
  Modelica.Electrical.Analog.Sources.SignalVoltage sensor_accelX "Integrated sensor X axis of the accelerometer, as seen by the ADC" annotation(
    Placement(transformation(origin = {340, -60}, extent = {{-10, -10}, {10, 10}})));
  MicroPythonMCU.Internal.SensorSource src_accelX(source = accelXSource, k = accelX, table = accelXTable) "Source of X axis of the accelerometer: constant, time table or connector wired from the diagram" annotation(
    Placement(visible = false));
  Modelica.Electrical.Analog.Sources.SignalVoltage sensor_accelY "Integrated sensor Y axis of the accelerometer, as seen by the ADC" annotation(
    Placement(transformation(origin = {340, -100}, extent = {{-10, -10}, {10, 10}})));
  MicroPythonMCU.Internal.SensorSource src_accelY(source = accelYSource, k = accelY, table = accelYTable) "Source of Y axis of the accelerometer: constant, time table or connector wired from the diagram" annotation(
    Placement(visible = false));
  Modelica.Electrical.Analog.Sources.SignalVoltage sensor_accelZ "Integrated sensor Z axis of the accelerometer (default: gravity, board lying display up), as seen by the ADC" annotation(
    Placement(transformation(origin = {340, -140}, extent = {{-10, -10}, {10, 10}})));
  MicroPythonMCU.Internal.SensorSource src_accelZ(source = accelZSource, k = accelZ, table = accelZTable) "Source of Z axis of the accelerometer (default: gravity, board lying display up): constant, time table or connector wired from the diagram" annotation(
    Placement(visible = false));
  Modelica.Electrical.Analog.Sources.SignalVoltage sensor_magX "Integrated sensor X axis of the magnetometer/compass, as seen by the ADC" annotation(
    Placement(transformation(origin = {340, -180}, extent = {{-10, -10}, {10, 10}})));
  MicroPythonMCU.Internal.SensorSource src_magX(source = magXSource, k = magX, table = magXTable) "Source of X axis of the magnetometer/compass: constant, time table or connector wired from the diagram" annotation(
    Placement(visible = false));
  Modelica.Electrical.Analog.Sources.SignalVoltage sensor_magY "Integrated sensor Y axis of the magnetometer/compass (default: field pointing along +Y), as seen by the ADC" annotation(
    Placement(transformation(origin = {340, -220}, extent = {{-10, -10}, {10, 10}})));
  MicroPythonMCU.Internal.SensorSource src_magY(source = magYSource, k = magY, table = magYTable) "Source of Y axis of the magnetometer/compass (default: field pointing along +Y): constant, time table or connector wired from the diagram" annotation(
    Placement(visible = false));
  Modelica.Electrical.Analog.Sources.SignalVoltage sensor_magZ "Integrated sensor Z axis of the magnetometer/compass, as seen by the ADC" annotation(
    Placement(transformation(origin = {340, -260}, extent = {{-10, -10}, {10, 10}})));
  MicroPythonMCU.Internal.SensorSource src_magZ(source = magZSource, k = magZ, table = magZTable) "Source of Z axis of the magnetometer/compass: constant, time table or connector wired from the diagram" annotation(
    Placement(visible = false));
  Modelica.Electrical.Analog.Sources.SignalVoltage sensor_temp "Integrated sensor Temperature read by microbit.temperature(), as seen by the ADC" annotation(
    Placement(transformation(origin = {340, -300}, extent = {{-10, -10}, {10, 10}})));
  MicroPythonMCU.Internal.SensorSource src_temp(source = tempSource, k = temp, table = tempTable) "Source of Temperature read by microbit.temperature(): constant, time table or connector wired from the diagram" annotation(
    Placement(visible = false));
  Modelica.Electrical.Analog.Sources.SignalVoltage sensor_light "Integrated sensor Light level 0-255 read by display.read_light_level(), as seen by the ADC" annotation(
    Placement(transformation(origin = {340, -340}, extent = {{-10, -10}, {10, 10}})));
  MicroPythonMCU.Internal.SensorSource src_light(source = lightSource, k = light, table = lightTable) "Source of Light level 0-255 read by display.read_light_level(): constant, time table or connector wired from the diagram" annotation(
    Placement(visible = false));
  MicroPythonMCU.Internal.ButtonSource src_buttonA(source = buttonASource, pressed = buttonAPressed, table = buttonATable) "Source of button A: constant state, time table or connector wired from the diagram" annotation(
    Placement(visible = false));
  MicroPythonMCU.Internal.ButtonSource src_buttonB(source = buttonBSource, pressed = buttonBPressed, table = buttonBTable) "Source of button B: constant state, time table or connector wired from the diagram" annotation(
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
    Line(points = {{50, 200}, {260, 200}, {260, -64}, {-181.5, 40}}, color = {0, 0, 255}));
  connect(led_0_1.n, core.pin[5]) annotation(
    Line(points = {{50, 164}, {260, 164}, {260, -64}, {-181.5, 40}}, color = {0, 0, 255}));
  connect(led_0_2.n, core.pin[5]) annotation(
    Line(points = {{50, 128}, {260, 128}, {260, -64}, {-181.5, 40}}, color = {0, 0, 255}));
  connect(led_0_3.n, core.pin[5]) annotation(
    Line(points = {{50, 92}, {260, 92}, {260, -64}, {-181.5, 40}}, color = {0, 0, 255}));
  connect(led_0_4.n, core.pin[5]) annotation(
    Line(points = {{50, 56}, {260, 56}, {260, -64}, {-181.5, 40}}, color = {0, 0, 255}));
  connect(led_1_0.n, core.pin[8]) annotation(
    Line(points = {{86, 200}, {260, 200}, {260, -90}, {-181.5, 40}}, color = {0, 0, 255}));
  connect(led_1_1.n, core.pin[8]) annotation(
    Line(points = {{86, 164}, {260, 164}, {260, -90}, {-181.5, 40}}, color = {0, 0, 255}));
  connect(led_1_2.n, core.pin[8]) annotation(
    Line(points = {{86, 128}, {260, 128}, {260, -90}, {-181.5, 40}}, color = {0, 0, 255}));
  connect(led_1_3.n, core.pin[8]) annotation(
    Line(points = {{86, 92}, {260, 92}, {260, -90}, {-181.5, 40}}, color = {0, 0, 255}));
  connect(led_1_4.n, core.pin[8]) annotation(
    Line(points = {{86, 56}, {260, 56}, {260, -90}, {-181.5, 40}}, color = {0, 0, 255}));
  connect(led_2_0.n, core.pin[4]) annotation(
    Line(points = {{122, 200}, {260, 200}, {260, -116}, {-181.5, 40}}, color = {0, 0, 255}));
  connect(led_2_1.n, core.pin[4]) annotation(
    Line(points = {{122, 164}, {260, 164}, {260, -116}, {-181.5, 40}}, color = {0, 0, 255}));
  connect(led_2_2.n, core.pin[4]) annotation(
    Line(points = {{122, 128}, {260, 128}, {260, -116}, {-181.5, 40}}, color = {0, 0, 255}));
  connect(led_2_3.n, core.pin[4]) annotation(
    Line(points = {{122, 92}, {260, 92}, {260, -116}, {-181.5, 40}}, color = {0, 0, 255}));
  connect(led_2_4.n, core.pin[4]) annotation(
    Line(points = {{122, 56}, {260, 56}, {260, -116}, {-181.5, 40}}, color = {0, 0, 255}));
  connect(led_3_0.n, core.pin[7]) annotation(
    Line(points = {{158, 200}, {260, 200}, {260, -142}, {-181.5, 40}}, color = {0, 0, 255}));
  connect(led_3_1.n, core.pin[7]) annotation(
    Line(points = {{158, 164}, {260, 164}, {260, -142}, {-181.5, 40}}, color = {0, 0, 255}));
  connect(led_3_2.n, core.pin[7]) annotation(
    Line(points = {{158, 128}, {260, 128}, {260, -142}, {-181.5, 40}}, color = {0, 0, 255}));
  connect(led_3_3.n, core.pin[7]) annotation(
    Line(points = {{158, 92}, {260, 92}, {260, -142}, {-181.5, 40}}, color = {0, 0, 255}));
  connect(led_3_4.n, core.pin[7]) annotation(
    Line(points = {{158, 56}, {260, 56}, {260, -142}, {-181.5, 40}}, color = {0, 0, 255}));
  connect(led_4_0.n, core.pin[11]) annotation(
    Line(points = {{194, 200}, {260, 200}, {260, -168}, {-181.5, 40}}, color = {0, 0, 255}));
  connect(led_4_1.n, core.pin[11]) annotation(
    Line(points = {{194, 164}, {260, 164}, {260, -168}, {-181.5, 40}}, color = {0, 0, 255}));
  connect(led_4_2.n, core.pin[11]) annotation(
    Line(points = {{194, 128}, {260, 128}, {260, -168}, {-181.5, 40}}, color = {0, 0, 255}));
  connect(led_4_3.n, core.pin[11]) annotation(
    Line(points = {{194, 92}, {260, 92}, {260, -168}, {-181.5, 40}}, color = {0, 0, 255}));
  connect(led_4_4.n, core.pin[11]) annotation(
    Line(points = {{194, 56}, {260, 56}, {260, -168}, {-181.5, 40}}, color = {0, 0, 255}));
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
    Line(points = {{240, 310}, {240, 260}}, color = {230, 120, 0}));
  connect(usbCable.n, regulator.vin) annotation(
    Line(points = {{240, 240}, {240, 215}}, color = {230, 120, 0}));
  connect(usbSupply.n, core.gnd) annotation(
    Line(points = {{240, 290}, {210, 290}, {210, -250}, {-110, -250}, {-110, -31.5}}, color = {90, 90, 90}));
  connect(regulator.vout, P_3V) annotation(
    Line(points = {{240, 175}, {240, -190}, {-330, -190}}, color = {220, 0, 0}));
  connect(regulator.gnd, core.gnd) annotation(
    Line(points = {{220, 195}, {200, 195}, {200, -250}, {-110, -250}, {-110, -31.5}}, color = {90, 90, 90}));
  connect(regulator.en, regulator.vin) annotation(
    Line(points = {{220, 207}, {215, 207}, {215, 225}, {240, 225}, {240, 215}}, color = {230, 120, 0}));
  connect(P_3V, core.vdd) annotation(
    Line(points = {{-330, -190}, {-190, -190}, {-190, 130}, {-110, 130}, {-110, 111.5}}, color = {220, 0, 0}));
  connect(P_3V, core.vref) annotation(
    Line(points = {{-330, -190}, {-190, -190}, {-190, 125}, {-149, 125}, {-149, 111.5}}, color = {0, 150, 0}));
  connect(GND, core.gnd) annotation(
    Line(points = {{-330, -230}, {-110, -230}, {-110, -250}, {-110, -31.5}}, color = {90, 90, 90}));
  connect(P_3V, pullBtnA.p) annotation(
    Line(points = {{-330, -190}, {-160, -190}, {-160, -270}}, color = {220, 0, 0}));
  connect(pullBtnA.n, P5) annotation(
    Line(points = {{-160, -290}, {-344, -290}, {-344, 170}, {-330, 170}}, color = {0, 0, 255}));
  connect(switchA.p, P5) annotation(
    Line(points = {{-70, -280}, {-90, -280}, {-90, -296}, {-344, -296}, {-344, 170}, {-330, 170}}, color = {0, 0, 255}));
  connect(switchA.n, core.gnd) annotation(
    Line(points = {{-50, -280}, {-50, -250}, {-110, -250}, {-110, -31.5}}, color = {90, 90, 90}));
  connect(P_3V, pullBtnB.p) annotation(
    Line(points = {{-330, -190}, {-185, -190}, {-185, -305}, {-160, -305}}, color = {220, 0, 0}));
  connect(pullBtnB.n, P11) annotation(
    Line(points = {{-160, -325}, {-352, -325}, {-352, 14}, {-330, 14}}, color = {0, 0, 255}));
  connect(switchB.p, P11) annotation(
    Line(points = {{-70, -315}, {-90, -315}, {-90, -345}, {-352, -345}, {-352, 14}, {-330, 14}}, color = {0, 0, 255}));
  connect(switchB.n, core.gnd) annotation(
    Line(points = {{-50, -315}, {-50, -250}, {-110, -250}, {-110, -31.5}}, color = {90, 90, 90}));
  connect(P_3V, pullI2cScl.p) annotation(
    Line(points = {{-330, -190}, {-140, -190}, {-140, -160}}, color = {220, 0, 0}));
  connect(pullI2cScl.n, P19) annotation(
    Line(points = {{-140, -180}, {-330, -180}, {-330, -142}}, color = {0, 0, 255}));
  connect(P_3V, pullI2cSda.p) annotation(
    Line(points = {{-330, -190}, {-140, -190}, {-140, -190}}, color = {220, 0, 0}));
  connect(pullI2cSda.n, P20) annotation(
    Line(points = {{-140, -210}, {-330, -210}, {-330, -168}}, color = {0, 0, 255}));
  connect(P_3V, pullRing0.p) annotation(
    Line(points = {{-330, -190}, {-230, -190}, {-230, 120}}, color = {220, 0, 0}));
  connect(pullRing0.n, P0) annotation(
    Line(points = {{-210, 120}, {-252, 120}, {-252, 300}, {-330, 300}}, color = {0, 0, 255}));
  connect(P_3V, pullRing1.p) annotation(
    Line(points = {{-330, -190}, {-230, -190}, {-230, 90}}, color = {220, 0, 0}));
  connect(pullRing1.n, P1) annotation(
    Line(points = {{-210, 90}, {-244, 90}, {-244, 274}, {-330, 274}}, color = {0, 0, 255}));
  connect(P_3V, pullRing2.p) annotation(
    Line(points = {{-330, -190}, {-230, -190}, {-230, 60}}, color = {220, 0, 0}));
  connect(pullRing2.n, P2) annotation(
    Line(points = {{-210, 60}, {-236, 60}, {-236, 248}, {-330, 248}}, color = {0, 0, 255}));
  connect(sensor_accelX.p, core.pin[25]) annotation(
    Line(points = {{330, -60}, {250, -60}, {-181.5, 40}}, color = {0, 150, 0}));
  connect(sensor_accelX.n, core.gnd) annotation(
    Line(points = {{350, -60}, {365, -60}, {365, -250}, {-110, -250}, {-110, -31.5}}, color = {90, 90, 90}));
  connect(sensor_accelY.p, core.pin[26]) annotation(
    Line(points = {{330, -100}, {250, -100}, {-181.5, 40}}, color = {0, 150, 0}));
  connect(sensor_accelY.n, core.gnd) annotation(
    Line(points = {{350, -100}, {365, -100}, {365, -250}, {-110, -250}, {-110, -31.5}}, color = {90, 90, 90}));
  connect(sensor_accelZ.p, core.pin[27]) annotation(
    Line(points = {{330, -140}, {250, -140}, {-181.5, 40}}, color = {0, 150, 0}));
  connect(sensor_accelZ.n, core.gnd) annotation(
    Line(points = {{350, -140}, {365, -140}, {365, -250}, {-110, -250}, {-110, -31.5}}, color = {90, 90, 90}));
  connect(sensor_magX.p, core.pin[28]) annotation(
    Line(points = {{330, -180}, {250, -180}, {-181.5, 40}}, color = {0, 150, 0}));
  connect(sensor_magX.n, core.gnd) annotation(
    Line(points = {{350, -180}, {365, -180}, {365, -250}, {-110, -250}, {-110, -31.5}}, color = {90, 90, 90}));
  connect(sensor_magY.p, core.pin[29]) annotation(
    Line(points = {{330, -220}, {250, -220}, {-181.5, 40}}, color = {0, 150, 0}));
  connect(sensor_magY.n, core.gnd) annotation(
    Line(points = {{350, -220}, {365, -220}, {365, -250}, {-110, -250}, {-110, -31.5}}, color = {90, 90, 90}));
  connect(sensor_magZ.p, core.pin[30]) annotation(
    Line(points = {{330, -260}, {250, -260}, {-181.5, 40}}, color = {0, 150, 0}));
  connect(sensor_magZ.n, core.gnd) annotation(
    Line(points = {{350, -260}, {365, -260}, {365, -250}, {-110, -250}, {-110, -31.5}}, color = {90, 90, 90}));
  connect(sensor_temp.p, core.pin[31]) annotation(
    Line(points = {{330, -300}, {250, -300}, {-181.5, 40}}, color = {0, 150, 0}));
  connect(sensor_temp.n, core.gnd) annotation(
    Line(points = {{350, -300}, {365, -300}, {365, -250}, {-110, -250}, {-110, -31.5}}, color = {90, 90, 90}));
  connect(sensor_light.p, core.pin[32]) annotation(
    Line(points = {{330, -340}, {250, -340}, {-181.5, 40}}, color = {0, 150, 0}));
  connect(sensor_light.n, core.gnd) annotation(
    Line(points = {{350, -340}, {365, -340}, {365, -250}, {-110, -250}, {-110, -31.5}}, color = {90, 90, 90}));
  connect(src_buttonA.y, switchA.control);
  if buttonASource == InputSource.Connector then
    connect(buttonA, src_buttonA.u) annotation(
    Line(points = {{-330, -300}, {-70, -300}, {-70, -260}}, color = {150, 0, 200}));
  end if;
  connect(src_buttonB.y, switchB.control);
  if buttonBSource == InputSource.Connector then
    connect(buttonB, src_buttonB.u) annotation(
    Line(points = {{-330, -330}, {-75, -330}, {-75, -295}}, color = {150, 0, 200}));
  end if;
  if useRadio then
    connect(core.AntennaIn, Antenna) annotation(
    Line(points = {{-38.5, 53}, {-38.5, 335}, {330, 335}, {330, 310}}, color = {160, 90, 0}));
  end if;
  if accelXSource == InputSource.Connector then
    connect(accelXIn, src_accelX.u);
  end if;
  sensor_accelX.v = vRail*(0.5 + src_accelX.y/39.24);
  if accelYSource == InputSource.Connector then
    connect(accelYIn, src_accelY.u);
  end if;
  sensor_accelY.v = vRail*(0.5 + src_accelY.y/39.24);
  if accelZSource == InputSource.Connector then
    connect(accelZIn, src_accelZ.u);
  end if;
  sensor_accelZ.v = vRail*(0.5 + src_accelZ.y/39.24);
  if magXSource == InputSource.Connector then
    connect(magXIn, src_magX.u);
  end if;
  sensor_magX.v = vRail*(0.5 + src_magX.y/400);
  if magYSource == InputSource.Connector then
    connect(magYIn, src_magY.u);
  end if;
  sensor_magY.v = vRail*(0.5 + src_magY.y/400);
  if magZSource == InputSource.Connector then
    connect(magZIn, src_magZ.u);
  end if;
  sensor_magZ.v = vRail*(0.5 + src_magZ.y/400);
  if tempSource == InputSource.Connector then
    connect(tempIn, src_temp.u);
  end if;
  sensor_temp.v = vRail*((src_temp.y + 20)/100);
  if lightSource == InputSource.Connector then
    connect(lightIn, src_light.u);
  end if;
  sensor_light.v = vRail*(src_light.y/255);
  annotation(
    Icon(coordinateSystem(preserveAspectRatio = true, extent = {{-230, -210}, {230, 210}}, initialScale = 0.2), graphics = {Rectangle(lineColor = {0, 90, 40}, fillColor = {0, 120, 60}, fillPattern = FillPattern.Solid, extent = {{-204.7, 169.3}, {204.7, -169.3}}, radius = 6), Rectangle(lineColor = {200, 160, 40}, fillColor = {230, 190, 60}, fillPattern = FillPattern.Solid, extent = {{-174.3, -137.8}, {-165.7, -166.2}}), Rectangle(lineColor = {200, 160, 40}, fillColor = {230, 190, 60}, fillPattern = FillPattern.Solid, extent = {{-164.3, -137.8}, {-155.7, -166.2}}), Text(textColor = {255, 255, 255}, extent = {{-165, -120.9}, {-155, -135.8}}, textString = "3", fontSize = 9), Ellipse(lineColor = {200, 160, 40}, fillColor = {230, 190, 60}, fillPattern = FillPattern.Solid, extent = {{-155.7, -137.9}, {-124.3, -169.3}}), Ellipse(lineColor = {20, 20, 20}, fillColor = {25, 25, 25}, fillPattern = FillPattern.Solid, extent = {{-151.8, -141.8}, {-128.2, -165.4}}), Rectangle(lineColor = {25, 25, 25}, fillColor = {25, 25, 25}, fillPattern = FillPattern.Solid, extent = {{-153.4, -118.9}, {-126.6, -137.8}}), Text(textColor = {255, 255, 255}, extent = {{-150.4, -121.9}, {-129.6, -134.8}}, textString = "0", fontSize = 10), Rectangle(lineColor = {200, 160, 40}, fillColor = {230, 190, 60}, fillPattern = FillPattern.Solid, extent = {{-124.3, -137.8}, {-115.7, -166.2}}), Text(textColor = {255, 255, 255}, extent = {{-125, -120.9}, {-115, -135.8}}, textString = "4", fontSize = 9), Rectangle(lineColor = {200, 160, 40}, fillColor = {230, 190, 60}, fillPattern = FillPattern.Solid, extent = {{-114.3, -137.8}, {-105.7, -166.2}}), Text(textColor = {255, 255, 255}, extent = {{-115, -120.9}, {-105, -135.8}}, textString = "5", fontSize = 9), Rectangle(lineColor = {200, 160, 40}, fillColor = {230, 190, 60}, fillPattern = FillPattern.Solid, extent = {{-104.3, -137.8}, {-95.7, -166.2}}), Text(textColor = {255, 255, 255}, extent = {{-105, -120.9}, {-95, -135.8}}, textString = "6", fontSize = 9), Rectangle(lineColor = {200, 160, 40}, fillColor = {230, 190, 60}, fillPattern = FillPattern.Solid, extent = {{-94.3, -137.8}, {-85.7, -166.2}}), Text(textColor = {255, 255, 255}, extent = {{-95, -120.9}, {-85, -135.8}}, textString = "7", fontSize = 9), Ellipse(lineColor = {200, 160, 40}, fillColor = {230, 190, 60}, fillPattern = FillPattern.Solid, extent = {{-85.7, -137.9}, {-54.3, -169.3}}), Ellipse(lineColor = {20, 20, 20}, fillColor = {25, 25, 25}, fillPattern = FillPattern.Solid, extent = {{-81.8, -141.8}, {-58.2, -165.4}}), Rectangle(lineColor = {25, 25, 25}, fillColor = {25, 25, 25}, fillPattern = FillPattern.Solid, extent = {{-83.4, -118.9}, {-56.6, -137.8}}), Text(textColor = {255, 255, 255}, extent = {{-80.4, -121.9}, {-59.6, -134.8}}, textString = "1", fontSize = 10), Rectangle(lineColor = {200, 160, 40}, fillColor = {230, 190, 60}, fillPattern = FillPattern.Solid, extent = {{-54.3, -137.8}, {-45.7, -166.2}}), Text(textColor = {255, 255, 255}, extent = {{-55, -120.9}, {-45, -135.8}}, textString = "8", fontSize = 9), Rectangle(lineColor = {200, 160, 40}, fillColor = {230, 190, 60}, fillPattern = FillPattern.Solid, extent = {{-44.3, -137.8}, {-35.7, -166.2}}), Text(textColor = {255, 255, 255}, extent = {{-45, -120.9}, {-35, -135.8}}, textString = "9", fontSize = 9), Rectangle(lineColor = {200, 160, 40}, fillColor = {230, 190, 60}, fillPattern = FillPattern.Solid, extent = {{-34.3, -137.8}, {-25.7, -166.2}}), Text(textColor = {255, 255, 255}, extent = {{-35, -120.9}, {-25, -135.8}}, textString = "10", fontSize = 9), Rectangle(lineColor = {200, 160, 40}, fillColor = {230, 190, 60}, fillPattern = FillPattern.Solid, extent = {{-24.3, -137.8}, {-15.7, -166.2}}), Text(textColor = {255, 255, 255}, extent = {{-25, -120.9}, {-15, -135.8}}, textString = "11", fontSize = 9), Rectangle(lineColor = {200, 160, 40}, fillColor = {230, 190, 60}, fillPattern = FillPattern.Solid, extent = {{-14.3, -137.8}, {-5.7, -166.2}}), Text(textColor = {255, 255, 255}, extent = {{-15, -120.9}, {-5, -135.8}}, textString = "12", fontSize = 9), Ellipse(lineColor = {200, 160, 40}, fillColor = {230, 190, 60}, fillPattern = FillPattern.Solid, extent = {{-5.7, -137.9}, {25.7, -169.3}}), Ellipse(lineColor = {20, 20, 20}, fillColor = {25, 25, 25}, fillPattern = FillPattern.Solid, extent = {{-1.8, -141.8}, {21.8, -165.4}}), Rectangle(lineColor = {25, 25, 25}, fillColor = {25, 25, 25}, fillPattern = FillPattern.Solid, extent = {{-3.4, -118.9}, {23.4, -137.8}}), Text(textColor = {255, 255, 255}, extent = {{-0.4, -121.9}, {20.4, -134.8}}, textString = "2", fontSize = 10), Rectangle(lineColor = {200, 160, 40}, fillColor = {230, 190, 60}, fillPattern = FillPattern.Solid, extent = {{25.7, -137.8}, {34.3, -166.2}}), Text(textColor = {255, 255, 255}, extent = {{25, -120.9}, {35, -135.8}}, textString = "13", fontSize = 9), Rectangle(lineColor = {200, 160, 40}, fillColor = {230, 190, 60}, fillPattern = FillPattern.Solid, extent = {{35.7, -137.8}, {44.3, -166.2}}), Text(textColor = {255, 255, 255}, extent = {{35, -120.9}, {45, -135.8}}, textString = "14", fontSize = 9), Rectangle(lineColor = {200, 160, 40}, fillColor = {230, 190, 60}, fillPattern = FillPattern.Solid, extent = {{45.7, -137.8}, {54.3, -166.2}}), Text(textColor = {255, 255, 255}, extent = {{45, -120.9}, {55, -135.8}}, textString = "15", fontSize = 9), Rectangle(lineColor = {200, 160, 40}, fillColor = {230, 190, 60}, fillPattern = FillPattern.Solid, extent = {{55.7, -137.8}, {64.3, -166.2}}), Text(textColor = {255, 255, 255}, extent = {{55, -120.9}, {65, -135.8}}, textString = "16", fontSize = 9), Rectangle(lineColor = {200, 160, 40}, fillColor = {230, 190, 60}, fillPattern = FillPattern.Solid, extent = {{65.7, -137.8}, {74.3, -166.2}}), Rectangle(lineColor = {200, 160, 40}, fillColor = {230, 190, 60}, fillPattern = FillPattern.Solid, extent = {{75.7, -137.8}, {84.3, -166.2}}), Ellipse(lineColor = {200, 160, 40}, fillColor = {230, 190, 60}, fillPattern = FillPattern.Solid, extent = {{84.3, -137.9}, {115.7, -169.3}}), Ellipse(lineColor = {20, 20, 20}, fillColor = {25, 25, 25}, fillPattern = FillPattern.Solid, extent = {{88.2, -141.8}, {111.8, -165.4}}), Rectangle(lineColor = {25, 25, 25}, fillColor = {25, 25, 25}, fillPattern = FillPattern.Solid, extent = {{84.25, -118.9}, {115.75, -137.8}}), Text(textColor = {255, 255, 255}, extent = {{87.25, -121.9}, {112.75, -134.8}}, textString = "3V", fontSize = 10), Rectangle(lineColor = {200, 160, 40}, fillColor = {230, 190, 60}, fillPattern = FillPattern.Solid, extent = {{115.7, -137.8}, {124.3, -166.2}}), Text(textColor = {255, 255, 255}, extent = {{115, -120.9}, {125, -135.8}}, textString = "19", fontSize = 9), Rectangle(lineColor = {200, 160, 40}, fillColor = {230, 190, 60}, fillPattern = FillPattern.Solid, extent = {{125.7, -137.8}, {134.3, -166.2}}), Text(textColor = {255, 255, 255}, extent = {{125, -120.9}, {135, -135.8}}, textString = "20", fontSize = 9), Ellipse(lineColor = {200, 160, 40}, fillColor = {230, 190, 60}, fillPattern = FillPattern.Solid, extent = {{134.3, -137.9}, {165.7, -169.3}}), Ellipse(lineColor = {20, 20, 20}, fillColor = {25, 25, 25}, fillPattern = FillPattern.Solid, extent = {{138.2, -141.8}, {161.8, -165.4}}), Rectangle(lineColor = {25, 25, 25}, fillColor = {25, 25, 25}, fillPattern = FillPattern.Solid, extent = {{134.25, -118.9}, {165.75, -137.8}}), Text(textColor = {255, 255, 255}, extent = {{137.25, -121.9}, {162.75, -134.8}}, textString = "GND", fontSize = 10), Rectangle(lineColor = {200, 160, 40}, fillColor = {230, 190, 60}, fillPattern = FillPattern.Solid, extent = {{165.7, -137.8}, {174.3, -166.2}}), Rectangle(lineColor = {110, 110, 110}, fillColor = {200, 200, 200}, fillPattern = FillPattern.Solid, extent = {{-147.65, 166.9}, {-88.55, 123.6}}), Rectangle(lineColor = {60, 60, 60}, fillColor = {70, 70, 70}, fillPattern = FillPattern.Solid, extent = {{-133.8, 166.9}, {-102.4, 157.5}}), Polygon(visible = usbConnected, lineColor = {200, 140, 0}, fillColor = {255, 210, 0}, fillPattern = FillPattern.Solid, points = {{-114.2, 155.1}, {-123.3, 140.8}, {-118.1, 140.8}, {-122, 126.5}, {-111.6, 144.7}, {-116.8, 144.7}, {-112.9, 155.1}}), Rectangle(lineColor = {25, 25, 25}, fillColor = {25, 25, 25}, fillPattern = FillPattern.Solid, extent = {{-71.6, 92.1}, {-51.2, 71.7}}, radius = 2), Ellipse(lineColor = {60, 60, 60}, fillColor = DynamicSelect({80, 10, 10}, {integer(80 + min(1, max(0, led_0_0.mean.y)/led_0_0.IMax)*175), integer(10 + min(1, max(0, led_0_0.mean.y)/led_0_0.IMax)*50), integer(10 + min(1, max(0, led_0_0.mean.y)/led_0_0.IMax)*40)}), fillPattern = FillPattern.Solid, extent = {{-68.5, 89}, {-54.3, 74.8}}), Rectangle(lineColor = {25, 25, 25}, fillColor = {25, 25, 25}, fillPattern = FillPattern.Solid, extent = {{-71.6, 61.4}, {-51.2, 41}}, radius = 2), Ellipse(lineColor = {60, 60, 60}, fillColor = DynamicSelect({80, 10, 10}, {integer(80 + min(1, max(0, led_0_1.mean.y)/led_0_1.IMax)*175), integer(10 + min(1, max(0, led_0_1.mean.y)/led_0_1.IMax)*50), integer(10 + min(1, max(0, led_0_1.mean.y)/led_0_1.IMax)*40)}), fillPattern = FillPattern.Solid, extent = {{-68.5, 58.3}, {-54.3, 44.1}}), Rectangle(lineColor = {25, 25, 25}, fillColor = {25, 25, 25}, fillPattern = FillPattern.Solid, extent = {{-71.6, 30.7}, {-51.2, 10.3}}, radius = 2), Ellipse(lineColor = {60, 60, 60}, fillColor = DynamicSelect({80, 10, 10}, {integer(80 + min(1, max(0, led_0_2.mean.y)/led_0_2.IMax)*175), integer(10 + min(1, max(0, led_0_2.mean.y)/led_0_2.IMax)*50), integer(10 + min(1, max(0, led_0_2.mean.y)/led_0_2.IMax)*40)}), fillPattern = FillPattern.Solid, extent = {{-68.5, 27.6}, {-54.3, 13.4}}), Rectangle(lineColor = {25, 25, 25}, fillColor = {25, 25, 25}, fillPattern = FillPattern.Solid, extent = {{-71.6, 1.06581e-14}, {-51.2, -20.4}}, radius = 2), Ellipse(lineColor = {60, 60, 60}, fillColor = DynamicSelect({80, 10, 10}, {integer(80 + min(1, max(0, led_0_3.mean.y)/led_0_3.IMax)*175), integer(10 + min(1, max(0, led_0_3.mean.y)/led_0_3.IMax)*50), integer(10 + min(1, max(0, led_0_3.mean.y)/led_0_3.IMax)*40)}), fillPattern = FillPattern.Solid, extent = {{-68.5, -3.1}, {-54.3, -17.3}}), Rectangle(lineColor = {25, 25, 25}, fillColor = {25, 25, 25}, fillPattern = FillPattern.Solid, extent = {{-71.6, -30.7}, {-51.2, -51.1}}, radius = 2), Ellipse(lineColor = {60, 60, 60}, fillColor = DynamicSelect({80, 10, 10}, {integer(80 + min(1, max(0, led_0_4.mean.y)/led_0_4.IMax)*175), integer(10 + min(1, max(0, led_0_4.mean.y)/led_0_4.IMax)*50), integer(10 + min(1, max(0, led_0_4.mean.y)/led_0_4.IMax)*40)}), fillPattern = FillPattern.Solid, extent = {{-68.5, -33.8}, {-54.3, -48}}), Rectangle(lineColor = {25, 25, 25}, fillColor = {25, 25, 25}, fillPattern = FillPattern.Solid, extent = {{-40.9, 92.1}, {-20.5, 71.7}}, radius = 2), Ellipse(lineColor = {60, 60, 60}, fillColor = DynamicSelect({80, 10, 10}, {integer(80 + min(1, max(0, led_1_0.mean.y)/led_1_0.IMax)*175), integer(10 + min(1, max(0, led_1_0.mean.y)/led_1_0.IMax)*50), integer(10 + min(1, max(0, led_1_0.mean.y)/led_1_0.IMax)*40)}), fillPattern = FillPattern.Solid, extent = {{-37.8, 89}, {-23.6, 74.8}}), Rectangle(lineColor = {25, 25, 25}, fillColor = {25, 25, 25}, fillPattern = FillPattern.Solid, extent = {{-40.9, 61.4}, {-20.5, 41}}, radius = 2), Ellipse(lineColor = {60, 60, 60}, fillColor = DynamicSelect({80, 10, 10}, {integer(80 + min(1, max(0, led_1_1.mean.y)/led_1_1.IMax)*175), integer(10 + min(1, max(0, led_1_1.mean.y)/led_1_1.IMax)*50), integer(10 + min(1, max(0, led_1_1.mean.y)/led_1_1.IMax)*40)}), fillPattern = FillPattern.Solid, extent = {{-37.8, 58.3}, {-23.6, 44.1}}), Rectangle(lineColor = {25, 25, 25}, fillColor = {25, 25, 25}, fillPattern = FillPattern.Solid, extent = {{-40.9, 30.7}, {-20.5, 10.3}}, radius = 2), Ellipse(lineColor = {60, 60, 60}, fillColor = DynamicSelect({80, 10, 10}, {integer(80 + min(1, max(0, led_1_2.mean.y)/led_1_2.IMax)*175), integer(10 + min(1, max(0, led_1_2.mean.y)/led_1_2.IMax)*50), integer(10 + min(1, max(0, led_1_2.mean.y)/led_1_2.IMax)*40)}), fillPattern = FillPattern.Solid, extent = {{-37.8, 27.6}, {-23.6, 13.4}}), Rectangle(lineColor = {25, 25, 25}, fillColor = {25, 25, 25}, fillPattern = FillPattern.Solid, extent = {{-40.9, 1.06581e-14}, {-20.5, -20.4}}, radius = 2), Ellipse(lineColor = {60, 60, 60}, fillColor = DynamicSelect({80, 10, 10}, {integer(80 + min(1, max(0, led_1_3.mean.y)/led_1_3.IMax)*175), integer(10 + min(1, max(0, led_1_3.mean.y)/led_1_3.IMax)*50), integer(10 + min(1, max(0, led_1_3.mean.y)/led_1_3.IMax)*40)}), fillPattern = FillPattern.Solid, extent = {{-37.8, -3.1}, {-23.6, -17.3}}), Rectangle(lineColor = {25, 25, 25}, fillColor = {25, 25, 25}, fillPattern = FillPattern.Solid, extent = {{-40.9, -30.7}, {-20.5, -51.1}}, radius = 2), Ellipse(lineColor = {60, 60, 60}, fillColor = DynamicSelect({80, 10, 10}, {integer(80 + min(1, max(0, led_1_4.mean.y)/led_1_4.IMax)*175), integer(10 + min(1, max(0, led_1_4.mean.y)/led_1_4.IMax)*50), integer(10 + min(1, max(0, led_1_4.mean.y)/led_1_4.IMax)*40)}), fillPattern = FillPattern.Solid, extent = {{-37.8, -33.8}, {-23.6, -48}}), Rectangle(lineColor = {25, 25, 25}, fillColor = {25, 25, 25}, fillPattern = FillPattern.Solid, extent = {{-10.2, 92.1}, {10.2, 71.7}}, radius = 2), Ellipse(lineColor = {60, 60, 60}, fillColor = DynamicSelect({80, 10, 10}, {integer(80 + min(1, max(0, led_2_0.mean.y)/led_2_0.IMax)*175), integer(10 + min(1, max(0, led_2_0.mean.y)/led_2_0.IMax)*50), integer(10 + min(1, max(0, led_2_0.mean.y)/led_2_0.IMax)*40)}), fillPattern = FillPattern.Solid, extent = {{-7.1, 89}, {7.1, 74.8}}), Rectangle(lineColor = {25, 25, 25}, fillColor = {25, 25, 25}, fillPattern = FillPattern.Solid, extent = {{-10.2, 61.4}, {10.2, 41}}, radius = 2), Ellipse(lineColor = {60, 60, 60}, fillColor = DynamicSelect({80, 10, 10}, {integer(80 + min(1, max(0, led_2_1.mean.y)/led_2_1.IMax)*175), integer(10 + min(1, max(0, led_2_1.mean.y)/led_2_1.IMax)*50), integer(10 + min(1, max(0, led_2_1.mean.y)/led_2_1.IMax)*40)}), fillPattern = FillPattern.Solid, extent = {{-7.1, 58.3}, {7.1, 44.1}}), Rectangle(lineColor = {25, 25, 25}, fillColor = {25, 25, 25}, fillPattern = FillPattern.Solid, extent = {{-10.2, 30.7}, {10.2, 10.3}}, radius = 2), Ellipse(lineColor = {60, 60, 60}, fillColor = DynamicSelect({80, 10, 10}, {integer(80 + min(1, max(0, led_2_2.mean.y)/led_2_2.IMax)*175), integer(10 + min(1, max(0, led_2_2.mean.y)/led_2_2.IMax)*50), integer(10 + min(1, max(0, led_2_2.mean.y)/led_2_2.IMax)*40)}), fillPattern = FillPattern.Solid, extent = {{-7.1, 27.6}, {7.1, 13.4}}), Rectangle(lineColor = {25, 25, 25}, fillColor = {25, 25, 25}, fillPattern = FillPattern.Solid, extent = {{-10.2, 1.06581e-14}, {10.2, -20.4}}, radius = 2), Ellipse(lineColor = {60, 60, 60}, fillColor = DynamicSelect({80, 10, 10}, {integer(80 + min(1, max(0, led_2_3.mean.y)/led_2_3.IMax)*175), integer(10 + min(1, max(0, led_2_3.mean.y)/led_2_3.IMax)*50), integer(10 + min(1, max(0, led_2_3.mean.y)/led_2_3.IMax)*40)}), fillPattern = FillPattern.Solid, extent = {{-7.1, -3.1}, {7.1, -17.3}}), Rectangle(lineColor = {25, 25, 25}, fillColor = {25, 25, 25}, fillPattern = FillPattern.Solid, extent = {{-10.2, -30.7}, {10.2, -51.1}}, radius = 2), Ellipse(lineColor = {60, 60, 60}, fillColor = DynamicSelect({80, 10, 10}, {integer(80 + min(1, max(0, led_2_4.mean.y)/led_2_4.IMax)*175), integer(10 + min(1, max(0, led_2_4.mean.y)/led_2_4.IMax)*50), integer(10 + min(1, max(0, led_2_4.mean.y)/led_2_4.IMax)*40)}), fillPattern = FillPattern.Solid, extent = {{-7.1, -33.8}, {7.1, -48}}), Rectangle(lineColor = {25, 25, 25}, fillColor = {25, 25, 25}, fillPattern = FillPattern.Solid, extent = {{20.5, 92.1}, {40.9, 71.7}}, radius = 2), Ellipse(lineColor = {60, 60, 60}, fillColor = DynamicSelect({80, 10, 10}, {integer(80 + min(1, max(0, led_3_0.mean.y)/led_3_0.IMax)*175), integer(10 + min(1, max(0, led_3_0.mean.y)/led_3_0.IMax)*50), integer(10 + min(1, max(0, led_3_0.mean.y)/led_3_0.IMax)*40)}), fillPattern = FillPattern.Solid, extent = {{23.6, 89}, {37.8, 74.8}}), Rectangle(lineColor = {25, 25, 25}, fillColor = {25, 25, 25}, fillPattern = FillPattern.Solid, extent = {{20.5, 61.4}, {40.9, 41}}, radius = 2), Ellipse(lineColor = {60, 60, 60}, fillColor = DynamicSelect({80, 10, 10}, {integer(80 + min(1, max(0, led_3_1.mean.y)/led_3_1.IMax)*175), integer(10 + min(1, max(0, led_3_1.mean.y)/led_3_1.IMax)*50), integer(10 + min(1, max(0, led_3_1.mean.y)/led_3_1.IMax)*40)}), fillPattern = FillPattern.Solid, extent = {{23.6, 58.3}, {37.8, 44.1}}), Rectangle(lineColor = {25, 25, 25}, fillColor = {25, 25, 25}, fillPattern = FillPattern.Solid, extent = {{20.5, 30.7}, {40.9, 10.3}}, radius = 2), Ellipse(lineColor = {60, 60, 60}, fillColor = DynamicSelect({80, 10, 10}, {integer(80 + min(1, max(0, led_3_2.mean.y)/led_3_2.IMax)*175), integer(10 + min(1, max(0, led_3_2.mean.y)/led_3_2.IMax)*50), integer(10 + min(1, max(0, led_3_2.mean.y)/led_3_2.IMax)*40)}), fillPattern = FillPattern.Solid, extent = {{23.6, 27.6}, {37.8, 13.4}}), Rectangle(lineColor = {25, 25, 25}, fillColor = {25, 25, 25}, fillPattern = FillPattern.Solid, extent = {{20.5, 1.06581e-14}, {40.9, -20.4}}, radius = 2), Ellipse(lineColor = {60, 60, 60}, fillColor = DynamicSelect({80, 10, 10}, {integer(80 + min(1, max(0, led_3_3.mean.y)/led_3_3.IMax)*175), integer(10 + min(1, max(0, led_3_3.mean.y)/led_3_3.IMax)*50), integer(10 + min(1, max(0, led_3_3.mean.y)/led_3_3.IMax)*40)}), fillPattern = FillPattern.Solid, extent = {{23.6, -3.1}, {37.8, -17.3}}), Rectangle(lineColor = {25, 25, 25}, fillColor = {25, 25, 25}, fillPattern = FillPattern.Solid, extent = {{20.5, -30.7}, {40.9, -51.1}}, radius = 2), Ellipse(lineColor = {60, 60, 60}, fillColor = DynamicSelect({80, 10, 10}, {integer(80 + min(1, max(0, led_3_4.mean.y)/led_3_4.IMax)*175), integer(10 + min(1, max(0, led_3_4.mean.y)/led_3_4.IMax)*50), integer(10 + min(1, max(0, led_3_4.mean.y)/led_3_4.IMax)*40)}), fillPattern = FillPattern.Solid, extent = {{23.6, -33.8}, {37.8, -48}}), Rectangle(lineColor = {25, 25, 25}, fillColor = {25, 25, 25}, fillPattern = FillPattern.Solid, extent = {{51.2, 92.1}, {71.6, 71.7}}, radius = 2), Ellipse(lineColor = {60, 60, 60}, fillColor = DynamicSelect({80, 10, 10}, {integer(80 + min(1, max(0, led_4_0.mean.y)/led_4_0.IMax)*175), integer(10 + min(1, max(0, led_4_0.mean.y)/led_4_0.IMax)*50), integer(10 + min(1, max(0, led_4_0.mean.y)/led_4_0.IMax)*40)}), fillPattern = FillPattern.Solid, extent = {{54.3, 89}, {68.5, 74.8}}), Rectangle(lineColor = {25, 25, 25}, fillColor = {25, 25, 25}, fillPattern = FillPattern.Solid, extent = {{51.2, 61.4}, {71.6, 41}}, radius = 2), Ellipse(lineColor = {60, 60, 60}, fillColor = DynamicSelect({80, 10, 10}, {integer(80 + min(1, max(0, led_4_1.mean.y)/led_4_1.IMax)*175), integer(10 + min(1, max(0, led_4_1.mean.y)/led_4_1.IMax)*50), integer(10 + min(1, max(0, led_4_1.mean.y)/led_4_1.IMax)*40)}), fillPattern = FillPattern.Solid, extent = {{54.3, 58.3}, {68.5, 44.1}}), Rectangle(lineColor = {25, 25, 25}, fillColor = {25, 25, 25}, fillPattern = FillPattern.Solid, extent = {{51.2, 30.7}, {71.6, 10.3}}, radius = 2), Ellipse(lineColor = {60, 60, 60}, fillColor = DynamicSelect({80, 10, 10}, {integer(80 + min(1, max(0, led_4_2.mean.y)/led_4_2.IMax)*175), integer(10 + min(1, max(0, led_4_2.mean.y)/led_4_2.IMax)*50), integer(10 + min(1, max(0, led_4_2.mean.y)/led_4_2.IMax)*40)}), fillPattern = FillPattern.Solid, extent = {{54.3, 27.6}, {68.5, 13.4}}), Rectangle(lineColor = {25, 25, 25}, fillColor = {25, 25, 25}, fillPattern = FillPattern.Solid, extent = {{51.2, 1.06581e-14}, {71.6, -20.4}}, radius = 2), Ellipse(lineColor = {60, 60, 60}, fillColor = DynamicSelect({80, 10, 10}, {integer(80 + min(1, max(0, led_4_3.mean.y)/led_4_3.IMax)*175), integer(10 + min(1, max(0, led_4_3.mean.y)/led_4_3.IMax)*50), integer(10 + min(1, max(0, led_4_3.mean.y)/led_4_3.IMax)*40)}), fillPattern = FillPattern.Solid, extent = {{54.3, -3.1}, {68.5, -17.3}}), Rectangle(lineColor = {25, 25, 25}, fillColor = {25, 25, 25}, fillPattern = FillPattern.Solid, extent = {{51.2, -30.7}, {71.6, -51.1}}, radius = 2), Ellipse(lineColor = {60, 60, 60}, fillColor = DynamicSelect({80, 10, 10}, {integer(80 + min(1, max(0, led_4_4.mean.y)/led_4_4.IMax)*175), integer(10 + min(1, max(0, led_4_4.mean.y)/led_4_4.IMax)*50), integer(10 + min(1, max(0, led_4_4.mean.y)/led_4_4.IMax)*40)}), fillPattern = FillPattern.Solid, extent = {{54.3, -33.8}, {68.5, -48}}), Ellipse(lineColor = {255, 255, 255}, fillColor = {255, 255, 255}, fillPattern = FillPattern.Solid, extent = {{-216.5, 39.4}, {-153.5, -23.6}}), Ellipse(lineColor = {30, 30, 30}, fillColor = {180, 180, 180}, fillPattern = FillPattern.Solid, extent = {{-212.6, 35.5}, {-157.4, -19.7}}), Text(textColor = {0, 0, 0}, extent = {{-195, 17.9}, {-175, -2.1}}, textString = "A", fontSize = 18), Ellipse(lineColor = {255, 255, 255}, fillColor = {255, 255, 255}, fillPattern = FillPattern.Solid, extent = {{153.5, 39.4}, {216.5, -23.6}}), Ellipse(lineColor = {30, 30, 30}, fillColor = {180, 180, 180}, fillPattern = FillPattern.Solid, extent = {{157.4, 35.5}, {212.6, -19.7}}), Text(textColor = {0, 0, 0}, extent = {{175, 17.9}, {195, -2.1}}, textString = "B", fontSize = 18), Rectangle(lineColor = {20, 20, 20}, fillColor = {40, 40, 40}, fillPattern = FillPattern.Solid, extent = {{-27.55, -56.75}, {27.55, -111.85}}), Text(textColor = {220, 220, 220}, extent = {{-23.55, -60.75}, {23.55, -81.3}}, textString = "nRF", fontSize = 11), Text(textColor = {220, 220, 220}, extent = {{-23.55, -87.3}, {23.55, -107.85}}, textString = "52833", fontSize = 9), Ellipse(lineColor = {60, 60, 60}, fillColor = {200, 200, 200}, fillPattern = FillPattern.Solid, extent = {{140.2, 159}, {159, 140.2}}), Text(textColor = {230, 190, 60}, extent = {{-95, 141.3}, {95, 115.3}}, textString = "micro:bit", fontSize = 24, textStyle = {TextStyle.Bold}), Text(textColor = {28, 108, 200}, extent = {{-30, 111.3}, {30, 97.3}}, textString = "v2"), Text(textColor = {0, 0, 255}, extent = {{-150, -173.3}, {150, -191.3}}, textString = "%name"), Text(textColor = {70, 70, 70}, extent = {{195.7, 146}, {229.7, 136.5}}, textString = "accelX", fontSize = 8), Text(textColor = {70, 70, 70}, extent = {{195.7, 111}, {229.7, 101.5}}, textString = "accelY", fontSize = 8), Text(textColor = {70, 70, 70}, extent = {{195.7, 76}, {229.7, 66.5}}, textString = "accelZ", fontSize = 8), Text(textColor = {70, 70, 70}, extent = {{-229.7, 146}, {-195.7, 136.5}}, textString = "magX", fontSize = 8), Text(textColor = {70, 70, 70}, extent = {{-229.7, 111}, {-195.7, 101.5}}, textString = "magY", fontSize = 8), Text(textColor = {70, 70, 70}, extent = {{-229.7, 76}, {-195.7, 66.5}}, textString = "magZ", fontSize = 8), Text(textColor = {70, 70, 70}, extent = {{-52, 204.3}, {-18, 194.8}}, textString = "temp", fontSize = 8), Text(textColor = {70, 70, 70}, extent = {{18, 204.3}, {52, 194.8}}, textString = "light", fontSize = 8), Text(visible = useRadio, textColor = {70, 70, 70}, extent = {{123, 204.3}, {157, 194.8}}, textString = "ant", fontSize = 8)}),
    Diagram(coordinateSystem(preserveAspectRatio = true, extent = {{-360, -380}, {380, 340}}), graphics = {Rectangle(lineColor = {200, 200, 200}, fillColor = {235, 242, 255}, fillPattern = FillPattern.Solid, extent = {{-334, 320}, {-205, -340}}, radius = 4), Rectangle(lineColor = {200, 200, 200}, fillColor = {242, 242, 242}, fillPattern = FillPattern.Solid, extent = {{-60, 215}, {200, -20}}, radius = 4), Rectangle(lineColor = {200, 200, 200}, fillColor = {255, 243, 228}, fillPattern = FillPattern.Solid, extent = {{205, 325}, {345, 160}}, radius = 4), Rectangle(lineColor = {200, 200, 200}, fillColor = {255, 242, 252}, fillPattern = FillPattern.Solid, extent = {{270, 20}, {350, -370}}, radius = 4), Rectangle(lineColor = {200, 200, 200}, fillColor = {255, 242, 252}, fillPattern = FillPattern.Solid, extent = {{-200, -148}, {60, -236}}, radius = 4), Rectangle(lineColor = {200, 200, 200}, fillColor = {238, 238, 238}, fillPattern = FillPattern.Solid, extent = {{-200, -244}, {370, -264}}, radius = 4), Rectangle(lineColor = {200, 200, 200}, fillColor = {255, 242, 252}, fillPattern = FillPattern.Solid, extent = {{-200, -270}, {60, -335}}, radius = 4), Text(textColor = {90, 90, 90}, extent = {{-330, 318}, {-209, 310}}, textString = "Edge connector (P0-P20, 3V, GND), touch-ring pulls", horizontalAlignment = TextAlignment.Left), Text(textColor = {90, 90, 90}, extent = {{-56, 213}, {196, 205}}, textString = "LED matrix (5x5, multiplexed)", horizontalAlignment = TextAlignment.Left), Text(textColor = {90, 90, 90}, extent = {{209, 323}, {341, 315}}, textString = "Power supply: USB, regulator, 3V rail", horizontalAlignment = TextAlignment.Left), Text(textColor = {90, 90, 90}, extent = {{274, 18}, {346, 10}}, textString = "Integrated sensors", horizontalAlignment = TextAlignment.Left), Text(textColor = {90, 90, 90}, extent = {{-196, -150}, {56, -158}}, textString = "I2C pull resistors", horizontalAlignment = TextAlignment.Left), Text(textColor = {90, 90, 90}, extent = {{-196, -246}, {366, -254}}, textString = "Ground", horizontalAlignment = TextAlignment.Left), Text(textColor = {90, 90, 90}, extent = {{-196, -272}, {56, -280}}, textString = "Buttons (A, B)", horizontalAlignment = TextAlignment.Left)}),
    Documentation(info = "Light level 0-255 read by display.read_light_level()"));
end MicroBit_v2;
