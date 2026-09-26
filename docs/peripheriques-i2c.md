# Bus I2C : `machine.I2C` et les périphériques esclaves

Cette page décrit **comment** est construit le bus I2C : le maître côté microcontrôleur (`machine.I2C`), la classe de base des périphériques esclaves (`Internal.PartialI2cDevice`), le contrat des scripts Python qui décrivent ces périphériques, et l'écran Grove LCD RGB. Le **pourquoi** (alternatives écartées, restrictions) est dans [`requirements.md`](../requirements.md), décision « Bus I2C électrique en drain ouvert ».

## 1. Un vrai bus électrique, en drain ouvert

Deux fils partagés, `SDA` (données) et `SCL` (horloge), plus la masse. Personne ne force jamais une ligne à l'état haut : chaque acteur (le microcontrôleur, chaque périphérique) ne sait que **tirer la ligne à la masse** ou la **relâcher**. Ce sont les **résistances de tirage** qui remontent une ligne relâchée. Conséquences directes, sans une ligne de code pour les obtenir :

- **ET câblé** : une ligne est basse dès qu'au moins un acteur la tire. C'est ainsi qu'un esclave acquitte (il tire SDA pendant que le maître la relâche), et qu'autant de périphériques qu'on veut se partagent les deux fils — Kirchhoff fait la résolution de bus.
- **Sans tirage, rien ne marche** : les lignes relâchées restent à 0 V. C'est le symptôme d'un montage réel où on a oublié les résistances, et le maître le signale par `OSError(ETIMEDOUT)` (`Examples.I2c.NoPullUp`).

| Côté | Tirer à la masse | Relâcher | Lire |
|---|---|---|---|
| Microcontrôleur (`MCU`, **aucune modification de `MCU.mo`**) | broche en sortie à l'état bas (`pinIsOutputD = true`, `pinBoolOut = false`) | broche en entrée (interrupteur ouvert, haute impédance) | `pinBoolIn` |
| Périphérique (`Internal.PartialI2cDevice`) | conductance variable `sdaOut.G = 1/ROut` (SDA seulement) | `sdaOut.G = GOff` | `VoltageSensor` + seuil |

Les tirages sont portés par les périphériques : paramètre `usePullUp` (désactivé par défaut, `RPullUp = 4,7 kΩ`), composants conditionnels. Le Grove l'active, comme le module réel ; plusieurs paires se mettent en parallèle.

Chaque broche de périphérique porte aussi une capacité d'entrée `CIn` (10 pF). **Elle n'est pas cosmétique** : elle fait de SDA et SCL des états dynamiques, ce qui rompt la dépendance entre le `when` du microcontrôleur et ceux des esclaves (même rôle que `CIn` des périphériques série, cf. [peripheriques-uart-externes.md](peripheriques-uart-externes.md)). Elle fixe aussi le temps de montée : 4,7 kΩ × 10 pF = 47 ns, très en dessous du quart de période à 400 kHz (625 ns). Augmenter `CIn` ou `RPullUp` dégrade les fronts, comme sur un vrai bus trop chargé.

Pas de composant `Ideal.*` commutant côté périphérique (piège documenté de la LED embarquée, cf. `requirements.md`) : la sortie est une `VariableConductor`.

## 2. Le maître : une séquence cadencée par échéances

`Resources/Include/pyruntime/pyruntime_i2c.c`. Le maître n'attend aucun front : il **impose** l'horloge. Toute la séquence avance par échéances (`nextWakeTime`), un **quart de période** `q = 1/(4·freq)` à la fois :

```
bit :     SCL basse ─[q]→ SDA positionnée ─[q]→ SCL relâchée ─[q]→ SDA lue (SCL vérifiée haute) ─[q]→ SCL basse
START :   bus libre ? (SDA et SCL hautes) ─→ SDA basse ─[q]→ SCL basse
STOP :    SDA basse (SCL basse) ─[q]→ SCL relâchée ─[q]→ SDA relâchée ─[q]→ résultat disponible
START répété : SDA relâchée (SCL basse) ─[q]→ SCL relâchée ─[q]→ START
```

Une seule action par appel de `PyRuntime_sync`, et la suivante toujours **strictement dans le futur** : Modelica doit d'abord laisser la ligne évoluer à travers les tirages, et `time >= pre(nextWakeTime)` ne se redéclenche que s'il repasse de faux à vrai.

Une transaction complète : `[START adr+W, octets écrits] [START répété adr+R, octets lus] STOP`, chaque segment facultatif. Le maître acquitte chaque octet lu sauf le dernier (NACK), comme le veut le protocole.

