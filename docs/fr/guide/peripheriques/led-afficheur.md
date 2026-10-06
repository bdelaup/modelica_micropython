# LED et afficheurs pédagogiques

Des composants simples pour voir ce que fait le programme : une LED dont l'icône s'éclaire selon le courant qui la traverse, et des afficheurs de texte reliés au microcontrôleur par une liaison logique (un 20x2, et deux grands écrans qui se remplissent ligne après ligne).

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

## Afficheurs : `Display`, `Display4x32`, `Display8x32`

Trois afficheurs de texte qui montrent **sur leur icône** les messages envoyés par le programme avec `machine.Display(0).write(...)`. Ils servent à afficher un résultat sans avoir à monter une vraie liaison série ou I2C. Les trois se programment et se câblent de la même façon ; ils ne diffèrent que par leur taille et la façon dont les messages s'y succèdent.

| Composant | Taille | Défilement |
|---|---|---|
| `Peripherals.Display` | 2 lignes de 20 caractères | Chaque message s'affiche en **ligne 1** ; le précédent descend en ligne 2 |
| `Peripherals.Display4x32` | 4 lignes de 32 caractères | Comme un terminal : chaque message s'écrit **sous la dernière ligne écrite** ; une fois l'écran plein, tout remonte d'une ligne et le nouveau message prend la ligne du bas |
| `Peripherals.Display8x32` | 8 lignes de 32 caractères | Comme `Display4x32` |

Les grands écrans sont pratiques pour suivre un historique de mesures ou d'états sans ouvrir le journal.

<!-- ILLUSTRATION display-icone : icône de Peripherals.Display affichant deux messages (fin de simulation de Display.Demo) (cf. docs/ILLUSTRATIONS.md) -->
<!-- ILLUSTRATION grands-ecrans : icônes de Display4x32 et Display8x32 en fin de simulation de Display.Large (cf. docs/ILLUSTRATIONS.md) -->

```python
from machine import Display
import time

ecran = Display(0)
for i in range(10):
    ecran.write("Mesure %d : %d mV" % (i, 1650 + 10 * i))
    time.sleep_ms(100)
```

À la fin, le 20x2 montre les deux dernières mesures (la plus récente en haut), le 4x32 les mesures 6 à 9 et le 8x32 les mesures 2 à 9 (la plus récente en bas).

### Connecteur

| Connecteur | Rôle |
|---|---|
| `displayLink` | À relier à `mcu.Display0`. C'est une **liaison logique** : elle porte le texte directement, sans tension ni forme d'onde |

### Câblage

Un fil, de la sortie `DISPLAY` du microcontrôleur (`mcu.Display0`, au-dessus de l'icône du `MCU`) à l'entrée de l'afficheur (`displayLink`, à sa gauche). Pas de masse ni d'alimentation à câbler pour l'afficheur : la liaison est logique. Le `MCU`, lui, garde sa masse.

Plusieurs afficheurs peuvent être reliés au même `Display0` : ils reçoivent tous chaque message. C'est ce que fait `Display.Large`, avec un 20x2 (`display`), un 4x32 (`screen4`) et un 8x32 (`screen8`) :

![Schéma de Display.Large : la sortie DISPLAY du MCU reliée aux trois afficheurs, la broche GND du MCU à la masse](../../images/grands-ecrans-cablage.png){ width="440" }

En texte, dans la vue *Text* d'OMEdit : `connect(mcu.Display0, display.displayLink);`, et de même pour `screen4` et `screen8`.

### Paramètre

`Display` n'a pas de paramètre. Les deux grands écrans en ont un :

| Paramètre | Défaut | Rôle |
|---|---|---|
| `logReceived` | `true` | Imprime aussi chaque message reçu dans le journal de simulation. À mettre à `false` quand plusieurs afficheurs partagent `Display0`, pour ne pas avoir chaque message en double |

### Comportement

- Un message est une ligne envoyée par `write()`, qui s'utilise comme `print()` (voir [l'API](../api.md#machinedisplay)) : `write("a\nb")` envoie deux messages. Plusieurs messages envoyés au même instant (sans `sleep()` entre eux) arrivent tous, dans l'ordre : le 20x2 montre les deux derniers, les grands écrans les écrivent l'un sous l'autre.
- Un message écrit dès le début du programme, avant le premier `sleep()` (t = 0), s'affiche aussi. Les grands écrans démarrent vides : le premier message prend la ligne du haut.
- Un message plus long que la ligne (20 ou 32 caractères) est coupé sur l'icône, mais apparaît en entier dans le journal de simulation. Message limité à 128 caractères.
- Caractères affichables : lettres sans accent, chiffres et espace, plus `! ' , - . ?` sur le 20x2 et `! " # & ' ( ) * + , - . / : < = > ? _` sur les grands écrans. Les autres s'affichent comme des espaces.
- La liaison est instantanée : le message arrive au moment même du `write()`, sans délai de transmission. Écriture seule : l'afficheur ne répond rien.
- Sur les grands écrans, le texte de l'icône est enregistré dans `textCode` (codes ASCII, ligne `i`, colonne `j` à l'indice `(i - 1)*32 + j`) et le nombre de lignes écrites dans `filled` : on les retrouve dans les résultats.

Pour un afficheur relié par une **vraie** liaison électrique, voir `UartLcd20x2` ([Appareils série](uart.md)) ou l'écran Grove LCD RGB ([Périphériques I2C](i2c.md)).

Exemples : `Display.Demo` (un 20x2, deux messages), `Display.Large` (les trois afficheurs sur la même liaison), `Weighing.Hx711Read`.
