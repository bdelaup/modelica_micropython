# Architecture — arborescence et rôles

## Vue d'ensemble

`MicroPythonMCU` est une bibliothèque OpenModelica classique (dossier = package Modelica), avec deux ajouts par rapport à une bibliothèque purement Modelica :
- un morceau de code C (`Resources/Include/PyRuntimeImpl.c`) compilé par `omc` lui-même via les annotations `Include`/`Library` d'un *External Object* ;
- une distribution Python complète vendorée dans `Resources/PythonRuntime/`, pour que le modèle n'ait besoin d'aucun Python installé sur le poste qui l'exécute.

```mermaid
graph TD
    subgraph LIB["MicroPythonMCU (package Modelica)"]
        MCU["MCU (model)<br/>pont électrique GPIO + orchestration"]
        Interfaces["Interfaces (package)<br/>constantes VOH/VOL/VIH/VIL/ROut"]
        Internal["Internal (package)<br/>PyRuntime (ExternalObject) + PyRuntime_sync"]
        Examples["Examples (package)<br/>4 scénarios de vérification"]
    end
    subgraph RES["Resources"]
        Include["Include/<br/>PyRuntimeImpl.c + .h<br/>+ en-têtes Python 3.12 vendorés"]
        Library["Library/win64/<br/>libpython312.a<br/>(import lib régénérée MinGW)"]
        PythonRuntime["PythonRuntime/<br/>distribution Python « embeddable »<br/>(DLL + stdlib zip)"]
        Scripts["Scripts/<br/>demo.py"]
        Verification["Verification/<br/>scripts .py + .mos de test"]
    end

    MCU -- "paramètres VOH/VOL/..." --> Interfaces
    MCU -- "instancie (protected)" --> Internal
    Examples -- "extends / utilise" --> MCU
    Internal -- "Include = PyRuntimeImpl.c" --> Include
    Internal -- "LibraryDirectory" --> Library
    Internal -- "pythonHome (loadResource, runtime)" --> PythonRuntime
    MCU -- "scriptPath par défaut (loadResource)" --> Scripts
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
    ├── MCU.mo                      -- LE modèle : icône, 8 broches GP0-GP7 + GND, pont électrique, orchestration de la synchro
    ├── Interfaces/                 -- constantes de niveaux de tension (VOH, VOL, VIH, VIL, ROut) — approximation RP2040
    ├── Internal/                   -- détails d'implémentation, non destinés à l'usage direct
    │   ├── PyRuntime.mo            -- ExternalObject : constructor (démarre CPython + thread) / destructor
    │   └── PyRuntime_sync.mo       -- impure function : le point de synchro appelé depuis le `when` de MCU
    ├── Examples/                   -- un modèle par scénario de vérification de requirements.md
    │   ├── BasicBlink.mo           -- scénario 1 : clignotement de base
    │   ├── SleepCompression.mo     -- scénario 2 : compression d'un sleep long
    │   ├── InputReactivity.mo      -- scénario 3 : réactivité à une entrée pendant un sleep
    │   └── ScriptError.mo          -- scénario 4 : exception non gérée
    └── Resources/
        ├── Include/                -- PyRuntimeImpl.c/.h (le vrai code de PyRuntime) + Python.h et cie (vendorés)
        ├── Library/win64/          -- libpython312.a, bibliothèque d'import régénérée pour le compilateur MinGW d'OpenModelica
        ├── PythonRuntime/          -- distribution Python « embeddable » officielle (DLL + stdlib), voir integration-python.md
        ├── Scripts/demo.py         -- script par défaut (clignotement GP0), valeur par défaut de `MCU.scriptPath`
        └── Verification/           -- scripts Python de test + scripts `.mos` exécutables via `omc` (scénarios de requirements.md)
```

## Qui fait quoi, à quel moment

| Composant | Rôle | Quand il intervient |
|---|---|---|
| `MCU.mo` (Modelica) | Modélise le pont électrique GPIO (source de tension, résistance série, interrupteur, capteur), déclenche les points de synchro | Continuellement (équations électriques) + aux instants d'événement (`when`) |
| `PyRuntime.mo` (Modelica) | Déclare l'External Object et ses fonctions `constructor`/`destructor` | Une fois à l'initialisation, une fois (nominalement) à la fin |
| `PyRuntime_sync.mo` (Modelica) | Point d'entrée appelé depuis le `when` de `MCU` | À chaque événement de synchro |
| `PyRuntimeImpl.c` (C) | Implémente réellement `PyRuntime_new`/`_destroy`/`_sync`, gère le thread worker, le shim, la redirection stdout | Compilé une fois par `omc`, exécuté à chaque appel externe |
| Distribution Python vendorée | Fournit l'interpréteur (DLL) et la bibliothèque standard (zip) | Chargée dynamiquement au démarrage de l'exécutable de simulation |
| Script utilisateur (`.py`) | Le code écrit par l'élève/l'utilisateur, exécuté par le thread worker | Depuis t=0 jusqu'à sa fin/erreur, entrecoupé de pauses (voir cycle-de-vie.md) |

## Icône du modèle `MCU`

![Icône du modèle MCU](images/mcu-icone.svg)

*Diagramme vectoriel généré directement à partir des coordonnées de l'annotation `Icon` de `MCU.mo` (pas une capture d'écran) — fidèle au rendu réel vérifié dans OMEdit.*

L'icône représente le microcontrôleur comme un boîtier avec ses 8 broches réparties sur le pourtour — `GP0`-`GP3` sur le bord gauche, `GP4`-`GP7` sur le bord droit, chacune étiquetée en blanc (carré bleu plein = `PositivePin`) — et la broche `GND` en bas (carré à bord bleu = `NegativePin`). Le nom de classe et l'icône affichent volontairement « MCU » plutôt que « Pico »/RP2040 : cf. `requirements.md`, décision « Nom de la classe modèle et identité visuelle ». Voir aussi le scénario de vérification 6 pour l'historique des deux défauts de rendu trouvés et corrigés lors de la toute première version de l'icône (connecteurs fusionnés, `GND` hors cadre).

## Schémas des exemples

![Schéma simplifié du scénario BasicBlink](images/exemple-basicblink.svg)

Les 4 modèles d'`Examples/` suivent tous le même agencement : `mcu` au centre, `GP0`-`GP3` câblées vers des composants de charge/mesure à gauche (résistances de tirage, LED simulée, source de tension pour `InputReactivity`) et `GP4`-`GP7` vers des composants similaires à droite, avec une masse commune (`ground`) en bas. Le schéma interne du modèle `MCU` lui-même (le pont électrique par broche) est documenté dans `integration-python.md` et `cycle-de-vie.md`.

<!-- TODO screenshot (optionnel) : pour le schéma complet avec les 8 fils réellement routés (plutôt que ce résumé simplifié), capturer la vue "Diagram" de MicroPythonMCU.Examples.BasicBlink dans OMEdit et l'ajouter sous docs/images/exemple-basicblink-complet.png -->
