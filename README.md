<p align="center"><strong>🇬🇧 English</strong> — <a href="#francais">Plus bas en français ↓</a></p>

<p align="center">📖 More info / Plus d'info : <a href="https://bdelaup.gitlab.io/modelica_micropython3/">bdelaup.gitlab.io/modelica_micropython3</a></p>

## MicroPythonMCU

**Python-programmable microcontroller model for OpenModelica**

`MicroPythonMCU` provides an OpenModelica model (`MCU`) whose behavior is driven by a Python script compatible with [MicroPython](https://micropython.org/) (`machine`/`time` API, referencing the Raspberry Pi Pico / RP2040 board). The pins are real electrical nodes: the script drives and reads the surrounding Modelica circuit.

Use case: test control code on the digital twin before deploying it to a real prototype (educational or industrial context).

## Features

- **Microcontroller**: GPIO (`Pin`, `Pin.irq` interrupts, bit-banging), `ADC`, `PWM`, `Timer`, `UART` serial link, `I2C` master bus, flash-like file system (`open()`, `os`, `boot.py`/`main.py` startup), module imports, onboard LED. `sleep()` calls cost no real waiting time.
- **Peripherals to wire in**: serial devices (echo, temperature sensor, GPS, 20x2 display, generic), I2C devices (Grove LCD RGB display, echo, generic), HX711 weighing chain (converter, strain-gauge bridge, load cell), LED, pedagogical display.
- **31 examples** (`MicroPythonMCU.Examples`), including a kitchen scale that runs off-the-shelf MicroPython drivers unmodified.
- **Current limits**: Windows only, a single microcontroller per model, no SPI. Full list: [`requirements.md`](requirements.md#todo-vers-une-version-exhaustive) *(French only)*.

## Installation

- [OpenModelica](https://openmodelica.org/download/download-windows/) with OMEdit (tested with `1.27.1-64bit`) — nothing else to install: the Python runtime ships with the library.
- Published versions: [releases page](https://gitlab.com/bdelaup/modelica_micropython3/-/releases), instructions in [`docs/installation.md`](docs/installation.md) *(French only)*.
- From the repository: in OMEdit, *File → Open Model/Library File(s)…* → `MicroPythonMCU/package.mo`.

## Quick start

1. Open and simulate `MicroPythonMCU.Examples.BasicBlink`: `GP0` blinks (`Resources/Scripts/MCU/demo.py`).
   <p align="center"><img src="docs/images/BasicBlink.gif" alt="MCU blink diagram" width="300"></p>
2. In the `MCU` component's parameters, point **Script path** (the *…* button) to your own `.py` file:

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

   This same file can be copied as-is onto a real Raspberry Pi Pico. A `.py` module placed next to the script can be imported.

## Documentation

The [documentation site](https://bdelaup.gitlab.io/modelica_micropython3/) *(French only)* covers installation, the `machine`/`time` API and each peripheral family, the internals and the verification suite. Architecture decisions and their alternatives are in [`requirements.md`](requirements.md).

## License

[MIT](LICENSE) — attribution required (copyright + license text) in any copy or republication, whole or partial. The vendored Python distribution (`MicroPythonMCU/Resources/PythonRuntime/`) keeps its own license (Python Software Foundation).

The `Peripherals.LED` component (current-reactive icon) is inspired by `Arduino.Components.LED` from the [Modelica-Arduino](https://github.com/CATIA-Systems/Modelica-Arduino) library (CATIA-Systems).

## Context

Project led by B. Delaup, teacher of *sciences de l'ingénieur* (engineering sciences). MicroPythonMCU aims to sit at the crossroads of educational use (testing before deploying to a real prototype) and industrial use (digital twin of embedded software).

Partly developed with AI assistance.

This GitHub repository is a "passive" mirror of a GitLab repository.
Original active repository: https://gitlab.com/bdelaup/modelica_micropython3
Please use the GitLab repository for communications and pull requests.

---

<a id="francais"></a>

## MicroPythonMCU (Français)

**Modèle de microcontrôleur programmable en python pour OpenModelica**

`MicroPythonMCU` fournit un modèle OpenModelica (`MCU`) dont le comportement est exécuté par un script Python compatible [MicroPython](https://micropython.org/) (API `machine`/`time`, référence Raspberry Pi Pico / RP2040). Les broches sont de vrais nœuds électriques : le script pilote et lit le circuit Modelica qui l'entoure.

Usage : tester un code de pilotage sur le jumeau numérique avant de le déployer sur un prototype réel (pédagogique ou industriel).

## Ce que sait faire la bibliothèque

- **Microcontrôleur** : GPIO (`Pin`, interruptions `Pin.irq`, bit-banging), `ADC`, `PWM`, `Timer`, liaison série `UART`, bus `I2C` maître, système de fichiers façon flash (`open()`, `os`, démarrage `boot.py`/`main.py`), import de modules, LED embarquée. Les `sleep()` ne coûtent aucune attente réelle.
- **Périphériques à brancher** : appareils série (écho, capteur de température, GPS, afficheur 20x2, générique), appareils I2C (écran Grove LCD RGB, écho, générique), chaîne de pesée HX711 (convertisseur, pont de jauges, corps d'épreuve), LED, afficheur pédagogique.
- **31 exemples** (`MicroPythonMCU.Examples`), dont une balance de cuisine qui exécute tels quels des drivers MicroPython du commerce.
- **Limites actuelles** : Windows uniquement, un seul microcontrôleur par modèle, pas de SPI. Liste complète : [`requirements.md`](requirements.md#todo-vers-une-version-exhaustive).

## Installation

- [OpenModelica](https://openmodelica.org/download/download-windows/) avec OMEdit (testé avec `1.27.1-64bit`) — rien d'autre à installer : le runtime Python est fourni avec la bibliothèque.
- Versions publiées : [page des releases](https://gitlab.com/bdelaup/modelica_micropython3/-/releases), mode d'emploi dans [`docs/installation.md`](docs/installation.md).
- Depuis le dépôt : dans OMEdit, *File → Open Model/Library File(s)…* → `MicroPythonMCU/package.mo`.

## Démarrage rapide

1. Ouvrir et simuler `MicroPythonMCU.Examples.BasicBlink` : `GP0` clignote (`Resources/Scripts/MCU/demo.py`).
   <p align="center"><img src="docs/images/BasicBlink.gif" alt="schema MCU blik" width="300"></p>
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

   Ce même fichier peut être copié tel quel sur un vrai Raspberry Pi Pico. Un module `.py` posé à côté du script est importable.

## Documentation

Le [site de documentation](https://bdelaup.gitlab.io/modelica_micropython3/) décrit l'installation, l'API `machine`/`time` et chaque famille de périphériques, le fonctionnement interne et la suite de vérification. Les décisions d'architecture et leurs alternatives sont dans [`requirements.md`](requirements.md).

## Licence

[MIT](LICENSE) — attribution obligatoire (copyright + texte de licence) dans toute copie ou republication, totale ou partielle. La distribution Python vendorée (`MicroPythonMCU/Resources/PythonRuntime/`) garde sa propre licence (Python Software Foundation).

Le composant `Peripherals.LED` (icône réactive au courant) s'inspire de `Arduino.Components.LED` de la bibliothèque [Modelica-Arduino](https://github.com/CATIA-Systems/Modelica-Arduino) (CATIA-Systems).

## Contexte

Projet porté par B. Delaup, enseignant en sciences de l'ingénieur. MicroPythonMCU a vocation à être à la croisée d'un usage pédagogique (tester avant de déployer sur un prototype réel) et d'un usage industriel (jumeau numérique de logiciel embarqué).

En partie développé avec l'aide d'IA.

Ce dépôt GitHub est un miroir « passif » d'un dépôt GitLab.
Dépôt actif original : https://gitlab.com/bdelaup/modelica_micropython3
Merci d'utiliser le dépôt GitLab pour vos communications et pull requests.
