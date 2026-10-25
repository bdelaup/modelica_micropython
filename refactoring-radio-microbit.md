# Spécification — Refactoring : la radio de la micro:bit passe par un modem radio générique

*Statut : proposition à valider — 2026-10-24*
*Objet : remplacer la mécanique radio spécifique à `MicroBit_v2` (moteur de paquets C dédié, liaison logique `RadioAir`, plomberie dans le cœur et la synchro) par le réemploi du modem radio générique de la bibliothèque (`Internal.PartialRadioModem`), le protocole paquets du firmware étant déplacé dans le shim Python.*

---

## 1. Objet

La bibliothèque entretient aujourd'hui **deux mécanismes radio distincts** :

1. le **modem radio générique** (`Peripherals.Radio.RadioModem`, moteur C `RadioModemImpl.c`) : un appareil série branché sur deux broches `GPx`, un fil d'antenne acausal (`Interfaces.Antenna`), des tampons et délais paramétrables, un signal modulé tracé ;
2. la **radio embarquée de la micro:bit** (`microbit.radio`) : un moteur de paquets dédié côté C (`pyruntime_radio.c`, 397 lignes : registre des moteurs, filtrage `channel`/`group`/`address`, file `queue`, livraison à t + durée de trame), une topologie par **liaison logique** (`Interfaces.RadioAirInput`/`RadioAirOutput` + composant `Peripherals.Radio.RadioAir` + `Internal.StringHash`), et une plomberie dans le cœur et la synchro (`Internal.McuCoreRadio`, argument `boardNetwork` de `Internal.PyRuntime_syncBoard`, hooks C `set_network`/`next_inbox_deadline`).

Ce second mécanisme duplique ce que le premier sait déjà faire (transport d'octets dans l'air, collisions, semi-duplex) et laisse des spécificités micro:bit dans du code partagé — c'est exactement ce que la décision « Refactoring du socle des cartes » de `requirements.md` avait commencé à résorber (la radio est sortie du cœur partagé, mais sous forme d'un cœur parallèle `McuCoreRadio` et d'une synchro parallèle `PyRuntime_syncBoard`).

**Objectif du refactoring** : la radio embarquée de la micro:bit devient **un modem radio ordinaire**, monté à l'intérieur de la carte et branché en interne sur deux broches du cœur ; tout ce que la bibliothèque a de spécifique à `microbit.radio` se réduit au **protocole paquets du firmware, écrit en Python dans le shim** (`microbit_shim.py`). Après le chantier, il n'existe plus qu'**un seul mécanisme radio** dans la bibliothèque, un seul type de fil d'antenne, et plus aucune ligne de C dédiée à la radio micro:bit.

## 2. Ce que le refactoring supprime

| Élément actuel | Rôle | Devenir |
|---|---|---|
| `Resources/Include/pyruntime/pyruntime_radio.c` (397 l.) | moteur de paquets : registre des cartes, filtrage, file `queue`, minuteries de livraison | **Supprimé** |
| `Internal/McuCoreRadio.mo` | cœur parallèle avec `useRadio` + `AntennaIn` + synchro `syncBoard` | **Supprimé** — `MicroBit_v2` redevient `Internal.McuCore` |
| `Internal/PyRuntime_syncBoard.mo` (+ wrapper C) | variante de la synchro portant `boardNetwork` | **Supprimé** — retour à la seule `PyRuntime_sync` |
| `Interfaces/RadioAirInput.mo`, `Interfaces/RadioAirOutput.mo` | connecteurs causaux de la liaison logique | **Supprimés** |
| `Peripherals/Radio/RadioAir.mo` | « air » partagé distribuant un identifiant de réseau | **Supprimé** — le fil d'antenne `Interfaces.Antenna` est le medium |
| `Internal/StringHash.mo` | identifiant de réseau dérivé du nom de `RadioAir` | **Supprimé** (plus aucun utilisateur) |
| Hooks C `set_network`, `next_inbox_deadline` (`pyruntime_board.h`, `pyruntime_microbit.c`) | branchement du moteur de paquets dans la synchro | **Supprimés** |
| Natives `radio_*` (`pyruntime_module.c`) + entrées `_native.radio_*` du shim | API C du moteur de paquets | **Supprimées** |
|.Argument `radioNetwork` / champ `board_network` | identifiant de réseau transmis à chaque synchro | **Supprimé** |

