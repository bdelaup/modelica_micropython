# LED et afficheur pédagogique

Deux composants simples pour voir ce que fait le programme : une LED dont l'icône s'éclaire selon le courant qui la traverse, et un afficheur de texte relié au microcontrôleur par une liaison logique.

## `Peripherals.LED`

Une diode électroluminescente à deux broches. Électriquement, c'est une diode à caractéristique exponentielle lisse, avec une tension de seuil de 1,8 V par défaut (LED rouge). Son icône passe de `colorOff` à `colorOn` selon le courant moyen qui la traverse : on voit la LED s'allumer en rejouant le résultat dans OMEdit, et un PWM la fait paraître plus ou moins lumineuse.

<!-- ILLUSTRATION led-icones : icône de Peripherals.LED éteinte et allumée, côte à côte (cf. docs/ILLUSTRATIONS.md) -->

### Connecteurs

| Connecteur | Rôle |
|---|---|
| `p` | Anode, côté broche du microcontrôleur |
| `n` | Cathode, côté masse |

### Paramètres

| Paramètre | Défaut | Rôle |
|---|---|---|
| `Vknee` | 1,8 V | Tension de seuil de la diode. Environ 2 V pour une LED jaune ou verte, 3 V pour une bleue ou une blanche |
| `IMax` | 3,5 mA | Courant pour lequel l'icône atteint sa pleine couleur. **Échelle d'affichage seulement**, pas une limite physique. La valeur par défaut correspond à une LED alimentée par une broche à travers 330 Ω |
| `colorOn` | `{255, 0, 0}` | Couleur RGB de l'icône à pleine luminosité |
| `colorOff` | `{90, 25, 25}` | Couleur RGB de l'icône éteinte |

### Câblage type

Comme sur un vrai montage, une résistance limite le courant : `GP0` → résistance de 330 Ω → `p` de la LED, `n` → masse. Brancher la LED directement sur la broche fonctionne (la résistance de sortie de 100 Ω limite le courant), mais n'est pas représentatif d'un montage réel.

Le courant se trace sous `led0.p.i` (pour une LED nommée `led0`).

## `Peripherals.Display`

Un afficheur de texte de 2 lignes de 20 caractères, qui affiche **sur son icône** les messages envoyés par le programme avec `machine.Display(0).write(...)`. Il sert à afficher un résultat sans avoir à monter une vraie liaison série ou I2C.

<!-- ILLUSTRATION display-icone : icône de Peripherals.Display affichant deux messages (fin de simulation de DisplayDemo) (cf. docs/ILLUSTRATIONS.md) -->

```python
from machine import Display
import time

ecran = Display(0)
ecran.write("Bonjour")
time.sleep(1)
ecran.write("Ca marche")      # "Bonjour" descend en ligne 2
```

### Connecteur

| Connecteur | Rôle |
|---|---|
| `displayLink` | À relier à `mcu.Display0`. C'est une **liaison logique** : elle porte le texte directement, sans tension ni forme d'onde |

Le composant n'a pas de paramètre.

### Comportement

- Chaque message s'affiche en **ligne 1** ; le message précédent descend en **ligne 2**.
- Au-delà de 20 caractères, le message est coupé sur l'icône, mais apparaît en entier dans le journal de simulation (chaque message y est aussi imprimé).
- Caractères affichables : lettres sans accent, chiffres, espace et `! ' , - . ?`. Les autres s'affichent comme des espaces. Message limité à 128 caractères.
- La liaison est instantanée : le message arrive au moment même du `write()`, sans délai de transmission. Écriture seule : l'afficheur ne répond rien.

Pour un afficheur relié par une **vraie** liaison électrique, voir `UartLcd20x2` ([Appareils série](uart.md)) ou l'écran Grove LCD RGB ([Périphériques I2C](i2c.md)).

Exemples : `DisplayDemo`, `Weighing.Hx711Read`.
