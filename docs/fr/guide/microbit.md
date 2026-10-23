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

Les appuis ne viennent pas du clavier : les entrées logiques `buttonA` et
`buttonB` du composant se câblent dans le schéma (un `BooleanPulse`, un
capteur, une expression...). Appuyer = tirer la broche (`P5`/`P11`) à la
masse, comme un doigt sur la carte.

```python
if button_a.was_pressed():
    count += 1
while button_b.is_pressed():
    ...
```

### Capteurs intégrés

Chaque capteur a une **valeur constante** (onglet *Sensors*) et, si activé
(`useAccelInput`, `useMagInput`, `useTempInput`, `useLightInput`), un
**connecteur d'entrée** câblable qui la remplace — la valeur peut donc varier
pendant la simulation.

| Capteur | Onglet Sensors | API |
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

## Limites spécifiques à la micro:bit

- `microbit.radio` n'est pas simulé : pour une liaison sans fil, câbler un
  `Peripherals.Radio.RadioModem` sur l'UART (`machine.UART`), comme pour les
  autres cartes.
- Pas de SPI (aucune carte de la bibliothèque n'en a), pas de logo tactile,
  microphone ni haut-parleur (v2), pas de `reset()` logiciel (le programme
  s'arrête ; cohérent avec l'absence de redémarrage sur perte
  d'alimentation).
- Les gestes de l'accéléromètre dérivés de la gravité fonctionnent
  (`face up`, `up`, `left`...) ; les gestes dynamiques (`shake`, `freefall`)
  n'ont pas de source en simulation.
- `display.scroll`/`show` avec `wait=False` utilisent un `machine.Timer`
  interne (pool de 4).

Voir aussi : la référence de l'API `machine` (page « API machine / time »),
la page « Limites et dépannage », et `Examples.MicroBit`.
