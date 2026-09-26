# Architecture — arborescence et rôles

## Vue d'ensemble

`MicroPythonMCU` est une bibliothèque OpenModelica classique (dossier = package Modelica), avec deux ajouts par rapport à une bibliothèque purement Modelica :
- un morceau de code C (`Resources/Include/PyRuntimeImpl.c`) compilé par `omc` lui-même via les annotations `Include`/`Library` d'un *External Object* ;
- une distribution Python complète vendorée dans `Resources/PythonRuntime/`, pour que le modèle n'ait besoin d'aucun Python installé sur le poste qui l'exécute.

```mermaid
graph TD
    subgraph LIB["MicroPythonMCU (package Modelica)"]
        MCU["MCU (model)<br/>pont électrique GPIO + orchestration"]
        Interfaces["Interfaces (package)<br/>constantes VOH/VOL/VIH/VIL/ROut<br/>+ connecteurs logiques DisplayLinkOutput/DisplayLinkInput"]
        Internal["Internal (package)<br/>PyRuntime (ExternalObject) + PyRuntime_sync"]
        Peripherals["Peripherals (package)<br/>LED : icône réactive au courant<br/>Display : affiche le texte reçu (icône, 20x2, défilement) - périphérique pédagogique"]
        Examples["Examples (package)<br/>13 scénarios de vérification + LedChaser (démonstrateur)"]
    end
    subgraph RES["Resources"]
        Include["Include/<br/>PyRuntimeImpl.c (chapeau) + .h<br/>+ pyruntime/ (parties incluses)<br/>+ cpython312/ (en-têtes vendorés)"]
        Library["Library/win64/<br/>libpython312.a<br/>(import lib régénérée MinGW)"]
        PythonRuntime["PythonRuntime/<br/>distribution Python « embeddable »<br/>(DLL + stdlib zip)"]
        Scripts["Scripts/<br/>MCU/ + Device/ + _shim/machine_time_shim.py"]
        Verification["Verification/<br/>scripts .py + .mos de test"]
    end

    MCU -- "paramètres VOH/VOL/..." --> Interfaces
    MCU -- "instancie (protected)" --> Internal
    MCU -- "builtinLed (public, GP25 interne)" --> Peripherals
    MCU -- "Display0 (Interfaces.DisplayLinkOutput)" --> Interfaces
    Examples -- "extends / utilise" --> MCU
    Examples -- "Peripherals.LED (LedChaser)" --> Peripherals
    Examples -- "Peripherals.Display (DisplayDemo)" --> Peripherals
    Peripherals -- "displayLink (Interfaces.DisplayLinkInput)" --> Interfaces
    Internal -- "Include = PyRuntimeImpl.c" --> Include
    Internal -- "LibraryDirectory" --> Library
    Internal -- "pythonHome (loadResource, runtime)" --> PythonRuntime
    MCU -- "scriptPath par défaut + shimPath (loadResource)" --> Scripts
    Verification -. "scripts appelés par les Examples" .-> Examples
```

*Nom de classe* : le modèle s'appelait `Pico` pendant l'implémentation v0, renommé `MCU` ensuite pour ne pas afficher la carte cible (Raspberry Pi Pico / RP2040) directement sur l'identité visuelle publique — cf. `requirements.md`, décision « Nom de la classe modèle et identité visuelle ». La référence RP2040 reste la cible d'API interne (`machine`/`time`).

## Arborescence commentée

