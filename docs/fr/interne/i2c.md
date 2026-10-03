# Bus I2C : `machine.I2C`, `machine.I2CTarget` et les périphériques esclaves

!!! info "Référence interne"
    Cette page décrit le fonctionnement interne. Pour utiliser le composant (câblage, paramètres, exemples) : [Périphériques I2C](../guide/peripheriques/i2c.md).

Cette page décrit **comment** est construit le bus I2C : le maître côté microcontrôleur (`machine.I2C`), la classe de base des périphériques esclaves (`Internal.PartialI2cDevice`), le contrat des scripts Python qui décrivent ces périphériques, et l'écran Grove LCD RGB. Le **pourquoi** (alternatives écartées, restrictions) est dans [`requirements.md`](https://gitlab.com/bdelaup/modelica_micropython3/-/blob/main/requirements.md), décision « Bus I2C électrique en drain ouvert ».

## 1. Un vrai bus électrique, en drain ouvert

Deux fils partagés, `SDA` (données) et `SCL` (horloge), plus la masse. Personne ne force jamais une ligne à l'état haut : chaque acteur (le microcontrôleur, chaque périphérique) ne sait que **tirer la ligne à la masse** ou la **relâcher**. Ce sont les **résistances de tirage** qui remontent une ligne relâchée. Conséquences directes, sans une ligne de code pour les obtenir :

- **ET câblé** : une ligne est basse dès qu'au moins un acteur la tire. C'est ainsi qu'un esclave acquitte (il tire SDA pendant que le maître la relâche), et qu'autant de périphériques qu'on veut se partagent les deux fils — Kirchhoff fait la résolution de bus.
- **Sans tirage externe, rien ne marche** : `I2C()` active les tirages internes de 50 kΩ de SCL et SDA (`pin_pull`, comme le port `rp2`), mais face aux 10 pF d'entrée de chaque périphérique ils donnent des fronts montants de plusieurs microsecondes. SCL relâchée est encore basse un quart de période plus tard : le maître lève `OSError(ETIMEDOUT)`, le symptôme d'un montage réel où on a oublié les résistances (`Examples.I2c.NoPullUp` : 50 kΩ × 30 pF = 1,5 µs, contre 0,625 µs à 400 kHz).

| Côté | Tirer à la masse | Relâcher | Lire |
|---|---|---|---|
| Microcontrôleur (`MCU`, **aucune modification de `MCU.mo`**) | broche en sortie à l'état bas (`pinIsOutputD = true`, `pinBoolOut = false`) | broche en entrée (interrupteur ouvert, haute impédance) | `pinBoolIn` |
| Périphérique (`Internal.PartialI2cDevice`) | conductance variable `sdaOut.G = 1/ROut` (SDA seulement) | `sdaOut.G = GOff` | `VoltageSensor` + seuil |

Les tirages sont portés par les périphériques : paramètre `usePullUp` (désactivé par défaut, `RPullUp = 4,7 kΩ`), composants conditionnels. Le Grove l'active, comme le module réel ; plusieurs paires se mettent en parallèle.

Chaque broche de périphérique porte aussi une capacité d'entrée `CIn` (10 pF). **Elle n'est pas cosmétique** : elle fait de SDA et SCL des états dynamiques, ce qui rompt la dépendance entre le `when` du microcontrôleur et ceux des esclaves (même rôle que `CIn` des périphériques série, cf. [peripheriques-uart-externes.md](uart-peripheriques.md)). Elle fixe aussi le temps de montée : 4,7 kΩ × 10 pF = 47 ns, très en dessous du quart de période à 400 kHz (625 ns). Augmenter `CIn` ou `RPullUp` dégrade les fronts, comme sur un vrai bus trop chargé.

`CIn` est reliée à la broche à travers une résistance de plot `RIn` (10 Ω), et le transistor de SDA comme les capteurs de tension sont branchés sur ce nœud interne. Sans elle, les capacités de plusieurs périphériques d'un même bus seraient en parallèle : une seule variable pour omc après fusion des alias, portant plusieurs `start` fixés (avertissement « alias variables with redundant start »). Le nœud lu par le `when` reste un état dynamique, la rupture de boucle est inchangée ; `RIn` × `CIn` = 100 ps.

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

