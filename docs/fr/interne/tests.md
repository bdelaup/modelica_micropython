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

### Toute la suite, en parallèle (recommandé)

Depuis `MicroPythonMCU/Resources/Verification/`, dans un shell bash (Git Bash, ou le msys fourni avec OpenModelica) :
```
./run_tests.sh                        # toute la suite, 4 exécutions simultanées
./run_tests.sh -j 2                   # autre degré de parallélisme
./run_tests.sh verify_08_pwm.mos ...  # seulement certains scripts
./run_tests.sh -k                     # garder artefacts et journaux (débogage)
./run_tests.sh --copy                # avant un tag : sur une copie des fichiers suivis (voir ci-dessous)
```
Le script affiche un récapitulatif `PASS`/`FAIL`/`ERREUR` avec la durée de chaque `.mos`, puis la fin du journal de chaque script en échec ; il se termine avec le code 1 si un script n'a pas passé. Si `omc` n'est pas sur le `PATH` mais que `OPENMODELICAHOME` est positionné, il complète le `PATH` lui-même. Sauf `-k`, il supprime ensuite tous les artefacts générés, qui portent tous le nom du `fileNamePrefix` de leur script.

Les scripts qui partagent des fichiers sont exécutés **à la suite l'un de l'autre**, jamais en même temps : même `fileNamePrefix` (`verify_01`/`verify_05`, tous deux `BasicBlink`), ou manipulation des copies de système de fichiers (`verify_25`/`verify_27`, qui effacent tous les `mcu_datalogger_*` et écrivent `fs_copies.txt`). Ce regroupement est automatique : un nouveau script en conflit est pris en compte sans modifier `run_tests.sh`.

**Durées mesurées** (i5-13420H, 4 cœurs performants + 4 basse consommation, 16 Go, dépôt dans OneDrive) : ~265 s en séquentiel, **~125 s** avec `run_tests.sh`. Le gain plafonne à ~2× quel que soit `-j` (3, 4 ou 6 donnent le même temps) : chaque `omc` occupe déjà plusieurs cœurs, notamment en compilant en parallèle les fichiers C générés, et le processeur est saturé. Hors OneDrive, la suite est ~10–15 % plus rapide.

### Pendant le travail ou avant un tag : dépôt ou copie

| Quand | Commande | Ce qui est testé |
|---|---|---|
| Pendant le travail (itération) | `./run_tests.sh`, ou quelques scripts ciblés | le **dépôt**, tel qu'il est sur le disque |
| Avant de poser un tag | `./run_tests.sh --copy` | **ce que livrera le tag** : les seuls fichiers de `MicroPythonMCU/` suivis par git (modifications non commitées comprises), copiés dans un dossier temporaire hors du dépôt |

`--copy` attrape le défaut propre à une livraison par tag : un fichier nécessaire (script, source C, image de flash) présent sur le disque mais jamais ajouté à git. Il manquerait aux utilisateurs ; ici, la suite échoue. Les fichiers non suivis sont listés avant la suite. La copie tourne hors du dépôt, donc hors de OneDrive : aucun artefact n'est écrit dans le dossier synchronisé. Elle prend une demi-seconde (443 fichiers, 25 Mo).

`--copy` se combine avec les autres options (`-j`, `-k`, liste de scripts), transmises à la copie de `run_tests.sh`. Sous le récapitulatif, il rappelle le commit testé et la mention « + modifications non commitées » s'il y a lieu : un résultat doit dire sur quoi il a tourné. Avec `-k`, la copie est conservée et son chemin affiché.