```
modelica_micropython3/
├── requirements.md                 -- besoin, décisions d'architecture, restrictions v0, TODO (source de vérité du "pourquoi")
├── CLAUDE.md                       -- guidance pour Claude Code dans ce dépôt
├── docs/                           -- cette documentation (le "comment")
└── MicroPythonMCU/                 -- la bibliothèque OpenModelica elle-même
    ├── package.mo, package.order   -- déclaration du package racine
    ├── MCU.mo                      -- LE modèle : icône, 8 broches GP0-GP7 + GND (chacune numérique, analogique OU PWM, au choix du script), pont électrique, LED embarquée GP25 (même pont, interne, pas de connecteur), port Display0 (connecteur logique causal vers un périphérique d'affichage pédagogique), import de modules auxiliaires (addScriptDirToPath/libraryPath), orchestration de la synchro
    ├── Interfaces/                 -- constantes de niveaux de tension (VOH, VOL, VIH, VIL, ROut) — approximation RP2040 ; connecteurs logiques causaux DisplayLinkOutput/DisplayLinkInput (liaison d'affichage pédagogique, pas électrique)
    ├── Internal/                   -- détails d'implémentation, non destinés à l'usage direct
    │   ├── PyRuntime.mo            -- ExternalObject : constructor (démarre CPython + thread) / destructor
    │   ├── PyRuntime_sync.mo       -- impure function : le point de synchro appelé depuis le `when` de MCU
    │   ├── StringToCharCodes.mo    -- function utilitaire (external "C", indépendante de PyRuntime) : String -> Integer[n] de codes ASCII, pour afficher du texte sur une icône (String non storable dans les résultats de simulation)
    │   ├── UartDevice.mo           -- ExternalObject d'un périphérique série externe : files TX/RX, décodage, table de commandes, échéances. AUCUNE dépendance à Python (pas de Library = "python312")
    │   ├── UartDevice_sync.mo      -- impure function : le point de synchro appelé depuis le `when` de Internal.PartialUartDevice
    │   ├── TwoLineTextIcon.mo      -- partial model purement graphique : les 40 cellules de texte d'un afficheur 20x2, partagées par Display et UartLcd20x2
    │   ├── PartialUartDevice.mo    -- partial model : TOUTE la mécanique des appareils série externes (pont électrique, décodage, deux modes d'émission, ports réels). Non instanciable : Peripherals ne contient que des composants posables
    │   ├── I2cDevice.mo            -- ExternalObject d'un périphérique I2C esclave : décodeur du bus piloté par les fronts, script Python (on_write / on_read / outputs / lines)
    │   ├── I2cDevice_sync.mo       -- impure function : le point de synchro appelé à chaque front de SCL ou de SDA depuis le `when` de Internal.PartialI2cDevice
    │   ├── PartialI2cDevice.mo     -- partial model : TOUTE la mécanique des périphériques I2C (pont en drain ouvert sur SDA, capacités d'entrée, tirages conditionnels usePullUp, décodage). Non instanciable
    │   └── Lcd16x2RgbIcon.mo       -- partial model purement graphique : 32 cellules de texte d'un écran 16x2 et fond à la couleur du rétroéclairage RGB (généré mécaniquement)
    ├── Peripherals/                -- composants connectables à MCU
    │   ├── LED.mo                  -- diode + icône réactive au courant (DynamicSelect colorOff→colorOn), utilisée par MCU et par les exemples
    │   ├── Display.mo              -- afficheur pédagogique à liaison LOGIQUE (machine.Display), écriture seule ; hérite de Internal.TwoLineTextIcon pour le rendu du texte
    │   ├── UartGenericDevice.mo    -- appareil série entièrement décrit par ses paramètres (aucune classe à écrire)
    │   ├── UartEchoDevice.mo       -- dérivé : renvoie tel quel chaque octet reçu
    │   ├── UartTemperatureSensor.mo-- dérivé : répond AT+TEMP par la valeur de valueIn, et SET <n> capture n vers valueOut
    │   ├── UartGpsModule.mo        -- dérivé : pousse une trame $GPGLL toutes les period secondes, sans sollicitation
    │   ├── UartLcd20x2.mo          -- dérivé : affiche sur son icône les lignes décodées sur RX (hérite aussi de Internal.TwoLineTextIcon)
    │   ├── I2cGenericDevice.mo     -- périphérique I2C dont tout le comportement vient d'un script (gabarit Device/i2c_generic.py : banc de registres)
    │   ├── I2cEchoDevice.mo        -- périphérique I2C de test (0x42) : relit au maître sa dernière écriture
    │   └── I2cGroveLcdRgb.mo       -- écran Grove - LCD RGB Backlight : JHD1313 à 0x3E + PCA9633 à 0x62, tirages activés (hérite aussi de Internal.Lcd16x2RgbIcon)
    ├── Examples/                   -- un modèle par scénario de vérification de requirements.md ; la liaison série dans le sous-paquetage Uart/
    │   ├── BasicBlink.mo           -- scénario 1 : clignotement de base
    │   ├── LedChaser.mo            -- chenillard bidirectionnel sur les 8 GPIO (démonstrateur, pas un scénario de requirements.md)
    │   ├── PinEcho.mo              -- scénario 7 : bouclage électrique entre deux broches du même MCU (GP1 pilotée, GP2 relit, GP3 reproduit)
    │   ├── AdcRead.mo              -- scénario 8 : GP1 en entrée analogique (machine.ADC), pont diviseur externe, seuil recopié sur GP0
    │   ├── PwmLed.mo               -- scénario 9 : GP0 en sortie PWM (machine.PWM), créneau généré en continu côté Modelica
    │   ├── PwmLedFade.mo           -- variation progressive du rapport cyclique (démonstrateur)
    │   ├── ImportDemo.mo           -- scénario 10 : le script importe un module auxiliaire (addScriptDirToPath) et un module d'une bibliothèque partagée (libraryPath)
    │   ├── SleepCompression.mo     -- scénario 2 : compression d'un sleep long
    │   ├── InputReactivity.mo      -- scénario 3 : réactivité à une entrée pendant un sleep
    │   ├── ScriptError.mo          -- scénario 4 : exception non gérée
    │   ├── PinIrq.mo               -- scénario 11 : machine.Pin.irq() sur GP1 (front montant uniquement), bascule GP0 depuis le callback
    │   ├── TimerToggle.mo          -- scénario 12 : machine.Timer périodique bascule GP0 pendant un sleep() long, sans le faire retourner en avance
    │   ├── DisplayDemo.mo          -- scénario 13 : machine.Display(0).write() vers un Peripherals.Display câblé sur Display0
    │   ├── Uart/                   -- liaison série ; suffixe Py = appareil dont le comportement est décrit par un script Python
    │   │   ├── Loopback.mo         -- scénario 14 : machine.UART électrique réel, TX (GP0) bouclé sur RX (GP1) via loopR/loopC (voir peripherique-uart.md)
    │   │   ├── Echo.mo             -- scénario 21 : écho paramétré (mode Table), octet par octet - hérite de EchoPy, dont il ne change que le mode
    │   │   ├── EchoPy.mo           -- scénario 15 : dialogue avec un vrai périphérique externe, écho décrit par Device/echo.py
    │   │   ├── Sensor.mo           -- scénario 16 : requête/réponse dans les deux sens, avec une rampe sur valueIn et une consigne capturée sur valueOut
    │   │   ├── Regulation.mo       -- scénario 19 : boucle de régulation fermée à travers la seule liaison série (la sortie réelle pilote un procédé qui revient sur l'entrée)
    │   │   ├── GpsPy.mo            -- scénario 17 : émission périodique spontanée (phrases NMEA RMC avec somme de contrôle, Device/gps.py), le microcontrôleur écoute et vérifie
    │   │   ├── StateMachinePy.mo   -- scénario 20 : appareil à machine d'état décrit par Device/state_machine.py (la réponse dépend de ce qui précède)
    │   │   └── Lcd.mo              -- scénario 18 : afficheur 20x2 alimenté par une vraie trame série (pendant électrique de DisplayDemo)
    │   └── I2c/                    -- bus I2C électrique en drain ouvert (voir peripheriques-i2c.md)
    │       ├── Echo.mo             -- un maître, un écho : trame de 9 octets écrite puis relue, registre lu derrière un START répété
    │       ├── MultiDevice.mo      -- trois échos sur le même bus : scan(), pas de diaphonie, EIO sur une adresse absente
    │       ├── NoPullUp.mo         -- hérite de MultiDevice, sans aucun tirage : lignes à 0 V, ETIMEDOUT
    │       └── GroveLcd.mo         -- écran Grove LCD RGB piloté par un driver MicroPython du commerce, sans modification
    └── Resources/
        ├── Include/                -- nos sources C à la racine : PyRuntimeImpl.c + .h (chapeau du runtime Python), UartDeviceImpl.c + .h (chapeau des périphériques série), I2cDeviceImpl.c + .h (chapeau des périphériques I2C), StringToCharCodes.c, uartcore.h/.c et devscript.c
        │   ├── devscript.c         -- script Python d'un périphérique, PARTAGÉ par les chapeaux série et I2C : chargement dans un espace de noms propre, prélude print, conversions, arrêt propre sur exception
        │   ├── pyhost.c            -- hôte CPython PARTAGÉ par les deux chapeaux : démarrage unique de l'interpréteur (le premier composant construit le démarre), relais stdout/stderr, lecture de fichier
        │   ├── uartcore.h/.c       -- moteur UART générique PARTAGÉ par les deux chapeaux : files circulaires TX/RX, trame 8N1, décodage par échantillonnage, échéances. Ni Python ni thread. Garde d'inclusion obligatoire (omc peut réunir les deux chapeaux dans une seule unité de compilation)
        │   ├── pyruntime/          -- l'implémentation découpée, incluse textuellement par le chapeau dans un ordre significatif : pyruntime_core.h (constantes + PyRuntimeHandle), _sync.c, _pin.c, _display.c, _uart.c, _i2c.c (maître I2C en drain ouvert), _timer.c, _module.c
        │   ├── uartdevice/         -- idem côté périphériques : uartdevice_core.h (struct UartDevice), _format.c ({vN} et {oN}), _match.c (table de commandes), _script.c (mode Script : chargement du .py dans un espace de noms propre, appel des gestionnaires), _engine.c (construction, ordonnancement, synchro)
        │   ├── i2cdevice/          -- idem côté I2C : i2cdevice_core.h (struct I2cDevice), _script.c (contrat on_write / on_read / outputs / lines), _engine.c (décodeur piloté par les fronts, construction, synchro)
        │   └── cpython312/         -- en-têtes Python 3.12 vendorés (Python.h et cie), isolés pour ne pas noyer nos fichiers
        ├── Library/win64/          -- libpython312.a, bibliothèque d'import régénérée pour le compilateur MinGW d'OpenModelica
        ├── PythonRuntime/          -- distribution Python « embeddable » officielle (DLL + stdlib), voir integration-python.md
        ├── Scripts/
        │   ├── MCU/                -- programmes du microcontrôleur, un par exemple (dont demo.py, valeur par défaut de `MCU.scriptPath`) ; companion.py et lib/ servent à ImportDemo
        │   ├── Device/             -- scripts des périphériques, nommés d'après l'appareil : série (mode Script) echo.py, gps.py, temperature_sensor.py, state_machine.py, generic.py ; I2C i2c_echo.py, i2c_generic.py, grove_lcd_rgb.py - chaque périphérique fourni a le sien par défaut
        │   └── _shim/              -- machine_time_shim.py : le shim machine/time lui-même (source unique, exécuté par PyRuntime_new avant le script utilisateur)
        └── Verification/           -- scripts Python spécifiques à la vérification + scripts `.mos` exécutables via `omc` (scénarios de requirements.md)
```

