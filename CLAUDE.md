# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## État du dépôt

La v0 (preuve de concept) est implémentée et vérifiée : bibliothèque OpenModelica `MicroPythonMCU/` avec un modèle `MCU` fonctionnel (GPIO numériques + ADC + PWM + interruptions/minuteurs + import de modules auxiliaires + liaison vers un périphérique d'affichage pédagogique), un runtime CPython embarqué en C, 13 modèles d'exemple et 12 scénarios de vérification qui passent (`PASS`). Le cadrage détaillé (besoin, choix d'architecture avec alternatives, restrictions v0, TODO vers une version exhaustive) reste dans `requirements.md`, qui est la source de vérité — le consulter avant de modifier le périmètre ou l'architecture. Une documentation d'implémentation illustrée (arborescence, intégration Python/OpenModelica, cycle de vie) vit dans `docs/`.

## Projet

Bibliothèque OpenModelica fournissant un modèle de microcontrôleur programmable (classe `MCU`) : son comportement est piloté par un script Python écrit par l'utilisateur et compatible MicroPython, avec la carte Raspberry Pi Pico (RP2040) comme référence d'API interne — cible non affichée sur l'identité visuelle publique du bloc (icône « MCU », pas « Pico »), cf. `requirements.md`. Objectif : simuler dans Modelica le couplage matériel/logiciel d'un système embarqué (jumeau numérique), pour un usage pédagogique (Lycée Jules Haag) et industriel.

**`requirements.md` est la source de vérité du cadrage** (besoin détaillé, choix architecturaux avec alternatives, restrictions de la v0, TODO vers la version exhaustive) — le consulter avant de modifier le périmètre ou l'architecture, et le tenir à jour au fil des décisions plutôt que de dupliquer son contenu ici.

## Structure du dépôt

```
MicroPythonMCU/
├── package.mo, package.order   -- déclaration du package racine
├── MCU.mo                      -- le modèle : icône, 8 broches GP0-GP7 + GND (chacune numérique, analogique OU PWM, au choix du script) + liaison Display0 vers un périphérique d'affichage pédagogique, pont électrique Analog, LED embarquée GP25 interne (même pont, sans connecteur externe), import de modules auxiliaires (addScriptDirToPath/libraryPath), orchestration de la synchro
├── Interfaces/                 -- constantes de niveaux de tension (VOH, VOL, VIH, VIL, ROut) — approximation RP2040 ; connecteurs logiques causaux DisplayLinkOutput/DisplayLinkInput (liaison d'affichage pédagogique, pas électrique)
├── Internal/                   -- ExternalObject PyRuntime (constructor/destructor, +addScriptDirToPath/libraryPath) + PyRuntime_sync (point de synchro, transmet pinBoolIn/pinAnalogIn en entrée, pwmFreq/pwmDuty/displaySeq/displayPayload en sortie) + StringToCharCodes (utilitaire String -> Integer[n] de codes ASCII, pour afficher du texte sur une icône)
├── Peripherals/                -- composants connectables à MCU : LED.mo (icône réactive au courant, utilisée par MCU en LED embarquée et par les exemples) ; Display.mo (périphérique d'affichage pédagogique, écriture seule, affiche le texte réellement reçu sur l'icône + retour par print())
├── Examples/                   -- un modèle par scénario de vérification (BasicBlink, SleepCompression, InputReactivity, ScriptError, PinEcho, AdcRead, PwmLed, ImportDemo, PinIrq, TimerToggle, DisplayDemo) + LedChaser (chenillard bidirectionnel, démonstrateur)
└── Resources/
    ├── Include/                -- PyRuntimeImpl.c/.h (implémentation C réelle) + en-têtes Python 3.12 vendorés
    ├── Library/win64/          -- libpython312.a, import lib régénérée pour le compilateur MinGW d'OpenModelica
    ├── PythonRuntime/          -- distribution Python « embeddable » officielle vendorée (DLL + stdlib zip)
    ├── Scripts/                -- scripts des exemples (demo.py par défaut, un script par scénario d'Examples/)
    └── Verification/           -- scripts .py spécifiques à la vérification + scripts .mos exécutables via omc
docs/                            -- documentation d'implémentation (architecture, intégration Python, cycle de vie), voir docs/README.md
requirements.md                  -- source de vérité du cadrage et des décisions d'architecture
```

## Stack technique

- **Modelica** : OpenModelica / OMEdit (développé et testé avec l'installation `1.27.1-64bit`). Le serveur MCP `MCP-OpenModelica` est disponible dans l'environnement pour interagir directement avec les classes chargées dans OMEdit (créer/modifier des classes, composants, connexions, lancer des simulations, tracer des courbes, etc.) — préférer ces outils à l'édition à l'aveugle des fichiers `.mo`, et republier tout changement de fichier local vers OMEdit via `setSourceCode` pour rester synchronisé.
- **Runtime Python** : CPython 3.12 embarqué via l'API C (`Resources/Include/PyRuntimeImpl.c`), compilé par `omc` lui-même via les annotations `Include`/`Library` d'un *External Object* (`Internal/PyRuntime.mo`). Distribution Python « embeddable » officielle vendorée dans `Resources/PythonRuntime/` (aucun Python système requis à l'exécution). Le script utilisateur tourne dans un thread worker dédié, avec un shim `machine`/`time` imitant l'API MicroPython du Raspberry Pi Pico (RP2040) et interception de `sleep()` pour la compression temporelle — détails dans `docs/integration-python.md` et `docs/cycle-de-vie.md`.
- **Windows uniquement (v0)** : l'implémentation C utilise des API de threading Windows (`CRITICAL_SECTION`/`CONDITION_VARIABLE`) — non testé sur Linux/macOS, cf. restrictions v0 dans `requirements.md`.

## Build, test, vérification

Pas de manifeste de dépendances ni de build séparé : `omc` compile `PyRuntimeImpl.c` à la volée via les annotations `Include` du modèle. Les 12 scénarios de vérification de `requirements.md` sont exécutables indépendamment de toute session interactive :

```
cd MicroPythonMCU/Resources/Verification
omc verify_01_basic_blink.mos        # et verify_02_.../verify_12_...
```

Nécessite `omc` et le toolchain MinGW d'une installation OpenModelica sur le `PATH` (ex. `<OPENMODELICAHOME>/tools/msys/ucrt64/bin`), et `OPENMODELICAHOME` positionné. Chaque script affiche `PASS`/`FAIL` sur sa propre ligne. Les artefacts de compilation générés (`.exe`, `.o`, `.c` générés, `*_res.mat`, etc.) sont couverts par `.gitignore` — ne pas les committer. Détails, tableau des scénarios et prérequis pratiques (dont un piège de `PATH` déjà rencontré) : `docs/tests.md`.

## Note pour les futures instances

Ce fichier doit être mis à jour dès que la structure de dossiers, les dépendances ou les commandes de build/test/lint évoluent dans le dépôt (nouveau composant shim, portage Linux/macOS, etc.). Ne pas laisser ces sections devenir obsolètes ni inventer des détails absents du code ou de `requirements.md`.
