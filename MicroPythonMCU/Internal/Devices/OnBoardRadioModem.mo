within MicroPythonMCU.Internal.Devices;

model OnBoardRadioModem "The on-board 2.4 GHz radio of the micro:bit as a transparent modem: the same engine as Peripherals.Radio.RadioModem, mounted inside MicroBit_v2 on two internal pins of the core (34 = TX of the core, 35 = RX) - the packet protocol of microbit.radio (framing, channel/group/address filtering, receive queue) lives in the Python shim, see requirements.md decision \"Radios micro:bit\""
  extends PartialRadioModem(
    final baudrate = 115200 "internal serial link, at the guard-rail of the UART engine (a 1 Mbaud link would be an event storm)",
    final dataBits = 8,
    final parity = Interfaces.UartParity.None,
    final stopBits = 1,
    modulation = Interfaces.Modulation.FSK "not final: Integer(modulation) inlined by omc breaks the symbolic Jacobian of the antenna node",
    final fCarrier = 2.4e9 "the 2.4 GHz band of the nRF52833",
    final channelWidth = 200e3,
    final airBaudrate = 1000000 "RATE_1MBIT of the firmware",
    final halfDuplex = true,
    final txBufferSize = 256,
    final rxBufferSize = 512 "a few frames of headroom, cf. the queue of the firmware",
    final txDelay = 0.0001,
    final rxDelay = 0.0001,
    final fDisplay = 100000 "drawn carrier kept low: the signal is not meant to be observed on the board (no possible sampling at 1 Mbit/s)",
    final deltaFDisplay = 50000,
    final warnSampling = false,
    final useSupplyPin = false,
    final useGroundPin = true);
  annotation(
    Documentation(info = "<html>
<p>The on-board radio of <code>MicroBit_v2</code>, built on the generic radio modem: <code>PartialRadioModem</code> with every parameter <code>final</code> - the board stays a radio black box, the channel, group, address and data rate are set from the program by <code>radio.config()</code>, as on the real board. All the <code>microbit.radio</code> semantics (packet framing with a delimiter, byte stuffing and a CRC, filtering, receive queue of depth <code>queue</code>, truncation to <code>length</code>) are implemented in the Python shim, on top of the internal UART (slot 1) that links the core to this modem.</p>
</html>"));
end OnBoardRadioModem;
