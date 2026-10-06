within MicroPythonMCU.Peripherals.Analyzers;

model LogicAnalyzer "Logic analyser probe with 8 channels: records the lines it is clipped to (VCD file for PulseView) and decodes them into a text file (UART, I2C, synchronous serial: hex + ASCII, ASCII timing diagram)"
  parameter String fileName = "" "Base name of the files written in the simulation folder (<base>.vcd, <base>.txt); empty = name of the component (full paths shown in the log)" annotation(
    Dialog(group = "Files"));
  parameter Boolean writeText = true "Write the text file: decoded bytes in hex + ASCII and ASCII timing diagram (options in the \"Text file\" tab)" annotation(
    Dialog(group = "Files"),
    choices(checkBox = true));
  parameter Boolean openText = true "Open the text file in Notepad at the end of the simulation" annotation(
    Dialog(group = "Files", enable = writeText),
    choices(checkBox = true));
  parameter Boolean writeVcd = true "Write the VCD file (Value Change Dump), to be opened in PulseView or GTKWave" annotation(
    Dialog(group = "Files"),
    choices(checkBox = true));
  parameter Boolean writePulseViewSession = true "Write a PulseView session (<base>.pvs) next to the VCD file: PulseView, which loads it by itself with the VCD file, opens with its UART, I2C and SPI decoders already set up from the channels" annotation(
    Dialog(group = "Files", enable = writeVcd),
    choices(checkBox = true));
  parameter Boolean openPulseView = false "Open the VCD file in PulseView at the end of the simulation (a warning if PulseView is not found)" annotation(
    Dialog(group = "Files", enable = writeVcd),
    choices(checkBox = true));
  parameter String pulseViewPath = "" "Path of the PulseView executable (free software of the sigrok project): absolute path, path relative to the simulation folder, or modelica:// URI; empty = automatic search (environment variable MICROPYTHONMCU_PULSEVIEW, copy fetched by get_pulseview.cmd next to the library, then the sigrok installer folder)" annotation(
    Dialog(group = "Files", enable = writeVcd and openPulseView, loadSelector(filter = "Programs (*.exe)", caption = "Select pulseview.exe")));
  parameter Interfaces.ChannelKind ch0Kind = Interfaces.ChannelKind.Logic "Kind of channel CH0: Off, Logic (also for a clock line), Uart, I2cSda (SCL on clockChannel), SyncData (clock on clockChannel)" annotation(
    Dialog(tab = "CH0", group = "Channel"));
  parameter String ch0Name = "" "Name of CH0 in the files (no comma); empty = CH0" annotation(
    Dialog(tab = "CH0", group = "Channel", enable = ch0Kind <> Interfaces.ChannelKind.Off));
  parameter Real ch0Baudrate(min = 1) = 1200 "Speed of the serial link (baud)" annotation(
    Dialog(tab = "CH0", group = "UART", enable = ch0Kind == Interfaces.ChannelKind.Uart));
  parameter Integer ch0DataBits(min = 5, max = 8) = 8 "Data bits, from 5 to 8" annotation(
    Dialog(tab = "CH0", group = "UART", enable = ch0Kind == Interfaces.ChannelKind.Uart));
  parameter Interfaces.UartParity ch0Parity = Interfaces.UartParity.None "Parity: None, Even or Odd" annotation(
    Dialog(tab = "CH0", group = "UART", enable = ch0Kind == Interfaces.ChannelKind.Uart));
  parameter Integer ch0StopBits(min = 1, max = 2) = 1 "Stop bits, 1 or 2" annotation(
    Dialog(tab = "CH0", group = "UART", enable = ch0Kind == Interfaces.ChannelKind.Uart));
  parameter Interfaces.BitOrder ch0UartBitOrder = Interfaces.BitOrder.LsbFirst "Bit order (a UART sends the least significant bit first)" annotation(
    Dialog(tab = "CH0", group = "UART", enable = ch0Kind == Interfaces.ChannelKind.Uart));
  parameter Integer ch0ClockChannel(min = 0, max = 7) = 1 "Number of the clock channel (SCL for I2cSda, clock for SyncData), itself of kind Logic" annotation(
    Dialog(tab = "CH0", group = "Clock (I2cSda, SyncData)", enable = ch0Kind == Interfaces.ChannelKind.I2cSda or ch0Kind == Interfaces.ChannelKind.SyncData));
  parameter Interfaces.ClockEdge ch0ClockEdge = Interfaces.ClockEdge.Rising "Edge of the clock on which the data is read (HX711: Falling)" annotation(
    Dialog(tab = "CH0", group = "Synchronous serial (SyncData)", enable = ch0Kind == Interfaces.ChannelKind.SyncData));
  parameter Integer ch0WordBits(min = 1, max = 32) = 8 "Bits per word (HX711: 24); the clock pulses left over are counted apart" annotation(
    Dialog(tab = "CH0", group = "Synchronous serial (SyncData)", enable = ch0Kind == Interfaces.ChannelKind.SyncData));
  parameter Interfaces.BitOrder ch0SyncBitOrder = Interfaces.BitOrder.MsbFirst "Bit order (HX711 and most SPI devices: most significant bit first)" annotation(
    Dialog(tab = "CH0", group = "Synchronous serial (SyncData)", enable = ch0Kind == Interfaces.ChannelKind.SyncData));
  parameter Boolean ch0Signed = false "Words in two's complement (HX711: true)" annotation(
    Dialog(tab = "CH0", group = "Synchronous serial (SyncData)", enable = ch0Kind == Interfaces.ChannelKind.SyncData),
    choices(checkBox = true));
  parameter Interfaces.ChannelKind ch1Kind = Interfaces.ChannelKind.Logic "Kind of channel CH1: Off, Logic (also for a clock line), Uart, I2cSda (SCL on clockChannel), SyncData (clock on clockChannel)" annotation(
    Dialog(tab = "CH1", group = "Channel"));
  parameter String ch1Name = "" "Name of CH1 in the files (no comma); empty = CH1" annotation(
    Dialog(tab = "CH1", group = "Channel", enable = ch1Kind <> Interfaces.ChannelKind.Off));
  parameter Real ch1Baudrate(min = 1) = 1200 "Speed of the serial link (baud)" annotation(
    Dialog(tab = "CH1", group = "UART", enable = ch1Kind == Interfaces.ChannelKind.Uart));
  parameter Integer ch1DataBits(min = 5, max = 8) = 8 "Data bits, from 5 to 8" annotation(
    Dialog(tab = "CH1", group = "UART", enable = ch1Kind == Interfaces.ChannelKind.Uart));
  parameter Interfaces.UartParity ch1Parity = Interfaces.UartParity.None "Parity: None, Even or Odd" annotation(
    Dialog(tab = "CH1", group = "UART", enable = ch1Kind == Interfaces.ChannelKind.Uart));
  parameter Integer ch1StopBits(min = 1, max = 2) = 1 "Stop bits, 1 or 2" annotation(
    Dialog(tab = "CH1", group = "UART", enable = ch1Kind == Interfaces.ChannelKind.Uart));
  parameter Interfaces.BitOrder ch1UartBitOrder = Interfaces.BitOrder.LsbFirst "Bit order (a UART sends the least significant bit first)" annotation(
    Dialog(tab = "CH1", group = "UART", enable = ch1Kind == Interfaces.ChannelKind.Uart));
  parameter Integer ch1ClockChannel(min = 0, max = 7) = 0 "Number of the clock channel (SCL for I2cSda, clock for SyncData), itself of kind Logic" annotation(
    Dialog(tab = "CH1", group = "Clock (I2cSda, SyncData)", enable = ch1Kind == Interfaces.ChannelKind.I2cSda or ch1Kind == Interfaces.ChannelKind.SyncData));
  parameter Interfaces.ClockEdge ch1ClockEdge = Interfaces.ClockEdge.Rising "Edge of the clock on which the data is read (HX711: Falling)" annotation(
    Dialog(tab = "CH1", group = "Synchronous serial (SyncData)", enable = ch1Kind == Interfaces.ChannelKind.SyncData));
  parameter Integer ch1WordBits(min = 1, max = 32) = 8 "Bits per word (HX711: 24); the clock pulses left over are counted apart" annotation(
    Dialog(tab = "CH1", group = "Synchronous serial (SyncData)", enable = ch1Kind == Interfaces.ChannelKind.SyncData));
  parameter Interfaces.BitOrder ch1SyncBitOrder = Interfaces.BitOrder.MsbFirst "Bit order (HX711 and most SPI devices: most significant bit first)" annotation(
    Dialog(tab = "CH1", group = "Synchronous serial (SyncData)", enable = ch1Kind == Interfaces.ChannelKind.SyncData));
  parameter Boolean ch1Signed = false "Words in two's complement (HX711: true)" annotation(
    Dialog(tab = "CH1", group = "Synchronous serial (SyncData)", enable = ch1Kind == Interfaces.ChannelKind.SyncData),
    choices(checkBox = true));
  parameter Interfaces.ChannelKind ch2Kind = Interfaces.ChannelKind.Logic "Kind of channel CH2: Off, Logic (also for a clock line), Uart, I2cSda (SCL on clockChannel), SyncData (clock on clockChannel)" annotation(
    Dialog(tab = "CH2", group = "Channel"));
  parameter String ch2Name = "" "Name of CH2 in the files (no comma); empty = CH2" annotation(
    Dialog(tab = "CH2", group = "Channel", enable = ch2Kind <> Interfaces.ChannelKind.Off));
  parameter Real ch2Baudrate(min = 1) = 1200 "Speed of the serial link (baud)" annotation(
    Dialog(tab = "CH2", group = "UART", enable = ch2Kind == Interfaces.ChannelKind.Uart));
  parameter Integer ch2DataBits(min = 5, max = 8) = 8 "Data bits, from 5 to 8" annotation(
    Dialog(tab = "CH2", group = "UART", enable = ch2Kind == Interfaces.ChannelKind.Uart));
  parameter Interfaces.UartParity ch2Parity = Interfaces.UartParity.None "Parity: None, Even or Odd" annotation(
    Dialog(tab = "CH2", group = "UART", enable = ch2Kind == Interfaces.ChannelKind.Uart));
  parameter Integer ch2StopBits(min = 1, max = 2) = 1 "Stop bits, 1 or 2" annotation(
    Dialog(tab = "CH2", group = "UART", enable = ch2Kind == Interfaces.ChannelKind.Uart));
  parameter Interfaces.BitOrder ch2UartBitOrder = Interfaces.BitOrder.LsbFirst "Bit order (a UART sends the least significant bit first)" annotation(
    Dialog(tab = "CH2", group = "UART", enable = ch2Kind == Interfaces.ChannelKind.Uart));
  parameter Integer ch2ClockChannel(min = 0, max = 7) = 1 "Number of the clock channel (SCL for I2cSda, clock for SyncData), itself of kind Logic" annotation(
    Dialog(tab = "CH2", group = "Clock (I2cSda, SyncData)", enable = ch2Kind == Interfaces.ChannelKind.I2cSda or ch2Kind == Interfaces.ChannelKind.SyncData));
  parameter Interfaces.ClockEdge ch2ClockEdge = Interfaces.ClockEdge.Rising "Edge of the clock on which the data is read (HX711: Falling)" annotation(
    Dialog(tab = "CH2", group = "Synchronous serial (SyncData)", enable = ch2Kind == Interfaces.ChannelKind.SyncData));
  parameter Integer ch2WordBits(min = 1, max = 32) = 8 "Bits per word (HX711: 24); the clock pulses left over are counted apart" annotation(
    Dialog(tab = "CH2", group = "Synchronous serial (SyncData)", enable = ch2Kind == Interfaces.ChannelKind.SyncData));
  parameter Interfaces.BitOrder ch2SyncBitOrder = Interfaces.BitOrder.MsbFirst "Bit order (HX711 and most SPI devices: most significant bit first)" annotation(
    Dialog(tab = "CH2", group = "Synchronous serial (SyncData)", enable = ch2Kind == Interfaces.ChannelKind.SyncData));
  parameter Boolean ch2Signed = false "Words in two's complement (HX711: true)" annotation(
    Dialog(tab = "CH2", group = "Synchronous serial (SyncData)", enable = ch2Kind == Interfaces.ChannelKind.SyncData),
    choices(checkBox = true));
  parameter Interfaces.ChannelKind ch3Kind = Interfaces.ChannelKind.Logic "Kind of channel CH3: Off, Logic (also for a clock line), Uart, I2cSda (SCL on clockChannel), SyncData (clock on clockChannel)" annotation(
    Dialog(tab = "CH3", group = "Channel"));
  parameter String ch3Name = "" "Name of CH3 in the files (no comma); empty = CH3" annotation(
    Dialog(tab = "CH3", group = "Channel", enable = ch3Kind <> Interfaces.ChannelKind.Off));
  parameter Real ch3Baudrate(min = 1) = 1200 "Speed of the serial link (baud)" annotation(
    Dialog(tab = "CH3", group = "UART", enable = ch3Kind == Interfaces.ChannelKind.Uart));
  parameter Integer ch3DataBits(min = 5, max = 8) = 8 "Data bits, from 5 to 8" annotation(
    Dialog(tab = "CH3", group = "UART", enable = ch3Kind == Interfaces.ChannelKind.Uart));
  parameter Interfaces.UartParity ch3Parity = Interfaces.UartParity.None "Parity: None, Even or Odd" annotation(
    Dialog(tab = "CH3", group = "UART", enable = ch3Kind == Interfaces.ChannelKind.Uart));
  parameter Integer ch3StopBits(min = 1, max = 2) = 1 "Stop bits, 1 or 2" annotation(
    Dialog(tab = "CH3", group = "UART", enable = ch3Kind == Interfaces.ChannelKind.Uart));
  parameter Interfaces.BitOrder ch3UartBitOrder = Interfaces.BitOrder.LsbFirst "Bit order (a UART sends the least significant bit first)" annotation(
    Dialog(tab = "CH3", group = "UART", enable = ch3Kind == Interfaces.ChannelKind.Uart));
  parameter Integer ch3ClockChannel(min = 0, max = 7) = 2 "Number of the clock channel (SCL for I2cSda, clock for SyncData), itself of kind Logic" annotation(
    Dialog(tab = "CH3", group = "Clock (I2cSda, SyncData)", enable = ch3Kind == Interfaces.ChannelKind.I2cSda or ch3Kind == Interfaces.ChannelKind.SyncData));
  parameter Interfaces.ClockEdge ch3ClockEdge = Interfaces.ClockEdge.Rising "Edge of the clock on which the data is read (HX711: Falling)" annotation(
    Dialog(tab = "CH3", group = "Synchronous serial (SyncData)", enable = ch3Kind == Interfaces.ChannelKind.SyncData));
  parameter Integer ch3WordBits(min = 1, max = 32) = 8 "Bits per word (HX711: 24); the clock pulses left over are counted apart" annotation(
    Dialog(tab = "CH3", group = "Synchronous serial (SyncData)", enable = ch3Kind == Interfaces.ChannelKind.SyncData));
  parameter Interfaces.BitOrder ch3SyncBitOrder = Interfaces.BitOrder.MsbFirst "Bit order (HX711 and most SPI devices: most significant bit first)" annotation(
    Dialog(tab = "CH3", group = "Synchronous serial (SyncData)", enable = ch3Kind == Interfaces.ChannelKind.SyncData));
  parameter Boolean ch3Signed = false "Words in two's complement (HX711: true)" annotation(
    Dialog(tab = "CH3", group = "Synchronous serial (SyncData)", enable = ch3Kind == Interfaces.ChannelKind.SyncData),
    choices(checkBox = true));
  parameter Interfaces.ChannelKind ch4Kind = Interfaces.ChannelKind.Logic "Kind of channel CH4: Off, Logic (also for a clock line), Uart, I2cSda (SCL on clockChannel), SyncData (clock on clockChannel)" annotation(
    Dialog(tab = "CH4", group = "Channel"));
  parameter String ch4Name = "" "Name of CH4 in the files (no comma); empty = CH4" annotation(
    Dialog(tab = "CH4", group = "Channel", enable = ch4Kind <> Interfaces.ChannelKind.Off));
  parameter Real ch4Baudrate(min = 1) = 1200 "Speed of the serial link (baud)" annotation(
    Dialog(tab = "CH4", group = "UART", enable = ch4Kind == Interfaces.ChannelKind.Uart));
  parameter Integer ch4DataBits(min = 5, max = 8) = 8 "Data bits, from 5 to 8" annotation(
    Dialog(tab = "CH4", group = "UART", enable = ch4Kind == Interfaces.ChannelKind.Uart));
  parameter Interfaces.UartParity ch4Parity = Interfaces.UartParity.None "Parity: None, Even or Odd" annotation(
    Dialog(tab = "CH4", group = "UART", enable = ch4Kind == Interfaces.ChannelKind.Uart));
  parameter Integer ch4StopBits(min = 1, max = 2) = 1 "Stop bits, 1 or 2" annotation(
    Dialog(tab = "CH4", group = "UART", enable = ch4Kind == Interfaces.ChannelKind.Uart));
  parameter Interfaces.BitOrder ch4UartBitOrder = Interfaces.BitOrder.LsbFirst "Bit order (a UART sends the least significant bit first)" annotation(
    Dialog(tab = "CH4", group = "UART", enable = ch4Kind == Interfaces.ChannelKind.Uart));
  parameter Integer ch4ClockChannel(min = 0, max = 7) = 3 "Number of the clock channel (SCL for I2cSda, clock for SyncData), itself of kind Logic" annotation(
    Dialog(tab = "CH4", group = "Clock (I2cSda, SyncData)", enable = ch4Kind == Interfaces.ChannelKind.I2cSda or ch4Kind == Interfaces.ChannelKind.SyncData));
  parameter Interfaces.ClockEdge ch4ClockEdge = Interfaces.ClockEdge.Rising "Edge of the clock on which the data is read (HX711: Falling)" annotation(
    Dialog(tab = "CH4", group = "Synchronous serial (SyncData)", enable = ch4Kind == Interfaces.ChannelKind.SyncData));
  parameter Integer ch4WordBits(min = 1, max = 32) = 8 "Bits per word (HX711: 24); the clock pulses left over are counted apart" annotation(
    Dialog(tab = "CH4", group = "Synchronous serial (SyncData)", enable = ch4Kind == Interfaces.ChannelKind.SyncData));
  parameter Interfaces.BitOrder ch4SyncBitOrder = Interfaces.BitOrder.MsbFirst "Bit order (HX711 and most SPI devices: most significant bit first)" annotation(
    Dialog(tab = "CH4", group = "Synchronous serial (SyncData)", enable = ch4Kind == Interfaces.ChannelKind.SyncData));
  parameter Boolean ch4Signed = false "Words in two's complement (HX711: true)" annotation(
    Dialog(tab = "CH4", group = "Synchronous serial (SyncData)", enable = ch4Kind == Interfaces.ChannelKind.SyncData),
    choices(checkBox = true));
  parameter Interfaces.ChannelKind ch5Kind = Interfaces.ChannelKind.Logic "Kind of channel CH5: Off, Logic (also for a clock line), Uart, I2cSda (SCL on clockChannel), SyncData (clock on clockChannel)" annotation(
    Dialog(tab = "CH5", group = "Channel"));
  parameter String ch5Name = "" "Name of CH5 in the files (no comma); empty = CH5" annotation(
    Dialog(tab = "CH5", group = "Channel", enable = ch5Kind <> Interfaces.ChannelKind.Off));
  parameter Real ch5Baudrate(min = 1) = 1200 "Speed of the serial link (baud)" annotation(
    Dialog(tab = "CH5", group = "UART", enable = ch5Kind == Interfaces.ChannelKind.Uart));
  parameter Integer ch5DataBits(min = 5, max = 8) = 8 "Data bits, from 5 to 8" annotation(
    Dialog(tab = "CH5", group = "UART", enable = ch5Kind == Interfaces.ChannelKind.Uart));
  parameter Interfaces.UartParity ch5Parity = Interfaces.UartParity.None "Parity: None, Even or Odd" annotation(
    Dialog(tab = "CH5", group = "UART", enable = ch5Kind == Interfaces.ChannelKind.Uart));
  parameter Integer ch5StopBits(min = 1, max = 2) = 1 "Stop bits, 1 or 2" annotation(
    Dialog(tab = "CH5", group = "UART", enable = ch5Kind == Interfaces.ChannelKind.Uart));
  parameter Interfaces.BitOrder ch5UartBitOrder = Interfaces.BitOrder.LsbFirst "Bit order (a UART sends the least significant bit first)" annotation(
    Dialog(tab = "CH5", group = "UART", enable = ch5Kind == Interfaces.ChannelKind.Uart));
  parameter Integer ch5ClockChannel(min = 0, max = 7) = 4 "Number of the clock channel (SCL for I2cSda, clock for SyncData), itself of kind Logic" annotation(
    Dialog(tab = "CH5", group = "Clock (I2cSda, SyncData)", enable = ch5Kind == Interfaces.ChannelKind.I2cSda or ch5Kind == Interfaces.ChannelKind.SyncData));
  parameter Interfaces.ClockEdge ch5ClockEdge = Interfaces.ClockEdge.Rising "Edge of the clock on which the data is read (HX711: Falling)" annotation(
    Dialog(tab = "CH5", group = "Synchronous serial (SyncData)", enable = ch5Kind == Interfaces.ChannelKind.SyncData));
  parameter Integer ch5WordBits(min = 1, max = 32) = 8 "Bits per word (HX711: 24); the clock pulses left over are counted apart" annotation(
    Dialog(tab = "CH5", group = "Synchronous serial (SyncData)", enable = ch5Kind == Interfaces.ChannelKind.SyncData));
  parameter Interfaces.BitOrder ch5SyncBitOrder = Interfaces.BitOrder.MsbFirst "Bit order (HX711 and most SPI devices: most significant bit first)" annotation(
    Dialog(tab = "CH5", group = "Synchronous serial (SyncData)", enable = ch5Kind == Interfaces.ChannelKind.SyncData));
  parameter Boolean ch5Signed = false "Words in two's complement (HX711: true)" annotation(
    Dialog(tab = "CH5", group = "Synchronous serial (SyncData)", enable = ch5Kind == Interfaces.ChannelKind.SyncData),
    choices(checkBox = true));
  parameter Interfaces.ChannelKind ch6Kind = Interfaces.ChannelKind.Logic "Kind of channel CH6: Off, Logic (also for a clock line), Uart, I2cSda (SCL on clockChannel), SyncData (clock on clockChannel)" annotation(
    Dialog(tab = "CH6", group = "Channel"));
  parameter String ch6Name = "" "Name of CH6 in the files (no comma); empty = CH6" annotation(
    Dialog(tab = "CH6", group = "Channel", enable = ch6Kind <> Interfaces.ChannelKind.Off));
  parameter Real ch6Baudrate(min = 1) = 1200 "Speed of the serial link (baud)" annotation(
    Dialog(tab = "CH6", group = "UART", enable = ch6Kind == Interfaces.ChannelKind.Uart));
  parameter Integer ch6DataBits(min = 5, max = 8) = 8 "Data bits, from 5 to 8" annotation(
    Dialog(tab = "CH6", group = "UART", enable = ch6Kind == Interfaces.ChannelKind.Uart));
  parameter Interfaces.UartParity ch6Parity = Interfaces.UartParity.None "Parity: None, Even or Odd" annotation(
    Dialog(tab = "CH6", group = "UART", enable = ch6Kind == Interfaces.ChannelKind.Uart));
  parameter Integer ch6StopBits(min = 1, max = 2) = 1 "Stop bits, 1 or 2" annotation(
    Dialog(tab = "CH6", group = "UART", enable = ch6Kind == Interfaces.ChannelKind.Uart));
  parameter Interfaces.BitOrder ch6UartBitOrder = Interfaces.BitOrder.LsbFirst "Bit order (a UART sends the least significant bit first)" annotation(
    Dialog(tab = "CH6", group = "UART", enable = ch6Kind == Interfaces.ChannelKind.Uart));
  parameter Integer ch6ClockChannel(min = 0, max = 7) = 5 "Number of the clock channel (SCL for I2cSda, clock for SyncData), itself of kind Logic" annotation(
    Dialog(tab = "CH6", group = "Clock (I2cSda, SyncData)", enable = ch6Kind == Interfaces.ChannelKind.I2cSda or ch6Kind == Interfaces.ChannelKind.SyncData));
  parameter Interfaces.ClockEdge ch6ClockEdge = Interfaces.ClockEdge.Rising "Edge of the clock on which the data is read (HX711: Falling)" annotation(
    Dialog(tab = "CH6", group = "Synchronous serial (SyncData)", enable = ch6Kind == Interfaces.ChannelKind.SyncData));
  parameter Integer ch6WordBits(min = 1, max = 32) = 8 "Bits per word (HX711: 24); the clock pulses left over are counted apart" annotation(
    Dialog(tab = "CH6", group = "Synchronous serial (SyncData)", enable = ch6Kind == Interfaces.ChannelKind.SyncData));
  parameter Interfaces.BitOrder ch6SyncBitOrder = Interfaces.BitOrder.MsbFirst "Bit order (HX711 and most SPI devices: most significant bit first)" annotation(
    Dialog(tab = "CH6", group = "Synchronous serial (SyncData)", enable = ch6Kind == Interfaces.ChannelKind.SyncData));
  parameter Boolean ch6Signed = false "Words in two's complement (HX711: true)" annotation(
    Dialog(tab = "CH6", group = "Synchronous serial (SyncData)", enable = ch6Kind == Interfaces.ChannelKind.SyncData),
    choices(checkBox = true));
  parameter Interfaces.ChannelKind ch7Kind = Interfaces.ChannelKind.Logic "Kind of channel CH7: Off, Logic (also for a clock line), Uart, I2cSda (SCL on clockChannel), SyncData (clock on clockChannel)" annotation(
    Dialog(tab = "CH7", group = "Channel"));
  parameter String ch7Name = "" "Name of CH7 in the files (no comma); empty = CH7" annotation(
    Dialog(tab = "CH7", group = "Channel", enable = ch7Kind <> Interfaces.ChannelKind.Off));
  parameter Real ch7Baudrate(min = 1) = 1200 "Speed of the serial link (baud)" annotation(
    Dialog(tab = "CH7", group = "UART", enable = ch7Kind == Interfaces.ChannelKind.Uart));
  parameter Integer ch7DataBits(min = 5, max = 8) = 8 "Data bits, from 5 to 8" annotation(
    Dialog(tab = "CH7", group = "UART", enable = ch7Kind == Interfaces.ChannelKind.Uart));
  parameter Interfaces.UartParity ch7Parity = Interfaces.UartParity.None "Parity: None, Even or Odd" annotation(
    Dialog(tab = "CH7", group = "UART", enable = ch7Kind == Interfaces.ChannelKind.Uart));
  parameter Integer ch7StopBits(min = 1, max = 2) = 1 "Stop bits, 1 or 2" annotation(
    Dialog(tab = "CH7", group = "UART", enable = ch7Kind == Interfaces.ChannelKind.Uart));
  parameter Interfaces.BitOrder ch7UartBitOrder = Interfaces.BitOrder.LsbFirst "Bit order (a UART sends the least significant bit first)" annotation(
    Dialog(tab = "CH7", group = "UART", enable = ch7Kind == Interfaces.ChannelKind.Uart));
  parameter Integer ch7ClockChannel(min = 0, max = 7) = 6 "Number of the clock channel (SCL for I2cSda, clock for SyncData), itself of kind Logic" annotation(
    Dialog(tab = "CH7", group = "Clock (I2cSda, SyncData)", enable = ch7Kind == Interfaces.ChannelKind.I2cSda or ch7Kind == Interfaces.ChannelKind.SyncData));
  parameter Interfaces.ClockEdge ch7ClockEdge = Interfaces.ClockEdge.Rising "Edge of the clock on which the data is read (HX711: Falling)" annotation(
    Dialog(tab = "CH7", group = "Synchronous serial (SyncData)", enable = ch7Kind == Interfaces.ChannelKind.SyncData));
  parameter Integer ch7WordBits(min = 1, max = 32) = 8 "Bits per word (HX711: 24); the clock pulses left over are counted apart" annotation(
    Dialog(tab = "CH7", group = "Synchronous serial (SyncData)", enable = ch7Kind == Interfaces.ChannelKind.SyncData));
  parameter Interfaces.BitOrder ch7SyncBitOrder = Interfaces.BitOrder.MsbFirst "Bit order (HX711 and most SPI devices: most significant bit first)" annotation(
    Dialog(tab = "CH7", group = "Synchronous serial (SyncData)", enable = ch7Kind == Interfaces.ChannelKind.SyncData));
  parameter Boolean ch7Signed = false "Words in two's complement (HX711: true)" annotation(
    Dialog(tab = "CH7", group = "Synchronous serial (SyncData)", enable = ch7Kind == Interfaces.ChannelKind.SyncData),
    choices(checkBox = true));
  parameter Boolean textHexDump = true "Section of the decoded bytes in hex + ASCII (bursts, transactions, words), and summary of the logic channels" annotation(
    Dialog(tab = "Text file", group = "Contents", enable = writeText),
    choices(checkBox = true));
  parameter Boolean textWaveform = true "ASCII timing diagram of the channels, with the decoded bytes under the waveform" annotation(
    Dialog(tab = "Text file", group = "Contents", enable = writeText),
    choices(checkBox = true));
  parameter Boolean textBitLabels = true "Under each decoded waveform, the bits one by one (S start, P parity, s stop, A/N acknowledge...) above the bytes" annotation(
    Dialog(tab = "Text file", group = "Contents", enable = writeText and textWaveform),
    choices(checkBox = true));
  parameter Boolean textSplitFrames = true "Each frame (UART burst, I2C transaction, burst of clock pulses) starts on a new line, with a header" annotation(
    Dialog(tab = "Text file", group = "Layout", enable = writeText and textWaveform),
    choices(checkBox = true));
  parameter Boolean textCompressSilences = true "A silence longer than textSilence is not drawn: one line gives its duration" annotation(
    Dialog(tab = "Text file", group = "Layout", enable = writeText and textWaveform),
    choices(checkBox = true));
  parameter Modelica.Units.SI.Time textSilence(min = 0) = 0 "Shortest silence that is not drawn; 0 = automatic (40 columns)" annotation(
    Dialog(tab = "Text file", group = "Layout", enable = writeText and textWaveform and textCompressSilences));
  parameter Modelica.Units.SI.Time textResolution(min = 0) = 0 "Duration of one column of the timing diagram; 0 = automatic (half a bit of the fastest UART, half a level of the fastest clock)" annotation(
    Dialog(tab = "Text file", group = "Layout", enable = writeText and textWaveform));
  parameter Integer textWidth(min = 40, max = 1000) = 100 "Columns of the timing diagram per line" annotation(
    Dialog(tab = "Text file", group = "Layout", enable = writeText and textWaveform));
  parameter Modelica.Units.SI.Voltage VIH = Interfaces.VIH "Threshold above which a channel reads high" annotation(
    Dialog(tab = "Electrical"));
  parameter Modelica.Units.SI.Voltage VIL = Interfaces.VIL "Threshold below which a channel reads low (the level changes halfway between VIL and VIH)" annotation(
    Dialog(tab = "Electrical"));
  parameter Modelica.Units.SI.Conductance GIn = Interfaces.GOff "Input conductance of each channel to GND: 1e-9 S = 1 GOhm, the circuit is not disturbed, and an unconnected channel reads 0" annotation(
    Dialog(tab = "Electrical"));
  parameter Boolean useGroundPin = true "Show the GND pin - unchecked: the probe is referenced to the simulation ground (0 V), nothing to wire" annotation(
    Dialog(tab = "Electrical"),
    choices(checkBox = true));

  Modelica.Electrical.Analog.Interfaces.PositivePin CH0 "Channel 0" annotation(
    Placement(transformation(origin = {-100, 70}, extent = {{-6, -6}, {6, 6}}), iconTransformation(origin = {-90, 70}, extent = {{-5, -5}, {5, 5}})));
  Modelica.Electrical.Analog.Interfaces.PositivePin CH1 "Channel 1" annotation(
    Placement(transformation(origin = {-100, 50}, extent = {{-6, -6}, {6, 6}}), iconTransformation(origin = {-90, 50}, extent = {{-5, -5}, {5, 5}})));
  Modelica.Electrical.Analog.Interfaces.PositivePin CH2 "Channel 2" annotation(
    Placement(transformation(origin = {-100, 30}, extent = {{-6, -6}, {6, 6}}), iconTransformation(origin = {-90, 30}, extent = {{-5, -5}, {5, 5}})));
  Modelica.Electrical.Analog.Interfaces.PositivePin CH3 "Channel 3" annotation(
    Placement(transformation(origin = {-100, 10}, extent = {{-6, -6}, {6, 6}}), iconTransformation(origin = {-90, 10}, extent = {{-5, -5}, {5, 5}})));
  Modelica.Electrical.Analog.Interfaces.PositivePin CH4 "Channel 4" annotation(
    Placement(transformation(origin = {-100, -10}, extent = {{-6, -6}, {6, 6}}), iconTransformation(origin = {-90, -10}, extent = {{-5, -5}, {5, 5}})));
  Modelica.Electrical.Analog.Interfaces.PositivePin CH5 "Channel 5" annotation(
    Placement(transformation(origin = {-100, -30}, extent = {{-6, -6}, {6, 6}}), iconTransformation(origin = {-90, -30}, extent = {{-5, -5}, {5, 5}})));
  Modelica.Electrical.Analog.Interfaces.PositivePin CH6 "Channel 6" annotation(
    Placement(transformation(origin = {-100, -50}, extent = {{-6, -6}, {6, 6}}), iconTransformation(origin = {-90, -50}, extent = {{-5, -5}, {5, 5}})));
  Modelica.Electrical.Analog.Interfaces.PositivePin CH7 "Channel 7" annotation(
    Placement(transformation(origin = {-100, -70}, extent = {{-6, -6}, {6, 6}}), iconTransformation(origin = {-90, -70}, extent = {{-5, -5}, {5, 5}})));
  Modelica.Electrical.Analog.Interfaces.NegativePin GND if useGroundPin "Common reference (ground) of the probe, to be connected to the ground of the circuit - shown when useGroundPin is checked" annotation(
    Placement(transformation(origin = {0, -100}, extent = {{-6, -6}, {6, 6}}), iconTransformation(origin = {0, -90}, extent = {{-5, -5}, {5, 5}})));
