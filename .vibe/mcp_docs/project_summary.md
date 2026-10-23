# Projet MicroPythonMCU - Résumé

## Vue d'ensemble
MicroPythonMCU est une bibliothèque OpenModelica fournissant un modèle de microcontrôleur programmable en Python (compatible MicroPython) pour simuler des systèmes embarqués couplés à des circuits physiques.

## Objectif
Tester un code de pilotage sur un jumeau numérique avant de le déployer sur un prototype réel (pédagogique ou industriel).

## Caractéristiques principales
- **Microcontrôleur :** 8 broches GPIO (GP0-GP7), ADC, PWM, Timer, UART, I2C
- **API :** machine/time compatible MicroPython (référence Raspberry Pi Pico RP2040)
- **Synchronisation :** temps simulé compressé (sleep() n'attend pas en temps réel)
- **Périphériques :** LED, Display (20x2, 4x32, 8x32), UART devices, I2C devices, HX711, Radio, etc.
- **Runtime :** CPython 3.12 embarqué via API C
- **Debug :** Débogage pas à pas avec VS Code

## Architecture
- **Runtime Python :** CPython embarqué, pas de dépendance système
- **Threading :** Un thread worker par MCU, ping-pong avec Modelica
- **Pont électrique :** Connecteurs Modelica.Electrical.Analog avec résistance série
- **Synchronisation :** Points de synchro sur sleep, tick, transitions d'entrée

## Structure
```
MicroPythonMCU/
├── MCU.mo, RPi_Pico.mo
├── Internal/ (McuCore, PyRuntime, PinBridge, etc.)
├── Peripherals/ (LED, Display, UART, I2C, Radio, Weighing, Analyzers)
├── Examples/ (52 exemples)
├── Resources/
│   ├── Include/ (code C)
│   ├── PythonRuntime/ (CPython 3.12)
│   ├── Debugpy/ (débogueur)
│   └── Scripts/ (shims, drivers, programmes)
└── docs/ (documentation bilingue)
```

## Stack technique
- **Modelica :** OpenModelica/OMEdit 1.27.1+
- **Python :** CPython 3.12 embarqué
- **OS :** Windows uniquement (API threading Windows)
- **Outils :** PulseView (optionnel, analyseur logique)

## Serveur MCP
- **Disponible depuis :** OpenModelica 1.27.0 (expérimental)
- **URL :** http://localhost:3000/mcp
- **Protocole :** JSON-RPC 2.0 via HTTP POST
- **Activation :** Settings → MCP → Enable MCP server
- **Outils :** 30+ outils pour manipuler classes, composants, connexions, simulations

## Documentation
- **Site :** https://bdelaup.gitlab.io/modelica_micropython/
- **Dépôt :** https://gitlab.com/bdelaup/modelica_micropython
- **Requirements :** requirements.md (source de vérité)
- **CLAUDE.md :** Guide pour les agents IA

## Vérification
- **66 scénarios** de vérification (tous PASS)
- Exécutables via : `./run_tests.sh` ou `run_tests.cmd`

## Limitations
- Windows uniquement
- Un seul MCU par modèle (multi-instances en développement)
- Pas de SPI (en développement)
- Serveur MCP expérimental

## Historique récent
- 2026-10-06 : Display.write() comme print(), message à t=0 affiché
- 2026-10-04 : Grands écrans, multi-MCU
- 2026-10-02 : Liaison radio
- 2026-09-27 : UART électrique, I2C
- 2026-09-26 : ADC, PWM, Timers, Interruptions

## Contributeur principal
B. Delaup (Lycée Jules Haag)

## Licence
MIT (avec attributions pour les composants tiers)