Soit environ **400 lignes de C** et **cinq fichiers Modelica** en moins, et deux branches en moins dans le code de synchro partagé.

## 3. Principe cible

```
AVANT                                             APRÈS

script Python                                     script Python
   │  import radio                                   │  import radio
   ▼                                                 ▼
shim : _native.radio_*                   shim : protocole paquets (Python)
   │  (paquets déjà formés)                          │  trames sur l'UART interne (nid 1)
   ▼                                                 ▼
moteur C pyruntime_radio.c              moteur UART DÉDIÉ n° 1 (uartcore, existant)
   │  (filtrage, queue, horodatage)                  │  bits sur broches internes 34/35
   ▼                                                 ▼        (le moteur n° 0 reste au script)
identifiant de réseau (synchro)          modem radio INTERNE à la carte
   │                                                 │  (Internal.PartialRadioModem,
   ▼                                                 │   moteur RadioModemImpl.c existant)
liaison logique RadioAirInput/Output                 │
   │                                                 ▼
   ▼                                      fil d'antenne Interfaces.Antenna
composant Peripherals.Radio.RadioAir                 │
 (identifiant dérivé du nom)                         ▼
                                          l'autre carte (ou un RadioModem)
```

Le transport d'octets (sérialisation, tampons, collisions, semi-duplex) est **entièrement délégué au modem générique** ; la sémantique du firmware micro:bit (filtrage, file, troncation) vit **entièrement dans le shim**, comme le reste de l'API `microbit`. La carte n'a plus aucun code radio spécifique : elle a un périphérique interne de plus, comme sa matrice a ses broches internes.

## 4. Conception détaillée

### 4.1 Côté carte (Modelica, généré par `tools/make_microbit.py`)