protected
  constant Integer NCH = 8;
  Modelica.Electrical.Analog.Interfaces.NegativePin gnd "Internal reference of the probe: GND, or the simulation ground when the GND pin is hidden" annotation(
    Placement(visible = false, transformation(extent = {{40, -10}, {60, 10}})));
  Modelica.Electrical.Analog.Basic.Ground implicitGround if not useGroundPin "Simulation ground, when there is no GND pin" annotation(
    Placement(visible = false, transformation(extent = {{40, -40}, {60, -20}})));
  Modelica.Electrical.Analog.Sensors.VoltageSensor sns[NCH] "Voltage of each channel" annotation(
    Placement(visible = false, transformation(extent = {{-40, -10}, {-20, 10}})));
  Modelica.Electrical.Analog.Basic.Conductor gIn[NCH](each G = GIn) "Input conductance of each channel: very high impedance, and a determined voltage (0 V) for an unconnected channel" annotation(
    Placement(visible = false, transformation(extent = {{0, -10}, {20, 10}})));
  final parameter Interfaces.ChannelKind kinds[NCH] = {ch0Kind, ch1Kind, ch2Kind, ch3Kind, ch4Kind, ch5Kind, ch6Kind, ch7Kind} "Kind of each channel";
  Boolean level[NCH](each start = false, each fixed = true) "Logic level of each channel (constant false for an Off channel: no crossing function)";
  Integer levelC[NCH] "level as passed to the C code (0/1): arrays of Boolean are not exchanged with the C code";
  discrete Integer calls(start = 0, fixed = true) "Number of recordings, assigned by the when clause";
  discrete Integer finished(start = 0, fixed = true);
  Internal.LogicAnalyzerCapture an = Internal.LogicAnalyzerCapture(fileName, getInstanceName(), ch0Name + "," + ch1Name + "," + ch2Name + "," + ch3Name + "," + ch4Name + "," + ch5Name + "," + ch6Name + "," + ch7Name, {Integer(kinds[i]) for i in 1:NCH}, {ch0Baudrate, ch1Baudrate, ch2Baudrate, ch3Baudrate, ch4Baudrate, ch5Baudrate, ch6Baudrate, ch7Baudrate}, {ch0DataBits, ch1DataBits, ch2DataBits, ch3DataBits, ch4DataBits, ch5DataBits, ch6DataBits, ch7DataBits}, {Integer(ch0Parity) - 2, Integer(ch1Parity) - 2, Integer(ch2Parity) - 2, Integer(ch3Parity) - 2, Integer(ch4Parity) - 2, Integer(ch5Parity) - 2, Integer(ch6Parity) - 2, Integer(ch7Parity) - 2}, {ch0StopBits, ch1StopBits, ch2StopBits, ch3StopBits, ch4StopBits, ch5StopBits, ch6StopBits, ch7StopBits}, {if ch0Kind == Interfaces.ChannelKind.Uart then (if ch0UartBitOrder == Interfaces.BitOrder.MsbFirst then 1 else 0) else (if ch0SyncBitOrder == Interfaces.BitOrder.MsbFirst then 1 else 0), if ch1Kind == Interfaces.ChannelKind.Uart then (if ch1UartBitOrder == Interfaces.BitOrder.MsbFirst then 1 else 0) else (if ch1SyncBitOrder == Interfaces.BitOrder.MsbFirst then 1 else 0), if ch2Kind == Interfaces.ChannelKind.Uart then (if ch2UartBitOrder == Interfaces.BitOrder.MsbFirst then 1 else 0) else (if ch2SyncBitOrder == Interfaces.BitOrder.MsbFirst then 1 else 0), if ch3Kind == Interfaces.ChannelKind.Uart then (if ch3UartBitOrder == Interfaces.BitOrder.MsbFirst then 1 else 0) else (if ch3SyncBitOrder == Interfaces.BitOrder.MsbFirst then 1 else 0), if ch4Kind == Interfaces.ChannelKind.Uart then (if ch4UartBitOrder == Interfaces.BitOrder.MsbFirst then 1 else 0) else (if ch4SyncBitOrder == Interfaces.BitOrder.MsbFirst then 1 else 0), if ch5Kind == Interfaces.ChannelKind.Uart then (if ch5UartBitOrder == Interfaces.BitOrder.MsbFirst then 1 else 0) else (if ch5SyncBitOrder == Interfaces.BitOrder.MsbFirst then 1 else 0), if ch6Kind == Interfaces.ChannelKind.Uart then (if ch6UartBitOrder == Interfaces.BitOrder.MsbFirst then 1 else 0) else (if ch6SyncBitOrder == Interfaces.BitOrder.MsbFirst then 1 else 0), if ch7Kind == Interfaces.ChannelKind.Uart then (if ch7UartBitOrder == Interfaces.BitOrder.MsbFirst then 1 else 0) else (if ch7SyncBitOrder == Interfaces.BitOrder.MsbFirst then 1 else 0)}, {ch0ClockChannel, ch1ClockChannel, ch2ClockChannel, ch3ClockChannel, ch4ClockChannel, ch5ClockChannel, ch6ClockChannel, ch7ClockChannel}, {if ch0ClockEdge == Interfaces.ClockEdge.Falling then 1 else 0, if ch1ClockEdge == Interfaces.ClockEdge.Falling then 1 else 0, if ch2ClockEdge == Interfaces.ClockEdge.Falling then 1 else 0, if ch3ClockEdge == Interfaces.ClockEdge.Falling then 1 else 0, if ch4ClockEdge == Interfaces.ClockEdge.Falling then 1 else 0, if ch5ClockEdge == Interfaces.ClockEdge.Falling then 1 else 0, if ch6ClockEdge == Interfaces.ClockEdge.Falling then 1 else 0, if ch7ClockEdge == Interfaces.ClockEdge.Falling then 1 else 0}, {ch0WordBits, ch1WordBits, ch2WordBits, ch3WordBits, ch4WordBits, ch5WordBits, ch6WordBits, ch7WordBits}, {if ch0Signed then 1 else 0, if ch1Signed then 1 else 0, if ch2Signed then 1 else 0, if ch3Signed then 1 else 0, if ch4Signed then 1 else 0, if ch5Signed then 1 else 0, if ch6Signed then 1 else 0, if ch7Signed then 1 else 0}, writeVcd, writePulseViewSession, openPulseView, Internal.ResolvePath(pulseViewPath), Modelica.Utilities.Files.loadResource("modelica://MicroPythonMCU/../PulseView/pulseview.exe"), writeText, openText, {if textHexDump then 1 else 0, if textWaveform then 1 else 0, if textBitLabels then 1 else 0, if textSplitFrames then 1 else 0, if textCompressSilences then 1 else 0}, textSilence, textResolution, textWidth) "VCD recording and text file" annotation(
    Placement(visible = false, transformation(extent = {{-20, 75}, {20, 95}})));
