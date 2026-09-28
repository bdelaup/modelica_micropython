within MicroPythonMCU.Peripherals;

model UartTemperatureSensor "Serial temperature sensor: answers AT+TEMP with the measured value, and accepts a setpoint through SET"
  extends Internal.PartialUartDevice(
    respondEnabled = true,
    commandTable = "AT+TEMP=>TEMP={v1:.1f}\r\n|AT+ID=>SIM-TEMP-1\r\n|SET {o1}=>OK\r\n",
    responseDelay = 0.005,
    useValueInput = true,
    nIn = 1,
    nOut = 1,
    fixedValue = 20,
    periodicEnabled = false,
    scriptPath = Modelica.Utilities.Files.loadResource("modelica://MicroPythonMCU/Resources/Scripts/Device/temperature_sensor.py"));
  annotation(
    Icon(graphics = {Text(textColor = {255, 255, 255}, extent = {{-90, -22}, {90, -40}}, textString = "TEMP", textStyle = {TextStyle.Bold})}),
    Documentation(info = "<html>
<p>Device derived from <code>Internal.PartialUartDevice</code> by overriding parameters only — no logic coded again. It answers three commands, all ending with a line feed:</p>
<ul>
<li><code>AT+TEMP</code> → <code>TEMP=&lt;value&gt;</code>, where the value is the one present on the <code>valueIn[1]</code> connector when the question arrives. Connect a ramp, a thermal model, or any quantity of the model to it.</li>
<li><code>AT+ID</code> → a fixed identification string, like any real AT module.</li>
<li><code>SET &lt;number&gt;</code> → <code>OK</code>, and the received number comes out on <code>valueOut[1]</code>.</li>
</ul>
<p>This last command is what makes the device <strong>an actuator as much as a sensor</strong>: the microcontroller reads the measurement through the serial link and sends a setpoint back through the same link, which lets a control loop be closed inside the model, without any extra wire. See <code>Examples.Uart.Regulation</code>.</p>
<p><code>responseDelay</code> is 5 ms: a real device does not answer instantly, so the embedded program must wait for its reply rather than assume it has already arrived.</p>
</html>"));
end UartTemperatureSensor;
