# La carte micro:bit v2

Référence interne : architecture de `MicroBit_v2` (carte BBC micro:bit v2,
nRF52833), de son module `microbit` dans le shim et du moteur de matrice LED
côté C. Guide utilisateur : « La carte micro:bit » du guide. Décisions et
historique : `requirements.md`, décision « MCU micro:bit v2 ».

## Vue d'ensemble

`MicroBit_v2.mo` est généré par `tools/make_microbit.py` (mêmes principes que
`tools/make_pico.py` — ne pas éditer le `.mo` à la main) et contient :

- le cœur `Internal.McuCore` (32 entrées de table : 19 broches edge, 5 lignes
  de la matrice, 8 capteurs), profil de carte `"microbit"` ;
- la **matrice LED** : 25 `Peripherals.LED` câblées entre les ponts de broches
  des lignes (anode) et des colonnes (cathode), publiques pour l'icône
  `DynamicSelect` et les résultats ;
- les **boutons A/B** : entrées logiques `buttonA`/`buttonB` à câbler
  (interrupteur idéal vers la masse, tirage externe 10 kΩ vers le rail, comme
  la carte — cf. `verify_74` pour le choix de `Goff = 1e-9`, la fuite par défaut
  de `IdealClosingSwitch` de la MSL étant de 100 kΩ) ;
- les **capteurs intégrés** : chaque capteur a un paramètre constant et, si
  activé, un connecteur d'entrée qui le remplace (patron MSL : connecteur
  conditionnel + `Constant` conditionnelle vers un nœud interne, puis équation
  sur le `v` de la `SignalVoltage` — licite, même forme que `tempSensor` de
  `McuCore`) ;
- les **tirages edge** comme sur la carte : 10 MΩ sur les anneaux P0/P1/P2,
  4,7 kΩ sur P19/P20 (I2C) ;
- l'**alimentation** : USB 5 V → `Internal.Rt6150` (`VOut = VTgt` = 3,0 V,
  rail de la micro:bit v2) → broche `3V` ; l'enable du régulateur est câblé à
  l'entrée VIN (sur le rail, il ne démarrerait jamais — boucle morte) ;
- le fichier `.mo` généré fait ~530 lignes et 130 `connect()`.

## Le moteur de matrice (`Resources/Include/pyruntime/pyruntime_matrix.c`)

La matrice 5×5 est multiplexée sur 10 GPIO, comme la carte : 5 lignes (source,
HIGH pendant leur créneau) sur des pseudo-broches internes (ids 21-25), 5
colonnes (sink, LOW = LED allumée) sur les broches edge P4/P7/P3/P6/P10 (COL1
à COL5). Fidèle au driver CODAL (`NRF52LedMatrix`) :

- **trame de 60 Hz** (`NRF52_LED_MATRIX_FREQUENCY`), un créneau de 3,33 ms par
  ligne ;
- pendant le créneau de la ligne *i*, chaque colonne reste basse pendant
  `créneau × niveau/9` (niveaux `set_pixel` 0-9), puis est relâchée (HIGH) ;
- `display.off()` relâche les 10 broches en haute impédance, `on()` les reprend ;
- le balayage continue après la fin du programme (matériel autonome), et
  s'arrête à la coupure d'alimentation.

Le moteur vit **côté C, comme `uartcore` pour l'UART**, parce que le balayage
exige des transitions à la granularité du quantum (~370 µs), sous le plancher
des `machine.Timer` (1 ms, 4 minuteurs). Il est cadencé par `PyRuntime_sync` :

- `matrix_step(h, now)` — idempotent, recalculé depuis l'ancre `t0` — écrit
  `pin_is_output`/`pin_driven_value` des 10 broches : le chemin « sortie
  digitale » habituel de `Internal.PinBridge`, **aucune signature de synchro à
  changer** ;
- `earliest_matrix_deadline(h)` — prochaine transition réelle (frontière de
  créneau ou relâche de colonne), alimente `nextWakeTime` : un événement
  Modelica par transition, ~600-1800/s, l'ordre de grandeur d'un UART à
  1200 bauds ; les relâches déjà passées sont ignorées (sinon chattering —
  constaté au premier essai avec un niveau intermédiaire, cf. `verify_73`) ;