**Appel bloquant.** `writeto`, `readfrom`, `readfrom_mem`... ne rendent la main au script qu'à la fin réelle de la séquence, en temps simulé : la primitive `i2c_xfer` arme la transaction puis se gare (`yield_to_modelica(1e300)`). En fin de transaction, le moteur pose `i2c_done_wake`, qui rend ce réveil **authentique** (cf. [cycle-de-vie.md](cycle-de-vie.md), réveil authentique vs. pitstop) : un Timer ou une IRQ pendant l'attente ne fait pas revenir l'appel trop tôt.

**Erreurs** (valeurs errno de MicroPython) : adresse non acquittée → `OSError(EIO)` ; ligne restée basse (bus pas libre avant un START, ou SCL relâchée qui ne remonte pas) → `OSError(ETIMEDOUT)` ; appel I2C depuis un callback pendant une transaction → `OSError(EBUSY)`.

Les broches du bus sont **réservées** (`i2c_claimed`, même motif que la réception UART) : leurs fronts ne réveillent pas le script et ne déclenchent pas d'IRQ GPIO.

## 3. L'esclave : un décodeur piloté par les fronts

`Resources/Include/I2cDeviceImpl.c` (chapeau) et `i2cdevice/`. L'esclave n'a pas d'horloge : il **suit** celle du maître. Le `when` de `PartialI2cDevice` se déclenche à chaque franchissement de seuil de SCL ou de SDA, et `I2cDevice_sync` compare les niveaux à ceux du dernier appel :

| Événement | Interprétation |
|---|---|
| SDA descend pendant que SCL est haute | START (ou START répété) : clôture de la phase en cours, attente de l'adresse |
| SDA monte pendant que SCL est haute | STOP : clôture de la phase en cours |
| SCL monte | un bit est lu (adresse, octet écrit) ou l'acquittement du maître est lu (lecture) ; **l'impulsion est comptée ici** |
| SCL descend | l'esclave positionne SDA pour le bit suivant : ACK après le 8e bit, bit de donnée en lecture, ou relâchée |

Changer SDA juste **après** le front descendant de SCL garantit qu'un esclave ne fabrique jamais de faux START/STOP. Un esclave dont l'adresse ne correspond pas reste muet jusqu'au STOP ou au START suivant — c'est ce qui permet plusieurs périphériques sur le bus. Rappelée au même instant avec les mêmes niveaux (itérations d'événements), la fonction ne fait rien : il n'y a pas de nouveau front.

**Piège rencontré** : les impulsions étaient d'abord comptées au front *descendant* de SCL. Or le premier front descendant après un START n'est pas un coup d'horloge de donnée : l'esclave ne capturait que 7 bits, lisait `0x42` au lieu de `0x84`, et n'acquittait jamais. Diagnostiqué en traçant SDA/SCL (CSV) et les états du décodeur.

## 4. Le contrat d'un script de périphérique

Le comportement d'un périphérique I2C est **toujours** décrit par un script Python — il n'y a pas de table de commandes. Le script ne voit que des **transactions** : ni bits, ni START/STOP, ni acquittements. Quatre fonctions, toutes facultatives :

```python
def on_write(addr, data, t, v):   # une phase d'écriture adressée vient de se clore (STOP ou START répété)
    ...                           # data : bytes reçus (jamais vide : une sonde de scan() n'appelle rien)

def on_read(addr, t, v):          # le maître commence à lire
    return b'...'                 # bytes, str, liste d'entiers ou entier ; sortis un par un,
                                  # on_read rappelée si le maître en veut plus (0xFF si rien)

def outputs():                    # relue après chaque gestionnaire -> connecteur valueOut
    return (a, b)

def lines():                      # relue après chaque gestionnaire -> line1/line2 (écrans)
    return ('ligne 1', 'ligne 2')
```

`addr` est l'adresse utilisée par le maître : un composant peut en avoir plusieurs (paramètre `addresses`, chaîne `"0x3E, 0x62"` — Modelica n'a pas de littéraux hexadécimaux). `t` : temps simulé ; `v` : tuple des grandeurs du connecteur `valueIn`.

Le chargement (espace de noms propre à chaque instance, `print()` préfixé du nom du composant, arrêt propre de la simulation sur exception) est **commun** avec les périphériques série : `Resources/Include/devscript.c`. Deux instances du même script ont deux états indépendants ; les variables de module persistent d'un appel à l'autre.

