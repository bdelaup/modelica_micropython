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
| `.irq(handler, trigger)` | `irq(handler=None, trigger=IRQ_RISING\|IRQ_FALLING, **kwargs)` | Enregistre (ou efface, si `handler=None`) un callback appelé sur un front correspondant au `trigger`. Le callback reçoit l'objet `Pin` en argument (`handler(pin)`), comme sur le vrai MicroPython. `**kwargs` absorbe `hard=`/`priority=`/`wake=` pour compatibilité de signature, sans effet (cf. Limitations). | Oui |

Constantes de `trigger` : `Pin.IRQ_RISING = 1`, `Pin.IRQ_FALLING = 2` (à combiner par `|` pour les deux sens ; valeurs propres à ce shim, pas garanties identiques à un port MicroPython réel — sans conséquence, un script utilise toujours les noms symboliques). Le callback tourne « soft » : il est exécuté au prochain point de réveil du worker (celui qui a déclenché la transition, ou tout point de synchro ultérieur si le worker était déjà occupé), jamais en préemption immédiate du script — cf. `cycle-de-vie.md` pour le mécanisme exact (« pitstop »). Une transition d'entrée réveille le script même sans `irq()` enregistré (comportement déjà existant, « réactivité en entrée ») : enregistrer un `irq()` ajoute l'appel du callback à ce réveil, ça ne change pas le fait que le `sleep()` en cours retourne quand même en avance.

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

## `machine.PWM`

```python
from machine import Pin, PWM
pwm = PWM(Pin(0))
pwm.freq(1000)          # Hz
pwm.duty_u16(32768)     # 0-65535 (~50%)
```

Une fois configuré, le créneau est généré **en continu côté Modelica** (expression `mod(time, période)` dans `MCU.mo`), sans aller-retour avec le thread Python à chaque front — le script peut se terminer, le PWM continue de tourner, fidèle au vrai périphérique matériel du RP2040. Voir `requirements.md`, décision « PWM (sorties modulées) », pour le détail du mécanisme et sa validation.

### Constructeur

`PWM(pin, freq=None, duty_u16=None)` — `pin` : `0`-`7` (entier) ou objet `Pin` (son `.id` est utilisé). Prend la broche en sortie (comme le vrai RP2040). `freq`/`duty_u16` optionnels, équivalents à appeler `.freq()`/`.duty_u16()` juste après construction.

### Méthodes

| Méthode | Signature | Comportement | Synchronise ? |
|---|---|---|---|
| `.freq(f)` | `freq(f)` | Configure la fréquence PWM (Hz) ; place aussi la broche en sortie | Oui |
| `.freq()` | `freq() -> int` | Renvoie la dernière fréquence configurée (valeur mise en cache côté Python, pas de nouvel appel natif) | **Non** |
| `.duty_u16(d)` | `duty_u16(d)` | Configure le rapport cyclique (0-65535, borné) | Oui |
| `.duty_u16()` | `duty_u16() -> int` | Renvoie le dernier rapport cyclique configuré (valeur mise en cache) | **Non** |
| `.deinit()` | `deinit()` | Arrête le PWM ; la broche repasse en sortie numérique classique (bas par défaut) | Oui |

## `machine.Timer`

```python
from machine import Timer
tim = Timer()
tim.init(period=500, mode=Timer.PERIODIC, callback=lambda t: led.toggle())
tim.deinit()
```

Minuteur logiciel : une fois armé, le callback continue de se déclencher **pendant** un `sleep()` déjà en cours ailleurs dans le script, sans jamais le faire retourner en avance — mécanisme de « pitstop », cf. `cycle-de-vie.md` et `requirements.md` (décision « Interruptions sur broche et minuteurs logiciels »).

### Constantes

| Constante | Valeur | Usage |
|---|---|---|
| `Timer.ONE_SHOT` | `0` | le callback se déclenche une seule fois puis le timer se désarme tout seul |
| `Timer.PERIODIC` | `1` | le callback se redéclenche indéfiniment toutes les `period` ms |

### Constructeur

