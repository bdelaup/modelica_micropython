# La carte micro:bit

`MicroBit_v2` est la réplique de la carte **BBC micro:bit v2** (nRF52833) :
brochage et cotes réels, matrice LED 5×5 multiplexée, boutons A/B, capteurs
intégrés, alimentation USB. On y exécute le même programme que sur une vraie
micro:bit, écrit pour l'API officielle (`from microbit import *`).

## Démarrage rapide

1. Poser un composant `MicroBit_v2` dans le schéma, relier sa broche `GND` à
   une masse. Par défaut `usbConnected = true` : la carte est alimentée par
   son USB, rien d'autre à câbler.
2. Dans les paramètres du composant, pointer **Script path** vers votre
   programme (le bouton *…*) :

   ```python
   from microbit import *

   display.show(Image.HEART)
   while True:
       sleep(1000)
       display.show(Image.HAPPY)
       sleep(1000)
   ```

3. Simuler : les points de la matrice s'allument sur l'icône (relecture
   animée des résultats dans OMEdit) — ce sont les **courants réels** dans
   les 25 LED, calculés par le solveur.
4. Exemples prêts à simuler : `Examples.MicroBit.Heart`, `Buttons`,
   `GpioEdge`.

## Le programme : le module `microbit`

L'API du portage MicroPython officiel de la micro:bit. `machine` reste
disponible aussi (comme sur la vraie v2). `microbit.sleep()` prend des
**millisecondes**, comme sur la carte.

### `display` — la matrice LED 5×5

```python
display.show(Image.HEART)             # une image (ou un caractère, un chiffre)
display.show(Image.ALL_CLOCKS, delay=100)  # animation, 100 ms par image
display.scroll('Hello!', delay=150)  # texte qui défile
display.set_pixel(0, 0, 9)            # luminosité 0 (éteinte) à 9 (maxi)
display.clear()
display.read_light_level()            # niveau de lumière 0-255
```

Comme sur la vraie carte, la matrice est **multiplexée sur 10 GPIO** (5
lignes + 5 colonnes) et balayée à 60 Hz : `display.show()` n'allume pas 25
sorties, elle écrit des pixels que le driver balaie. Les 5 colonnes
(`P3`, `P4`, `P6`, `P7`, `P10`) sont partagées avec le connecteur edge :

- tant que l'affichage est actif, elles appartiennent au driver (les piloter
  en GPIO lève une erreur explicite) ;
- `display.off()` les libère (haute impédance, comme `disable()` du firmware) ;
  `display.on()` reprend le balayage.

### Boutons A et B

Les appuis ne viennent pas du clavier. Chaque bouton est piloté par son
**menu déroulant de source** (`buttonASource`, `buttonBSource`, onglet
*Buttons*) :

- **Connector** (défaut) : l'entrée logique `buttonA`/`buttonB` se câble
  dans le schéma (un `BooleanPulse`, un capteur, une expression...).
  Appuyer = tirer la broche (`P5`/`P11`) à la masse, comme un doigt sur la
  carte.
- **Table** : table horaire interne, colonne 1 = temps (s), colonne 2 = 0
  (relâché) ou 1 (pressé). Exemple de table par défaut pour A :
  `{{0,0},{1,0},{2,1},{3,0},{4,0},{5,1},{6,0}}` — deux appuis à t=2 s et
  t=5 s.
- **Constant** : état fixe (`buttonAPressed`), rien à câbler.

```python
if button_a.was_pressed():
    count += 1
while button_b.is_pressed():
    ...
```

### Capteurs intégrés

Chaque capteur est piloté par son propre **menu déroulant de source**
(`accelXSource`... `lightSource`, onglet *Sensors*) : **Constant** (défaut)
pour une valeur de paramètre, **Table** pour une table horaire interne
(temps, valeur), ou **Connector** pour une entrée câblée dans le schéma —
son port **étiqueté apparaît alors au bord correspondant de l'icône**,
tourné vers la carte (accéléromètre sur le bord droit, boussole sur le bord
gauche, température et lumière sur le bord haut) — la valeur peut donc varier
pendant la simulation. L'exemple `Examples.MicroBit.SensorInputs` câble
**tous** les capteurs et les deux boutons sur des blocs `TimeTable`,
`Constant` et `BooleanPulse`.

| Capteur | Paramètres (unité) | API |
|---|---|---|
| Accéléromètre | `accelX`, `accelY`, `accelZ` (m/s², gravité sur Z par défaut) | `accelerometer.get_x()` (milli-g), `get_values()`, gestes `current_gesture()` |
| Boussole | `magX`, `magY`, `magZ` (µT) | `compass.get_x()` (nano-tesla), `heading()` (calibration instantanée) |
| Thermomètre | `temp` (°C) | `temperature()` |
| Lumière | `light` (0-255) | `display.read_light_level()` |

### Broches edge : `pin0`...`pin20`

