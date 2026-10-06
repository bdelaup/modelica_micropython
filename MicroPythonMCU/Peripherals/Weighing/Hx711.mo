within MicroPythonMCU.Peripherals.Weighing;

model Hx711 "HX711 converter: 24-bit amplifier and ADC for a gauge bridge, PD_SCK/DOUT serial link"
  extends Internal.PartialSupplyPin(IQ = 1.5e-3);
  import Modelica.Units.SI;
  parameter Real rate(unit = "Hz") = 10 "Conversion rate (RATE pin of the chip: 10 or 80 samples per second)" annotation(
    Dialog(group = "Conversion"));
  parameter SI.Voltage AVDD = 4.3 "Excitation voltage of the bridge, E+ output (module supplied with 5 V) - with the VCC pin, at most VCC - VDropout" annotation(
    Dialog(group = "Conversion"));
  parameter Real noiseLsb = 0 "Conversion noise, standard deviation in LSB (0 = perfect, reproducible measurement)" annotation(
    Dialog(group = "Conversion"));
  parameter Integer seed = 711 "Noise seed: same seed, same sequence of measurements" annotation(
    Dialog(group = "Conversion", enable = noiseLsb > 0));
  parameter SI.Time tPowerDown = 60e-6 "PD_SCK held high longer than this: power-down" annotation(
    Dialog(group = "Timing"));
  parameter SI.Time tUpdate = 10e-6 "Time during which DOUT goes back up before each new data, when the previous one has not been read" annotation(
    Dialog(group = "Timing"));
  parameter Integer settlingConversions = 4 "Conversions discarded after power-up or wake-up (400 ms at 10 samples/s)" annotation(
    Dialog(group = "Timing"));
  parameter SI.Voltage VDropout = 0.1 "Dropout of the analog regulator of the module: with the VCC pin, AVDD is limited to VCC - VDropout" annotation(
    Dialog(tab = "Electrical", group = "Supply", enable = useSupplyPin));
  parameter SI.Voltage VOL = Interfaces.VOL "Low level of DOUT" annotation(
    Dialog(tab = "Electrical", group = "Levels"));
  parameter SI.Voltage VIH = Interfaces.VIH "Threshold above which an input reads high (PD_SCK)" annotation(
    Dialog(tab = "Electrical", group = "Levels"));
  parameter SI.Voltage VIL = Interfaces.VIL "Threshold below which an input reads low (PD_SCK)" annotation(
    Dialog(tab = "Electrical", group = "Levels"));
  parameter SI.Resistance ROut = Interfaces.ROut "Series resistance of the DOUT output" annotation(
    Dialog(tab = "Electrical", group = "Impedances"));

  Modelica.Electrical.Analog.Interfaces.PositivePin PD_SCK "Serial clock and power-down control (SCK pin of the module), driven by the microcontroller" annotation(
    Placement(transformation(origin = {-124, 30}, extent = {{-7, -7}, {7, 7}}), iconTransformation(origin = {-110, 30}, extent = {{-5, -5}, {5, 5}})));
  Modelica.Electrical.Analog.Interfaces.PositivePin DOUT "Serial data (DT pin of the module), read by the microcontroller" annotation(
    Placement(transformation(origin = {-124, -30}, extent = {{-7, -7}, {7, 7}}), iconTransformation(origin = {-110, -30}, extent = {{-5, -5}, {5, 5}})));
  Modelica.Electrical.Analog.Interfaces.PositivePin E_plus "Bridge excitation (+)" annotation(
    Placement(transformation(origin = {124, 45}, extent = {{-7, -7}, {7, 7}}), iconTransformation(origin = {110, 30}, extent = {{-5, -5}, {5, 5}})));
  Modelica.Electrical.Analog.Interfaces.PositivePin A_plus "Differential input of channel A (+), from S+ of the bridge" annotation(
    Placement(transformation(origin = {124, 15}, extent = {{-7, -7}, {7, 7}}), iconTransformation(origin = {110, 10}, extent = {{-5, -5}, {5, 5}})));
  Modelica.Electrical.Analog.Interfaces.NegativePin A_minus "Differential input of channel A (-), from S- of the bridge" annotation(
    Placement(transformation(origin = {124, -15}, extent = {{-7, -7}, {7, 7}}), iconTransformation(origin = {110, -10}, extent = {{-5, -5}, {5, 5}})));
  Modelica.Electrical.Analog.Interfaces.NegativePin E_minus "Bridge excitation (-), connected to the module ground" annotation(
    Placement(transformation(origin = {124, -45}, extent = {{-7, -7}, {7, 7}}), iconTransformation(origin = {110, -30}, extent = {{-5, -5}, {5, 5}})));

  // Public: they animate the icon and are used by the checks (protected
  // variables are missing from the simulation results).
  discrete Integer code(start = 0, fixed = true) "Last conversion result (two's complement, 24 bits)";
  discrete Integer gain(start = 128, fixed = true) "Gain of the current conversion (128 or 64 on channel A, 32 on channel B)";
  discrete Integer pulses(start = 0, fixed = true) "PD_SCK pulses received since the data became ready";
  discrete Boolean ready(start = false, fixed = true) "Data ready, not read yet: DOUT is at 0";
  discrete Boolean poweredDown(start = false, fixed = true) "Powered down (PD_SCK held high longer than tPowerDown)";
  SI.Voltage vIn "Differential voltage of channel A, A+ - A-";
  SI.Voltage vRef "Excitation voltage, E+ - E-: reference of the conversion (ratiometric measurement)";