## Qui fait quoi, à quel moment

| Composant | Rôle | Quand il intervient |
|---|---|---|
| `MCU.mo` (Modelica) | Modélise le pont électrique GPIO (source de tension, résistance série, interrupteur, capteur), déclenche les points de synchro | Continuellement (équations électriques) + aux instants d'événement (`when`) |
| `PyRuntime.mo` (Modelica) | Déclare l'External Object et ses fonctions `constructor`/`destructor` | Une fois à l'initialisation, une fois (nominalement) à la fin |
| `PyRuntime_sync.mo` (Modelica) | Point d'entrée appelé depuis le `when` de `MCU` ; transmet `pinBoolIn` (seuillé, numérique) et `pinAnalogIn`/`pinNodeVoltage` (brut, lu par `machine.ADC`) en entrée ; `pwmFreq`/`pwmDuty` (configurés par `machine.PWM`), `displaySeq`/`displayPayload` (configurés par `machine.Display.write()`) et les sorties série `uartTxPin`/`uartTxActive`/`uartTxStart`/`uartBitDur`/`uartTxNumBits`/`uartTxBits` (motif de trame dont Modelica génère la forme d'onde, cf. `peripherique-uart.md`) en sortie, en plus de `pinBoolOut`/`pinIsOutput` | À chaque événement de synchro |
| `PyRuntimeImpl.c` (C) | Fichier chapeau : inclut les parties de `pyruntime/` qui implémentent `PyRuntime_new`/`_destroy`/`_sync`, le thread worker, le shim (dont `machine.Pin.irq()`/`machine.Timer`/`machine.Display`, cf. `cycle-de-vie.md` §3bis), le décodage de la réception série (machine à états entièrement en C, cf. `peripherique-uart.md`) et la redirection stdout | Compilé une fois par `omc` (une seule unité de compilation), exécuté à chaque appel externe |
| Distribution Python vendorée | Fournit l'interpréteur (DLL) et la bibliothèque standard (zip) | Chargée dynamiquement au démarrage de l'exécutable de simulation |
| Script utilisateur (`.py`) | Le code écrit par l'élève/l'utilisateur, exécuté par le thread worker | Depuis t=0 jusqu'à sa fin/erreur, entrecoupé de pauses (voir cycle-de-vie.md) |

