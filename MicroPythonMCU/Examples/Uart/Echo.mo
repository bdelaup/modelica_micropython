within MicroPythonMCU.Examples.Uart;

model Echo "Même montage que EchoPy, avec l'écho paramétré du mode Table : chaque octet repart dès qu'il est décodé"
  // Hérite de EchoPy et ne change que le mode : le schéma n'est écrit qu'une fois, et
  // les deux exemples restent identiques par construction. C'est la variante Py qui
  // porte le schéma complet, pour que le chemin du script y apparaisse comme une
  // valeur propre du composant dans le dialogue de paramètres.
  extends EchoPy(echo(comportement = MicroPythonMCU.Interfaces.UartBehaviour.Table));
  annotation(
    experiment(StopTime = 0.1, Interval = 5e-6),
    Documentation(info = "<html>
<p>Reprend <code>Examples.Uart.EchoPy</code> à l'identique — schéma, programme du microcontrôleur, appareil — et ne change qu'un paramètre : <code>echo.comportement = Table</code>. Le script <code>Device/echo.py</code> n'est alors plus utilisé ; c'est l'écho paramétré du composant (<code>echoEnabled</code>) qui répond.</p>
<p>La différence se voit en traçant <code>mcu.GP5.v</code> et <code>mcu.GP4.v</code> : ici chaque octet repart <strong>dès qu'il est décodé</strong>, bit de stop compris, avec environ une trame de décalage — sans attendre la fin de la ligne, comme un répéteur. Dans <code>EchoPy</code>, le script ne voit que des lignes entières et ne répond qu'après le saut de ligne.</p>
<p>Le programme du microcontrôleur relit la même ligne dans les deux cas : les deux exemples sont gardés côte à côte pour que chaque mode ait son scénario de non-régression.</p>
</html>"));
end Echo;
