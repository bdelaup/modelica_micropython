within MicroPythonMCU.Examples.I2c;

model NoPullUp "Même bus que MultiDevice, sans aucune résistance de tirage : les lignes restent basses et le maître lève OSError(ETIMEDOUT)"
  // Hérite de MultiDevice : même schéma, seuls les tirages sont retirés et le
  // programme du microcontrôleur change (il attend l'erreur au lieu des échanges).
  extends MultiDevice(mcu(scriptPath = Modelica.Utilities.Files.loadResource("modelica://MicroPythonMCU/Resources/Scripts/MCU/i2c_nopullup.py")), e1(usePullUp = false), e2(usePullUp = false));
  annotation(
    experiment(StopTime = 0.003, Interval = 1e-6),
    Documentation(info = "<html>
<p>Reprend <code>Examples.I2c.MultiDevice</code> à l'identique, mais <strong>aucun</strong> composant ne porte les résistances de tirage (<code>usePullUp = false</code> partout). C'est l'erreur de câblage la plus fréquente sur un vrai bus I2C.</p>
<p>En drain ouvert, personne ne force jamais une ligne à l'état haut : relâchées, SDA et SCL restent basses. Le maître le constate dès la vérification du bus libre qui précède le START : <code>writeto()</code> lève <code>OSError(ETIMEDOUT)</code> et <code>scan()</code> ne trouve personne. Le programme (<code>Scripts/MCU/i2c_nopullup.py</code>) allume <code>GP7</code> s'il observe bien ces deux symptômes.</p>
<p>Tracer <code>mcu.GP4.v</code> et <code>mcu.GP5.v</code> et comparer avec <code>MultiDevice</code> : ici les deux lignes restent à 0 V du début à la fin. Les tirages internes du RP2040 ne sont pas modélisés (trop faibles pour un vrai bus), cf. <code>requirements.md</code>.</p>
</html>"));
end NoPullUp;