## Icône du modèle `MCU`

![Icône du modèle MCU](images/mcu-icone.svg)

*Diagramme vectoriel généré directement à partir des coordonnées de l'annotation `Icon` de `MCU.mo` (pas une capture d'écran) — fidèle au rendu réel vérifié dans OMEdit au moment de sa génération ; ne reflète pas encore le connecteur `Display0` ajouté depuis (miroir SVG statique, resynchronisé manuellement comme `logo.svg`, cf. « Icône du package » ci-dessous).*

L'icône représente le microcontrôleur comme un boîtier avec ses 8 broches réparties sur le pourtour — `GP0`-`GP3` sur le bord gauche, `GP4`-`GP7` sur le bord droit, chacune étiquetée en blanc (carré bleu plein = `PositivePin`) — et la broche `GND` en bas (carré à bord bleu = `NegativePin`). Le nom de classe et l'icône affichent volontairement « MCU » plutôt que « Pico »/RP2040 : cf. `requirements.md`, décision « Nom de la classe modèle et identité visuelle ». Voir aussi le scénario de vérification 6 pour l'historique des deux défauts de rendu trouvés et corrigés lors de la toute première version de l'icône (connecteurs fusionnés, `GND` hors cadre). Un petit connecteur triangulaire en haut, aligné avec `GP4` et étiqueté « DISPLAY », expose la liaison logique vers un périphérique d'affichage pédagogique (`machine.Display(0)`) — cf. `requirements.md`, décision « Périphérique d'affichage pédagogique ».

