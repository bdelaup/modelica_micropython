within MicroPythonMCU.Interfaces;

type InputSource = enumeration(
  Constant "Constant parameter value",
  Table "Time table (column 1 = time in s, column 2 = value)",
  Connector "Connector wired from the diagram") "Source of each button and integrated sensor value of the boards: constant parameter, time table, or connector wired from the diagram - cf. Internal.Sources.SensorSource and Internal.Sources.ButtonSource, and requirements.md decision \"Refactoring du socle des cartes\"";