### Un script à la fois

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
omc verify_10_pin_irq.mos
omc verify_11_timer.mos
omc verify_12_display.mos
omc verify_13_uart_loopback.mos
omc verify_14_uart_echo.mos
omc verify_15_uart_sensor.mos
omc verify_16_uart_gps.mos
omc verify_17_uart_lcd.mos
omc verify_18_uart_regulation.mos
omc verify_19_uart_state_machine.mos
omc verify_20_uart_echo_table.mos
omc verify_21_i2c_echo.mos
omc verify_22_i2c_multi.mos
omc verify_23_i2c_nopullup.mos
omc verify_24_i2c_grove_lcd.mos
omc verify_25_filesystem.mos
omc verify_26_adc_sleep.mos
omc verify_27_filesystem_script.mos
omc verify_28_gpio_timing.mos
omc verify_29_python_dll.mos
omc verify_30_stdlib_import.mos
omc verify_31_hx711.mos
omc verify_32_kitchen_scale.mos
```
Chaque script est autonome (charge `Modelica`, charge `../../package.mo`, simule, vérifie) et affiche `PASS: verify_0X_...` ou `FAIL: verify_0X_...` sur sa propre ligne — reproductible en ligne de commande, sans session OMEdit interactive.

## Ce que vérifie chaque script

| Script | Modèle exercé | Scénario de `requirements.md` | Résultat attendu |
|---|---|---|---|
| `verify_01_basic_blink.mos` | `Examples.BasicBlink` | Clignotement de base (shim `machine`/`time`, boucle de synchro) | `GP0` alterne ≈3 V / 0 V à la bonne période |
| `verify_02_sleep_compression.mos` | `Examples.Program.SleepCompression` | Compression du `sleep` (cœur de la valeur du projet) | Bascules aux instants attendus, simulation rapide (pas de temps réel proportionnel au temps simulé) |
| `verify_03_input_reactivity.mos` | `Examples.Gpio.InputReactivity` | Réactivité en entrée pendant un `sleep` | Réaction peu après la transition, pas à l'échéance du `sleep` |
| `verify_04_script_error.mos` | `Examples.Program.Error` | Exception non gérée dans le script | La simulation s'arrête **proprement** en erreur : l'exécutable, relancé par son `.bat`, sort avec le code `-1` (et non `-1073741819`, le plantage que contourne `Library = "-lwinpthread"`), et son journal contient `ZeroDivisionError` et le message du runtime |
| `verify_05_reset.mos` | `Examples.BasicBlink` (relancé deux fois) | Cycle de vie de l'External Object | Deux relances produisent des résultats strictement identiques |
| `verify_06_pin_echo.mos` | `Examples.Gpio.PinEcho` | Bouclage entre deux broches du même `MCU` | `GP3` suit `GP1` (relu via `GP2`) à chaque phase, sans lecture périmée |
| `verify_07_adc_read.mos` | `Examples.Adc.Read` | Entrée analogique (`machine.ADC`) | `GP1` reflète le pont diviseur (~2,2 V), `GP0` (LED) allumée à t=0,3 s, après la 2e lecture (la 1re, à t=0, voit encore 0 V) |
| `verify_08_pwm.mos` | `Examples.Pwm.Led` | Sortie PWM (`machine.PWM`) | `GP0` suit le créneau attendu (haut/bas conformes à la période/rapport cyclique), y compris bien après la fin du script |
| `verify_09_import.mos` | `Examples.Program.Imports` | Import de modules auxiliaires (`addScriptDirToPath`/`libraryPath`) | `GP0`/`GP1` (LED) s'allument, confirmant que les deux imports (dossier du script, bibliothèque partagée) ont réussi |
| `verify_10_pin_irq.mos` | `Examples.Irq.Pin` | Interruption sur broche (`machine.Pin.irq`) | `GP0` bascule au front montant, reste inchangée au front descendant (filtrage par sens de front) |
| `verify_11_timer.mos` | `Examples.Irq.Timer` | Minuteur logiciel (`machine.Timer`) | `GP0` bascule toutes les 500 ms pendant un `sleep` long, sans l'écourter (« pitstop ») |
| `verify_12_display.mos` | `Examples.Display.Demo` | Périphérique d'affichage pédagogique (`machine.Display`) | `seq` 0→1→2, `charCode` conformes au texte, défilement 20×2 (ancien message en ligne 2) |
| `verify_13_uart_loopback.mos` | `Examples.Uart.Loopback` | Liaison série électrique réelle bouclée (`machine.UART`) | Trame 8N1 correcte sur `GP0` (start bas, données poids faible en tête, stop/repos hauts), deux trames enchaînées sans trou, témoin `GP3` allumé (octets relus intacts) |
| `verify_14_uart_echo.mos` | `Examples.Uart.EchoPy` | Dialogue avec un périphérique série externe, **en mode Script** | Les deux lignes au repos haut, trame `'H'` correcte à l'entrée du périphérique, périphérique muet avant la fin de la ligne puis en émission, témoin `GP7` à l'état haut |
| `verify_15_uart_sensor.mos` | `Examples.Uart.Sensor` | Requête/réponse dans les deux sens (`{vN}` et `{oN}`) | Deux mesures **différentes** lues sur une rampe, et `valueOut[1]` passe à 42,5 après `SET 42.5` |
| `verify_16_uart_gps.mos` | `Examples.Uart.GpsPy` | Émission périodique spontanée, **en mode Script** | Rien avant la première échéance, émissions aux échéances, au moins 4 phrases NMEA à somme de contrôle correcte en 500 ms, compteur du script publié sur `valueOut` |
| `verify_17_uart_lcd.mos` | `Examples.Uart.Lcd` | Afficheur 20x2 sur une vraie trame série | Codes ASCII conformes au texte décodé, défilement ligne 1 → ligne 2 (valide aussi l'icône factorisée `Internal.TwoLineTextIcon`) |
| `verify_18_uart_regulation.mos` | `Examples.Uart.Regulation` | Boucle de régulation fermée par la liaison série | La température part de 20 °C et rejoint la consigne de 40 °C, avec une commande cohérente avec le gain statique du procédé — seule la **sortie réelle** de l'appareil peut produire ce résultat |
| `verify_19_uart_state_machine.mos` | `Examples.Uart.StateMachinePy` | Appareil décrit par un script Python à machine d'état | État 0 → 1 → 0 et exactement 2 lectures servies : l'état persiste, et aucune transition n'est rejouée |
| `verify_20_uart_echo_table.mos` | `Examples.Uart.Echo` | Même montage que `Uart.EchoPy`, **en mode Table** | Écho octet par octet : le périphérique émet déjà à t=17 ms, avant la fin de la ligne — complément exact de `verify_14` |
| `verify_21_i2c_echo.mos` | `Examples.I2c.Echo` | Bus I2C électrique, un maître et un esclave | Bus au repos haut, START conforme, ACK de l'adresse tenu par l'esclave, trame de 9 octets écrite puis relue, registre lu derrière un START répété, témoin `GP7` allumé |
| `verify_22_i2c_multi.mos` | `Examples.I2c.MultiDevice` | Trois esclaves sur le même bus, deux paires de tirages en parallèle, 400 kHz | `scan()` exact, chaque écho ne reçoit que sa trame (pas de diaphonie), `EIO` sur une adresse absente, témoin `GP7` allumé |
| `verify_23_i2c_nopullup.mos` | `Examples.I2c.NoPullUp` | Même bus sans aucune résistance de tirage | Lignes à 0 V, `ETIMEDOUT`, `scan()` vide, aucun esclave sollicité, témoin `GP7` allumé |
| `verify_24_i2c_grove_lcd.mos` | `Examples.I2c.GroveLcd` | Écran Grove LCD RGB piloté par un driver du commerce, sans modification | Écran éteint et noir avant l'initialisation, puis « hello World » en ligne 1 dès la colonne 2, rétroéclairage rouge, vert, bleu |
| `verify_25_filesystem.mos` | `Examples.FileSystem.Boot` | Système de fichiers, démarrage `boot.py`/`main.py`, déterminisme | Deux simulations : `GP1` allumée (auto-contrôle de `main.py`), deux copies horodatées distinctes aux `mesures.csv` identiques, `..` bloqué à la racine de la flash, image source intacte. Le script supprime lui-même ses copies en fin de scénario |
| `verify_27_filesystem_script.mos` | `Examples.FileSystem.Script` | `boot.py` de la flash, puis un script à la place de `main.py` | `GP1` allumée, la copie contient `data/notes.txt` et pas `data/mesures.csv` (main.py n'a pas tourné) |
| `verify_26_adc_sleep.mos` | `Examples.Adc.Sleep` | Entrée ADC traversant le seuil logique (correctif « l'ADC coupe l'entrée numérique ») | Cinq `sleep(0.2)` de 200 000 µs exactement (`ticks_us()`) malgré 10 franchissements du seuil par seconde, `sleep_us(250)` mesuré à 250 µs, aucune IRQ, témoin `GP1` allumé à la fin seulement |
| `verify_28_gpio_timing.mos` | `Examples.Gpio.Timing` | Coût temporel des accès GPIO (`gpioOpTime` = 5 µs) : bit-banging, attente active, `disable_irq`/`enable_irq`, `idle()` | Impulsion `on(); off()` de 5 µs **mesurée côté Modelica**, 11 impulsions, rafale de 100 µs mesurée par `ticks_us()`, attente active sortie 0,5 µs après le front, callback du front masqué exécuté à `enable_irq()` (500 ms), `idle()` sur une milliseconde ronde |
| `verify_29_python_dll.mos` | `PythonDll`, défini dans le script (`Examples.BasicBlink` avec `Verification/python_dll_origin.py`) | Distribution Python embarquée : `python312.dll` chargée par son chemin absolu, pas par le PATH | `GP0` allumée : la DLL chargée (`sys.dllhandle`) est dans `sys.prefix`, soit `Resources/PythonRuntime`, même avec un Python système dans le PATH ; sinon exception, simulation en erreur |
| `verify_30_stdlib_import.mos` | `StdlibImport`, défini dans le script (`Examples.BasicBlink` avec `Verification/stdlib_import.py`) | Cloisonnement de `os` limité au code du microcontrôleur, y compris pour les modules de `python312.zip` | `GP0` allumée : `ctypes`, `random`, `tempfile` importés et utilisables (vrai `os`), alors que l'`import os` du script reste celui de MicroPython (refus sans système de fichiers) |
| `verify_31_hx711.mos` | `Examples.Weighing.Hx711Read` | HX711 lu par le driver de robert-hh sans modification, chaîne force → corps d'épreuve → pont → convertisseur | Codes exacts (429 497 à gain 128, 214 748 à gain 64 pour 1 kg) côté HX711 et relus par le driver sur l'afficheur ; 25 puis 27 impulsions ; veille pendant `power_down()`, gain 128 au réveil |
| `verify_32_kitchen_scale.mos` | `Examples.Weighing.KitchenScale` | Balance de cuisine complète : écran I2C, HX711 bruité, bouton TARE sur interruption, deux drivers du commerce | Écran : « 0 g » après la tare du plateau, « 350 g » avec le bol, « Tare... » puis « 0 g » après l'appui, « 250 g » après la farine (à 1 g près). Le plus long de la suite (≈ 50 s de simulation, cf. peripheriques-pesee.md) |

## Scénarios sans `.mos` (vérification visuelle ou démonstrateurs)

Certains éléments de `Examples/` ne correspondent volontairement à aucun script `.mos` :

- **Lisibilité visuelle de l'icône/du diagramme** (scénario dédié de `requirements.md`) : vérifiée via les outils MCP-OpenModelica (`iconDiagram`/`classDiagram`) et une relecture visuelle directe de l'image obtenue — pas de critère numérique automatisable.
- **`Examples.Gpio.LedChaser`** : démonstrateur (chenillard visuel sur les 8 GPIO), pas un scénario de vérification de `requirements.md` — sert à donner à voir l'animation des icônes `Peripherals.LED` en conditions de clignotement rapide, pas à être rejoué automatiquement.

Un nouvel exemple a besoin d'un `.mos` dédié seulement s'il vérifie un comportement numérique précis (une décision d'architecture, un correctif). Un exemple purement illustratif (comme `Gpio.LedChaser`) n'en a pas besoin.

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
**Scénario d'échec attendu** : le résultat de `simulate()` n'est pas lisible depuis un `.mos` (`r.resultFile` introuvable), et `getErrorString()` peut être vide alors que la simulation a échoué. Relancer l'exécutable par son `.bat` avec `system(".\\MonScenario.bat", "MonScenario_run.txt")` (code de sortie non nul), lire le journal par `readFile`, et y chercher un texte précis avec `regex(texte, motif, 1)`, qui rend le nombre de correspondances (cf. `verify_04_script_error.mos`). `Modelica.Utilities.Strings.find`/`System.stringFind` restent indisponibles.

**Piège rencontré en session** : `getErrorString()` n'est **pas** un critère, ni de succès ni d'échec. Il a longtemps contenu l'avertissement « The initial conditions are not fully specified », présent dans *tous* les scénarios, y compris ceux qui réussissent parfaitement : ce texte a fait échouer à tort un critère `b == ""`, et réussir à tort l'ancien critère `b <> ""` de `verify_04`. Cet avertissement a disparu (valeurs de départ explicites, cf. `requirements.md`), mais n'importe quel autre avertissement peut prendre sa place. Un `if b == "" and ... then PASS`, comme tenté une première fois pour `verify_09_import.mos`, échoue donc à tort. Se fier uniquement aux valeurs numériques attendues (`val(...)`) pour le critère de succès ; `b` reste utile seulement pour le diagnostic affiché dans le message `FAIL`.

## Nettoyage

`run_tests.sh` les supprime lui-même à la fin (sauf `-k`). Lancés à la main, les artefacts de compilation générés par ces exécutions (`.exe`, `.o`, `.c` générés, `*_res.mat`, `*.makefile`, etc.) sont couverts par `.gitignore` — vérifier `git status` après une session de vérification pour confirmer qu'aucun artefact non couvert (ex. un nouveau motif de nom de fichier) ne traîne. Les copies de système de fichiers (`mcu_datalogger_*`) créées par `verify_25` et `verify_27` sont supprimées par les scripts eux-mêmes, qui désactivent aussi l'ouverture de l'Explorateur (`simflags = "-override=mcu.fsOpenExplorer=false"`) ; s'il est interrompu, elles restent dans ce dossier (et sont effacées au lancement suivant).
