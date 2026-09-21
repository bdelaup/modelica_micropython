# Rejouer la suite de vérification

Cette page documente comment relancer, de façon reproductible, les scripts qui vérifient les scénarios de `requirements.md` (section « Vérification de la v0 ») — et comment en ajouter un nouveau. Pour le *pourquoi* de chaque scénario (quelle décision d'architecture il vérifie), voir `requirements.md` ; cette page se concentre sur le *comment les rejouer*.

## Prérequis

- `omc` (OpenModelica Compiler) et le toolchain MinGW d'une installation OpenModelica sur le `PATH` — voir `CLAUDE.md`.
- `OPENMODELICAHOME` positionné sur la racine de l'installation (ex. `D:/Programmes/OpenModelica1.27.1-64bit`).

**Piège rencontré en session** : sur un poste où OpenModelica est installé mais où `omc` n'a pas été ajouté au `PATH` d'un shell fraîchement ouvert (`omc: command not found`), le chemin d'installation réel peut se retrouver dans un artefact de build laissé par une session précédente (ex. un `*.makefile` généré par une simulation, qui référence l'installation via `CPPFLAGS`/`LDFLAGS`) — plus rapide que de chercher sur tout le disque. Une fois le chemin connu, préfixer la commande :
```
export PATH="/d/Programmes/OpenModelica1.27.1-64bit/bin:$PATH"   # adapter le chemin à l'installation réelle
```

## Lancer la suite

Depuis `MicroPythonMCU/Resources/Verification/` :
```
omc verify_01_basic_blink.mos
omc verify_02_sleep_compression.mos
omc verify_03_input_reactivity.mos
omc verify_04_script_error.mos
omc verify_05_reset.mos
omc verify_06_pin_echo.mos
omc verify_07_adc_read.mos
omc verify_08_pwm.mos
omc verify_09_import.mos
```
Chaque script est autonome (charge `Modelica`, charge `../../package.mo`, simule, vérifie) et affiche `PASS: verify_0X_...` ou `FAIL: verify_0X_...` sur sa propre ligne — reproductible en ligne de commande, sans session OMEdit interactive.

## Ce que vérifie chaque script

| Script | Modèle exercé | Scénario de `requirements.md` | Résultat attendu |
|---|---|---|---|
| `verify_01_basic_blink.mos` | `Examples.BasicBlink` | Clignotement de base (shim `machine`/`time`, boucle de synchro) | `GP0` alterne ≈3 V / 0 V à la bonne période |
| `verify_02_sleep_compression.mos` | `Examples.SleepCompression` | Compression du `sleep` (cœur de la valeur du projet) | Bascules aux instants attendus, simulation rapide (pas de temps réel proportionnel au temps simulé) |
| `verify_03_input_reactivity.mos` | `Examples.InputReactivity` | Réactivité en entrée pendant un `sleep` | Réaction peu après la transition, pas à l'échéance du `sleep` |
| `verify_04_script_error.mos` | `Examples.ScriptError` | Exception non gérée dans le script | La simulation s'arrête en erreur (`getErrorString() <> ""`) |
| `verify_05_reset.mos` | `Examples.BasicBlink` (relancé deux fois) | Cycle de vie de l'External Object | Deux relances produisent des résultats strictement identiques |
| `verify_06_pin_echo.mos` | `Examples.PinEcho` | Bouclage entre deux broches du même `MCU` | `GP3` suit `GP1` (relu via `GP2`) à chaque phase, sans lecture périmée |
| `verify_07_adc_read.mos` | `Examples.AdcRead` | Entrée analogique (`machine.ADC`) | `GP1` reflète le pont diviseur (~2,2 V), `GP0` (LED) s'allume (seuil franchi) |
| `verify_08_pwm.mos` | `Examples.PwmLed` | Sortie PWM (`machine.PWM`) | `GP0` suit le créneau attendu (haut/bas conformes à la période/rapport cyclique), y compris bien après la fin du script |
| `verify_09_import.mos` | `Examples.ImportDemo` | Import de modules auxiliaires (`addScriptDirToPath`/`libraryPath`) | `GP0`/`GP1` (LED) s'allument, confirmant que les deux imports (dossier du script, bibliothèque partagée) ont réussi |

## Scénarios sans `.mos` (vérification visuelle ou démonstrateurs)

Certains éléments de `Examples/` ne correspondent volontairement à aucun script `.mos` :
- **Lisibilité visuelle de l'icône/du diagramme** (scénario dédié de `requirements.md`) : vérifiée via les outils MCP-OpenModelica (`iconDiagram`/`classDiagram`) et une relecture visuelle directe de l'image obtenue — pas de critère numérique automatisable.
- **`Examples.LedChaser`** : démonstrateur (chenillard visuel sur les 8 GPIO), pas un scénario de vérification de `requirements.md` — sert à donner à voir l'animation des icônes `Peripherals.LED` en conditions de clignotement rapide, pas à être rejoué automatiquement.

Un nouvel exemple a besoin d'un `.mos` dédié seulement s'il vérifie un comportement numérique précis (une décision d'architecture, un correctif). Un exemple purement illustratif (comme `LedChaser`) n'en a pas besoin.

## Écrire un nouveau `verify_0N_....mos`

Reprendre la structure des scripts existants (voir `verify_01_basic_blink.mos` pour le cas simple, `verify_04_script_error.mos` pour le cas « échec attendu ») :
```
loadModel(Modelica); getErrorString();
loadFile("../../package.mo"); getErrorString();

simulate(MicroPythonMCU.Examples.MonScenario, stopTime = ..., numberOfIntervals = ..., fileNamePrefix = "MonScenario");
b := getErrorString();

vX := val(mcu.GPx.v, <instant>, "MonScenario_res.mat");

if <condition de succès> then
  print("PASS: verify_0N_mon_scenario (...)\n");
else
  print("FAIL: verify_0N_mon_scenario (...)\n" + b);
end if;
```
**Limitation connue de cette installation `omc`** : pas de fonction fiable de recherche de sous-chaîne dans le scripting `.mos` (`Modelica.Utilities.Strings.find`/`System.stringFind` indisponibles) — pour un scénario d'échec attendu, détecter via `getErrorString() <> ""` plutôt qu'en cherchant un texte précis dans la trace (cf. `verify_04_script_error.mos`).

**Piège rencontré en session** : `getErrorString()` n'est **pas** fiable comme critère « aucune erreur » pour un scénario de succès attendu — l'avertissement anodin « The initial conditions are not fully specified » (présent dans *tous* les scénarios, y compris ceux qui réussissent parfaitement) s'y retrouve capturé. Un `if b == "" and ... then PASS`, comme tenté une première fois pour `verify_09_import.mos`, échoue donc à tort. Se fier uniquement aux valeurs numériques attendues (`val(...)`) pour le critère de succès ; `b` reste utile seulement pour le diagnostic affiché dans le message `FAIL`.

## Nettoyage

Les artefacts de compilation générés par ces exécutions (`.exe`, `.o`, `.c` générés, `*_res.mat`, `*.makefile`, etc.) sont couverts par `.gitignore` — vérifier `git status` après une session de vérification pour confirmer qu'aucun artefact non couvert (ex. un nouveau motif de nom de fichier) ne traîne.
