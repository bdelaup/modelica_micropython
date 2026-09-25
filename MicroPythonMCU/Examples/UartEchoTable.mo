within MicroPythonMCU.Examples;

model UartEchoTable "Même montage que UartEcho, avec l'écho paramétré du mode Table : chaque octet repart dès qu'il est décodé"
  extends UartEcho(echo(comportement = MicroPythonMCU.Interfaces.UartBehaviour.Table));
  annotation(
    experiment(StopTime = 0.1, Interval = 5e-6),
    Documentation(info = "<html>
<p>Reprend <code>Examples.UartEcho</code> à l'identique — schéma, programme du microcontrôleur, appareil — et ne change qu'un paramètre : <code>echo.comportement = Table</code>. Le script <code>uart_echo_device.py</code> n'est alors plus utilisé ; c'est l'écho paramétré du composant (<code>echoEnabled</code>) qui répond.</p>
<p>La différence se voit en traçant <code>mcu.GP5.v</code> et <code>mcu.GP4.v</code> : ici chaque octet repart <strong>dès qu'il est décodé</strong>, bit de stop compris, avec environ une trame de décalage — sans attendre la fin de la ligne, comme un répéteur. Dans <code>UartEcho</code>, le script ne voit que des lignes entières et ne répond qu'après le saut de ligne.</p>
<p>Le programme du microcontrôleur relit la même ligne dans les deux cas : les deux exemples sont gardés côte à côte pour que chaque mode ait son scénario de non-régression.</p>
</html>"));
end UartEchoTable;
