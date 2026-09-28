# Chaîne de pesée : HX711, pont de jauges, corps d'épreuve

!!! info "Référence interne"
    Cette page décrit le fonctionnement interne. Pour utiliser le composant (câblage, paramètres, exemples) : [Chaîne de pesée](../guide/peripheriques/pesee.md).

Cette page décrit **comment** est construite la chaîne de mesure d'une balance électronique (`Peripherals.Weighing`) et ce qu'elle suppose côté microcontrôleur : le coût temporel des accès aux broches, sans lequel le HX711 ne pourrait pas être lu. Le **pourquoi** (alternatives écartées, restrictions) est dans [`requirements.md`](https://gitlab.com/bdelaup/modelica_micropython3/-/blob/main/requirements.md), décisions « Coût temporel des accès GPIO » et « Chaîne de pesée ».

## 1. De la masse au nombre

```
masse (kg) ─→ Gain(g_n) ─→ Force ─→ LoadCell ─eps→ WheatstoneBridge ─A+/A-→ Hx711 ─PD_SCK/DOUT→ MCU ─I2C→ écran
                 poids       (MSL)   corps d'épreuve   4 jauges           CAN 24 bits
```

| Maillon | Composant | Entrée → sortie | Ordre de grandeur (défauts) |
|---|---|---|---|
| Poids | `Modelica.Mechanics.Translational.Sources.Force` (bibliothèque standard) | masse × `g_n` → force sur une bride | 1 kg → 9,81 N |
| Corps d'épreuve | `Weighing.LoadCell` | force (bride `flange`) → déformation `eps` | 5 kg → 500 µm/m |
| Pont de jauges | `Weighing.WheatstoneBridge` | `eps` → tension `S+ − S−` | 500 µm/m → 1 mV/V (4,3 mV sous 4,3 V) |
| Convertisseur | `Weighing.Hx711` | `A+ − A−` → code 24 bits sur `DOUT` | 1 mV/V à gain 128 → 2 147 484 |

Aucun de ces composants n'a de C ni de Python : ce sont des modèles Modelica lisibles, qu'un élève peut ouvrir.

- **`LoadCell` est quasi-statique** : un ressort sans masse, appuyé sur un point fixe (`flange.s = flange.f · sNom/FNom`), dont la déformation suit la force instantanément (`eps = epsNom · F/FNom`). Pas d'oscillation à la pose du poids : c'est légitime tant que la charge varie lentement devant la fréquence propre du capteur. L'icône rougit en surcharge (plus de 150 % de la portée).
- **`WheatstoneBridge` est un pont complet** : quatre `VariableResistor`, `R = R0·(1 ± K·eps)`, deux étirées et deux comprimées en diagonale. Sa sortie vaut `E·K·eps`, **proportionnelle à l'excitation `E`**. Le schéma interne (onglet Diagramme) montre les quatre jauges.

## 2. Le HX711

Le composant alimente le pont (`E+`, tension `AVDD`, `E−` à la masse) et mesure `A+ − A−`. La conversion est **ratiométrique** : elle divise par l'excitation mesurée, donc le code ne dépend pas de l'alimentation.

```
code = round( (A+ − A−) / (E+ − E−) × gain × 2^24 ),  borné à [−2^23, 2^23 − 1]
```

Soit, pour 1 kg sur le capteur de 5 kg : `2e-4 × 128 × 2^24 = 429 497` à gain 128. Un bruit gaussien optionnel s'y ajoute (`noiseLsb`, en LSB), tiré par `Modelica.Math.Random.Generators.Xorshift64star` : même graine, même suite de mesures.

La liaison avec le microcontrôleur suit la fiche technique. Tout est décrit par une machine d'états dans une section `algorithm`, pour que plusieurs `when` puissent modifier les mêmes variables :

| Événement | Effet |
|---|---|
| Fin de conversion (toutes les `1/rate`, 10 ou 80 par seconde) | code figé dans un registre à décalage, `DOUT` passe à 0 (« donnée prête ») |
| `tUpdate` avant une nouvelle donnée, si la précédente n'a pas été lue | `DOUT` remonte brièvement : chaque donnée est annoncée par un **front descendant**, celui que guette `Pin.irq(trigger=Pin.IRQ_FALLING)` du driver |
| Fronts montants 1 à 24 de `PD_SCK` | un bit sort sur `DOUT`, poids fort en tête |
| Fronts 25, 26 ou 27 | `DOUT` remonte ; le nombre d'impulsions fixe le gain de la conversion **suivante** : 128 (canal A), 32 (canal B), 64 (canal A) |
| `PD_SCK` haute plus de 60 µs | veille |
| Retour de `PD_SCK` à 0 après la veille | redémarrage : gain 128, première donnée après 4 conversions (400 ms à 10 par seconde) |

Côté électrique : `DOUT` est une sortie push-pull (`SignalVoltage` + `rOut`), `PD_SCK` une entrée avec une capacité `CIn` et un tirage bas. `CIn` rompt la dépendance entre le `when` du HX711 et celui du microcontrôleur, comme pour les périphériques série et I2C.

L'icône affiche le gain et le dernier code, un voyant cyan quand une donnée attend d'être lue, un voyant ambre en veille.

## 3. Lire le HX711 : le coût temporel des accès GPIO

Le driver utilisé, [`hx711_gpio.py`](https://github.com/robert-hh/hx711) de Robert Hammelrath, est copié **sans modification** dans `Resources/Scripts/MCU/`. Il produit l'horloge bit par bit (*bit-banging*) :

```python
for j in range(24 + self.GAIN):
    state = disable_irq()
    self.clock(True)
    self.clock(False)
    enable_irq(state)
    result = (result << 1) | self.data()
```

Il n'y a pas de `sleep` entre `clock(True)` et `clock(False)`. Si ces appels ne prenaient aucun temps simulé, les deux écritures tomberaient au même instant et Modelica ne verrait jamais l'impulsion. C'est pourquoi chaque accès à une broche occupe le processeur pendant **`MCU.gpioOpTime`** (5 µs par défaut, l'ordre de grandeur de MicroPython sur un RP2040). Avec 5 µs par accès, voici ce qui se passe :

```
t0        clock(True)   PD_SCK monte ; le HX711 pose le bit suivant sur DOUT
t0+5µs    clock(False)  PD_SCK redescend : impulsion de 5 µs (< 60 µs, pas de veille)
t0+10µs   data()        lit DOUT à t0+15µs, en fin d'accès
```

Détails dans [api-machine.md](../guide/api.md) (`gpioOpTime`, `pin(x)`, `disable_irq`/`enable_irq`/`idle`) et [cycle-de-vie.md](cycle-de-vie.md) (l'attente « processeur occupé », qu'un front d'entrée n'écourte pas).

## 4. Les exemples

- **`Examples.Weighing.Hx711Read`** : 1 kg posé, HX711 sans bruit, un `Peripherals.Display` pour les résultats. Le programme `hx711_read.py` lit à gain 128, passe à gain 64, met le HX711 en veille puis le réveille. Les codes lus sont exactement les codes théoriques : `128:429497 64:214748`, puis `reveil:429497`, car le circuit repart à gain 128.
- **`Examples.Weighing.KitchenScale`** : la balance complète.
  - **Écran** : Grove LCD RGB sur `GP4`/`GP5`.
  - **HX711** : sur `GP6` (`PD_SCK`) et `GP7` (`DOUT`), avec un bruit de 25 LSB.
  - **Bouton TARE** : sur `GP0`, avec un tirage de 10 kΩ vers 3,3 V. Le contact est une `VariableConductor` commandée par une `BooleanTable`, pas un interrupteur idéal.
  - **Charge posée** : une `TimeTable` donne la masse posée sur le plateau de 200 g.
  - **Programme `kitchen_scale.py`** : il tare au démarrage, convertit en grammes (429,497 points par gramme), affiche au gramme près et retare sur interruption.

  L'écran ne reçoit que les caractères qui changent. Chacun coûte une transaction I2C, soit environ 175 événements de simulation.

## 5. Ce que vérifient les scénarios

| Scénario | Vérifie |
|---|---|
| `verify_28_gpio_timing` | `on(); off()` sans `sleep` donne une impulsion de 5 µs vue par le circuit ; `ticks_us` avance ; une attente active voit le front attendu ; `disable_irq` diffère le callback |
| `verify_31_hx711` | codes exacts à gain 128 et 64, relus par le driver ; 25 puis 27 impulsions ; veille et réveil à gain 128 |
| `verify_32_kitchen_scale` | « 0 g », « 350 g », « Tare... » puis « 0 g », « 250 g » sur l'écran, à 1 g près |

## 6. Restrictions et coût de simulation

- Le canal B (gain 32) n'est pas câblé : il lit 0 V. Chaque conversion est un échantillon instantané de l'entrée, sans moyennage ni temps d'établissement après un changement de gain.
- La durée de `tUpdate` (10 µs) est supposée : la fiche technique ne la chiffre pas.
- **La balance complète est lente à simuler** : 46 s de calcul pour 7 s simulées, soit environ 40 000 événements.
  - **Écran** : environ 23 000 événements, pour 133 transactions I2C.
  - **HX711** : environ 16 000 événements. Le driver attend chaque donnée par des `sleep_ms(1)`, soit un réveil par milliseconde.
  - **Coût par événement** : environ 1,2 ms. Après chaque front, le solveur résout des transitoires RC de l'ordre de la nanoseconde. C'est une piste de performance générale de la bibliothèque, notée dans le TODO de `requirements.md`.