## Icône du package et logo du projet

![Logo MicroPythonMCU](images/logo.svg)

`MicroPythonMCU/package.mo` reprend la même silhouette que l'icône du modèle `MCU` ci-dessus (boîtier, 8 broches, `GND`, pastille LED), avec le texte central remplacé par « µPy » (police « Trebuchet MS », plus grande) — cf. `requirements.md`, décision « Logo du projet / icône du package ». `docs/images/logo.svg` en est un miroir SVG (même méthode que `mcu-icone.svg`), utilisé comme logo dans `README.md` ; à resynchroniser manuellement si l'icône du package change.

## Schémas des exemples

![Schéma simplifié du scénario BasicBlink](images/exemple-basicblink.svg)

Les 4 premiers modèles de scénario d'`Examples/` suivent tous le même agencement : `mcu` au centre, `GP0` câblée vers une vraie `Peripherals.LED` (résistance série + LED) à gauche, `GP1` vers `btnSrc` pour `InputReactivity` (les broches non utilisées par le script sont laissées non connectées, cf. `requirements.md`, décision « Nettoyage du schéma interne de MCU et simplification du câblage des exemples »), avec une masse commune (`ground`) en bas. Le schéma interne du modèle `MCU` lui-même (le pont électrique par broche) est documenté dans `integration-python.md` et `cycle-de-vie.md` ; il est volontairement laissé vide dans la vue `Diagram` d'OMEdit (composants masqués, `visible = false`) depuis la même décision.