`Resources/Include/i2ctarget.h/.c` (moteur cible **partagé** par les périphériques, `I2cDeviceImpl.c` + `i2cdevice/`, et par `machine.I2CTarget` du microcontrôleur, §5bis ; même idiome qu'`uartcore`). L'esclave n'a pas d'horloge : il **suit** celle du maître. Le `when` de `PartialI2cDevice` se déclenche à chaque franchissement de seuil de SCL ou de SDA ; `I2cDevice_sync` passe les niveaux à `i2ct_sync`, qui les compare à ceux du dernier appel. Ce que l'hôte fait des octets passe par des crochets (`addr_match`, `write_byte`, `write_end`, `read_byte`, `read_end`) : pour un périphérique, ce sont `on_write()`/`on_read()` et le journal.

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

## 5bis. La cible côté microcontrôleur : `machine.I2CTarget`

`Resources/Include/pyruntime/pyruntime_i2ctarget.c`, classe `I2CTarget` du shim. Un `MCU` peut être l'esclave d'un autre `MCU` (`Examples.MultiMcu.I2c` et `I2cIrq`). Le décodeur est **le même** que celui des périphériques (`i2ctarget.c`, §3) ; ce que le microcontrôleur fait des octets passe par les crochets du moteur, appelés sur le thread Modelica pendant `PyRuntime_sync` :

| Crochet | Mode mémoire (`mem=`) | Sans mémoire |
|---|---|---|
| `addr_match` | remet à zéro le compteur d'octets d'adresse | — |
| `write_byte` | `mem_addrsize/8` premiers octets → `memaddr`, puis écriture dans `mem[memaddr++]` (rebouclage) | file `rx` (lue par `readinto()`), `IRQ_WRITE_REQ` |
| `write_end` | `IRQ_END_WRITE`, sauf si l'écriture n'a fait que choisir l'adresse | `IRQ_END_WRITE` |
| `read_byte` | `mem[memaddr++]` | file `tx` (remplie par `write()`) ; vide → `I2CT_DEFER` + `IRQ_READ_REQ` si un gestionnaire peut répondre, sinon `0xFF` |
| `read_end` | `IRQ_END_READ` | `IRQ_END_READ` |

Côté électrique, rien de neuf : les deux broches sont prises (`i2c_claimed`, ni réveil ni IRQ GPIO), SDA est tirée ou relâchée par `i2c_drive` comme pour le maître, SCL n'est jamais tenue (pas de clock stretching).

**La mémoire est écrite sans le GIL.** Le `bytearray` de `mem=` est exporté une fois (`PyObject_GetBuffer`, tampon tenu jusqu'à `deinit()` : sa taille ne peut plus changer), et le C y lit et écrit directement pendant `PyRuntime_sync`. C'est sûr parce que le worker est **garé** pendant toute la synchro (alternance stricte des tours) : aucun code Python du microcontrôleur ne peut toucher `mem` au même moment. Le mode mémoire continue donc de répondre après la fin du programme.

**IRQ au même instant.** Un événement dont le déclencheur est demandé pose `i2ct.irq_pending`. `PyRuntime_sync` ajoute cette condition au drain (`i2ct_due`) : le worker reçoit un pitstop au même instant simulé, `run_due_callbacks` remet les drapeaux (`irq().flags()`) et appelle le gestionnaire. Pour `IRQ_READ_REQ`, le moteur a **différé** l'octet (`read_deferred`, SDA relâchée) ; après le drain, `i2ct_finish` → `i2ct_resume` redemande l'octet (sans nouveau report : `0xFF` si le gestionnaire n'a rien écrit) et fixe SDA avant que les sorties ne soient publiées. Le maître échantillonne SDA un quart de période plus tard : il voit le bon bit, sans clock stretching.

## 6. Ce que vérifient les scénarios

| Script | Modèle | Ce qui est vérifié |
|---|---|---|
| `verify_21_i2c_echo.mos` | `Examples.I2c.Echo` | START conforme, ACK de l'adresse tenu par l'esclave, trame de 9 octets écrite puis relue, lecture de registre derrière un START répété |
| `verify_22_i2c_multi.mos` | `Examples.I2c.MultiDevice` | Trois esclaves sur un bus, deux paires de tirages en parallèle, 400 kHz : `scan()` exact, pas de diaphonie, `EIO` sur une adresse absente |
| `verify_23_i2c_nopullup.mos` | `Examples.I2c.NoPullUp` | Sans tirage externe : lignes au repos à 3,3 V (tirages internes), mais `ETIMEDOUT`, `scan()` vide, aucun esclave sollicité |
| `verify_24_i2c_grove_lcd.mos` | `Examples.I2c.GroveLcd` | Driver du commerce tel quel : écran éteint puis « hello World », rétroéclairage rouge, vert, bleu |
| `verify_37_multi_i2c_mem.mos` | `Examples.MultiMcu.I2c` | Cible `MCU` en mode mémoire : `scan()` = `[0x42]`, registre 4 → LED de B, registres 0-1 relus (2,000 V) |
| `verify_38_multi_i2c_irq.mos` | `Examples.MultiMcu.I2cIrq` | Cible `MCU` à gestionnaire : `ID` → `b'MCU-B'`, puis `CNT` → 2 et 3 (`IRQ_READ_REQ` servi au même instant) |

**Message « Chattering detected ... `time >= pre(mcu.nextWakeTime)` »** dans le journal : information bénigne d'OpenModelica, qui signale 100 événements d'affilée dans un seul pas de sortie. Elle apparaît quand l'intervalle de sortie (`Interval`) est grand devant la période d'horloge du bus ; les exemples fournis choisissent un intervalle qui l'évite. Ce n'est pas une erreur : la séquence I2C est pilotée par événements, pas par le pas de sortie.

## 7. Restrictions et suites

Un seul bus maître et une seule cible (`I2CTarget`, adresse 7 bits, pas d'IRQ après la fin du programme) par microcontrôleur ; pas de clock stretching ni d'arbitrage multi-maître ; 1 kHz - 1 MHz ; 256 octets par transaction ; un esclave acquitte toujours ; au plus 4 adresses par composant. Détails dans `requirements.md`.
