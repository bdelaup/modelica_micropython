within MicroPythonMCU.Internal.Boards;

model McuCore "Programmable core without on-board radio, placed inside the boards MCU and RPi_Pico: adds the sync point (PyRuntime_sync: this core carries no radio) to PartialMcuCore"
  extends PartialMcuCore;
equation
  // initial() must stand alone (or in a literal vector) to be recognized by omc: the
  // vector of conditions is built with cat() to cover any number of pins, hence the
  // separate initial branch.
  when initial() then
    (pinBoolOutC, pinIsOutputC, pinPullC, pwmFreq, pwmDuty, Display0.seq, Display0.payload, uartTxPin, uartTxLevel, nextWakeTime) = Internal.Runtime.PyRuntime_sync(rt, time, pinBoolInC, pinNodeVoltage, powerGood, adcRef);
    Display0.charCode = Internal.Functions.StringToCharCodes(Internal.Functions.DisplayMessage(Display0.payload, Internal.Functions.DisplayMessageCount(Display0.payload)), Interfaces.DISPLAY_COLS) "ASCII codes of the last message of Display0.payload (a String, which cannot be stored in the results), so that the connected display peripheral can animate the text actually received on its icon - see Internal.Functions.StringToCharCodes";
  elsewhen cat(1, {time >= pre(nextWakeTime), sample(0, tickPeriod), change(powerGood)}, {change(pinBoolIn[i]) and not pre(pinIsOutputD[i]) for i in 1:nAll}) then
    (pinBoolOutC, pinIsOutputC, pinPullC, pwmFreq, pwmDuty, Display0.seq, Display0.payload, uartTxPin, uartTxLevel, nextWakeTime) = Internal.Runtime.PyRuntime_sync(rt, time, pinBoolInC, pinNodeVoltage, powerGood, adcRef);
    Display0.charCode = Internal.Functions.StringToCharCodes(Internal.Functions.DisplayMessage(Display0.payload, Internal.Functions.DisplayMessageCount(Display0.payload)), Interfaces.DISPLAY_COLS);
  end when;
  annotation(
    Documentation(info = "<html>
<p>The programmable core with its sync point <code>PyRuntime_sync</code>: <code>PartialMcuCore</code> (Python program, electrical stage of each pin, power-on logic) plus the <code>when</code> that calls the C runtime. Every board uses it - <code>MCU</code>, <code>RPi_Pico</code> and <code>MicroBit_v2</code>: the on-board radio of the micro:bit is a modem mounted inside the board on two internal pins, no longer a board link carried by the sync (cf. <code>requirements.md</code>, decisions \"Refactoring du socle des cartes\" and \"Radios micro:bit\").</p>
</html>"));
end McuCore;