protected
  // Gives the PD_SCK node a dynamic state, which breaks the mutual dependency
  // between the when of this component and that of the microcontroller (same role as the
  // input capacitance of the serial devices); against the 100 Ω of the
  // microcontroller, 1 nF gives a 0.1 µs rise, with no effect on the timing.
  parameter SI.Capacitance CIn = 1e-9 "Input capacitance of PD_SCK";
  parameter SI.Resistance RPullDown = 1e6 "Pull-down of PD_SCK to ground: disconnected pin or microcontroller not started yet = low level";
  constant Integer FULL = 16777216 "2^24";
  constant Integer HALF = 8388608 "2^23: most significant bit";

  Boolean sckHigh(start = false, fixed = true) "PD_SCK seen at high level";
  discrete Boolean doutHigh(start = true, fixed = true) "Level driven on DOUT (idle = high: no data ready)";
  discrete Integer shifter(start = 0, fixed = true) "Shift register: the most significant bit goes out on DOUT at each rising edge";
  discrete Integer nextGain(start = 128, fixed = true) "Gain of the next conversion, chosen by the number of pulses (25, 26 or 27)";
  discrete SI.Time tConv(start = settlingConversions/rate, fixed = true) "End of the next conversion";
  discrete SI.Time tSleep(start = 1e300, fixed = true) "Power-down instant if PD_SCK stays high (1e300: nothing scheduled)";
  discrete Integer rngState[2] "State of the noise generator (Xorshift64*)";
  discrete Real noise(start = 0, fixed = true) "Noise drawn for the last conversion, in LSB";
  discrete Real u(start = 0.5, fixed = true) "Uniform draw on ]0, 1] - working variable of the algorithm";

  Modelica.Electrical.Analog.Sources.SignalVoltage excitation "Bridge excitation (AVDD), between E+ and ground" annotation(
    Placement(visible = false, transformation(extent = {{-10, 60}, {10, 80}})));
  Modelica.Electrical.Analog.Sources.SignalCurrent excitationLoad "Current of the excitation, drawn from the supply rail (linear regulator of the module)" annotation(
    Placement(visible = false, transformation(extent = {{30, 60}, {50, 80}})));
  Modelica.Electrical.Analog.Sensors.VoltageSensor inSns "Differential input A+/A- (infinite impedance)" annotation(
    Placement(visible = false, transformation(extent = {{-10, 30}, {10, 50}})));
  Modelica.Electrical.Analog.Sensors.VoltageSensor refSns "Measurement of the excitation, reference of the conversion" annotation(
    Placement(visible = false, transformation(extent = {{-10, 0}, {10, 20}})));
  Modelica.Electrical.Analog.Sensors.VoltageSensor sckSns "Level of PD_SCK" annotation(
    Placement(visible = false, transformation(extent = {{-10, -30}, {10, -10}})));
  Modelica.Electrical.Analog.Basic.Capacitor cIn(C = CIn, v(start = 0, fixed = true)) "Input capacitance of PD_SCK" annotation(
    Placement(visible = false, transformation(extent = {{-50, -30}, {-30, -10}})));
  Modelica.Electrical.Analog.Basic.Resistor rPull(R = RPullDown) "Pull-down of PD_SCK to ground" annotation(
    Placement(visible = false, transformation(extent = {{-90, -30}, {-70, -10}})));
  Modelica.Electrical.Analog.Sources.SignalVoltage doutSrc "Push-pull output of DOUT" annotation(
    Placement(visible = false, transformation(extent = {{-90, -70}, {-70, -50}})));
  Modelica.Electrical.Analog.Basic.Resistor rOut(R = ROut) "Series resistance of DOUT" annotation(
    Placement(visible = false, transformation(extent = {{-50, -70}, {-30, -50}})));
initial algorithm
  rngState := Modelica.Math.Random.Generators.Xorshift64star.initialState(seed, 0);
