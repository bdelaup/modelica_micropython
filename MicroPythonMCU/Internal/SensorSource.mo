within MicroPythonMCU.Internal;

block SensorSource "Source of an integrated sensor value: constant parameter, time table, or connector wired from the diagram - one parameterized block instead of the constant/table/internal-node pattern repeated by each board, cf. requirements.md decision \"Refactoring du socle des cartes\""
  parameter MicroPythonMCU.Interfaces.InputSource source = MicroPythonMCU.Interfaces.InputSource.Constant "How the value is driven: constant parameter, time table, or connector wired from the diagram" annotation(
    Dialog(group = "Source"));
  parameter Real k = 0 "Constant value, in the unit of the driven sensor" annotation(
    Dialog(group = "Source", enable = source == MicroPythonMCU.Interfaces.InputSource.Constant));
  parameter Real table[:, 2] = [0, 0] "Time table of the value (column 1 = time in s, column 2 = value)" annotation(
    Dialog(group = "Source", enable = source == MicroPythonMCU.Interfaces.InputSource.Table));
  Modelica.Blocks.Interfaces.RealInput u if source == MicroPythonMCU.Interfaces.InputSource.Connector "Value from the diagram, in the unit of the driven sensor" annotation(
    Placement(transformation(extent = {{-110, -10}, {-90, 10}})));
  Modelica.Blocks.Interfaces.RealOutput y "Value currently driven, in the unit of the driven sensor" annotation(
    Placement(transformation(extent = {{90, -10}, {110, 10}})));
protected
  Modelica.Blocks.Sources.Constant const(k = k) if source == MicroPythonMCU.Interfaces.InputSource.Constant "Constant value in constant mode" annotation(
    Placement(visible = false));
  Modelica.Blocks.Sources.RealExpression timeSource(y = time) "Simulation time for the table" annotation(
    Placement(visible = false));
  Modelica.Blocks.Tables.CombiTable1Ds tbl(table = table, extrapolation = Modelica.Blocks.Types.Extrapolation.HoldLastPoint) if source == MicroPythonMCU.Interfaces.InputSource.Table "Time table in table mode" annotation(
    Placement(visible = false));
equation
  if source == MicroPythonMCU.Interfaces.InputSource.Table then
    connect(timeSource.y, tbl.u);
    y = tbl.y[1];
  elseif source == MicroPythonMCU.Interfaces.InputSource.Connector then
    y = u;
  else
    y = const.y;
  end if;
  annotation(
    Icon(coordinateSystem(preserveAspectRatio = true, extent = {{-100, -100}, {100, 100}}), graphics = {Rectangle(lineColor = {20, 20, 20}, fillColor = {245, 245, 245}, fillPattern = FillPattern.Solid, extent = {{-90, 40}, {90, -40}}, radius = 6), Text(textColor = {70, 70, 70}, extent = {{-80, 26}, {80, 6}}, textString = "%source"), Text(textColor = {70, 70, 70}, extent = {{-80, 0}, {80, -22}}, textString = "k / table / in"), Text(textColor = {0, 0, 255}, extent = {{-150, 120}, {150, 100}}, textString = "%name")}),
    Documentation(info = "<html>
<p>Parameterizable source of a real value, the pattern shared by the integrated sensors of the boards: a <b>constant</b> parameter (<code>k</code>), a <b>time table</b> (<code>table</code>, interpolated and held after its last point), or a <b>connector</b> wired from the diagram (<code>u</code>, shown in this mode only). The value currently driven is <code>y</code>; the mode is chosen by <code>source</code> (<code>Interfaces.InputSource</code>), typically set by the board from its own parameter so that the boards keep their dialog and API. Boolean companion: <code>Internal.ButtonSource</code>.</p>
</html>"));
end SensorSource;
