# Illustrations de la documentation

Ce fichier n'est pas publié : il se trouve hors des deux dossiers du site (`docs/fr/`, `docs/en/`). Il recense les images attendues par les pages, leur format, et la façon de les produire. Chaque emplacement est marqué dans les pages françaises par un commentaire `<!-- ILLUSTRATION <id> : ... -->`, invisible sur le site ; `grep -rn "ILLUSTRATION" docs/fr` les liste tous.

## Conventions

| Sorte d'image | Format | Comment la produire | Taille |
|---|---|---|---|
| Icône d'un composant, vue *Diagramme* d'un exemple | **SVG** | OMEdit, vue *Icon* ou *Diagram* ouverte : menu *File → Export*, export en image au format SVG (OMEdit propose aussi PNG et BMP) | Affichée à 160-480 px de large (`{ width="..." }` dans la page) |
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
| `mcu-icone` | `guide/mcu.md`, `interne/architecture.md` | Icône actuelle du bloc `MCU`, **avec le connecteur DISPLAY** : remplace `mcu-icone.svg`, périmé (généré avant l'ajout de `Display0`) | SVG | 1 | oui |
| `premiers-pas-omedit` | `guide/premiers-pas.md` | Fenêtre d'OMEdit : bibliothèque dépliée dans l'explorateur, `BasicBlink` ouvert en vue *Diagramme* | PNG | 1 | non |
| `premiers-pas-parametres` | `guide/premiers-pas.md` | Boîte de paramètres du `MCU`, onglet *General*, champ *scriptPath* avec son bouton *…* | PNG | 1 | non |
| `mcu-parametres` | `guide/mcu.md` | Les quatre onglets de la boîte de paramètres du `MCU` (*General*, *Temps d'exécution*, *Électrique*, *Système de fichiers*), en une image composée ou en quatre (`mcu-parametres-1.png`…) | PNG | 2 | non |
| `uart-schema` | `guide/peripheriques/uart.md` | Vue *Diagramme* de `Examples.Uart.Sensor` : `MCU`, `UartTemperatureSensor`, fils TX/RX croisés | SVG | 1 | oui |
| `i2c-schema` | `guide/peripheriques/i2c.md` | Vue *Diagramme* de `Examples.I2c.MultiDevice` : trois esclaves sur le même bus | SVG | 1 | oui |
| `pesee-schema` | `guide/peripheriques/pesee.md` | Vue *Diagramme* de `Examples.Weighing.KitchenScale` : chaîne complète, écran, bouton TARE | SVG | 1 | oui |
| `grove-lcd` | `guide/peripheriques/i2c.md` | Icône de `I2cGroveLcdRgb` en fin de simulation de `I2c.GroveLcd` : « hello World » sur fond coloré | PNG (capture de la relecture) | 2 | non |
| `display-icone` | `guide/peripheriques/led-afficheur.md` | Icône de `Peripherals.Display` en fin de simulation de `Display.Demo` : deux messages | PNG | 2 | non |
| `hx711-icone` | `guide/peripheriques/pesee.md` | Icône de `Weighing.Hx711` pendant `Hx711Read` : gain, code, voyant cyan | PNG | 3 | non |
| `led-icones` | `guide/peripheriques/led-afficheur.md` | Icône de `Peripherals.LED` éteinte et allumée, côte à côte | PNG | 3 | non |
| `uart-icones` | `guide/peripheriques/uart.md` | Les cinq icônes des appareils série côte à côte (`UartGenericDevice`, `UartEchoDevice`, `UartTemperatureSensor`, `UartGpsModule`, `UartLcd20x2`) | SVG | 3 | oui |
| `exemples-vignettes` | `guide/exemples.md` | Une vignette (vue *Diagramme*) par exemple phare : `BasicBlink`, `Gpio.LedChaser`, `Pwm.LedFade`, `Uart.Sensor`, `I2c.GroveLcd`, `Weighing.KitchenScale` (`exemple-<nom>.svg`) | SVG | 2 | oui |
| `kitchen-scale-gif` | `guide/exemples.md` | Animation de la balance : l'écran Grove affiche 0 g, 350 g, Tare..., 250 g pendant qu'on déplace le curseur de temps | GIF | 2 | non |
| `ledchaser-gif` | `guide/exemples.md` | Animation du chenillard `Gpio.LedChaser` | GIF | 3 | non |

Le serveur MCP-OpenModelica n'était pas joignable lors de la refonte du 2026-09-28 : les images marquées « oui » restent à faire, par Claude une fois le serveur relancé (avec OMEdit ouvert), ou à la main avec l'export SVG d'OMEdit.

## Images déjà présentes

| Fichier | Page(s) | Origine |
|---|---|---|
| `logo.svg`, `logo.png` | en-tête et onglet du site, `interne/architecture.md` | Miroir de l'icône de `package.mo`, resynchronisé à la main |
| `BasicBlink.gif`, `BasicBlink.png` | accueil, `guide/premiers-pas.md` | Capture de la relecture de `BasicBlink` |
| `library_tree.png` | `guide/premiers-pas.md` | Capture de l'explorateur d'OMEdit |
| `exemple-basicblink.svg` | `interne/architecture.md` | Export OMEdit de la vue *Diagramme* de `BasicBlink` |
| `mcu-icone.svg` | `interne/architecture.md` | Périmé, voir `mcu-icone` ci-dessus |
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
| `uart-regulation.svg` | `Uart.Regulation` | `procede.y`, `capteur.valueOut[1]`, consigne | appareils série |
| `i2c-chronogramme.svg` | `I2c.Echo` | `echo.SCL.v`, `echo.SDA.v`, octets et ACK repérés | périphériques I2C |
| `pwm-led.svg` | `Pwm.Led` | `mcu.GP0.v`, `led0.p.i` | exemples |
| `hx711-lecture.svg` | `Weighing.Hx711Read` | `hx.PD_SCK.v`, `hx.DOUT.v` (pas de 0,5 µs) | chaîne de pesée |

À relancer quand un exemple ou un composant tracé change. Prérequis : `omc` (via `OPENMODELICAHOME` ou le `PATH`) et `matplotlib`. Compter quelques minutes : chaque figure compile son exemple.

Pistes pour d'autres courbes : `Pwm.LedFade` (rapport cyclique croissant et courant de la LED), `Gpio.InputReactivity` (réveil du programme au front du bouton), `Gpio.Timing` (impulsion de 5 µs), `Weighing.KitchenScale` (masse posée et code du HX711, simulation longue).