- l'activation **au démarrage** est faite par `matrix_boot_enable`, appelée à
  la première synchro alimentée d'une carte de profil `microbit` : le shim ne
  peut rien appeler qui rende la main pendant son init (le constructeur
  `PyRuntime_new` n'échange pas de tours → deadlock), et le firmware active
  lui-même son driver au boot.

Deux artefacts corrigés au passage :

- **réveil parasite à l'arrêt** : la première transition des broches après
  `display.off()` (l'établissement de leur niveau hors haute impédance) ne
  réveille pas le script — drapeau `matrix_pin_released`, cf. la boucle
  `input_changed` de `PyRuntime_sync` ;
- les transitions des broches **pendant** le balayage n'entrent pas dans cette
  boucle : ce sont des sorties.

`MAX_PINS` est passé de 32 à 40 (la micro:bit en occupe 32 : 19 + 5 + 8).

## Le module `microbit` du shim

Il vit dans `machine_time_shim.py`, sous `if _MBIT:` (profil de carte),
fournit l'API officielle du portage MicroPython de la micro:bit **par-dessus
`machine`** (le vrai portage v2 expose aussi `machine`) :

- `display` (`show`/`scroll`/`clear`/`set_pixel`/`get_pixel`/`on`/`off`/
  `is_on`/`read_light_level`), animations d'arrière-plan par un `machine.Timer`
  caché (`wait=False`), défilement proportionnel par la police
  **pendolino3** du firmware (475 octets, 95 glyphes, données de
  `microbit-dal`) ;
- `Image` : les trois formes de constructeur, `set_pixel`/`get_pixel`/
  `shift_*`/`crop`/`copy`/`invert`/`fill`/`blit`, et les 60 images intégrées
  du portage (données de `microbitconstimage.cpp`, en lecture seule comme en
  vrai) ;
- `pin0`...`pin16`, `pin19`, `pin20` : `read_digital`/`write_digital`,
  `read_analog` (0-1023)/`write_analog` (+ `set_analog_period*`),
  `set_pull`/`get_pull`/`get_mode` ;
- `button_a`/`button_b` : IRQ interne sur les deux fronts (un appui bref entre
  deux appels n'est pas perdu), `is_pressed`/`was_pressed`/`get_presses` avec
  des compteurs **indépendants** (comme la vraie carte) ;
- `accelerometer` (mg, ±2 g), `compass` (nano-tesla, ±200 µT),
  `temperature()`, `uart` (tx/rx **obligatoires** : pas de console USB en
  simulation), `i2c` (défauts P19/P20), `panic`/`reset` (SystemExit),
  `scale`, `running_time`, `sleep` (**millisecondes**, comme la vraie API).

Les gardes de profil (`_mbit_check`) limitent `machine.Pin`/`ADC`/`PWM`/`UART`/
`I2C`/`I2CTarget` aux broches edge (pas de P17/P18, lignes et capteurs
invisibles) et interdisent toute prise de direction des colonnes de la matrice
tant que l'affichage est actif (`display.off()` les libère).

## Les capteurs intégrés

Chaque capteur est une pseudo-broche ADC (ids 26-33 : accéléromètre X/Y/Z,
boussole X/Y/Z, température, lumière) alimentée par une `SignalVoltage`
d'équation `v = vRail × f(valeur)` — lisible par `adc_read` en **fraction de
la référence**, donc indépendant du rail :

| Capteur | Encodage | API |
|---|---|---|
| Accéléromètre (m/s²) | `f = 0,5 + a/39,24` (±2 g) | `get_x()` en mg |
| Boussole (µT) | `f = 0,5 + m/400` (±200 µT) | `get_x()` en nT |
| Température (°C) | `f = (T + 20)/100` | `temperature()` en °C |
| Lumière (0-255) | `f = L/255` | `read_light_level()` |

Défauts du modèle : gravité sur Z (carte à plat, geste « face up »), 50 µT sur
Y, 27 °C, lumière 100. `display.read_light_level()` lit le capteur du modèle
(en vrai, la carte mesure la décharge de la matrice — simplification
documentée). La calibration de la boussole est instantanée (le vrai jeu de
calibration n'a pas de sens sans main qui tourne la carte).

## Vérification

Scénarios `verify_72` à `verify_76` (cf. `interne/tests.md` pour le mode
d'emploi) :

| Scénario | Ce qui est vérifié |
|---|---|
| `verify_72_microbit_smoke` | module chargé, capteurs (défauts), matrice sous HEART (une ligne haute à la fois, colonnes basses), `off()` relâche tout, `on()` reprend |
| `verify_73_microbit_matrix_quantum` | fenêtres exactes des niveaux 9/4/1 aux instants calculés (ancre déterministe `t0` = boot) |
| `verify_74_microbit_buttons` | boutons électriques (tirage 10 k, Goff de l'interrupteur), `is_pressed`/`was_pressed`/`get_presses` |
| `verify_75_microbit_board` | la carte complète : rail 3,0 V, courants réels des LED (allumée ~0,3 mA moyen, éteinte ~0), arrêt propre |
| `verify_76_microbit_example_buttons` | l'exemple `Examples.MicroBit.Buttons` : 4 appuis comptés, P5 au niveau électrique attendu à chaque instant |

`IMax` des LED de matrice : 0,4 mA (le courant **moyen** d'une LED allumée à
plein niveau, duty 1/5 sur la trame — l'icône atteint sa pleine luminosité sur
ce courant-là).

## Ce qui n'est pas simulé (Phase 2)

`microbit.radio` (protocole paquets — réutiliser un `Peripherals.Radio.RadioModem`
câblé sur l'UART ou l'implémenter au-dessus, décision en suspens), SPI (chantier
commun à toutes les cartes), logo tactile, micro/haut-parleur de la v2, USB HID.
Le redémarrage logiciel (`microbit.reset()`) n'est pas simulé (cohérent avec
l'absence de redémarrage sur perte d'alimentation) : le programme se termine.
