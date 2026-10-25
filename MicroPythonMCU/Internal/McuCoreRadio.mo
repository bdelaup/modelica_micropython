within MicroPythonMCU.Internal;

model McuCoreRadio "Programmable core with the on-board 2.4 GHz packet radio (microbit.radio), placed inside MicroBit_v2: adds the sync point (PyRuntime_sync) and the radio air link to PartialMcuCore - the shared McuCore carries no radio, cf. requirements.md decision \"Refactoring du socle des cartes\""
  extends PartialMcuCore;
  parameter Boolean useRadio = false "On-board 2.4 GHz radio (microbit.radio): shows the AntennaIn port, to wire to the antenna of a Peripherals.Radio.RadioAir - the boards sharing the same air hear each other";
  Interfaces.RadioAirInput AntennaIn if useRadio "Radio air link (microbit.radio): network id carried by the antenna of the Peripherals.Radio.RadioAir the board is wired to - no radio when unwired (id -1, radio.on() then raises an explicit error)" annotation(
    Placement(transformation(origin = {110, 20}, extent = {{-10, -10}, {10, 10}})));
protected
  Integer radioNetworkC "Network id of the radio air link (-1: no radio, antenna unwired), passed to PyRuntime_sync";
equation
  // Antenne radio : conditionnel (useRadio), la reference reste legale car gardee par la meme condition
  if useRadio then
    radioNetworkC = AntennaIn.networkId;
  else
    radioNetworkC = -1;
  end if;
  // initial() must stand alone (or in a literal vector) to be recognized by omc: the
  // vector of conditions is built with cat() to cover any number of pins, hence the
  // separate initial branch. This when is deliberately duplicated in McuCore (same
  // triggers, other sync function): keep the two in step.
  when initial() then
    (pinBoolOutC, pinIsOutputC, pinPullC, pwmFreq, pwmDuty, Display0.seq, Display0.payload, uartTxPin, uartTxLevel, nextWakeTime) = Internal.PyRuntime_syncBoard(rt, time, pinBoolInC, pinNodeVoltage, powerGood, adcRef, radioNetworkC);
    Display0.charCode = Internal.StringToCharCodes(Internal.DisplayMessage(Display0.payload, Internal.DisplayMessageCount(Display0.payload)), Interfaces.DISPLAY_COLS) "ASCII codes of the last message of Display0.payload (a String, which cannot be stored in the results), so that the connected display peripheral can animate the text actually received on its icon - see Internal.StringToCharCodes";
  elsewhen cat(1, {time >= pre(nextWakeTime), sample(0, tickPeriod), change(powerGood)}, {change(pinBoolIn[i]) and not pre(pinIsOutputD[i]) for i in 1:nAll}) then
    (pinBoolOutC, pinIsOutputC, pinPullC, pwmFreq, pwmDuty, Display0.seq, Display0.payload, uartTxPin, uartTxLevel, nextWakeTime) = Internal.PyRuntime_syncBoard(rt, time, pinBoolInC, pinNodeVoltage, powerGood, adcRef, radioNetworkC);
    Display0.charCode = Internal.StringToCharCodes(Internal.DisplayMessage(Display0.payload, Internal.DisplayMessageCount(Display0.payload)), Interfaces.DISPLAY_COLS);
  end when;
  annotation(
    Documentation(info = "<html>
<p>The programmable core placed inside <code>MicroBit_v2</code>: <code>PartialMcuCore</code> plus the sync point <code>PyRuntime_sync</code> and the <b>on-board 2.4 GHz packet radio</b> (<code>microbit.radio</code>), which stays out of the shared <code>McuCore</code> — the boards that carry no radio do not see it (cf. <code>requirements.md</code>, decision \"Refactoring du socle des cartes\"). The network id of the radio air link (<code>AntennaIn</code>, shown when <code>useRadio</code>) is passed to the C engine at each sync point; unwired, the id is <code>-1</code> and <code>radio.on()</code> raises an explicit error. See the decision \"Radios micro:bit\" for the packet engine itself.</p>
</html>"));
end McuCoreRadio;
