within MicroPythonMCU.Internal;

model McuCore "Programmable core without on-board radio, placed inside the boards MCU and RPi_Pico: adds the sync point (PyRuntime_sync: this core carries no radio) to PartialMcuCore"
  extends PartialMcuCore;
equation
  // initial() must stand alone (or in a literal vector) to be recognized by omc: the
  // vector of conditions is built with cat() to cover any number of pins, hence the
  // separate initial branch. This when is deliberately duplicated in McuCoreRadio (same
  // triggers, other sync function): keep the two in step.
  when initial() then
    (pinBoolOutC, pinIsOutputC, pinPullC, pwmFreq, pwmDuty, Display0.seq, Display0.payload, uartTxPin, uartTxLevel, nextWakeTime) = Internal.PyRuntime_sync(rt, time, pinBoolInC, pinNodeVoltage, powerGood, adcRef);
    Display0.charCode = Internal.StringToCharCodes(Internal.DisplayMessage(Display0.payload, Internal.DisplayMessageCount(Display0.payload)), Interfaces.DISPLAY_COLS) "ASCII codes of the last message of Display0.payload (a String, which cannot be stored in the results), so that the connected display peripheral can animate the text actually received on its icon - see Internal.StringToCharCodes";
  elsewhen cat(1, {time >= pre(nextWakeTime), sample(0, tickPeriod), change(powerGood)}, {change(pinBoolIn[i]) and not pre(pinIsOutputD[i]) for i in 1:nAll}) then
    (pinBoolOutC, pinIsOutputC, pinPullC, pwmFreq, pwmDuty, Display0.seq, Display0.payload, uartTxPin, uartTxLevel, nextWakeTime) = Internal.PyRuntime_sync(rt, time, pinBoolInC, pinNodeVoltage, powerGood, adcRef);
    Display0.charCode = Internal.StringToCharCodes(Internal.DisplayMessage(Display0.payload, Internal.DisplayMessageCount(Display0.payload)), Interfaces.DISPLAY_COLS);
  end when;
  annotation(
    Documentation(info = "<html>
<p>The programmable core placed inside the boards <code>MCU</code> and <code>RPi_Pico</code>: <code>PartialMcuCore</code> (Python program, electrical stage of each pin, power-on logic) plus the sync point <code>PyRuntime_sync</code> — with no board link, as this core carries no radio (a board needing one instantiates <code>McuCoreRadio</code> instead, which keeps the radio out of the shared core — cf. <code>requirements.md</code>, decision \"Refactoring du socle des cartes\").</p>
</html>"));
end McuCore;
