## MicroPythonMCU

**Modèle de microcontrôleur programmable en python pour OpenModelica**

`MicroPythonMCU` fournit un modèle OpenModelica (`MCU`) dont le comportement est exécuté par un script Python compatible [MicroPython](https://micropython.org/) (API `machine`/`time`, référence Raspberry Pi Pico / RP2040).

 Usage : tester un code de pilotage sur le jumeau numérique avant de le déployer sur un prototype réel (pédagogique ou industriel). 
 
 Détails d'architecture : [`requirements.md`](requirements.md).

## Installation

- [OpenModelica](https://openmodelica.org/download/download-windows/) avec OMEdit (testé avec `1.27.1-64bit`) — le toolchain de compilation est déjà inclus, rien d'autre à installer (le runtime Python est vendoré dans la bibliothèque).
- Windows uniquement pour cette v0.

Dans OMEdit : *File → Open Model/Library File(s)…* → sélectionner `MicroPythonMCU/package.mo`. La bibliothèque et ses exemples (`MicroPythonMCU.Examples`) apparaissent dans l'explorateur.

<p align="center"><img src="docs/images/library_tree.png" alt="Tree" width=""></p>

## Démarrage rapide

<p align="center"><img src="docs/images/basicblink.png" alt="schema MCU blik" width=""></p>

1. Ouvrir et simuler `MicroPythonMCU.Examples.BasicBlink` : `GP0` clignote (`Resources/Scripts/demo.py`).
2. Dans les paramètres du composant `MCU`, pointer **Chemin du script** (bouton *…*) vers votre propre `.py` :

   ```python
   from machine import Pin
   import time

   led = Pin(0, Pin.OUT)
   while True:
       led.on()
       time.sleep(1)
       led.off()
       time.sleep(1)
   ```

   Ce même fichier peut être copié tel quel sur un vrai Raspberry Pi Pico.
3. Un second fichier `.py` posé à côté du script devient automatiquement importable (`addScriptDirToPath`) ; pour une bibliothèque partagée dans un autre dossier, utiliser le paramètre `libraryPath` (voir `Examples.ImportDemo`).

## API `machine` / `time`

Référence complète (toutes les signatures, ce qui synchronise ou non le script) : [`docs/api-machine.md`](docs/api-machine.md). Aperçu :

```python
from machine import Pin, ADC, PWM
import time

# Pin — GPIO numérique
led = Pin(0, Pin.OUT)          # ou Pin(Pin.LED, Pin.OUT) pour la LED embarquée
btn = Pin(1, Pin.IN)
led.on(); led.off(); led.toggle()
btn.value()                     # lit l'état résolu de la broche (0/1)

# ADC — entrée analogique
adc = ADC(2)                    # n'importe laquelle de GP0-GP7
niveau = adc.read_u16()         # 0-65535, référence 3,3 V

# PWM — sortie modulée, générée en continu côté Modelica une fois configurée
pwm = PWM(Pin(3))
pwm.freq(1000)                  # Hz
pwm.duty_u16(32768)             # 0-65535 (~50%)

# time — horloge simulée, sleep() compressé (pas d'attente réelle)
time.sleep(1)                   # sleep_ms()/sleep_us() aussi disponibles
time.ticks_ms()                 # ne synchronise pas (simple lecture)
```

## Vérifier l'installation

```
cd MicroPythonMCU/Resources/Verification
omc verify_01_basic_blink.mos   # … verify_09_import.mos
```

nécessite `omc` sur le `PATH` et `OPENMODELICAHOME` positionné — détail : [`docs/tests.md`](docs/tests.md).

## Documentation

| Document | Contenu |
|---|---|
| [`requirements.md`](requirements.md) | Source de vérité : besoin, décisions d'architecture (avec alternatives), restrictions v0, roadmap |
| [`docs/architecture.md`](docs/architecture.md) | Arborescence du dépôt |
| [`docs/integration-python.md`](docs/integration-python.md) | Intégration CPython/OpenModelica, shim `machine`/`time` |
| [`docs/cycle-de-vie.md`](docs/cycle-de-vie.md) | Protocole de synchro (diagrammes de séquence), pièges rencontrés |
| [`docs/api-machine.md`](docs/api-machine.md) | Référence API `machine`/`time` |
| [`docs/tests.md`](docs/tests.md) | Rejouer/ajouter un scénario de vérification |

## État

- [x] GPIO numériques (`machine.Pin`)
- [x] Entrées analogiques (`machine.ADC`)
- [x] Sorties modulées (`machine.PWM`)
- [x] Compression des `sleep`
- [x] Import de modules auxiliaires
- [x] Circuit électrique réel (pas de signaux logiques abstraits)
- [x] LED embarquée
- [x] Gestion des erreurs de script
- [ ] I2C / SPI / UART
- [ ] Timers / interruptions
- [ ] Multi-instances
- [ ] Linux / macOS

Liste complète et justifications : [`requirements.md`](requirements.md#todo-vers-une-version-exhaustive).

## Licence

[MIT](LICENSE) — attribution obligatoire (copyright + texte de licence) dans toute copie ou republication, totale ou partielle. La distribution Python vendorée (`MicroPythonMCU/Resources/PythonRuntime/`) garde sa propre licence (Python Software Foundation).

## Contexte

Projet porté par B. Delaup, enseignant en sciences de l'ingénieur. MicroPythonMCU a vocation à être à la croisée d'un usage pédagogique (tester avant de déployer sur un prototype réel) et d'un usage industriel (jumeau numérique de logiciel embarqué).

En partie développer avec l'aide d'IA.
