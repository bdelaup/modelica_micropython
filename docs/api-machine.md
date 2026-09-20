# API `machine` / `time` côté script (v0)

Cette page documente, du point de vue de qui **écrit un script** pour `MCU`, le sous-ensemble de l'API MicroPython `machine`/`time` réellement implémenté en v0. Pour savoir *comment* ce shim est construit et intégré à CPython, voir [integration-python.md](integration-python.md) ; pour le protocole de synchronisation qui se cache derrière chaque appel, voir [cycle-de-vie.md](cycle-de-vie.md). L'implémentation exacte (source de vérité) est la chaîne `SHIM_BOOTSTRAP` dans `MicroPythonMCU/Resources/Include/PyRuntimeImpl.c` ; un miroir lisible en est tenu à jour dans [shim/machine_time_shim.py](shim/machine_time_shim.py).

**Notion clé** : un appel qui *synchronise* rend la main à Modelica (le solveur peut avancer le temps simulé, éventuellement jusqu'à un `sleep` en cours) avant de continuer le script — c'est ce qui rend une transition d'entrée ou un `sleep` visibles/compressibles côté simulation. Un appel qui ne synchronise pas est une simple lecture immédiate de l'état déjà connu du script.

## `machine.Pin`

```python
from machine import Pin
led = Pin(0, Pin.OUT)          # ou Pin(Pin.LED, Pin.OUT) pour la LED embarquée
```

### Constantes

| Constante | Valeur | Usage |
|---|---|---|
| `Pin.IN` | `0` | mode entrée, passé à `mode=` |
| `Pin.OUT` | `1` | mode sortie, passé à `mode=` |
| `Pin.PULL_UP` | `2` | passé à `pull=` — accepté mais **sans effet électrique** (cf. Limitations) |
| `Pin.PULL_DOWN` | `3` | idem |
| `Pin.LED` | `25` | identifiant de la LED embarquée (câblée en interne sur `MCU`, pas un connecteur `GPx`) |

### Constructeur

`Pin(id, mode=None, pull=None)`

- `id` : `0`-`7` (broches `GP0`-`GP7`), ou `25`/`Pin.LED`/`"LED"` (LED embarquée). Toute autre valeur lève `ValueError` au premier appel qui la résout (`pin_init`/`pin_write`/`pin_read`).
- `mode` : `Pin.IN` ou `Pin.OUT`. Si omis, la direction n'est pas (re)configurée — utile pour se contenter de lire l'état déjà en place. **Synchronise** si fourni (appelle `pin_init`).
- `pull` : accepté pour compatibilité de signature avec MicroPython, ignoré (v0).

### Méthodes

| Méthode | Signature | Comportement | Synchronise ? |
|---|---|---|---|
| `.value()` | `value() -> int` | Lit l'état résolu de la broche (0/1), quelle que soit sa direction | Oui |
| `.value(x)` | `value(x)` | Pilote la broche à `x` (0/1) — sans effet si la broche est actuellement en entrée | Oui |
| `.on()` | `on()` | Équivalent à `value(1)` | Oui |
| `.off()` | `off()` | Équivalent à `value(0)` | Oui |
| `.toggle()` | `toggle()` | Inverse l'état courant (lit puis réécrit l'opposé) — implémenté en Python pur au-dessus de `value()`, pas d'appel natif dédié | Oui (via `value()`, deux fois) |

## `machine.ADC`

```python
from machine import ADC
adc = ADC(1)                   # ou ADC(Pin(1))
v = adc.read_u16()             # 0-65535
```

### Constructeur

`ADC(id)` — `id` : `0`-`7` (n'importe laquelle des broches `GP0`-`GP7`, utilisées en analogique plutôt qu'en numérique — v0 : **toutes** ADC-capables, contrairement au vrai Pico où seules `GP26`-`GP28` le sont) ou un objet `Pin` (son `.id` est utilisé). La LED embarquée (`25`/`Pin.LED`) n'est pas ADC-capable. Ne synchronise pas et ne modifie ni la direction ni l'état piloté de la broche — la construction seule n'a aucun effet électrique.

### Méthodes

| Méthode | Signature | Comportement | Synchronise ? |
|---|---|---|---|
| `.read_u16()` | `read_u16() -> int` | Lit la tension mesurée sur la broche et la restitue sur 16 bits (`round(v / 3.3 * 65535)`, bornée à `[0, 65535]`) | Oui |

## `time`

```python
import time
time.sleep(1)
```

| Fonction | Signature | Comportement | Synchronise ? |
|---|---|---|---|
| `sleep(s)` | secondes (`float`/`int`) | Suspend le script jusqu'à `sim_time + s` ; le temps simulé peut être avancé directement jusqu'à ce point (compression du sleep, cf. `cycle-de-vie.md`) | Oui |
| `sleep_ms(ms)` | millisecondes | Équivalent à `sleep(ms/1000)` | Oui |
| `sleep_us(us)` | microsecondes | Équivalent à `sleep(us/1e6)` | Oui |
| `ticks_ms()` | — | Horloge simulée courante, en ms (`sim_time * 1000`) | **Non** — simple lecture |
| `ticks_us()` | — | Horloge simulée courante, en µs | **Non** |
| `ticks_diff(a, b)` | — | `a - b` (fonction Python pure, pas d'appel natif) | **Non** |

`ticks_ms()`/`ticks_us()` sont délibérément exclus de la synchronisation : une boucle de polling non bloquante (`while ticks_diff(...) < ...`) resterait ainsi bon marché plutôt que de déclencher un point de synchro à chaque itération.

## Limitations connues (v0)

Détails et justifications dans `requirements.md` (section Restrictions v0) :

- `pull` (`Pin.PULL_UP`/`Pin.PULL_DOWN`) accepté en paramètre mais sans résistance de tirage réellement modélisée.
- Seules les broches `0`-`7` et `25`/`Pin.LED` sont reconnues (pas les 29 broches du vrai Pico).
- Aucune autre classe `machine.*` (pas de `PWM`, `Timer`, `I2C`, `SPI`, `UART`) — voir le TODO de `requirements.md` pour les extensions prévues.
- Pas d'`irq()` sur `Pin` (interruptions sur changement d'état).
- `ADC.read_u16()` : référence de conversion (3,3 V) codée en dur dans le shim, pas liée au paramètre `VOH` de `MCU` ; pas d'échantillonnage périodique ni d'événement de seuil (contrairement à une broche numérique en entrée, une variation sur l'ADC ne réveille jamais le script — il faut l'interroger explicitement).
- **Relire une broche juste après avoir écrit sur une autre (même physiquement reliées) peut renvoyer l'état d'*avant* l'écriture.** Plusieurs appels au shim qui s'enchaînent sans qu'aucun ne demande un vrai délai restent dans le même passage côté runtime C, sans repasser par la résolution du circuit Modelica entre-temps — la lecture voit alors un instantané pris avant l'écriture qui vient de se produire. Il faut un point de synchro explicite entre les deux (n'importe quel `sleep`/`sleep_ms`/`sleep_us` non nul suffit, même très court) pour forcer ce passage. Exemple concret : [`Examples/PinEcho.mo`](../MicroPythonMCU/Examples/PinEcho.mo) (script [`pin_echo.py`](../MicroPythonMCU/Resources/Scripts/pin_echo.py)), où `GP2` relit électriquement ce que le script vient d'écrire sur `GP1`.