Écrire un nouveau périphérique : copier `Resources/Scripts/Device/i2c_generic.py` (un banc de registres commenté), puis soit le désigner dans un `Peripherals.I2cGenericDevice`, soit en faire une classe (`extends Internal.PartialI2cDevice(addresses = ..., scriptPath = ..., usePullUp = ...)`, sur le modèle de `I2cEchoDevice`).

## 5. Les périphériques fournis

| Composant | Adresse(s) | Script | Rôle |
|---|---|---|---|
| `I2cEchoDevice` | `0x42` | `Device/i2c_echo.py` | Composant de test : relit au maître la dernière écriture. `valueOut` = (écritures, octets reçus, premier octet) |
| `I2cGenericDevice` | à régler | `Device/i2c_generic.py` | Gabarit : banc de 16 registres à pointeur auto-incrémenté |
| `I2cGroveLcdRgb` | `0x3E, 0x62` | `Device/grove_lcd_rgb.py` | Écran Grove - LCD RGB Backlight, tirages activés |

**L'écran Grove** porte deux circuits, d'où deux adresses pour un seul composant. Le script les émule d'après leurs fiches techniques, sans rien savoir du programme qui les pilote :

- **JHD1313** (`0x3E`, compatible HD44780) : chaque octet est précédé d'un octet de contrôle (bit 7 `Co` : un autre octet de contrôle suit ; bit 6 `RS` : commande ou caractère). Commandes : effacement, retour au début, mode d'entrée, écran allumé/éteint, décalage, configuration, position d'écriture (DDRAM 2 × 40, ligne 2 à `0x40`). Écran **éteint à la mise sous tension**. Un octet reçu pendant un effacement (1,52 ms) est ignoré, avec un avertissement dans le journal.
- **PCA9633** (`0x62`) : registres `MODE1`/`MODE2`, `PWM0`–`PWM3` (bleu, vert, rouge), gradation de groupe, `LEDOUT` ; pointeur de registre à auto-incrément ; oscillateur en veille à la mise sous tension.

Rendu : `Internal.Lcd16x2RgbIcon`, 32 cellules générées mécaniquement et un fond qui prend la couleur du rétroéclairage, animés pendant la relecture d'un résultat dans OMEdit.

`Examples.I2c.GroveLcd` exécute **sans modification** un driver MicroPython existant (`Scripts/MCU/driver_grove_lcd_rgb.py`, importé par le programme principal `Scripts/MCU/i2c_grove_lcd_rgb.py`, comme un module posé à côté de `main.py` sur la vraie carte), écrit pour la vraie carte : c'est la démonstration « jumeau numérique ». Le shim accepte pour cela `I2C(scl=..., sda=..., freq=...)` sans identifiant, en plus de la forme rp2 `I2C(0, scl=..., sda=...)`.

## 6. Ce que vérifient les scénarios

| Script | Modèle | Ce qui est vérifié |
|---|---|---|
| `verify_21_i2c_echo.mos` | `Examples.I2c.Echo` | START conforme, ACK de l'adresse tenu par l'esclave, trame de 9 octets écrite puis relue, lecture de registre derrière un START répété |
| `verify_22_i2c_multi.mos` | `Examples.I2c.MultiDevice` | Trois esclaves sur un bus, deux paires de tirages en parallèle, 400 kHz : `scan()` exact, pas de diaphonie, `EIO` sur une adresse absente |
| `verify_23_i2c_nopullup.mos` | `Examples.I2c.NoPullUp` | Sans tirage : lignes à 0 V, `ETIMEDOUT`, `scan()` vide, aucun esclave sollicité |
| `verify_24_i2c_grove_lcd.mos` | `Examples.I2c.GroveLcd` | Driver du commerce tel quel : écran éteint puis « hello World », rétroéclairage rouge, vert, bleu |

**Message « Chattering detected ... `time >= pre(mcu.nextWakeTime)` »** dans le journal : information bénigne d'OpenModelica, qui signale 100 événements d'affilée dans un seul pas de sortie. Elle apparaît quand l'intervalle de sortie (`Interval`) est grand devant la période d'horloge du bus ; les exemples fournis choisissent un intervalle qui l'évite. Ce n'est pas une erreur : la séquence I2C est pilotée par événements, pas par le pas de sortie.

## 7. Restrictions et suites

Maître uniquement (l'I2C esclave côté microcontrôleur suppose un second `MCU`, donc le multi-instance — cf. TODO) ; un seul bus ; pas de clock stretching ni d'arbitrage multi-maître ; 1 kHz - 1 MHz ; 256 octets par transaction ; un esclave acquitte toujours ; au plus 4 adresses par composant. Détails dans `requirements.md`.