equation
  connect(GND, gnd);
  connect(implicitGround.p, gnd);
  connect(CH0, sns[1].p);
  connect(CH1, sns[2].p);
  connect(CH2, sns[3].p);
  connect(CH3, sns[4].p);
  connect(CH4, sns[5].p);
  connect(CH5, sns[6].p);
  connect(CH6, sns[7].p);
  connect(CH7, sns[8].p);
  for i in 1:NCH loop
    connect(sns[i].p, gIn[i].p);
    connect(sns[i].n, gnd);
    connect(gIn[i].n, gnd);
    level[i] = if kinds[i] <> Interfaces.ChannelKind.Off then sns[i].v > (VIL + VIH)/2 else false "logic threshold halfway, same approximation as the microcontroller";
    levelC[i] = if level[i] then 1 else 0;
  end for;
  when {initial(), change(level[1]), change(level[2]), change(level[3]), change(level[4]), change(level[5]), change(level[6]), change(level[7]), change(level[8])} then
    calls = Internal.LogicAnalyzer_record(an, time, levelC);
  end when;
  when terminal() then
    finished = Internal.LogicAnalyzer_finish(an, time);
  end when;
  annotation(
    Icon(coordinateSystem(preserveAspectRatio = true, extent = {{-100, -100}, {100, 100}}, initialScale = 0.2), graphics = {Rectangle(fillColor = {40, 44, 52}, fillPattern = FillPattern.Solid, lineColor = {20, 20, 20}, extent = {{-86, 86}, {86, -86}}, radius = 6), Text(textColor = {255, 255, 255}, extent = {{-30, 80}, {82, 60}}, textString = "LOGIC", textStyle = {TextStyle.Bold}), Rectangle(fillColor = {15, 20, 25}, fillPattern = FillPattern.Solid, lineColor = {90, 90, 90}, extent = {{-30, 52}, {78, -62}}), Line(points = {{-24, 40}, {-10, 40}, {-10, 48}, {8, 48}, {8, 40}, {24, 40}, {24, 48}, {40, 48}, {40, 40}, {72, 40}}, color = {80, 220, 120}, thickness = 0.5), Line(points = {{-24, 14}, {0, 14}, {0, 22}, {16, 22}, {16, 14}, {48, 14}, {48, 22}, {72, 22}}, color = {80, 200, 255}, thickness = 0.5), Line(points = {{-24, -12}, {4, -12}, {4, -4}, {10, -4}, {10, -12}, {18, -12}, {18, -4}, {24, -4}, {24, -12}, {30, -12}, {30, -4}, {36, -4}, {36, -12}, {72, -12}}, color = {255, 200, 70}, thickness = 0.5), Line(points = {{-24, -38}, {32, -38}, {32, -30}, {72, -30}}, color = {255, 110, 110}, thickness = 0.5), Text(textColor = {170, 170, 170}, extent = {{-30, -66}, {78, -80}}, textString = "TXT  VCD"), Text(textColor = {255, 255, 255}, extent = {{-84, 76}, {-40, 64}}, textString = "CH0", horizontalAlignment = TextAlignment.Left), Text(textColor = {255, 255, 255}, extent = {{-84, 56}, {-40, 44}}, textString = "CH1", horizontalAlignment = TextAlignment.Left), Text(textColor = {255, 255, 255}, extent = {{-84, 36}, {-40, 24}}, textString = "CH2", horizontalAlignment = TextAlignment.Left), Text(textColor = {255, 255, 255}, extent = {{-84, 16}, {-40, 4}}, textString = "CH3", horizontalAlignment = TextAlignment.Left), Text(textColor = {255, 255, 255}, extent = {{-84, -4}, {-40, -16}}, textString = "CH4", horizontalAlignment = TextAlignment.Left), Text(textColor = {255, 255, 255}, extent = {{-84, -24}, {-40, -36}}, textString = "CH5", horizontalAlignment = TextAlignment.Left), Text(textColor = {255, 255, 255}, extent = {{-84, -44}, {-40, -56}}, textString = "CH6", horizontalAlignment = TextAlignment.Left), Text(textColor = {255, 255, 255}, extent = {{-84, -64}, {-40, -76}}, textString = "CH7", horizontalAlignment = TextAlignment.Left), Text(visible = useGroundPin, extent = {{7, -86}, {47, -94}}, textString = "GND", horizontalAlignment = TextAlignment.Left), Text(textColor = {0, 0, 255}, extent = {{-150, 110}, {150, 90}}, textString = "%name")}),
    Documentation(info = "<html>
<p>Probe of a <strong>logic analyser</strong>: connect its channels <code>CH0</code>…<code>CH7</code> to lines of the circuit (a UART link, the SCL/SDA lines of an I2C bus, the clock and data lines of an HX711, a PWM output...) and its <code>GND</code> to the ground of the circuit, as with the clips of a real analyser (or uncheck <code>useGroundPin</code>, \"Electrical\" tab: the pin disappears and the probe is referenced to the simulation ground, 0 V). Each channel has a very high input impedance (<code>GIn</code>, 1 GΩ to ground): the circuit behaves the same with or without the probe.</p>
<p>Each channel has its own tab (<code>CH0</code>…<code>CH7</code>): a name and a <strong>kind</strong> (<code>Interfaces.ChannelKind</code>):</p>
<ul>
<li><code>Off</code>: not recorded, costs nothing;</li>
<li><code>Logic</code>: logic level only — also the kind of a clock line;</li>
<li><code>Uart</code>: serial link decoded with the format of the tab (speed, data bits, parity, stop bits, bit order);</li>
<li><code>I2cSda</code>: SDA line of an I2C bus, whose SCL line is the channel <code>clockChannel</code>;</li>
<li><code>SyncData</code>: data of a synchronous serial link (HX711, simplified SPI), read on an edge of the channel <code>clockChannel</code>, in words of <code>wordBits</code> bits.</li>
</ul>
<p>At the end of the simulation, the probe writes in the simulation folder, named after the component unless <code>fileName</code> is given (full paths in the log):</p>
<ul>
<li>a <strong>text file</strong> (<code>writeText</code>), opened in Notepad if <code>openText</code> is set: the decoded bytes of each channel in hexadecimal + ASCII (UART bursts, I2C transactions, synchronous words, summary of the logic channels), then an <strong>ASCII timing diagram</strong> of the channels, with the bits and bytes under each decoded waveform. The \"Text file\" tab chooses the sections, the frames on separate lines, the silences not drawn, the resolution and the width;</li>
<li>a <strong>VCD file</strong> (<code>writeVcd</code>, <em>Value Change Dump</em>), opened in <strong>PulseView</strong> (free software of the sigrok project, with its own protocol decoders) if <code>openPulseView</code> is set; GTKWave also reads it. Next to it, a PulseView session (<code>writePulseViewSession</code>, <code>&lt;base&gt;.pvs</code>) that PulseView loads by itself with the VCD file: its UART, I2C and SPI decoders are already set up from the channels (a <code>SyncData</code> channel is decoded as SPI).</li>
</ul>
<p>With <code>pulseViewPath</code> empty (the default), the probe looks for PulseView in this order: the environment variable <code>MICROPYTHONMCU_PULSEVIEW</code> (path of <code>pulseview.exe</code> or of its folder, e.g. a copy on a network share), the portable copy fetched by <code>get_pulseview.cmd</code> into the <code>PulseView</code> folder next to the library, then the folder of the sigrok installer (<code>C:/Program Files/sigrok/PulseView</code>).</p>
<p>A level change is detected halfway between <code>VIL</code> and <code>VIH</code>; a level that changes and changes back at the same simulated instant is not recorded. Cost: one threshold-crossing function per channel that is not <code>Off</code>; on lines that already change at events of the model (outputs of the microcontroller or of a device), the probe adds no event of its own. The text file is written from the level changes kept in memory, without any extra event.</p>
</html>"));
end LogicAnalyzer;
