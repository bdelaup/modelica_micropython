# Illustrations de la documentation

Ce fichier n'est pas publié : il se trouve hors des deux dossiers du site (`docs/fr/`, `docs/en/`). Il recense les images attendues par les pages, leur format, et la façon de les produire. Chaque emplacement est marqué dans les pages françaises par un commentaire `<!-- ILLUSTRATION <id> : ... -->`, invisible sur le site ; `grep -rn "ILLUSTRATION" docs/fr` les liste tous.

## Conventions

| Sorte d'image | Format | Comment la produire | Taille |
|---|---|---|---|
| Icône d'un composant, vue *Diagramme* d'un exemple | **PNG** (capture MCP) ou SVG | Capture par le serveur MCP-OpenModelica recadrée par `docs/figures/crop_mcp.py` (voir plus bas) ; à défaut, OMEdit, vue *Icon* ou *Diagram* ouverte : menu *File → Export*, au format SVG | Affichée à 160-700 px de large (`{ width="..." }` dans la page) |
| Courbe de simulation | **SVG** | `python docs/figures/make_figures.py` (voir plus bas), pas de capture d'écran | 700-800 px |
| Boîte de dialogue, fenêtre d'OMEdit | **PNG** | Capture d'écran Windows (`Win + Maj + S`), recadrée au plus juste | Largeur réelle ≤ 900 px, affichée à 480-700 px |
| Animation (relecture d'un résultat) | **GIF** | Enregistreur d'écran (ScreenToGif, ShareX) sur la vue *Diagramme* d'OMEdit pendant qu'on déplace le curseur de temps | ≤ 480 px de large, ≤ 10 images/s, **≤ 1 Mo** (`BasicBlink.gif` : 320 × 240, 730 Ko) |

- **Emplacement** : toujours `docs/fr/images/` (sous-dossier `sim/` pour les courbes). Le site anglais en reçoit une copie à la construction ; ne rien déposer dans `docs/en/images/`.
- **Nom** : l'identifiant de la table ci-dessous, en minuscules avec des tirets (`grove-lcd.svg`).
- **Fond** : blanc de préférence. Le site a un thème sombre : un SVG à fond transparent y montre des traits noirs sur fond sombre, peu lisibles.
- **Texte dans l'image** : en français, les pages anglaises en donnent la traduction dans leur légende. Éviter autant que possible le texte dans les captures.
- **Insertion** : remplacer le commentaire `<!-- ILLUSTRATION <id> ... -->` par `![Texte alternatif](../images/<id>.svg){ width="400" }` (chemin relatif à la page), **dans la page française et dans sa traduction** (`docs/en/`, même chemin), avec un texte alternatif dans chaque langue.

## Images attendues

Priorité : **1** = la page en a vraiment besoin ; **2** = utile ; **3** = confort. Colonne MCP : « oui » si l'image peut être produite par Claude avec le serveur MCP-OpenModelica (rendu d'icône ou de diagramme d'une classe chargée dans OMEdit) ; « non » s'il faut une capture interactive (dialogue, animation, relecture d'un résultat).

| Id | Page(s) | Contenu | Format | Priorité | MCP |
|---|---|---|---|---|---|
| `premiers-pas-omedit` | `guide/premiers-pas.md` | Fenêtre d'OMEdit : bibliothèque dépliée dans l'explorateur, `BasicBlink` ouvert en vue *Diagramme* | PNG | 1 | non |
| `premiers-pas-parametres` | `guide/premiers-pas.md` | Boîte de paramètres du `MCU`, onglet *General*, champ *scriptPath* avec son bouton *…* | PNG | 1 | non |
| `mcu-parametres` | `guide/mcu.md` | Les cinq onglets de la boîte de paramètres du `MCU` (*General*, *Execution time*, *Electrical*, *File system*, *Debugging*), en une image composée ou en cinq (`mcu-parametres-1.png`…) | PNG | 2 | non |
| `grove-lcd` | `guide/peripheriques/i2c.md` | Icône de `I2cGroveLcdRgb` en fin de simulation de `I2c.GroveLcd` : « hello World » sur fond coloré | PNG (capture de la relecture) | 2 | non |
| `display-icone` | `guide/peripheriques/led-afficheur.md` | Icône de `Peripherals.Display` en fin de simulation de `Display.Demo` : deux messages | PNG | 2 | non |
| `hx711-icone` | `guide/peripheriques/pesee.md` | Icône de `Weighing.Hx711` pendant `Hx711Read` : gain, code, voyant cyan | PNG | 3 | non |
| `led-icones` | `guide/peripheriques/led-afficheur.md` | Icône de `Peripherals.LED` éteinte et allumée, côte à côte | PNG | 3 | non |
| `kitchen-scale-gif` | `guide/exemples.md` | Animation de la balance : l'écran Grove affiche 0 g, 350 g, Tare..., 250 g pendant qu'on déplace le curseur de temps | GIF | 2 | non |
| `grands-ecrans` | `guide/peripheriques/led-afficheur.md` | Icônes de `Display4x32` et `Display8x32` en fin de simulation de `Display.Large` (messages 7 à 10 et 3 à 10) | PNG (capture de la relecture) | 2 | non |
| `ledchaser-gif` | `guide/exemples.md` | Animation du chenillard `Gpio.LedChaser` | GIF | 3 | non |
| `analyseur-bloc-notes` | `guide/peripheriques/analyseurs.md` | Fichier texte de `UartLink` dans un éditeur à interligne serré (le Bloc-notes de Windows 11 espace les lignes du chronogramme et souligne les mots) | PNG | 3 | non |
| `analyseur-onglets` | `guide/peripheriques/analyseurs.md` | Boîte de paramètres de `LogicAnalyzer` : onglet `CH1` d'`Analyzer.I2cBus` (type `I2cSda`, horloge `CH0`), groupes UART et série synchrone grisés | PNG | 2 | non |
| `debogage-vscode` | `guide/debogage.md` | VS Code arrêté sur un point d'arrêt de `debug_demo.py` (`Program.Debug`) : ligne surlignée, panneau *Variables* (`count`, `presses`), barre de débogage ; à côté ou en médaillon, le journal d'OMEdit avec « waiting for VS Code » puis « VS Code attached » | PNG | 1 | non |

Les images « oui » ont été faites le 2026-10-02 (voir ci-dessous) ; celles qui restent demandent une capture interactive. **Captures MCP** : le serveur rend une vue en PNG 1024 × 1024 (`iconDiagram` pour une icône, `classDiagram` pour une vue *Diagramme*), sur fond quadrillé ; `python docs/figures/crop_mcp.py capture.png sortie.png` remplace fond et quadrillage par du blanc et recadre, `--no-name` efface le texte `%name` d'une icône, `--row ... -o sortie.png` assemble plusieurs captures côte à côte, `--max-width` réduit. Pièges : recharger la bibliothèque dans OMEdit avant de capturer (sinon l'ancienne version est rendue) ; une vue *Diagramme* jamais ouverte peut sortir vide, un `listComponents` sur la classe avant la capture suffit ; les icônes très lourdes (`TextIcon8x32`) peuvent faire expirer l'appel. Rendu matriciel : un schéma très large (`KitchenScale`) y perd en finesse. Le petit texte est lissé avec des franges colorées (rose, cyan), que `--no-name` sait ignorer. Captures d'icônes et de schémas refaites le 2026-10-06 après le passage des icônes à `initialScale = 0.2` (décision « Taille des icônes » de `requirements.md`) : à refaire de même après toute retouche d'icône ou de mise en page d'un exemple capturé.

## Images déjà présentes

| Fichier | Page(s) | Origine |
|---|---|---|
| `mcu-icone.png` | `guide/mcu.md` (FR et EN), `interne/architecture.md` | Capture MCP de l'icône de `MCU`, `--no-name` (remplace `mcu-icone.svg`, périmé, supprimé) |
| `uart-schema.png`, `i2c-schema.png`, `pesee-schema.png` | `guide/peripheriques/uart.md`, `i2c.md`, `pesee.md` (FR et EN), vignettes de `guide/exemples.md` | Captures MCP des vues *Diagramme* de `Uart.Sensor`, `I2c.MultiDevice`, `Weighing.KitchenScale` |
| `analyseur-schema.png` | `guide/peripheriques/analyseurs.md` (FR et EN) | Capture MCP de la vue *Diagramme* de `Analyzer.UartLink` |
| `pulseview-uart.png`, `pulseview-i2c.png` | `guide/peripheriques/analyseurs.md` (FR et EN) | Captures d'écran de PulseView (copie portable) ouvert sur les VCD d'`Analyzer.UartLink` (`stopTime` = 0,17 s) et d'`Analyzer.I2cBus` (`stopTime` = 3,4 ms), décodeurs chargés depuis la session `.pvs` ; fenêtre maximisée capturée par PowerShell (`System.Drawing`), recadrée sur la règle et les voies, réduite à 1500 px |
| `grands-ecrans-cablage.png` | `guide/peripheriques/led-afficheur.md` (FR et EN), section « Câblage » des afficheurs | Capture MCP de la vue *Diagramme* de `Display.Large`, refaite le 2026-10-07 après le resserrement du schéma (`display-cablage.png`, schéma de `Display.Demo`, retirée le même jour avec la fusion des deux sections d'afficheurs) |
| `radio-schema.png` | `guide/peripheriques/radio.md` (FR et EN) | Capture MCP de la vue *Diagramme* de `Radio.Link` |
| `uart-icones.png` | `guide/peripheriques/uart.md` (FR et EN) | Cinq captures MCP d'icônes, `--no-name --row --max-width 1400` |
| `exemple-basicblink.png`, `exemple-ledchaser.png`, `exemple-ledfade.png`, `exemple-grovelcd.png` | vignettes de `guide/exemples.md` (FR et EN), `interne/architecture.md` (BasicBlink) | Captures MCP des vues *Diagramme* (remplacent `exemple-basicblink.svg`, supprimé) |
| `logo.svg`, `logo.png` | en-tête et onglet du site, `interne/architecture.md` | Miroir de l'icône de `package.mo`, resynchronisé à la main |
| `BasicBlink.gif`, `BasicBlink.png` | accueil, `guide/premiers-pas.md` | Capture de la relecture de `BasicBlink`. **À refaire** : montre encore « (v0) » sous « MCU », retiré de l'icône le 2026-10-02 |
| `library_tree.png` | `guide/premiers-pas.md` | Capture de l'explorateur d'OMEdit |
| `broche-modele.svg` | `guide/mcu.md` (FR et EN) | Schéma du pont électrique d'une broche (source, `ROut`, interrupteur, tirages internes, capteur), dessiné à la main en SVG d'après l'ancien `MCU.mo`. **À refaire** : depuis le 2026-10-04, l'étage de sortie est la brique `Internal.PinBridge` du cœur (deux conductances `1/ROut`, vers l'alimentation `vdd` et vers `VOL`, sans source ni interrupteur) ; le texte de `guide/mcu.md` est à jour, pas l'image. Texte en français, traduit dans la légende de la page anglaise |
| `pico-icone.png` | `guide/pico.md` (FR et EN) | Capture MCP de l'icône de `RPi_Pico`, `--no-name`. Icône générée par `make_pico.py` : la recapturer après toute retouche du générateur |
| `pico-schema-interne.png` | `guide/pico.md` (FR et EN), `interne/cartes.md` | Capture MCP de la vue *Diagramme* de `RPi_Pico` (fils colorés par réseau, zones de fond), générée par `make_pico.py` |
| `exemple-pico-blink.png`, `exemple-pico-battery.png`, `exemple-pico-powerup.png` | vignettes de `guide/exemples.md` (FR et EN) | Captures MCP des vues *Diagramme* des exemples `Pico.*` |
| `pico-alimentation.svg`, `pico-alimentation-en.svg` | `guide/pico.md` (FR, EN), `interne/cartes.md` | Schéma de principe de l'alimentation de la Pico, dessiné à la main en SVG d'après `make_pico.py` (mêmes couleurs que les fils du schéma interne). **Version anglaise à part** (demande de l'utilisateur, exception à la règle « texte en français ») : `-en.svg` est produite à partir du français par la table de traductions de `python docs/figures/make_pico_alimentation_en.py` ; retoucher d'abord le français, puis répercuter dans l'anglais. À retoucher si l'arbre d'alimentation change |
| `sim/*.svg` | pages du guide | Générées par `docs/figures/make_figures.py` |

## Courbes de simulation générées

`docs/figures/make_figures.py` simule des exemples avec `omc` (dans un dossier temporaire hors du dépôt) et trace les courbes avec matplotlib, en SVG, dans `docs/fr/images/sim/` :

```
python docs/figures/make_figures.py                # toutes
python docs/figures/make_figures.py uart hx711     # certaines
```

| Figure | Exemple simulé | Grandeurs | Pages |
|---|---|---|---|
| `basicblink-gp0.svg` | `BasicBlink` | `mcu.GP0.v` | premiers pas |
| `uart-trame.svg` | `Uart.Loopback` | `mcu.GP0.v`, grille des bits de `'H'` | appareils série, exemples |
| `uart-regulation.svg` | `Uart.Regulation` | `plant.y`, `sensor.valueOut[1]`, consigne | appareils série |
| `i2c-chronogramme.svg` | `I2c.Echo` | `echo.SCL.v`, `echo.SDA.v`, octets et ACK repérés | périphériques I2C |
| `pwm-led.svg` | `Pwm.Led` | `mcu.GP0.v`, `led0.p.i` | exemples |
| `hx711-lecture.svg` | `Weighing.Hx711Read` | `hx.PD_SCK.v`, `hx.DOUT.v` (pas de 0,5 µs) | chaîne de pesée |
| `pwm-fade.svg` | `Pwm.LedFade` | `mcu.pwmDuty[1]` (variable protégée, `-emit_protected`), deux zooms de `mcu.GP0.v` à 25 % et 75 % | exemples |
| `input-reactivity.svg` | `Gpio.InputReactivity` | `mcu.GP1.v`, `mcu.GP0.v` | exemples |
| `gpio-timing.svg` | `Gpio.Timing` | `mcu.GP0.v` à la µs : impulsion `on(); off()` et rafale de 10 impulsions | API |
| `kitchen-scale.svg` | `Weighing.KitchenScale` | `totalMass.y`, `hx.code`, appui TARE | chaîne de pesée |
| `radio-modulations.svg` | `Radio.Modulations` (pas de 2,5 µs) | `txOOK.sTx`, `txASK.sTx`, `txFSK.sTx`, `txBPSK.sTx`, grille des bits de `U` | liaison radio |
| `radio-signal-trace.svg` | aucun : schéma calculé (bits 0 1 1 0, réglages par défaut) ; écrit aussi `MicroPythonMCU/Resources/Images/radio_drawn_signal.png` (version anglaise, image du groupe *Drawn carrier* de la boîte de paramètres du `RadioModem`) | `sTx` ASK et FSK annotés (`fDisplay`, `deltaFDisplay`, `askLowAmplitude`) | liaison radio |
| `radio-sampling.svg` | `Radio.Modulations` simulé deux fois (intervalles 2,5 µs et 200 µs) | `txFSK.sTx` : porteuse nette, puis repliement | liaison radio |
| `radio-overflow.svg` | `Radio.Overflow` | `radioA.txFill`, `radioA.nDropped`, `radioA.carrierOn` | liaison radio |
| `pico-power.svg` | `Pico.PowerUp` | `pico.vSys`, `pico.vRail`, `pico.GP15.v`, `pico.core.powerGood` | carte Pico, exemples |
| `pico-battery.svg` | `Pico.Battery` | `iBattery.i`, `pico.GP15.v` | carte Pico |

À relancer quand un exemple ou un composant tracé change. Prérequis : `omc` (via `OPENMODELICAHOME` ou le `PATH`) et `matplotlib`. Compter quelques minutes : chaque figure compile son exemple.

Les textes des figures sont en français ; les pages anglaises en traduisent les libellés dans le texte alternatif de l'image.
