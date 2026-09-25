within MicroPythonMCU.Peripherals;

model UartLcd20x2 "Afficheur série 20x2 : affiche sur son icône les lignes reçues sur sa broche RX, avec défilement"
  extends Internal.PartialUartDevice(
    final comportement = Interfaces.UartBehaviour.Table,
    respondEnabled = false,
    echoEnabled = false,
    periodicEnabled = false);
  extends Internal.TwoLineTextIcon;
equation
  when {initial(), change(eventSeq)} then
    line2CharCode = pre(line1CharCode) "l'ancienne ligne 1 descend, comme sur un afficheur qui décale son historique";
    line1CharCode = Internal.StringToCharCodes(lastRx, Interfaces.DISPLAY_COLS) "la ligne qui vient d'être reçue occupe la ligne 1";
  end when;
  annotation(
    Documentation(info = "<html>
<p>Le pendant <strong>électriquement réel</strong> de <code>Peripherals.Display</code>. Là où <code>Display</code> reçoit son texte d'un coup par une liaison logique causale (<code>machine.Display</code>, sans bauds simulés), celui-ci décode une vraie trame série arrivant sur sa broche <code>RX</code>, bit par bit, à son propre débit. Un désaccord de débit avec le microcontrôleur se voit donc directement à l'écran, en caractères faux.</p>
<p>Côté programme embarqué, il suffit d'écrire une ligne terminée par un saut de ligne : c'est lui qui valide la ligne et déclenche l'affichage, exactement comme le <code>terminator</code> d'une commande.</p>
<p>Il hérite de deux classes : <code>Internal.PartialUartDevice</code> pour toute la mécanique série, et <code>Internal.TwoLineTextIcon</code> pour le rendu du texte — la même icône 20x2 que <code>Display</code>, écrite une seule fois. Au-delà de 20 caractères, la ligne est tronquée à l'écran ; le texte complet reste lisible dans le journal de simulation.</p>
<p>Écriture seule : l'appareil ne répond rien et n'émet jamais, sa broche <code>TX</code> reste au repos. Elle existe quand même, comme sur un module série réel.</p>
</html>"));
end UartLcd20x2;
