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

SPI (chantier commun à toutes les cartes), logo tactile, micro/haut-parleur
de la v2, USB HID. Le redémarrage logiciel (`microbit.reset()`) n'est pas
simulé (cohérent avec l'absence de redémarrage sur perte d'alimentation) :
le programme se termine.

## Radio `microbit.radio` (Lot 8, 2026-10-23)

Décision « Radios micro:bit » de `requirements.md` : **moteur de paquets
dédié côté C** (comme la matrice LED l'est pour le balayage), pas un
`RadioModem` sur l'UART — la radio de la micro:bit n'est pas sur un UART,
l'API est par paquets (file `queue`, filtrage `channel`/`group`/`address`,
troncation `length`) et une trame électrique à 1 ou 2 Mbit/s coûterait des
milliers de points de synchro par paquet.

- **Topologie** : le port **Antenna** de la carte (paramètre `useRadio`)
  porte une liaison logique `Interfaces.RadioAirInput` vers un
  `Peripherals.Radio.RadioAir`, qui donne son identifiant de réseau à
  toutes les antennes câblées à lui (`networkId` explicite, sinon un hash
  du nom d'instance, `Internal.StringHash`). Deux moteurs s'entendent
  s'ils partagent l'identifiant ; `radio.on()` lève une erreur explicite
  tant que l'antenne n'est pas câblée. L'identifiant transite par un
  nouvel entrée de `PyRuntime_sync` (`radioNetwork`, -1 = pas d'antenne),
  plomberie dans `Internal.McuCore` (connecteur conditionnel `AntennaIn`,
  `useRadio`).
- **Moteur** (`pyruntime_radio.c`, inclus par le chapeau) : registre global
  des moteurs du process (tous les MCU d'un modèle partagent l'exe) ;
  `radio_send` pose le paquet dans la file d'arrivee de chaque auditeur du
  meme réseau avec `arrival = t + (len + 6)*8/data_rate`, `radio_step`
  (chaque synchro) livre les paquets arrivés, filtres par la config du
  RECEPTEUR, dans sa file `queue` (les plus vieux partent en premier,
  file pleine = paquet perdu, avertissements plafonnés côté thread
  Modelica). Verrou global `g_radio_cs` pour l'inbox/registre (aucun cycle :
  l'emetteur ne prend jamais le cs d'un autre handle) ; `earliest_radio_deadline`
  entre dans le calcul du prochain réveil (livraison exacte à l'arrivée).
- **Natives** : `radio_on/off/config/send_bytes/any/read_bytes` (table du
  module natif ; `pyimports.h` régénéré par `tools/make_pyimports.sh` pour
  `PyErr_WarnEx`).
- **Shim** : module `radio` autonome (`import radio`, aussi attaché à
  `microbit.radio`), config gardée côté Python (les sept valeurs
  repassées à chaque `config()`), `send`/`receive` encodent/décodent en
  UTF-8, `receive_bytes_into` vérifie la taille du tampon. `power` accepté,
  sans effet (pas de portée).
- **Exemple** : `Examples.MicroBit.RadioChat` (scripts
  `microbit_radio_tx.py` / `microbit_radio_rx.py`).
- **Vérification** : `verify_78_microbit_radio.mos` — deux cartes sur le
  même air, 5 PING émis/reçus, marqueurs TX/RX.

## Sources des boutons et capteurs (retravail du paramétrage, 2026-10-23)

Chaque bouton et chaque capteur est piloté par un **menu déroulant de
source** : l'énumération `InputSource` (déclarée dans `MicroBit_v2`) vaut
`Constant` (paramètre), `Table` (table horaire interne `CombiTable1Ds` MSL)
ou `Connector` (entrée câblée dans le schéma). Le composant est
**régénéré intégralement** par `tools/make_microbit.py` (plus d'édition à la
main : l'ancienne dérive générateur/modèle est résorbée) :

- **Boutons** : `buttonASource`/`buttonBSource` (défaut `Connector`) +
  `buttonATable`/`buttonBTable` (`Real[:,2]`, colonne 1 = temps en s,
  colonne 2 = 0/1, mode Table) + `buttonAPressed`/`buttonBPressed` (état
  fixe, mode Constant). En mode Table un `CombiTable1Ds` + un
  `RealToBoolean` internes remplacent le connecteur dans l'équation de
  câblage de l'interrupteur (`switchA.control`) ; le connecteur
  `buttonA`/`buttonB` n'existe qu'en mode Connector.
- **Capteurs** : `<capteur>Source` (défaut `Constant`, ex.
  `accelXSource`) + valeur `accelX`... + table `<capteur>Table`. Le nœud
  `internal_<capteur>` reçoit la table, le connecteur ou le bloc constant
  selon le mode.

Au passage : **bug corrigé** — les blocs constants internes utilisaient la
valeur par défaut en dur (`const_temp(k = 27)`) au lieu du paramètre
(`const_temp(k = temp)`), qui était donc ignoré. **Second bug corrigé** : les
connecteurs `accelXIn`... étaient en section `protected`, donc impossibles à
câbler depuis un modèle contenant (« Illegal access of protected element ») ;
ils passent en section publique et, quand leur source vaut `Connector`,
**apparaissent au bord correspondant de l'icône**, tournés vers la carte,
avec une étiquette au-dessus de chacun (accéléromètre sur le bord droit,
boussole sur le bord gauche, température et lumière sur le bord haut ;
avant : `visible = false`,
aucune entrée n'était câblable — c'était le paramétrage « connecteur » qui ne
montrait rien à l'écran).

**Icône (retravail du même jour)** : la puce nRF couvrait la rangée basse de
la matrice LED et les textes étaient tronqués (« m… », « nRF… ») — la matrice
est resserrée et remontée (pas u(3,9)), la puce abaissée (`chip_cy = -u(10,7)`)
avec sa référence sur deux lignes (`nRF` / `52833`), le texte `micro:bit`
élargi (±95, fs 24) et le nom d'instance déplacé sous la carte (le bord
supérieur accueille les ports capteurs).

**API casse** (lot 7 initial, remplacé par ce design) : les paramètres
`useXxxTable`/`useXxxInput` (booléens) et `buttonTableA`/`buttonTableB`
disparaissent au profit des `<nom>Source` + `<nom>Table`. Migration :
`useTempTable = true` → `tempSource = InputSource.Table` (qualifier en
`MicroPythonMCU.MicroBit_v2.InputSource.Table` hors du composant).

Les tables par défaut (paramètres `<nom>Table`) sont pédagogiques : bouton A
pressé à t=2 s et t=5 s, bouton B à t=3 s, secousse accelX à t=1 s, rampe de
température 27→35 °C sur 10 s, rampe de lumière 200→50 sur 5 s.

**Exemples** : `Examples.MicroBit.Scenario` (script
`Resources/Scripts/MCU/microbit_scenario.py`) — scénario complet piloté
uniquement par les sources en mode Table ; `Examples.MicroBit.SensorInputs` —
même script, mais **toutes** les entrées câblées depuis le schéma : chaque
famille de sources fait face à ses ports, **sorties tournées vers la carte**
(boussole colonne à gauche, accéléromètre colonne à droite en miroir,
température et lumière empilées au-dessus pivotées vers le bas, boutons en
face de leur connecteur — fils rectilignes ; blocs espacés de 15 unités),
`TimeTable` pour la secousse et les rampes, `Constant` pour
les niveaux fixes. Schéma vérifié par script : aucun chevauchement de
composants, aucun croisement ni superposition de fils, aucun fil sur la
carte dessinée, et chaque fil démarre exactement sur la sortie réelle de son
bloc (contrôle géométrique sur les boîtes et segments) ; ports
confirmés par le serveur MCP d'OMEdit (`getComponentPlacement`,
`listShapes`, `checkModel`).

**Vérification** : `verify_77_microbit_tables.mos` (script
`Resources/Verification/microbit_tables.py`) — modèle inline `MicroBitTables`
héritant de `MicroBit_v2` avec des tables de test contrôlées (appuis à
t=0,2/0,5 s, secousse à t=0,1 s, rampe température 20→30 °C, rampe lumière
200→50). Vérifie les marqueurs du script Python. `Examples.MicroBit.SensorInputs`
vérifié par simulation (omc) : les entrées câblées pilotent bien les capteurs
(accéléromètre à 5 m/s² à t=1 s, température 27→35 °C, lumière 200→50 puis
maintenue — la `TimeTable` MSL extrapole linéairement, d'où le point final de
maintien dans l'exemple).