equation
  connect(excitation.p, E_plus);
  connect(excitation.n, gnd);
  connect(excitationLoad.p, rail);
  connect(excitationLoad.n, gnd);
  excitation.v = if useSupplyPin then min(AVDD, max(vRail - VDropout, 0)) else AVDD;
  excitationLoad.i = -excitation.i "the bridge current comes from the supply";
  connect(E_minus, gnd);
  connect(inSns.p, A_plus);
  connect(inSns.n, A_minus);
  connect(refSns.p, E_plus);
  connect(refSns.n, E_minus);
  connect(sckSns.p, PD_SCK);
  connect(sckSns.n, gnd);
  connect(cIn.p, PD_SCK);
  connect(cIn.n, gnd);
  connect(rPull.p, PD_SCK);
  connect(rPull.n, gnd);
  connect(doutSrc.n, gnd);
  connect(doutSrc.p, rOut.p);
  connect(rOut.n, DOUT);
  vIn = inSns.v;
  vRef = refSns.v;
  sckHigh = sckSns.v > (VIL + VIH)/2 "logic threshold halfway, same approximation as the microcontroller";
  doutSrc.v = if doutHigh then vRail else VOL "high level: the supply voltage (VOH, or VCC with useSupplyPin)";
algorithm
  // An algorithm section (and not equations): several when clauses
  // assign the same variables, in the order in which they are written.

  // Update of the output register shortly before a new data: if the
  // previous one has not been read, DOUT briefly goes back up, and its return to 0
  // signals the new data (falling edge watched by Pin.irq()).
  when time >= tConv - tUpdate then
    if ready and not poweredDown then
      ready := false;
      doutHigh := true;
    end if;
  end when;

  // End of conversion: the measurement is latched in the register, DOUT goes to 0.
  // No update during a read in progress (bits already going out).
  when time >= tConv then
    if not poweredDown then
      tConv := tConv + 1/rate;
      if pulses == 0 or pulses >= 25 then
        gain := nextGain;
        if noiseLsb > 0 then
          (u, rngState) := Modelica.Math.Random.Generators.Xorshift64star.random(pre(rngState));
          noise := Modelica.Math.Distributions.Normal.quantile(u, 0, noiseLsb);
        end if;
        // Channel B (gain 32): not wired in this model, it reads 0 V.
        code := if gain == 32 then 0 else integer(floor(vIn*gain/vRef*FULL + noise + 0.5));
        code := max(-HALF, min(HALF - 1, code));
        shifter := if code < 0 then code + FULL else code;
        pulses := 0;
        ready := true;
        doutHigh := false;
      end if;
    end if;
  end when;

  // Rising edge of PD_SCK: a bit goes out on DOUT (most significant first). Pulses
  // 25 to 27 choose the gain of the next conversion, and DOUT
  // goes back up: the data is consumed.
  when sckHigh then
    tSleep := time + tPowerDown;
    if not poweredDown and (ready or pulses > 0) and pulses < 27 then
      pulses := pulses + 1;
      if pulses <= 24 then
        doutHigh := shifter >= HALF;
        shifter := mod(shifter*2, FULL);
      else
        ready := false;
        doutHigh := true;
        nextGain := if pulses == 25 then 128 elseif pulses == 26 then 32 else 64;
      end if;
    end if;
  end when;

  // PD_SCK held high too long: power-down.
  when time >= tSleep then
    if sckHigh then
      poweredDown := true;
      ready := false;
      doutHigh := true;
    end if;
  end when;

  // Falling edge: wake-up, the chip restarts as at power-up
  // (gain 128, settling conversions discarded).
  when not sckHigh then
    tSleep := 1e300;
    if poweredDown then
      poweredDown := false;
      gain := 128;
      nextGain := 128;
      pulses := 0;
      tConv := time + settlingConversions/rate;
    end if;
  end when;
  annotation(
    Icon(coordinateSystem(preserveAspectRatio = true, extent = {{-100, -100}, {100, 100}}, initialScale = 0.2), graphics = {Rectangle(fillColor = {30, 110, 60}, fillPattern = FillPattern.Solid, extent = {{-104, 56}, {104, -56}}), Rectangle(fillColor = {30, 30, 30}, fillPattern = FillPattern.Solid, extent = {{-40, 30}, {40, -12}}), Text(textColor = {255, 255, 255}, extent = {{-38, 26}, {38, 6}}, textString = "HX711", textStyle = {TextStyle.Bold}), Text(textColor = {200, 200, 200}, extent = {{-38, 4}, {38, -10}}, textString = "24 bits"), Text(textColor = {255, 255, 255}, extent = {{-40, -18}, {40, -34}}, textString = DynamicSelect("gain 128", "gain " + String(gain))), Text(textColor = {255, 255, 255}, extent = {{-40, -36}, {40, -52}}, textString = DynamicSelect("", String(code))), Ellipse(fillColor = DynamicSelect({60, 60, 60}, if ready then {60, 210, 255} else {60, 60, 60}), fillPattern = FillPattern.Solid, lineColor = {30, 30, 30}, extent = {{-60, -38}, {-48, -50}}), Ellipse(fillColor = DynamicSelect({60, 60, 60}, if poweredDown then {255, 180, 60} else {60, 60, 60}), fillPattern = FillPattern.Solid, lineColor = {30, 30, 30}, extent = {{48, -38}, {60, -50}}), Text(textColor = {255, 255, 255}, extent = {{-98, 38}, {-66, 22}}, textString = "SCK", horizontalAlignment = TextAlignment.Left), Text(textColor = {255, 255, 255}, extent = {{-98, -22}, {-66, -38}}, textString = "DT", horizontalAlignment = TextAlignment.Left), Text(textColor = {255, 255, 255}, extent = {{66, 38}, {98, 22}}, textString = "E+", horizontalAlignment = TextAlignment.Right), Text(textColor = {255, 255, 255}, extent = {{66, 18}, {98, 2}}, textString = "A+", horizontalAlignment = TextAlignment.Right), Text(textColor = {255, 255, 255}, extent = {{66, -2}, {98, -18}}, textString = "A-", horizontalAlignment = TextAlignment.Right), Text(textColor = {255, 255, 255}, extent = {{66, -22}, {98, -38}}, textString = "E-", horizontalAlignment = TextAlignment.Right), Text(visible = useGroundPin, extent = {{7, -56}, {47, -64}}, textString = "GND", horizontalAlignment = TextAlignment.Left), Text(textColor = {0, 0, 255}, extent = {{-150, 80}, {150, 60}}, textString = "%name")}),
    Diagram(coordinateSystem(preserveAspectRatio = true, extent = {{-100, -100}, {100, 100}})),
    Documentation(info = "<html>
<p>The <strong>HX711</strong> (Avia Semiconductor) is the converter of electronic scales: a programmable-gain amplifier followed by a 24-bit analog-to-digital converter, designed to read a gauge bridge directly. This model reproduces its behaviour as seen from the microcontroller, based on the datasheet.</p>
<h4>Bridge side</h4>
<p>The module supplies the bridge through <code>E+</code>/<code>E−</code> (voltage <code>AVDD</code>) and measures the differential voltage between <code>A+</code> and <code>A−</code>. The conversion is <strong>ratiometric</strong>: the result depends on the ratio between the bridge output and its excitation, not on the value of the supply.</p>
<p><code>code = vIn · gain / vRef · 2<sup>24</sup></code>, rounded and clamped to [−2<sup>23</sup>, 2<sup>23</sup>−1] (full scale: ±AVDD/(2·gain), i.e. ±17 mV at gain 128).</p>
<h4>Microcontroller side</h4>
<ul>
<li>Every <code>1/rate</code> seconds, a new data is ready: <code>DOUT</code> goes to 0. If the previous one has not been read, <code>DOUT</code> first goes back up briefly (<code>tUpdate</code>), so that each new data is announced by a falling edge.</li>
<li>Each rising edge of <code>PD_SCK</code> shifts a bit out on <code>DOUT</code>, most significant first. After the 24 data bits, 1 to 3 extra pulses choose the gain of the <em>next</em> conversion: 25 pulses → 128 (channel A), 26 → 32 (channel B), 27 → 64 (channel A). <code>DOUT</code> then goes back to 1.</li>
<li><code>PD_SCK</code> held high for more than 60 µs powers the chip down. When it returns to 0, the chip restarts as at power-up: gain 128, and first data after 4 conversions (400 ms at 10 samples/s).</li>
</ul>
<p>The microcontroller therefore drives <code>PD_SCK</code> bit by bit (<em>bit-banging</em>). Its pin accesses must take simulated time (parameter <code>MCU.gpioOpTime</code>, 5 µs by default): otherwise, the pulses would have a zero duration.</p>
<h4>Simplifications</h4>
<ul>
<li>Channel B (inputs B+/B−, gain 32) is not wired: it reads 0 V.</li>
<li>Each conversion is an instantaneous sample of the input (no averaging over the period), with no settling time after a gain change.</li>
<li>The noise (<code>noiseLsb</code>, standard deviation in LSB) is Gaussian and reproducible: the <code>seed</code> fixes the sequence of draws.</li>
</ul>
<p>The icon shows the gain and the last converted code. The cyan light signals a data ready, the amber light the power-down.</p>
</html>"));
end Hx711;
