within MicroPythonMCU.Internal;

partial model PartialBoard "Common base of the boards (MCU, RPi_Pico, MicroBit_v2): the user settings and the core contract are written here once - the boards add their pins, their connectors, their supply and their pin table (modifier of core in their extends)"
  extends PartialMcuSettings;
  parameter Modelica.Units.SI.Current ICore = 0.02 "Current drawn from the supply rail by the core and its memory while supplied (program running, pins excluded)" annotation(
    Dialog(tab = "Power supply", group = "Consumption"));
  parameter Modelica.Units.SI.Voltage VPowerOn = 1.8 "Supply rail voltage above which the core starts (power-on reset)" annotation(
    Dialog(tab = "Power supply", group = "Power-on"));
  parameter Modelica.Units.SI.Voltage VPowerOff = 1.6 "Supply rail voltage below which a running core stops for good (brown-out)" annotation(
    Dialog(tab = "Power supply", group = "Power-on"));
  replaceable Internal.PartialMcuCore core(final instanceName = boardName, final ICore = ICore, final VPowerOn = VPowerOn, final VPowerOff = VPowerOff, final scriptPath = scriptPath, final addScriptDirToPath = addScriptDirToPath, final libraryPath = libraryPath, final fsEnabled = fsEnabled, final fsSource = fsSource, final fsWorkspace = fsWorkspace, final fsOpenExplorer = fsOpenExplorer, final tickPeriod = tickPeriod, final gpioOpTime = gpioOpTime, final hangWarningTime = hangWarningTime, final debugEnabled = debugEnabled, final debugPort = debugPort, final VOL = VOL, final VIH = VIH, final VIL = VIL, final ROut = ROut, final RPullUp = RPullUp, final RPullDown = RPullDown, final GOff = GOff) "Programmable core, public like in the boards so that its plotted variables (powerGood, supplyOk...) stay in the simulation results - partial: every board redeclares it (McuCore, or McuCoreRadio for the boards with the on-board radio); pin table (nPins, pinIds, pinCaps), board profile and on-board devices are set by the board in the modifier of its extends, pins in the order of pinIds" annotation(
    Placement(transformation(extent = {{-40, -40}, {40, 40}})));
protected
  final parameter String boardName = getInstanceName() "Instance name of the board, given to the core (log prefix, name of the copy of the flash): getInstanceName() written in the modifier of core would return the name of the core";
  annotation(
    Icon(coordinateSystem(preserveAspectRatio = true, extent = {{-100, -100}, {100, 100}}, initialScale = 0.2), graphics = {Rectangle(lineColor = {20, 20, 20}, fillColor = {60, 60, 60}, fillPattern = FillPattern.Solid, extent = {{-55, 65}, {55, -65}}), Text(textColor = {230, 230, 230}, extent = {{-40, 10}, {40, -10}}, textString = "board")}),
    Documentation(info = "<html>
<p>Common base of the boards <code>MCU</code>, <code>RPi_Pico</code> and <code>MicroBit_v2</code>. It carries the parameters shared with the programmable core (<code>PartialMcuSettings</code>), the power-on thresholds (<code>ICore</code>, <code>VPowerOn</code>, <code>VPowerOff</code>) and the core itself: the <code>final</code> modifiers of its declaration form the board-core contract, written once here instead of once per board.</p>
<p>Each board extends this class and redeclares the core in the modifier of its <code>extends</code> clause (<code>redeclare Internal.McuCore core(final nPins = ..., final pinIds = ..., final pinCaps = ..., final boardProfile = ...)</code>, or <code>Internal.McuCoreRadio</code> for the boards with the on-board 2.4 GHz radio), then adds its own pins, connectors and supply, and wires them to <code>core</code>. The placement of the inherited core cannot be changed by a board (annotations are not inherited-modifiable): the boards that need their own position carry it in the annotation of their <code>redeclare</code>.</p>
</html>"));
end PartialBoard;
