within MicroPythonMCU.Examples;
model GpioTiming "Coût temporel des accès GPIO (gpioOpTime) : impulsion on()/off() sans sleep, rafale bit-bang, attente active, IRQ masquée, idle()"
  extends Modelica.Icons.Example;
  MCU mcu(scriptPath = Modelica.Utilities.Files.loadResource("modelica://MicroPythonMCU/Resources/Verification/gpio_timing.py")) "scriptPath = Verification/gpio_timing.py ; gpioOpTime par défaut (5 µs)" annotation(
    Placement(transformation(origin = {0, 0}, extent = {{-50, -50}, {50, 50}})));
  Modelica.Electrical.Analog.Basic.Ground ground annotation(
    Placement(transformation(origin = {0, -100}, extent = {{-15, -15}, {15, 15}})));
  Modelica.Electrical.Analog.Basic.Resistor rLoad(R = 10e3) "Charge de GP0, la broche des impulsions" annotation(
    Placement(transformation(origin = {-90, 25}, extent = {{-15, -15}, {15, 15}})));
  Modelica.Electrical.Analog.Sources.SignalVoltage inSrc "Pilote GP1 : l'entrée guettée par l'attente active" annotation(
    Placement(transformation(origin = {-90, -20}, extent = {{15, -15}, {-15, 15}})));
  Modelica.Blocks.Sources.Step inStep(height = 3.3, startTime = 0.3) "Front montant sur GP1 à t = 300 ms" annotation(
    Placement(transformation(origin = {-90, 70}, extent = {{-15, -15}, {15, 15}})));
  Modelica.Electrical.Analog.Sources.SignalVoltage irqSrc "Pilote GP3 : l'entrée de l'IRQ" annotation(
    Placement(transformation(origin = {-90, -60}, extent = {{15, -15}, {-15, 15}})));
  Modelica.Blocks.Sources.Step irqStep(height = 3.3, startTime = 0.45) "Front montant sur GP3 à t = 450 ms, pendant le masquage des IRQ" annotation(
    Placement(transformation(origin = {-140, -60}, extent = {{-15, -15}, {15, 15}})));
  Boolean gp0High = mcu.GP0.v > 1.65 "GP0 vue par un observateur externe";
  discrete Modelica.Units.SI.Time tRise(start = 0, fixed = true) "Dernier front montant de GP0";
  discrete Modelica.Units.SI.Time pulseWidth(start = 0, fixed = true) "Largeur de la dernière impulsion de GP0, mesurée côté Modelica";
  discrete Integer pulseCount(start = 0, fixed = true) "Nombre d'impulsions vues sur GP0";
  discrete Modelica.Units.SI.Time tFlag(start = -1, fixed = true) "Instant où GP2 monte : sortie de l'attente active";
  discrete Modelica.Units.SI.Time tIrq(start = -1, fixed = true) "Instant où GP4 monte : exécution du callback IRQ";
equation
  when gp0High then
    tRise = time;
    pulseCount = pre(pulseCount) + 1;
  end when;
  when not gp0High then
    pulseWidth = time - pre(tRise);
  end when;
  when mcu.GP2.v > 1.65 then
    tFlag = time;
  end when;
  when mcu.GP4.v > 1.65 then
    tIrq = time;
  end when;
  connect(mcu.GND, ground.p) annotation(
    Line(points = {{0, -39}, {0, -85}}, color = {0, 0, 255}));
  connect(mcu.GP0, rLoad.n) annotation(
    Line(points = {{-31, 25}, {-75, 25}}, color = {0, 0, 255}));
  connect(rLoad.p, ground.p) annotation(
    Line(points = {{-105, 25}, {-157, 25}, {-157, -85}, {0, -85}}, color = {0, 0, 255}));
  connect(inStep.y, inSrc.v) annotation(
    Line(points = {{-90, 54}, {-90, -8}}, color = {0, 0, 127}));
  connect(mcu.GP1, inSrc.p) annotation(
    Line(points = {{-31, 10}, {-31, -20}, {-75, -20}}, color = {0, 0, 255}));
  connect(inSrc.n, ground.p) annotation(
    Line(points = {{-105, -20}, {-115, -20}, {-115, -85}, {0, -85}}, color = {0, 0, 255}));
  connect(irqStep.y, irqSrc.v) annotation(
    Line(points = {{-124, -60}, {-110, -60}, {-110, -40}, {-90, -40}, {-90, -48}}, color = {0, 0, 127}));
  connect(mcu.GP3, irqSrc.p) annotation(
    Line(points = {{-31, -25}, {-50, -25}, {-50, -60}, {-75, -60}}, color = {0, 0, 255}));
  connect(irqSrc.n, ground.p) annotation(
    Line(points = {{-105, -60}, {-115, -60}, {-115, -85}, {0, -85}}, color = {0, 0, 255}));
  annotation(
    Diagram(coordinateSystem(extent = {{-170, -120}, {80, 100}})),
    experiment(StopTime = 0.6, Interval = 0.001, StartTime = 0, Tolerance = 1e-06),
    Documentation(info = "<html>
<p>Scénario de vérification 28 : le <strong>coût temporel des accès GPIO</strong>. Chaque <code>Pin.value()</code>, <code>on()</code>, <code>off()</code> ou <code>pin(x)</code> occupe le processeur pendant <code>mcu.gpioOpTime</code> (5 µs par défaut, l'ordre de grandeur de MicroPython sur RP2040) : deux écritures sans <code>sleep()</code> entre elles donnent donc une vraie impulsion, visible par le circuit. C'est ce qui permet le <em>bit-banging</em> (driver HX711, par exemple).</p>
<p>Le script <code>Verification/gpio_timing.py</code> enchaîne, à des instants fixés :</p>
<ul>
<li>t = 100 ms : <code>on()</code> puis <code>off()</code> sur GP0 → une impulsion de 5 µs (<code>pulseWidth</code>, mesurée ici côté Modelica) ;</li>
<li>t = 200 ms : 10 impulsions par <code>out(1); out(0)</code> → 11 impulsions au total (<code>pulseCount</code>), et le script mesure 100 µs par <code>ticks_us()</code> ;</li>
<li>t = 280 ms : attente active <code>while not inp(): pass</code>, sans <code>sleep()</code> : le temps avance de 5 µs par lecture, et le front de GP1 à t = 300 ms est vu → GP2 monte juste après (<code>tFlag</code>) ;</li>
<li>t = 400 ms : <code>disable_irq()</code> ; le front de GP3 à t = 450 ms ne déclenche pas le callback tout de suite, il s'exécute à <code>enable_irq()</code>, à t = 500 ms (<code>tIrq</code>, GP4) ;</li>
<li>enfin <code>idle()</code> rend la main à la milliseconde ronde suivante.</li>
</ul>
<p>Le script affiche <code>dt=100 id=0</code> sur la liaison <code>Display0</code> (durée de la rafale en µs, reste de <code>ticks_us()</code> modulo 1000 après <code>idle()</code>).</p>
</html>"));
end GpioTiming;