```python
pin1.write_digital(1)     # sortie
v = pin0.read_digital()   # entrée
a = pin2.read_analog()    # 0-1023 (P0-P4, P10 ont l'ADC)
pin8.write_analog(512)    # PWM 0-1023
pin12.set_pull(Pin.PULL_UP)
```

Tirages présents sur la carte : 10 MΩ vers 3V sur les anneaux P0/P1/P2,
4,7 kΩ sur P19/P20 (bus I2C, `i2c.init()` par défaut : `scl=pin19`,
`sda=pin20`), 10 kΩ sur les boutons. Il n'y a pas de broche P17/P18.

### Un scénario complet : sources en mode *Table*

Pour simuler un scénario complet sans câbler de source externe, passer le
menu déroulant de chaque bouton et capteur sur **Table** et remplir les
tables horaires (colonne 1 = temps (s), colonne 2 = valeur dans l'unité du
capteur, ou 0/1 pour les boutons). L'exemple `Examples.MicroBit.Scenario`
montre un scénario complet piloté uniquement par les tables horaires (appuis
boutons, secousse, rampe de température et de lumière).

### `uart`

Pas de console USB en simulation : `tx` et `rx` sont **obligatoires**.

```python
uart.init(9600, tx=pin0, rx=pin1)
uart.write('hello')
uart.any(); uart.read()
```

## Alimentation

`usbConnected = true` (défaut) : 5 V par le câble USB (paramètres `VUsb`,
`RUsb`) → régulateur buck-boost → **rail 3,0 V** exposé sur la broche `3V`
(paramètre `VTgt`). Le programme démarre quand le rail dépasse `VPowerOn`
et s'arrête définitivement s'il passe sous `VPowerOff` (pas de redémarrage
simulé). La broche `3V` alimente aussi le 3V de la carte.

## Radio : `microbit.radio`

La radio 2,4 GHz embarquée est un **modem radio ordinaire monté dans la carte**
(le même moteur que `Peripherals.Radio.RadioModem`, branché en interne sur deux
broches du cœur) — **toujours présente, comme sur le vrai matériel**. Son port
**Antenna** (en haut de l'icône) se câble **en un seul fil** entre toutes les
cartes qui doivent s'entendre — exactement comme entre deux `RadioModem`. Le
protocole du firmware (trames, filtrage `channel`/`group`/`address`, file de
réception, troncation) vit dans le shim Python ; l'API du programme :

```python
import radio
radio.on()                     # toujours presente : reussit sans condition ;
                                # une antenne non câblée émet dans le vide,
                                # comme un modem isolé
radio.config(channel=7, group=0, power=6)   # filtrage channel/group/address,
                                            # file de réception queue (défaut 3)
radio.send('PING 1')            # ou send_bytes(b'...'), au plus length octets
msg = radio.receive()           # str ou None (receive_bytes() : bytes ou None)
```

Un paquet voyage au rythme du modem (liaison interne à 115 200 bauds, air à
1 Mbit/s) ; les sémantiques du firmware s'appliquent (filtrage, file,
troncation à `length`), `power` est accepté mais sans effet (pas de portée
simulée), et `data_rate` doit correspondre des deux côtés (une trame d'un
autre débit est ignorée, comme deux radios réelles incompatibles). Deux cartes
neuves sur le même fil s'entendent — même `channel`/`group`/`address` par
défaut, comme deux vraies micro:bits. Aucun signal modulé n'est tracé côté
carte ; le `RadioModem` reste l'outil pour les modulations. L'exemple
`Examples.MicroBit.RadioChat` fait dialoguer deux cartes, et la radio coexiste
avec `machine.UART` (deux moteurs distincts, l'un interne à la radio, l'autre
au service du programme).

## Limites spécifiques à la micro:bit

- Pas de SPI (aucune carte de la bibliothèque n'en a), pas de logo tactile,
  microphone ni haut-parleur (v2), pas de `reset()` logiciel (le programme
  s'arrête ; cohérent avec l'absence de redémarrage sur perte
  d'alimentation).
- Les gestes de l'accéléromètre dérivés de la gravité fonctionnent
  (`face up`, `up`, `left`...) ; les gestes dynamiques (`shake`, `freefall`)
  n'ont pas de source en simulation.
- `display.scroll`/`show` avec `wait=False` utilisent un `machine.Timer`
  interne (pool de 4).
- Radio : une antenne **non câblée** ne se signale pas (un fil d'antenne
  acausal ne peut pas dire « personne au bout ») — l'émission part dans le
  vide, comme un modem isolé ; le rythme des
  échanges est celui du modem interne (liaison à 115 200 bauds, air à
  1 Mbit/s), pas la durée de trame exacte du matériel, et un flux continu
  dense coûte plus d'événements de simulation qu'un envoi sporadique.

Voir aussi : la référence de l'API `machine` (page « API machine / time »),
la page « Limites et dépannage », et `Examples.MicroBit`.
