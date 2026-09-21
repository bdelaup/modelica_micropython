within MicroPythonMCU;
package Peripherals "Composants pouvant être connectés à MCU : électriques génériques (LED, ...) et périphériques pédagogiques pilotés via une liaison logique (Display, ...)"
  extends Modelica.Icons.Package;

  annotation(
    Documentation(info = "<html>
<p>Deux familles de composants cohabitent ici : des composants électriques génériques réutilisables dans un montage (ex. <code>LED</code>, câblée sur une broche <code>GPx</code> comme n'importe quel circuit) et des périphériques pédagogiques réagissant à un message logique (ex. <code>Display</code>, câblé sur <code>MCU.Display0</code>) via les connecteurs logiques causaux de <code>Interfaces</code> plutôt que <code>Modelica.Electrical.Analog</code> — cf. <code>requirements.md</code>, décision « Périphérique d'affichage pédagogique ». Tous ont un comportement fixe (pas programmables), à la différence de <code>MCU</code> — cf. la piste différée « intelligence des périphériques » dans <code>requirements.md</code>.</p>
</html>"));
end Peripherals;
