within MicroPythonMCU.Internal.Sources;

block ButtonSource "Source of a button state: constant state, time table, or connector wired from the diagram - Boolean companion of Internal.Sources.SensorSource (the table holds 0 released / 1 pressed)"
  parameter MicroPythonMCU.Interfaces.InputSource source = MicroPythonMCU.Interfaces.InputSource.Connector "How the button is driven: connector wired from the diagram, time table, or constant state" annotation(
    Dialog(group = "Source"));
  parameter Boolean pressed = false "State in constant mode (true = pressed)" annotation(
    Dialog(group = "Source", enable = source == MicroPythonMCU.Interfaces.InputSource.Constant),
    choices(checkBox = true));
  parameter Real table[:, 2] = [0, 0] "Time table of the button (column 1 = time in s, column 2 = 0 released / 1 pressed)" annotation(
    Dialog(group = "Source", enable = source == MicroPythonMCU.Interfaces.InputSource.Table));
  Modelica.Blocks.Interfaces.BooleanInput u if source == MicroPythonMCU.Interfaces.InputSource.Connector "State from the diagram (true = pressed)" annotation(
    Placement(transformation(extent = {{-110, -10}, {-90, 10}})));
  Modelica.Blocks.Interfaces.BooleanOutput y "State currently driven (true = pressed)" annotation(
    Placement(transformation(extent = {{90, -10}, {110, 10}})));
protected
  Modelica.Blocks.Sources.BooleanConstant const(k = pressed) if source == MicroPythonMCU.Interfaces.InputSource.Constant "Constant state in constant mode" annotation(
    Placement(visible = false));
  Modelica.Blocks.Sources.RealExpression timeSource(y = time) "Simulation time for the table" annotation(
    Placement(visible = false));
  Modelica.Blocks.Tables.CombiTable1Ds tbl(table = table, extrapolation = Modelica.Blocks.Types.Extrapolation.HoldLastPoint) if source == MicroPythonMCU.Interfaces.InputSource.Table "Time table in table mode" annotation(
    Placement(visible = false));
  Modelica.Blocks.Math.RealToBoolean conv(threshold = 0.5) if source == MicroPythonMCU.Interfaces.InputSource.Table "Converts the table output to boolean" annotation(
    Placement(visible = false));
equation
  if source == MicroPythonMCU.Interfaces.InputSource.Table then
    connect(timeSource.y, tbl.u);
    connect(tbl.y[1], conv.u);
    y = conv.y;
  elseif source == MicroPythonMCU.Interfaces.InputSource.Connector then
    y = u;
  else
    y = const.y;
  end if;
  annotation(
    Icon(coordinateSystem(preserveAspectRatio = true, extent = {{-100, -100}, {100, 100}}), graphics = {Rectangle(lineColor = {20, 20, 20}, fillColor = {245, 245, 245}, fillPattern = FillPattern.Solid, extent = {{-90, 40}, {90, -40}}, radius = 6), Text(textColor = {70, 70, 70}, extent = {{-80, 26}, {80, 6}}, textString = "%source"), Text(textColor = {70, 70, 70}, extent = {{-80, 0}, {80, -22}}, textString = "pressed / table / in"), Text(textColor = {0, 0, 255}, extent = {{-150, 120}, {150, 100}}, textString = "%name")}),
    Documentation(info = "<html>
<p>Parameterizable source of a button state, the pattern shared by the buttons of the boards: a <b>constant</b> state (<code>pressed</code>), a <b>time table</b> (<code>table</code>, 0 released / 1 pressed, converted to boolean at 0.5), or a <b>connector</b> wired from the diagram (<code>u</code>, shown in this mode only). The state currently driven is <code>y</code>. Real companion: <code>Internal.Sources.SensorSource</code>.</p>
</html>"));
end ButtonSource;
