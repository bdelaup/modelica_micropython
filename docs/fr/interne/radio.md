# La liaison radio (`Peripherals.Radio`)

!!! info "Référence interne"
    Cette page décrit le fonctionnement interne. Pour utiliser les modules (câblage, paramètres, exemples) : [Liaison radio](../guide/peripheriques/radio.md). Pour le *pourquoi* des choix, voir la décision « Liaison radio modulée » de [`requirements.md`](https://gitlab.com/bdelaup/modelica_micropython3/-/blob/main/requirements.md).

Un module radio est un **appareil série** côté microcontrôleur (mêmes broches, même pont électrique) et un **nœud d'un fil d'antenne** côté radio. Entre les deux, un moteur C sans Python ni thread fait passer les octets par deux files horodatées. Le signal modulé est calculé en Modelica, pour être tracé seulement.

## 1. Les classes

| Classe | Rôle |
|---|---|
| `Internal.PartialUartPins` | Pont électrique `TX`/`RX`/`GND`, **partagé** avec `Internal.PartialUartDevice` : source `VOH`/`VOL` derrière `ROut` sur `TX` ; sur `RX`, résistance de plot `RIn` (10 Ω), puis tirage, capacité `CIn` et capteur sur le nœud interne. La classe dérivée affecte `txLevel` dans son `when` et réagit à `change(rxBoolIn)` |
| `Internal.PartialRadioModem` | Toute la mécanique : paramètres, connecteur d'antenne, calcul du signal tracé, appel du moteur. Non instanciable |
| `Peripherals.Radio.RadioModem` | `extends PartialRadioModem` sans rien fixer ; icône « RADIO » et `%airBaudrate` |
| `Peripherals.Radio.Apc220` | `extends PartialRadioModem(final ...)` : les réglages de la fiche (`frequency` en kHz, `rfDataRate`, `power`, `serialRate`, `serialParity`) alimentent les paramètres génériques, tous les autres sont `final` donc absents du dialogue. Listes déroulantes par `choices`, valeurs refusées par `assert` en `initial equation`. L'icône affiche `%rfDataRate` : sur une instance, `%airBaudrate` afficherait l'expression du modificateur, pas sa valeur |
| `Interfaces.Antenna` | Connecteur acausal à six paires potentiel/flux (§ 3) |
| `Interfaces.Modulation` | `OOK`, `ASK`, `FSK`, `BPSK` |
| `Internal.RadioModem`, `Internal.RadioModem_sync` | External Object et point de synchro ; chapeau `RadioModemImpl.c` |

## 2. Le moteur C

`Resources/Include/RadioModemImpl.c` inclut `uartcore.c` (le moteur bit/octet du microcontrôleur et des appareils série, garde d'inclusion) puis `radiomodem/radiomodem_core.h` et `radiomodem/radiomodem_engine.c`. Chaque modem porte :

- **deux `UartEngine`** : `ser` côté microcontrôleur, au format choisi (`baudrate`, `dataBits`, `parity`, `stopBits`) ; `air` côté radio, en 8N1 au débit radio ;
- **deux files horodatées** `up` (UART vers air) et `down` (air vers UART), de capacité paramétrée (4096 octets au plus). Chaque octet porte l'instant à partir duquel il peut repartir : fin de sa réception + `txDelay` (ou `rxDelay`). File pleine = octet perdu ;
- un **identifiant** 1, 2, 3… attribué dans l'ordre de construction (compteur statique du chapeau, une simulation = un process), 48 modules au plus.

Les files internes des `UartEngine` ne servent jamais de tampon : on n'y pousse un octet que quand l'émetteur concerné est libre, et on le lance aussitôt (`uartcore_tx_kick`). La taille de tampon vue par l'utilisateur est donc exactement celle des files `up`/`down`.

Ordre des opérations dans `RadioModem_sync`, idempotent au même instant comme tous nos points de synchro (chaque étape est pilotée par une échéance ou consomme ce qu'elle traite) :

1. `ser` : clore la trame rendue au microcontrôleur arrivée à échéance ;
2. `ser` : décoder `RX` ; octets reçus → `up` (ou perdus, avertissement) ; un octet en erreur de parité ou de trame est gardé, comme par les appareils série ;
3. `air` : clore la trame émise arrivée à échéance ;
4. `air` : si l'émetteur est libre et la tête de `up` prête, lancer sa trame ; en semi-duplex, cela coupe la trame en cours de réception (comptée perdue) ;
5. `air` : décoder le niveau entendu. Il est forcé au repos pendant notre émission en semi-duplex et pendant un brouillage. Le **début** d'un brouillage abandonne la trame en cours et compte une trame perdue, même si elle n'avait pas commencé : deux émetteurs partis au même instant ne laissent rien voir au décodeur. Une trame en erreur (stop bas) est jetée ; sinon → `down` (ou perdue) ;
6. `ser` : si l'émetteur est libre et la tête de `down` prête, lancer l'octet vers le microcontrôleur ;
7. publier ; `nextWakeTime` = min des échéances des deux `UartEngine` et des têtes de file **dont l'émetteur est libre** (sinon c'est la fin de la trame en cours qui réveille).

Le destructeur écrit un bilan d'une ligne (`ModelicaFormatMessage`), que la suite de vérification relit. Les avertissements sont plafonnés à 10 par module.

Côté Modelica, le `when` affecte des variables **protégées** (`carrierOnC`, `txFillC`, `nSentC`…, et `jam` pour la collision), qui portent les `start`/`fixed` nécessaires à `pre()`. Les sorties publiques (`carrierOn`, `txFill`, `nSent`…, `collision`) en sont des copies sans valeur de départ : OMEdit range toute variable publique déclarée avec un `start` dans un groupe « Initialization » du dialogue, alors que ces valeurs sont réécrites par le moteur dès t = 0. Publiques, elles restent dans le fichier de résultats et animent l'icône.

## 3. Le fil d'antenne : une moyenne sur les émetteurs

L'exigence est **un seul fil apparent** entre deux modules. Un connecteur causal (une sortie et une entrée) en demanderait deux, et une entrée non branchée laisserait le modèle sous-déterminé. `Interfaces.Antenna` est donc acausal : six paires potentiel/flux, `s`, `bit`, `f`, `modulation`, `id`, `idSq`. Chaque module écrit, pour chaque paire :

```modelica
g = if txOn then 1 else EPS;          // EPS = 1e-9
antenna.iS = g*(antenna.s - sTx);     // idem pour bit, f, modulation, id, id^2
```

La loi des nœuds (somme des flux nulle) donne `x = Σ g·x_k / Σ g` : la **moyenne des valeurs des modules qui émettent** (les autres pèsent 1e-9). Avec un émetteur, c'est sa valeur, à 1e-9 près ; avec aucun, 0 ; un module seul, antenne débranchée, impose sa propre valeur (flux nul) et émet dans le vide.

Ce que le récepteur en déduit :

| Situation | Test | Conséquence |
|---|---|---|
| Personne d'autre n'émet | `id < 0,5` (ou, pendant notre émission, `idSq - id² ≈ 0`) | rien à entendre, ligne au repos |
| Exactement un autre émetteur | variance des identifiants nulle (ou, pendant notre émission, `(myId² + oId²)/2 = idSq` avec `oId = 2·id - myId`) | ses grandeurs : directement la moyenne, ou `2·moyenne - soi` pendant notre émission (duplex intégral) |
| Deux autres ou plus | variance non nulle | `collision` : trame perdue |
| Un autre, mais pas sur notre canal ou pas dans notre modulation | `|f - fCarrier| > channelWidth/2` ou modulation différente | ligne au repos (`heard` faux) |

Le test de variance est **relatif** (1e-6) : il ne dépend pas de l'échelle des identifiants. Avec des identifiants 1 à 48, deux émetteurs simultanés donnent une variance relative d'au moins 1e-4. Une première version utilisait des puissances de 2 (une moyenne de puissances distinctes n'en est jamais une), mais l'erreur due aux poids de 1e-9 grandit avec l'identifiant et finissait par dépasser l'écart à détecter.

Les relations sont sous `noEvent` : ces grandeurs ne sautent qu'aux événements (elles dérivent de variables discrètes), donc aucune fonction de franchissement n'est utile entre deux événements. Les booléens qui en sortent (`airLevelIn`, `collision`) sont réévalués à chaque itération d'événement, et leur `change()` déclenche le `when` du récepteur au même instant.

## 4. Ruptures de boucle

Ce que le `when` publie (porteuse, bit, identifiant) n'entre dans le fil qu'à travers `pre()` : `txOn = pre(carrierOn)`, `txBit = pre(airTxLevel)`, `myId = pre(airId)`. Sans cela, l'entrée du `when` d'un module (le niveau entendu) dépend de ses propres sorties et de celles de l'autre module au même instant : boucle algébrique entre équations discrètes. omc l'a refusée (« non-linear equations within when-equations »). C'est la même coupure que celle des sorties du `MCU` entre deux cartes câblées. Le décalage d'une itération d'événement se fait au même instant simulé, comme pour une broche.

`RIn`, ajoutée à `PartialUartPins` à cette occasion : `Examples.Radio.Modulations` branche quatre entrées `RX` sur la même broche `TX`. Leurs `CIn` se retrouvaient en parallèle, fusionnées par omc en une variable alias à quatre valeurs initiales fixées (avertissement « alias variables with redundant start »). Même remède que pour les périphériques I2C ; `RIn·CIn` = 10 ns, invisible.

## 5. Le signal tracé

`sTx` est **algébrique** et ne coûte rien au solveur :

- OOK : `sin(2π·fDisplay·t)` pour un 1, 0 pour un 0 ;
- ASK : même porteuse, amplitude 1 ou `askLowAmplitude` ;
- BPSK : même porteuse, signe selon le bit ;
- FSK : phase continue sans état continu. À chaque changement de bit (`when change(txBit) or change(txOn)`), `phi0` cumule la phase parcourue depuis le changement précédent ; entre deux, `sin(phi0 + 2π·f(bit)·(t - tRef))`.

La contrepartie : `sTx` n'existe dans le fichier de résultats qu'aux points de sortie. D'où `fDisplay`, porteuse mise à l'échelle (4 × débit radio), distincte de `fCarrier`, qui ne sert qu'à l'accord, et l'intervalle de 10 µs de `Examples.Radio.Modulations`. `sRx` rend le signal de l'autre émetteur, tel que vu depuis ce module.

## 6. Coût

`Examples.Radio.Link` (deux MCU, deux modules, 0,25 s, 42 octets dans chaque sens de l'air) : 2,8 s de simulation sur une copie hors OneDrive (OpenModelica 1.27.1). `Radio.Modulations` (huit modules, 40 ms, sortie toutes les 10 µs) : 1 s. Les événements ajoutés par un module sont ceux de ses deux liaisons série (un par changement de niveau, un réveil par octet reçu) ; le fil d'antenne n'en crée aucun en propre.

## 7. Pour aller plus loin

Démodulation filtrée (le récepteur lirait `antenna.s` au lieu de `antenna.bit`, la chaîne de filtres alimentant le même décodeur), enveloppe complexe, canal (distance, atténuation, bruit, taux d'erreur), écoute avant d'émettre, paquets : TODO de `requirements.md`, entrées « Liaison radio ».

## 8. Vérification

`verify_51` (liaison PING/PONG par deux `Apc220`, instant de la première porteuse, bilans sans perte), `verify_52` (tampon plein : octets reçus et perdus calculés à la main), `verify_53` (forme des quatre modulations sur deux bits, par une seule lecture du fichier de résultats), `verify_54` (désaccord de fréquence, de débit radio, diffusion vers deux récepteurs, collision ; modèles déclarés dans le script par `loadString`).