`Timer(id=-1)` — `id` accepté pour compatibilité de signature avec MicroPython, ignoré (v0 : un pool fixe de 4 minuteurs logiciels partagé par tous les `Timer()`, cf. Limitations). Ne synchronise pas (pure allocation d'un emplacement dans le pool).

### Méthodes

| Méthode | Signature | Comportement | Synchronise ? |
|---|---|---|---|
| `.init(period, mode, callback)` | `init(period=1000, mode=PERIODIC, callback=None)` | Arme (ou réarme) le minuteur : `period` en **millisecondes** (comme le vrai MicroPython), `mode` = `ONE_SHOT`/`PERIODIC`, `callback` reçoit l'objet `Timer` en argument (`callback(timer)`) | Oui |
| `.deinit()` | `deinit()` | Arrête et libère le minuteur (son emplacement redevient disponible pour un futur `Timer()`) | Oui |

## `machine.Display`

```python
from machine import Display
display = Display(0)
display.write("Bonjour")        # vers un Peripherals.Display cable sur MCU.Display0
```

Liaison logique unique et **écriture seule** vers un périphérique d'affichage pédagogique (`Display0` côté `MCU`). Ce n'est pas un vrai protocole UART/Serial : pas de réception, pas d'adressage. Contrairement aux broches `GPx`, la liaison n'est pas électrique (`Modelica.Electrical.Analog`) mais un connecteur logique causal (`Interfaces.DisplayLinkOutput`/`DisplayLinkInput`) : le message est livré **instantanément** au point de synchro suivant, pas de simulation de bauds ni de forme d'onde série bit-à-bit — cf. `requirements.md`, décision « Périphérique d'affichage pédagogique ».

### Constructeur

`Display(id=0, **kwargs)` — `id` : seul `0` est supporté (`ValueError` sinon). `**kwargs` accepté pour une signature volontairement souple mais sans effet en v0. Ne synchronise pas.

### Méthodes

| Méthode | Signature | Comportement | Synchronise ? |
|---|---|---|---|
| `.write(text)` | `write(text)` | Transmet `text` (converti en `str` si nécessaire) au périphérique câblé sur `MCU.Display0` ; livraison instantanée, message entier d'un coup (pas de découpage octet par octet) | Oui |

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
- Pas d'`I2C`, `SPI`, ni de vrai `UART`/`Serial` sur les broches GPIO — voir le TODO de `requirements.md` pour les extensions prévues.
- `machine.Display` : une seule liaison logique, **écriture seule** (pas de réception), livraison instantanée du message entier (pas de bauds simulés) ; liaison modélisée comme un connecteur logique causal, pas électrique — cf. `requirements.md`, décision « Périphérique d'affichage pédagogique ».
- `Pin.irq()` : tout callback tourne « soft » (déféré au prochain point de réveil du worker) ; `hard=` accepté mais sans effet — aucune notion de contexte d'interruption matérielle possible dans ce modèle mono-thread. Une exception levée dans un callback arrête toute la simulation (même politique que le script principal), pas d'isolation « le callback plante mais le reste continue ».
- `machine.Timer` : pool fixe de 4 minuteurs partagé par tous les `Timer()` (au-delà, `Timer()` lève `RuntimeError`) ; période minimale 1 ms (`ValueError` en dessous, garde-fou contre une tempête d'événements à durée simulée nulle).
- `ADC.read_u16()` : référence de conversion (3,3 V) codée en dur dans le shim, pas liée au paramètre `VOH` de `MCU` ; pas d'échantillonnage périodique ni d'événement de seuil (contrairement à une broche numérique en entrée, une variation sur l'ADC ne réveille jamais le script — il faut l'interroger explicitement).
- `PWM` : chaque broche a sa fréquence/rapport cyclique indépendants (le vrai RP2040 partage un canal de fréquence entre deux broches voisines, pas modélisé ici) ; `deinit()` repasse la broche en sortie numérique **basse**, pas en haute impédance.
- **Relire une broche juste après avoir écrit sur une autre (même physiquement reliées) peut renvoyer l'état d'*avant* l'écriture.** Plusieurs appels au shim qui s'enchaînent sans qu'aucun ne demande un vrai délai restent dans le même passage côté runtime C, sans repasser par la résolution du circuit Modelica entre-temps — la lecture voit alors un instantané pris avant l'écriture qui vient de se produire. Il faut un point de synchro explicite entre les deux (n'importe quel `sleep`/`sleep_ms`/`sleep_us` non nul suffit, même très court) pour forcer ce passage. Exemple concret : [`Examples/PinEcho.mo`](../MicroPythonMCU/Examples/PinEcho.mo) (script [`pin_echo.py`](../MicroPythonMCU/Resources/Scripts/pin_echo.py)), où `GP2` relit électriquement ce que le script vient d'écrire sur `GP1`.