- **Deux broches internes** ajoutées à la table du cœur : identifiants **34** (TX du cœur vers le modem) et **35** (RX du cœur depuis le modem), capacité numérique, `nPins` passe de 32 à 34 (limite `MAX_PINS` : 40). Elles n'apparaissent ni sur l'edge ni dans le dialogue : réservées à la radio, comme les broches des lignes de la matrice.
- **Un modem radio interne** : nouvelle petite classe `Internal.OnBoardRadioModem` (extends `Internal.PartialRadioModem`, tous les paramètres `final`, icône vide, instanciée `protected` et invisible dans `MicroBit_v2`) ; ses broches série sont câblées aux broches internes 34/35 du cœur (même topologie électrique qu'un `RadioModem` externe sur deux `GPx` : rien de nouveau côté physique ni côté `PinBridge`).
- **Le port public de la carte devient un `Interfaces.Antenna`** (conditionné par `useRadio`, étiquette `ant` conservée sur l'icône) : le même connecteur acausal que les `RadioModem`, câblé par un simple `connect(radio.antenna, Antenna)` sous `if useRadio`. **Un seul type de fil d'antenne dans toute la bibliothèque.**
- **Le cœur redevient `Internal.McuCore`** : plus de `useRadio` au cœur, plus de `McuCoreRadio`, plus de `PyRuntime_syncBoard`.
- **Aucun paramètre radio nouveau sur la carte** : le canal, le groupe, l'adresse, le débit se règlent par `radio.config()` dans le programme utilisateur, comme sur la vraie carte. La carte reste une boîte noire radio, fidèle au matériel.

Valeurs des paramètres `final` du modem interne (à ajuster aux mesures de vérification) :

| Paramètre | Valeur | Justification |
|---|---|---|
| `baudrate` | 1 000 000 | liaison série interne, hors vue utilisateur |
| `airBaudrate` | 1 000 000 | `RATE_1MBIT` du firmware |
| `dataBits`/`parity`/`stopBits` | 8 / None / 1 | trame 8N1 du modem |
| `txBufferSize` | 256 | quelques trames d'avance |
| `rxBufferSize` | 512 | approxime la file `queue` (cf. § 5) |
| `txDelay` / `rxDelay` | 100 µs | latence proche de la durée réelle d'une trame |
| `halfDuplex` | true | un canal radio ne porte pas les deux sens à la fois |
| `fDisplay` | 100 000 | signal tracé sans intérêt ici, on abaisse la porteuse |
| `warnSampling` | false | pas d'avertissement d'échantillonnage sur la carte |
| `modulation` | FSK (défaut) | sans objet, aucun signal observable attendu |

### 4.2 Côté shim (`Resources/Scripts/_shim/microbit_shim.py`)

Le module `radio` n'appelle plus `_native.radio_*` : il parle à **son propre moteur UART (nid 1)**, par des aides internes du shim qui appellent directement `_native.uart_init(1, 34, 35, ...)`/`uart_write(1, ...)`/`uart_read(1, ...)` — **sans passer par la classe `machine.UART`** ni son verrou de ressource : la radio a son moteur, le script garde le sien, aucun conflit. Elle implémente en Python :

- **Trame** : délimiteur `0x7E`, échappement `0x7D` (style PPP : un `0x7E` de données est émis `0x7D 0x5E`, un `0x7D` devient `0x7D 0x5D`), en-tête fixe, charge utile, CRC-16/CCITT. Une trame coupée (octets perdus par un tampon plein, collision half-duplex) est simplement jetée : le délimiteur suivant resynchronise, comme un récepteur réel.
- **En-tête** (une dizaine d'octets) : canal (1 o), groupe (1 o), adresse (4 o), débit (1 o), longueur de charge utile (1 o).
- **Émission** (`radio.send`, `send_bytes`, `send_string`…) : troncation de la charge utile à `length` (comportement du firmware), construction de la trame, écriture sur l'UART interne, puis **attente de la fin d'émission** pour conserver la sémantique observée aujourd'hui (`TX n` … `TX_DONE` au moment où la trame quitte l'antenne) : le shim sonde la fin de transmission via une petite nouvelle native `uart_tx_busy` (lecture de l'état d'émission du moteur, quelques lignes dans `pyruntime_uart.c`).
- **Réception** (`radio.receive`, `receive_bytes`, `receive_bytes_into`) : machine à états de déframage alimentée par `uart.any()`/`uart.read()`, filtrage `channel`/`group`/`address`, rejet des trames d'un débit différent (fidèle à l'incompatibilité réelle), trames valides empilées dans la file `queue` ( deque borné, le firmware jette le nouveau paquet quand la file est pleine).
- **Configuration** : `radio.config()` mémorisée côté Python (plus d'appel natif) ; `power` accepté et non simulé (déjà le cas) ; `data_rate` porté dans l'en-tête. Les constantes `RATE_1MBIT`/`RATE_2MBIT` sont inchangées.
- **L'API est inchangée** : `on/off/config/send/send_bytes/send_string/receive/receive_bytes/receive_bytes_into/receive_full`, module autonome (`import radio`) et `microbit.radio`. Les scripts utilisateurs (`microbit_radio_tx.py`, `microbit_radio_rx.py`) ne changent **pas une ligne**.

### 4.3 Côté C : un deuxième moteur UART, et les démolitions

**Ajout — le moteur UART dédié à la radio.** Le runtime n'a aujourd'hui qu'un seul moteur UART par microcontrôleur (`struct UartEngine uart` du handle, moteur n° 0 du script, cf. `pyruntime_core.h`) ; la radio internalisée en exige un deuxième, en même temps que le script garde le sien — comme sur la carte réelle, où la radio et `UARTE0` sont deux périphériques distincts. Le moteur réutilise tel quel `uartcore.c` ; le travail est la généralisation mécanique du moteur unique en **deux slots** :

- `pyruntime_core.h` : le handle porte un tableau de deux slots (`configured`, `tx_pin`, `rx_pin`, `err_reported`, `struct UartEngine`) — n° 0 pour `machine.UART` du script (comportement inchangé), n° 1 pour la radio. Le tableau `uart_rx_claimed[]` reste par broche, commun.
- `pyruntime_uart.c` : `resolve_uart_index` accepte 0 et 1 ; `uart_init`/`write`/`any`/`read`/`deinit` adressent le slot choisi (le code des natives est inchangé, seul le slot est paramétré) ; ajout de `uart_tx_busy(nid)` (vrai tant que le slot émet ou a de la file) pour la fin de `radio.send()`.
- `pyruntime_module.c` (le point de synchro) : les quatre appels au moteur unique — `uart_tx_advance`, `uart_rx_step`, `uart_publish`, `earliest_uart_deadline` (trois sites : branche `script_done`, synchro courante, calcul de `nextWakeTime`) — deviennent une boucle sur les deux slots ; `nextWakeTime` est le minimum des deux. La publication du niveau TX (`uartTxPinOut`/`uartTxLevelOut`) devient un vecteur de deux couples (0 = slot absent) ; le slot 1 est configuré seulement par la radio du shim, donc absent des cartes sans radio et des scripts sans radio.
- `uart_init` du slot 1 marque la broche 34 sortie, la 35 entrée et `uart_rx_claimed[35] = 1` : ses fronts réveillent la synchro (le décodage s'y fait) mais jamais le script, comme pour le moteur n° 0. Les broches 34/35 restent inaccessibles au script : `Pin(34)` est refusé par `_mbit_check`, et `_native` n'est pas exposé aux scripts.
- Côté Modelica, l'interface de synchro suit : `uartTxPin`/`uartTxLevel` deviennent des vecteurs de taille 2 dans `Internal.PartialPyRuntimeSync`, et `Internal.PartialMcuCore` pilote la broche indiquée par chaque couple (boucle sur 2, la valeur 0 signifiant « pas de broche »). `McuCore` et `McuCoreRadio` (ce dernier supprimé par la suite) sont les seuls appelants.

**Démolitions** (inchangées par rapport à la motivation initiale) :

- Suppression de `pyruntime_radio.c`, du registre et de `g_radio_cs`, des hooks `set_network`/`next_inbox_deadline` dans `pyruntime_board.h` et `pyruntime_microbit.c`, du champ `board_network`, du wrapper C de `PyRuntime_syncBoard`, des natives `radio_*` dans `pyruntime_module.c`.
- `Resources/Include/pyimports.h` : régénérer si le C n'utilise plus un symbole (`PyErr_WarnEx` notamment) — `tools/make_pyimports.sh`.

### 4.4 Pourquoi un moteur dédié (et pas le moteur du script)

L'alternative envisagée — faire partager le moteur n° 0 entre la radio et `machine.UART`, avec exclusion mutuelle — a été écartée : sur la carte réelle, la radio et l'UART coexistent (deux périphériques distincts du nRF52833), et un script qui fait de la radio tout en dialogue par série filaire (radio + GPS, radio + console) est un usage plausible du modèle. Le coût du moteur dédié est borné et mécanique : un slot de plus dans le handle, une boucle de plus dans la synchro, un vecteur de publication — aucun nouveau concept, `uartcore` et la discipline de synchro restent exactement les mêmes.

## 5. Comportements : conservés, approximés, changés

| Comportement | Avant | Après |
|---|---|---|
| API `radio` (signature, sémantique de retour) | — | **Identique**, scripts inchangés |
| Filtrage `channel`/`group`/`address` | moteur C | shim Python, même résultat observable |
| Troncation à `length`, file `queue` | moteur C | shim ; **approximation** : quand le script ne lit pas, la saturation se manifeste au niveau du tampon RX de l'UART (octets perdus) plutôt qu'au niveau de la file (paquets perdus) — `rxBufferSize` dimensionné pour plusieurs trames, écart sans effet pour un usage normal |
| Deux réseaux isolés | deux `RadioAir` distincts (identifiant) | même fil mais `channel`/`group`/`address` différents : filtrage des trames. **Plus fidèle** : deux cartes neuves (config par défaut) sur le même fil s'entendent, comme deux vraies micro:bits |
| Collision, semi-duplex | gérés par le moteur paquets | gérés par le modem générique (déjà éprouvés, `verify_54`) |
| `radio.on()` sans antenne branchée | erreur explicite | **changement** : silence (émission dans le vide, réception vide). Un connecteur acausal ne peut pas signaler « non branché » ; consigné dans `limites.md` |
| `useRadio = false` | erreur à `radio.on()` | **changement** : idem, silence |
| `radio` et `machine.UART` simultanés | possibles (moteurs distincts) | **inchangé** : deux moteurs distincts (n° 0 script, n° 1 radio), comme sur la carte réelle |
| Temporisation d'une trame | durée exacte calculée par le moteur | chaîne UART + modem : sérialisation à 1 Mbit/s + `txDelay`/`rxDelay` — calibrée pour rester proche ; vérifiée par `verify_78` |
| Coût d'événements | par paquet | par **bit** (≈ 20 événements par octet acheminé) : sans effet sur les usages des exemples ; à mentionner dans `limites.md` pour les flux continus denses |

## 6. Fichiers touchés

| Fichier | Action |
|---|---|
| `MicroPythonMCU/Internal/OnBoardRadioModem.mo` | **création** (modem interne de la carte) |
| `tools/make_microbit.py` | broches 34/35, instance du modem, câblage, port `Antenna` en `Interfaces.Antenna`, cœur `McuCore` |
| `MicroPythonMCU/MicroBit_v2.mo` | **régénéré** (ne jamais éditer à la main) |
| `Resources/Scripts/_shim/microbit_shim.py` | module `radio` réécrit sur l'UART interne (nid 1) + protocole |
| `Resources/Include/pyruntime/pyruntime_radio.c` | **suppression** |
| `Resources/Include/pyruntime/pyruntime_core.h` | le moteur UART unique devient un tableau de deux slots |
| `Resources/Include/pyruntime/pyruntime_uart.c` | natives paramétrées par le slot (0/1), ajout `uart_tx_busy` |
| `Resources/Include/pyruntime/pyruntime_module.c` | boucle sur les deux slots dans la synchro, `nextWakeTime` au minimum, publication TX en vecteur ; retrait des natives et hooks radio |
| `Resources/Include/pyruntime/pyruntime_microbit.c`, `pyruntime_board.h` | retrait des hooks radio (`set_network`, `next_inbox_deadline`) |
| `Resources/Include/PyRuntimeImpl.c` | retrait de l'inclusion de `pyruntime_radio.c` |
| `Resources/Include/pyimports.h` | régénération éventuelle |
| `MicroPythonMCU/Internal/PartialPyRuntimeSync.mo`, `PartialMcuCore.mo` | interface de synchro : `uartTxPin`/`uartTxLevel` en vecteurs de 2, pilotage des deux couples |
| `MicroPythonMCU/Internal/McuCoreRadio.mo`, `PyRuntime_syncBoard.mo`, `StringHash.mo` | **suppression** |
| `MicroPythonMCU/Interfaces/RadioAirInput.mo`, `RadioAirOutput.mo` | **suppression** |
| `MicroPythonMCU/Peripherals/Radio/RadioAir.mo` (+ `package.order`) | **suppression** |
| `MicroPythonMCU/Internal/package.order`, `Interfaces/package.order` | mise à jour |
| `MicroPythonMCU/Examples/MicroBit/RadioChat.mo` | les deux ports `Antenna` reliés par **un seul fil**, plus de `RadioAir` |
| `Resources/Verification/verify_78_microbit_radio.mos` | adapté (mêmes attentes fonctionnelles, plus de `RadioAir`) ; éventuel `verify_80` : deux canaux différents ne communiquent pas |
| `docs/fr/guide/microbit.md`, `docs/en/guide/microbit.md` | section radio (câblage : un fil direct) |
| `docs/fr/guide/peripheriques/radio.md`, `docs/en/...` | `RadioAir` disparaît de la page |
| `docs/fr/guide/limites.md`, `docs/en/...` | nouvelles limites (§ 5) |
| `docs/fr/interne/radio.md`, `docs/fr/interne/microbit.md`, `docs/fr/interne/architecture.md`, `docs/fr/interne/cartes.md` | référence interne mise à jour |
| `requirements.md` | décision « Radios micro:bit » : choix retenu remplacé par celui-ci |
| `CLAUDE.md` | descriptions de la structure (radio micro:bit = modem interne + shim) |

## 7. Plan de travail

Chaque étape se termine par une vérification explicite ; la bibliothèque n'est jamais modifiée pendant qu'une suite tourne (règle de `CLAUDE.md`).

1. **C + interface de synchro** : deuxième slot UART dans le handle, boucle sur les deux slots dans le point de synchro, publication `uartTxPin`/`uartTxLevel` en vecteurs de 2 (`PartialPyRuntimeSync` + `PartialMcuCore`), `resolve_uart_index` accepte 1, ajout de `uart_tx_busy` ; `make_pyimports.sh` si nouveau symbole. **Aucun changement de comportement visible** : le slot 1 n'est configuré par personne à ce stade. Vérifications : `verify_01` (UART du script) et `verify_51` (les modems) toujours PASS ; diff de flattening de `MCU` vide (les vecteurs de publication sont consommés pareil quand le slot 1 est absent).
2. **Shim** : réécrire le module `radio` sur l'UART interne (nid 1) + protocole (§ 4.2). Vérification : à ce stade les scripts radio ne peuvent pas encore passer (la carte n'a pas le modem) — validation du déframage par un petit test hors carte si utile (scratchpad, pas dans le dépôt).
3. **Modelica + générateur** : `Internal.OnBoardRadioModem`, broches 34/35, port `Antenna` en `Interfaces.Antenna`, cœur rebasé sur `McuCore`, régénération de `MicroBit_v2.mo`, `RadioChat` recâblé. Vérifications : `checkModel`/`instantiateModel` sans erreur ; diff de flattening de `MicroBit_v2` (structures attendues : broches en plus, modem, plus de `radioNetworkC`) ; `verify_72` à `verify_79` adaptés et PASS, en particulier `verify_78` (les 5 PING) et `verify_79` (carte jamais alimentée — vérifier qu'il ne dépendait pas du registre radio supprimé). **Nouveau cas à couvrir** : un script qui utilise `machine.UART` sur l'edge **et** la radio en même temps (les deux moteurs coexistent) — à ajouter à `verify_78` ou en `verify_80`.
4. **Démolition** (§ 2) : supprimer moteur, hooks, connecteurs, `RadioAir`, `StringHash`, natives ; régénérer `pyimports.h` si besoin. Vérification : la suite complète `run_tests.sh` PASS (annoncer sur quoi elle a tourné : dépôt ou copie `--copy`).
5. **Documentation et métadonnées** : tableau du § 6. Vérification : `tools/make_docs.sh` en `--strict` (les deux langues), navigation à jour.

**Critères d'acceptation** :

- les scripts `microbit_radio_tx.py`/`microbit_radio_rx.py` sont inchangés et `verify_78` passe ;
- plus aucune référence à `pyruntime_radio`, `RadioAir`, `RadioAirInput`/`Output`, `McuCoreRadio`, `syncBoard`, `StringHash` dans le dépôt (`grep` vide hors `requirements-archive.md` et historique) ;
- la radio de la micro:bit et les `RadioModem` partagent le même connecteur `Interfaces.Antenna` et le même moteur C ;
- suite complète PASS, documentation FR/EN à jour et construite en `--strict`.

## 8. Alternatives écartées

- **Garder le moteur de paquets C et unifier seulement les connecteurs** : ne réduit pas la mécanique (le doublon de transport et la plomberie de synchro restent).
- **Étendre le modem générique avec le protocole paquets en C** : ferait sortir le modem de son rôle de transport transparent et dupliquerait la sémantique du firmware hors du shim, là où elle n'est ni lisible ni modifiable par l'utilisateur.
- **Liaison logique interne sans broches** (shim → modem sans passer par l'électrique) : nécessiterait un nouveau chemin de données entre deux `ExternalObject`, exactement la mécanique que l'on veut supprimer.

## 9. Points ouverts (à trancher avant l'étape 3)

1. **Exclusivité radio/UART** (option A retenue, cf. § 4.4) — repli : deuxième moteur UART (option B).
2. **`radio.on()` sans antenne : silence au lieu d'erreur** — assumé (indétectable sur connecteur acausal), à confirmer.
3. **CRC-16/CCITT** (2 octets) vs CRC-8 : le CRC-16 coûte un octet de plus par trame, détecte mieux ; proposer CRC-16 par défaut.
4. **Nom de la classe interne** : `Internal.OnBoardRadioModem` (proposition) — ou `Internal.BoardRadioModem`.
