# Analyse des trames — la sonde d'analyseur logique

!!! info "Référence interne"
    Cette page décrit le fonctionnement interne. Pour utiliser la sonde (câblage, réglage des voies, fichiers, PulseView) : [Analyseur logique](../guide/peripheriques/analyseurs.md).

Cadrage et alternatives : décision « Analyseur logique » de [`requirements.md`](https://gitlab.com/bdelaup/modelica_micropython3/-/blob/main/requirements.md) (lot 3). Un seul instrument, la sonde `Peripherals.Analyzers.LogicAnalyzer` : la capture intégrée au `MCU` et les sondes décodantes `UartMonitor`/`I2cMonitor`, livrées en chemin, ont été retirées (détail dans `requirements-archive.md`).

## 1. Organisation

| Côté | Fichier | Rôle |
|---|---|---|
| Modelica | `Peripherals/Analyzers/LogicAnalyzer.mo` | 8 voies électriques, un onglet de paramètres par voie, `when change(level[i])` → `LogicAnalyzer_record`, `when terminal()` → `LogicAnalyzer_finish` |
| Modelica | `Internal/LogicAnalyzerCapture.mo` (+ `LogicAnalyzer_record`, `LogicAnalyzer_finish`) | External Object ; le constructeur reçoit la configuration des 8 voies en tableaux |
| C | `AnalyzerImpl.c/.h` | Chapeau, sans Python ni thread ; inclut `launch.c` puis `analyzer/` dans cet ordre : |
| C | `analyzer/analyzer_vcd.c` | Enregistreur VCD |
| C | `analyzer/analyzer_core.h` | Constantes et structures (`struct LogicAnalyzer`, `struct AnChannel`) |
| C | `analyzer/analyzer_text.c` | Décodeurs (UART, I2C, série synchrone) et écriture du fichier texte |
| C | `analyzer/analyzer_pvs.c` | Session PulseView (`.pvs`) |
| C | `analyzer/analyzer_logic.c` | Construction, capture, destructeur (API exportée) |

## 2. Côté Modelica

Huit voies `CH0`…`CH7`, chacune une `VoltageSensor` et une conductance `GIn` (1 GΩ) vers `GND` : une voie non câblée a une tension déterminée (0 V), et le montage n'est pas perturbé. `level[i] = if kinds[i] <> Off then sns[i].v > seuil else false` : une voie `Off` n'a pas de fonction de franchissement (`kinds` est un paramètre). La sonde ne pilote rien : pas de boucle `when` ↔ réseau électrique, donc pas de capacité d'entrée pour couper un cycle (contrairement à `PartialUartDevice`).

**Paramètres par voie** : ≈ 90 paramètres scalaires (`ch0Kind` … `ch7Signed`), un onglet `CHn` par voie, grisés par `enable` selon le type. Un onglet unique à tableaux aurait été plus court à écrire, mais OMEdit montre un tableau comme une liste `{…}` à taper. La partie protégée les rassemble en tableaux pour le constructeur : noms joints par des virgules (une chaîne, pas un tableau de `String`), types par `Integer(kind)`, parité par `Integer(parity) - 2` (convention `machine.UART`), ordre des bits pris dans le groupe UART ou synchrone selon le type, booléens en entiers 0/1 (jamais de tableau de `Boolean` vers le C, cf. décision « Tableaux de booléens et fonctions externes »). Le constructeur valide la configuration (`ModelicaFormatError`) : voie d'horloge d'une voie `I2cSda`/`SyncData` différente d'elle-même et de type `Logic`, format UART, taille de mot.

La sonde voit les fronts **électriques** : sur la liaison de `Analyzer.UartLink`, ≈ 86 ns après la commande, le temps que la capacité d'entrée `CIn` de l'appareil (1 nF face aux 100 Ω de sortie) franchisse le seuil. D'où les motifs à la microseconde de `verify_47`.

## 3. Capture : VCD et fronts en mémoire

`LogicAnalyzer_record` reçoit les 8 niveaux à chaque changement. Modelica la rappelle 2 à 3 fois au même instant, et une sortie publiée ne devient tension qu'à l'itération suivante : un instant peut voir passer des valeurs intermédiaires. D'où, des deux côtés, la **coalescence par instant** — on garde la dernière valeur de chaque voie à l'instant en cours (temps en nanosecondes entières, `llround(t × 1e9)`), et l'on n'écrit, quand le temps avance, que ce qui diffère de la dernière valeur écrite. Le fichier ne contient que de vrais changements, sans glitch de largeur nulle.

- **VCD** (`analyzer_vcd.c`) : écrit au fil de l'eau, tamponné (`setvbuf`), voies actives seulement ; en-tête `$timescale 1 ns`, une variable `wire 1` par voie, identifiants `A`, `B`… (`$` ou `"`, permis par la norme, déroutent certains lecteurs) ; fichier binaire (`"wb"`, fins de ligne LF) ; `vcd_close(t_fin)` ajoute un horodatage final pour que les visionneuses montrent toute la durée.
- **Fronts en mémoire** (`an_commit_instant`) : un tableau dynamique `struct AnEdge {t, v}` par voie active, `edges[0]` = niveau initial à t = 0. Un front avant 1 µs (`AN_INIT_WINDOW`) remplace le niveau initial : c'est l'établissement des sources à t = 0 (le TX d'un MCU monte à 55 ns), pas une activité. Plafond `AN_MAX_EDGES` = 2 millions, toutes voies : au-delà, avertissement, le fichier texte s'arrête là (`t_full`), le VCD continue.

## 4. Fin de simulation : décodage hors ligne

Le destructeur clôt le VCD, puis appelle `an_write_text`. Les décodeurs travaillent **hors ligne** sur les fronts, avec `an_level(voie, t)` (recherche dichotomique du dernier front ≤ t) : lire le niveau à n'importe quel instant est plus simple et plus sûr que de rejouer une machine à états au fil des appels, et l'on voit toute la capture (salves, résolution automatique).

**Résolution** (`an_auto_resolution`), si `textResolution` = 0 : le minimum d'un demi-bit par voie UART (`0,5/baud`) et d'un demi-palier par voie d'horloge (plus petit intervalle entre deux fronts de la voie d'horloge, divisé par deux : 2,5 µs pour SCL à 100 kHz ou pour les impulsions de 5 µs de l'HX711) ; à défaut de voie décodée, la moitié du plus petit intervalle d'une voie logique (au moins 100 ns). Silence automatique : 40 colonnes.

**UART** (`an_decode_uart`) : un front descendant hors trame est un start s'il est encore bas un demi-bit plus tard ; chaque bit est lu en son milieu, `(1,5 + i) × T` après le start ; parité contrôlée, puis le **premier** stop seulement (comme le RP2040) ; l'octet est gardé même faux (`!P`, `!F`). La recherche du start suivant reprend au milieu du premier stop, comme un récepteur réel. Une trame coupée par la fin de la capture est ignorée. Salves : octets séparés de moins de deux durées de trame.

**I2C** (`an_decode_i2c`) : fusion chronologique des fronts de SDA et de SCL. SDA qui descend pendant que SCL est haute : START, ou START répété (`Sr`) si une transaction est ouverte ; SDA qui monte : STOP. Bit lu au front **montant** de SCL (même piège que pour l'esclave : compter au front descendant décale tout d'un bit) ; 9ᵉ bit = acquittement tel qu'il est vu sur le bus. Le maître remonte SCL avant un START répété ou un STOP : ce front montant n'est pas un bit, ses étiquettes sont retirées (`byte_labels`). Premier octet après un START = adresse et sens.

**Série synchrone** (`an_decode_sync`) : instants de lecture = fronts choisis de la voie d'horloge. Une rafale (intervalle de moins de 8 fois le plus court intervalle entre deux lectures) est une trame, découpée en mots de `wordBits` bits, poids fort ou faible en tête, signés en complément à deux si demandé ; les impulsions restantes (moins d'un mot) sont comptées à part.

**Voie logique** (`an_logic_summary`) : nombre de fronts, premier front, part du temps à l'état haut, impulsions haute et basse les plus courtes (entre deux fronts).

Chaque décodeur produit, par voie : des **étiquettes** (`struct AnLabel`, un bit à un instant), des **valeurs** (`struct AnSpan`, un octet sur un intervalle), les lignes de la section hexa (`struct AnText`), et, pour toute la sonde, des intervalles **occupés** (milieu d'un octet : une ligne n'y est pas coupée) et des **trames**.

## 5. Mise en page du chronogramme

- **Zones** (`an_build_regions`) : les trames des voies décodées ; les fronts des voies (logiques ou d'horloge) qui tombent hors de toute trame, groupés par silences, se rattachent à une trame voisine à moins d'un silence, sinon forment une zone ; les trames qui se chevauchent (l'aller et l'écho d'une liaison) fusionnent. Sans `textSplitFrames`, les zones séparées de moins d'un silence fusionnent aussi ; sans `textCompressSilences`, toutes.
- Entre deux zones : `~~ durée of silence ~~` au-delà du silence, sinon `-------- durée later`.
- **Lignes** : `textWidth` colonnes de `dt` ; la coupure se fait au dernier instant libre de la seconde moitié de la ligne (`an_is_busy` : intervalles occupés triés par début, maximum courant des fins, recherche dichotomique), sinon pleine largeur. La dernière ligne d'une zone peut déborder de 15 % pour éviter un reliquat de quelques colonnes.
- **Dessin** (`an_draw_block`) : niveau au milieu de chaque colonne ; colonne où le niveau change : `|` en bas ; haut : `_` en haut ; bas : `_` en bas (le `_` du haut est à la hauteur du haut du `|`). Sous une voie décodée : étiquettes à la colonne `(t − t0)/dt + 0,25`, puis valeurs entre crochets centrées ; une valeur coupée par une fin de ligne n'a de crochet qu'à ses vraies extrémités, son texte va dans la partie qui porte son début.
- Plafond `AN_TEXT_MAX_COLUMNS` = 200 000 colonnes : au-delà, une note, la section hexa reste complète.

Le fichier est écrit en binaire (LF) : le Bloc-notes les lit depuis Windows 10, et les motifs des scénarios n'ont pas à tenir compte de CR.

## 6. Session PulseView : `analyzer_pvs.c`

PulseView, quand il ouvre `X.vcd`, charge de lui-même `X.pvs` posé à côté (le nom de la session est celui du fichier, extension remplacée) : la sonde n'a qu'à l'écrire, après le VCD et avant de lancer PulseView, et cela marche aussi quand l'élève ouvre le VCD à la main. L'option `-s` de PulseView n'est pas utilisée.

Le format est celui de QSettings (INI), écrit par PulseView par *Save session setup* ; il **n'est pas documenté**. Relevé sur un fichier enregistré par PulseView, validé avec PulseView 0.5.0 :

```
[General]
decode_signals=2              ; nombre de décodeurs
generated_signals=0
views=0                       ; pas de vue enregistrée : celle par défaut
meta_objs=0

[decode_signal0]
name=UART TX
enabled=true
decoders=1
decoder0\id=uart
decoder0\visible=true
decoder0\options=6
decoder0\option0\name=baudrate
decoder0\option0\type=x                                        ; type GVariant
decoder0\option0\value=@ByteArray(\xb0\x4\x0\x0\x0\x0\x0\x0)     ; 1200, entier 64 bits petit-boutiste
...
channels=1
channel0\name=RX                                 ; voie du décodeur
channel0\initial_pin_state=2
channel0\assigned_signal_name=probe.TX           ; signal PulseView : scope du VCD + nom
```

- Valeur d'un réglage : le **GVariant sérialisé** (octets bruts) dans un `@ByteArray(...)`, chaque octet écrit `\xHH` (QSettings relit un nombre hexadécimal jusqu'au caractère suivant, `\` ici) ; type `x` (entier 64 bits), `d` (double), `s` (chaîne terminée par un NUL). Les réglages absents gardent leur valeur par défaut.
- Noms des voies de décodeur (`RX`, `SCL`, `SDA`, `CLK`, `MISO`) et identifiants des réglages (`baudrate`, `data_bits`, `parity`, `stop_bits`, `bit_order`, `format` ; `cpol`, `cpha`, `bitorder`, `wordsize`) : ceux des `pd.py` de libsigrokdecode (`share/libsigrokdecode/decoders/` du dossier de PulseView).
- PulseView nomme un signal du VCD par son scope suivi du nom : `probe.TX`. Le premier essai, avec `TX`, donnait « There are no channels assigned to this decoder ».
- SPI : `cpol` = niveau de l'horloge au début de la capture (`edges[0]` de la voie d'horloge) ; `cpha` = 0 si le front de lecture est le premier après le repos (montant pour `cpol` = 0), 1 sinon. HX711 : `cpol` = 0, lecture au front descendant, donc `cpha` = 1. Les données sont affectées à `MISO` (esclave vers maître). Le décodeur SPI de PulseView enchaîne les bits sans notion de rafale : les impulsions de gain décalent ses mots suivants.

À revalider à chaque nouvelle version de PulseView : les scénarios ne contrôlent que le contenu du fichier.

## 7. Ouverture en fin de simulation : `launch.c`

`launch_detached(what, exe, opts, file)` lance `"exe" opts "file"` par `CreateProcessA`, sans attendre (pas de `shell32` à lier). C'est le **seul** point du runtime qui dépend du système pour lancer un programme : `fsOpenExplorer` (Explorateur sur la copie de la flash), le Bloc-notes (`notepad.exe`, trouvé dans le `PATH`) et PulseView passent par lui. Hors Windows, il écrit au journal quel fichier ouvrir avec quoi : un portage Linux n'aura que lui à compléter (`posix_spawnp`).

PulseView : `pulseview -c -I vcd <fichier>`, d'après `pulseview --help` (`[OPTIONS] [FILE]`, `-I` format d'entrée, `-c` sans restaurer les sessions précédentes) ; options **avant** le fichier. Chemin par défaut `Interfaces.PULSEVIEW_PATH`, là où l'installeur Windows le place (hors `PATH`) ; une URI `modelica://` est résolue côté Modelica (`Internal.ResolvePath`), un chemin relatif est rendu absolu à la construction depuis le dossier de simulation (`launch_full_path`). Un échec n'est qu'un avertissement. Le dossier d'installation de PulseView est autonome : une copie en est posée à la racine du dépôt (`PulseView/`, ignorée par git), atteinte par `modelica://MicroPythonMCU/../PulseView/pulseview.exe`.

## 8. Vérification

- `verify_47_logic_analyzer.mos` : `Analyzer.UartLink`, VCD (trame 8E2 relevée à la microseconde), fichier texte (salves, bits, octets) et session (deux décodeurs `uart`, débit et parité en octets).
- `verify_48_analyzer_i2c.mos` : `Analyzer.I2cBus`, transactions, NACK, START répété, pas de bit fantôme avant le STOP, bilan de la voie logique, session `i2c`.
- `verify_49_analyzer_sync.mos` : `Analyzer.Hx711Serial`, mots de 24 bits égaux à la valeur que le programme lit, silences comprimés, session `spi` (`cpha` = 1, 24 bits).
- `verify_50_analyzer_options.mos` : `Analyzer.UartErrors`, octets en erreur de parité, puis options du fichier texte et `writeVcd = false` par `-override`.

Les motifs portent sur le texte des fichiers (`readFile` + `regex`) ; l'ouverture du Bloc-notes et de PulseView est désactivée par `-override`.

## 9. Notes pour plus tard

- SPI complet (MISO + MOSI + sélection d'esclave), adresses I2C sur 10 bits : non décodés.
- Le rattachement des fronts isolés aux trames est quadratique (groupes × trames) : à revoir si un PWM rapide côtoie de nombreuses trames décodées.