`LedChaser.mo` est un sixième modèle d'`Examples/`, mais un démonstrateur plutôt qu'un scénario de vérification de `requirements.md` : les 8 GPIO pilotent chacun une `Peripherals.LED` (chenillard bidirectionnel, ~150 ms/broche), pour donner à voir la luminosité de l'icône `Peripherals.LED` en conditions de clignotement rapide (cf. `requirements.md`, décision « Calibration de la luminosité de l'icône `Peripherals.LED` »).

`PinEcho.mo` (scénario de vérification 7) câble `GP1` en sortie (oscille), boucle son état électrique vers `GP2` en entrée (résistance + condensateur de constante de temps négligeable, `loopR`/`loopC` — un simple `connect()` direct entre les deux broches s'est avéré faire disparaître la tension pilotée des résultats de simulation, cf. `requirements.md`, décision « Domaine électrique vs logique pur », piège 3), et reproduit la lecture sur `GP3`. Les broches `GP0`/`GP4`-`GP7`, inutilisées dans ce scénario, sont laissées non connectées.

`AdcRead.mo` (scénario de vérification 8) câble `GP1` sur un pont diviseur externe (~2,2 V) et l'utilise en entrée analogique (`machine.ADC(1)`, pas `machine.Pin`) — la même broche que dans les autres exemples, juste interrogée différemment côté script. Le script recopie un seuil sur `Pin(0, Pin.OUT)` (`led0`) pour rendre la lecture observable via le circuit plutôt que de dépendre d'une lecture directe d'un flottant. Les broches `GP2`-`GP7`, inutilisées, sont laissées non connectées.

`PwmLed.mo` (scénario de vérification 9) configure `GP0` en sortie `machine.PWM` (200 Hz, ~30% de rapport cyclique) plutôt qu'en sortie numérique classique, pilotant directement `led0` — le script configure une seule fois puis se termine, le créneau continuant d'être généré côté Modelica indépendamment du thread Python (cf. `requirements.md`, décision « PWM (sorties modulées) », pour le mécanisme et sa validation en isolation avant intégration). Les broches `GP1`-`GP7`, inutilisées, sont laissées non connectées.

`ImportDemo.mo` (scénario de vérification 10) illustre l'import d'un module auxiliaire par le script principal (`import_demo.py`) : `companion.py`, posé à côté de lui dans `Resources/Scripts/` (rendu importable par `mcu.addScriptDirToPath`, actif par défaut), et `shared_helper.py`, dans le sous-dossier séparé `Resources/Scripts/MCU/lib/` (rendu importable via `mcu.libraryPath`). `led0`/`led1` confirment visuellement que les deux imports ont réussi — cf. `requirements.md`, décision « Import de modules auxiliaires ». Les broches `GP2`-`GP7`, inutilisées, sont laissées non connectées.

`PinIrq.mo` (scénario de vérification 11) câble `GP1` sur un créneau externe (`Modelica.Blocks.Sources.Pulse`, front montant et descendant dans la fenêtre simulée) ; le script `pin_irq_demo.py` enregistre `Pin(1, Pin.IN).irq(handler=on_rise, trigger=Pin.IRQ_RISING)`, qui bascule `led0` (GP0) — seul un front montant doit déclencher le callback, preuve du filtrage par sens de front. Cf. `requirements.md`, décision « Interruptions sur broche et minuteurs logiciels ». Les broches `GP2`-`GP7`, inutilisées, sont laissées non connectées.

`TimerToggle.mo` (scénario de vérification 12) n'a aucune source externe : le script `timer_toggle.py` arme un `Timer(period=500, mode=Timer.PERIODIC)` qui bascule `led0` (GP0), puis fait un seul `sleep(3600)`. Le basculement périodique se produit sans qu'aucune entrée du modèle ne change — preuve que le mécanisme de « pitstop » (cf. `cycle-de-vie.md`) fonctionne indépendamment du `sleep()` en cours, sans le faire retourner en avance. Les broches `GP1`-`GP7`, inutilisées, sont laissées non connectées.

`DisplayDemo.mo` (`verify_12_display.mos`) démontre le périphérique d'affichage pédagogique du projet (`machine.Display`, cf. `requirements.md`, décision « Périphérique d'affichage pédagogique ») : le script `display_demo.py` (`Resources/Scripts/`) appelle `Display(0).write(...)` à deux instants séparés par un `sleep(1)` ; un `Peripherals.Display` (nouveau paquet, cf. arborescence ci-dessus) reçoit chaque message via son connecteur `displayLink`, câblé sur `mcu.Display0` — un connecteur **logique causal** (`Interfaces.DisplayLinkOutput`/`DisplayLinkInput`), pas électrique comme les `GPx`, cf. `docs/peripherique-display.md`. Aucune broche `GPx` utilisée dans ce scénario. Détail à noter pour qui modifie l'icône de l'afficheur : le texte reçu s'affiche **réellement sur l'icône**, fidèle à un vrai 20×2 (20 caractères par ligne, un `Text` par colonne, cf. `Internal.StringToCharCodes` et `docs/peripherique-display.md` §4) — à chaque nouvelle réception, l'ancien message décale vers la ligne 2 (`line2CharCode = pre(displayLink.charCode)`) et le nouveau occupe la ligne 1 — en plus d'apparaître dans le journal de simulation (`Streams.print`, texte complet). Écran de couleur fixe (pas d'animation lumineuse). Le contournement (une `String` ne peut pas être stockée dans les résultats de simulation, `.mat`/`.csv`, vérifié empiriquement pendant ce chantier) passe par un tableau `Integer` de codes ASCII, lui bien storable, comme n'importe quelle grandeur numérique déjà utilisée pour `Peripherals.LED`.

`Uart/Loopback.mo` (scénario de vérification 14) est le seul exemple où une broche `GPx` porte un **signal série réel** : le script `uart_loopback.py` configure `machine.UART(0, baudrate=1200, tx=Pin(0), rx=Pin(1))` et émet `b'Hi'` ; `GP0` (TX) est bouclée électriquement sur `GP1` (RX) par le motif `loopR`/`loopC` de `PinEcho` (obligatoire : un `connect()` direct entre deux broches du même `MCU` fait disparaître la tension pilotée des résultats), et `led3` (GP3) confirme que les octets relus sont intacts. Tracer `mcu.GP0.v` donne une vraie trame 8N1 lisible comme à l'oscilloscope. Mécanisme complet (émission générée en continu par Modelica, réception décodée côté C) : [peripherique-uart.md](peripherique-uart.md).

<!-- TODO screenshot (optionnel) : pour le schéma complet avec les 8 fils réellement routés (plutôt que ce résumé simplifié), capturer la vue "Diagram" de MicroPythonMCU.Examples.BasicBlink dans OMEdit et l'ajouter sous docs/images/exemple-basicblink-complet.png -->
