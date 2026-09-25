# Les périphériques série externes (`Internal.PartialUartDevice` et ses dérivés)

Cette page explique le **fonctionnement interne** des appareils qui se branchent à l'autre bout de la liaison série. Pour la liaison elle-même (trame 8N1, génération de la forme d'onde, décodage), voir [peripherique-uart.md](peripherique-uart.md), dont celle-ci est la suite directe. Pour le *pourquoi* des choix, voir la décision « Périphériques UART externes connectables » de [`requirements.md`](../requirements.md).

## 1. Ce que ça remplace

`Examples.Uart.Loopback` renvoyait la trame du `MCU` vers lui-même à travers un réseau `loopR`/`loopC` qui n'existait que pour contourner une fusion d'alias entre deux broches du même composant. Il n'y avait donc **personne au bout du fil**.

Un appareil série externe est un véritable interlocuteur : deux composants distincts, un simple fil dans chaque sens, une masse commune.

```
   MCU.GP5  ──────────────►  dev.RX          (ce que le microcontrôleur émet)
   MCU.GP4  ◄──────────────  dev.TX          (ce que l'appareil répond)
   MCU.GND  ─────────────────  dev.GND       (indispensable, comme sur un montage réel)
```

> Les exemples utilisent `GP4`/`GP5` plutôt que `GP0`/`GP1` : ces broches sont sur le bord **droit** de l'icône du `MCU`, du côté où l'appareil est posé, ce qui donne des liaisons courtes qui ne contournent aucun composant. N'importe quelle paire de `GP0`-`GP7` conviendrait.

## 2. Le moteur est partagé, pas dupliqué

Le travail bit/octet vit dans **`Resources/Include/uartcore.h` + `uartcore.c`**, à la racine d'`Include/` : files circulaires, sérialisation 8N1, décodage par échantillonnage au milieu de chaque bit, calcul d'échéance. Ce code ne connaît ni Python, ni les threads, ni les broches — il n'a donc rien coûté à extraire de `pyruntime_uart.c`, où il vivait déjà sous cette forme.

| | Microcontrôleur | Périphérique |
|---|---|---|
| Chapeau | `PyRuntimeImpl.c` | `UartDeviceImpl.c` |
| Dépend de Python | oui (`Library = "python312"`, thread worker) | **non** |
| Moteur bit/octet | `uartcore.c` | `uartcore.c` — le même |
| Ce qui lui est propre | quelle broche fait TX/RX, les primitives natives du shim | table de commandes, échéance périodique, ports réels |

La classe de base Modelica est `Internal.PartialUartDevice`, déclarée `partial` : elle n'est pas instanciable, et `Peripherals` ne contient que des composants posables dans un schéma.

> **Garde d'inclusion obligatoire.** `omc` dédoublonne les annotations `Include` par leur texte, mais rien ne garantit que les deux chapeaux atterrissent dans des unités de compilation distinctes — or ils incluent tous deux `uartcore.c` textuellement. Sans `#ifndef UARTCORE_C_INCLUDED`, chaque fonction `static` y serait définie deux fois.

## 3. Un seul mécanisme d'émission, trois sources d'échéances

Les deux modes n'ont pas deux implémentations. Ils alimentent **la même file d'émission** ; seule diffère l'origine des octets.

| Source d'échéance | Rôle |
|---|---|
| `io.tx_end_time` | fin de trame → charger l'octet suivant |
| `io.rx_next_sample` | échantillonner le milieu du bit suivant |
| `pending_time` | réponse armée, après `responseDelay` |
| `next_emit_time` | tick d'émission périodique |

`uartdev_deadline()` en prend le `min`, Modelica le reçoit en `nextWakeTime` et rappelle la fonction à cet instant — exactement le mécanisme de `machine.Timer`.

## 4. Anatomie d'un appel à `UartDevice_sync`

L'ordre compte, et il ne change pas :

```
1. recopier valueIn[] -> value_in[]
2. tx_advance(now)        -- trame close ? charger l'octet suivant
3. rx_step(now, level)    -- front -> armer ; échéance -> échantillonner
4. drainer la FIFO RX vers l'accumulateur de ligne
      octet != terminateur -> empiler
      octet == terminateur -> LIVRER la ligne -> uartdev_on_line()
5. échéances d'émission (réponse armée, tick périodique -> uartdev_on_tick())
6. publier txActive / txStart / txBits[] / valueOut[] / rxBusy / eventSeq / lastRx / lastTx
7. nextWakeTime = min des échéances
```

**Toutes ces étapes sont rejouables.** Les étapes 2, 3 et 5 sont de la forme `while (now >= échéance)` ; l'étape 4 consomme les octets. C'est indispensable : Modelica rappelle une fonction externe plusieurs fois au même instant simulé (2 à 3 itérations d'événement). C'est aussi ce qui permettra à la phase 2 d'y loger une machine d'état sans qu'elle rejoue ses transitions.

Le `when` qui déclenche tout ça :

```modelica
when {initial(), time >= pre(nextWakeTime), sample(0, tickPeriod), change(rxBoolIn)} then
```

`change(rxBoolIn)` est **indispensable** : c'est ainsi que le périphérique voit le front descendant du bit de start. Contrairement au `MCU`, il n'y a pas de worker à protéger, donc pas d'équivalent de `uart_rx_claimed`.

## 5. Le format des gabarits

Une seule chaîne compacte décrit toute la table : `"CMD=>REPONSE|CMD=>REPONSE"`. `|` et `=>` sont **réservés**. Les échappements (`\r`, `\n`) sont déjà résolus par Modelica dans le littéral : le C reçoit les vrais octets.

| Marqueur | Sens | Où le placer |
|---|---|---|
| `{v1}`, `{v2:.3f}` | `valueIn[N]` → trame | dans une **réponse** ou le gabarit périodique |
| `{o1}`, `{o2}` | trame → `valueOut[N]` | dans une **commande** |

```modelica
commandTable = "AT+TEMP=>TEMP={v1:.1f}\r\n|AT+ID=>SIM-TEMP-1\r\n|SET {o1}=>OK\r\n"
```

C'est `{oN}` qui fait du composant un **actionneur** autant qu'un capteur : le script lit la température par la liaison série et renvoie une consigne par la même liaison, ce qui met toute une boucle de régulation dans le modèle sans un fil de plus.

La comparaison porte sur la **ligne complète**, délimiteur exclu — une commande fragmentée sur plusieurs trames est donc reconnue sans effort, puisque c'est l'accumulateur qui la réassemble.

## 6. Deux pièges rencontrés, et leur correction

### (a) Les deux `when` mutuellement dépendants — `omc` meurt en silence

Câbler **les deux** sens entre un `MCU` et un périphérique faisait échouer le build sans le moindre message : `getErrorString()` vide, tous les temps à zéro, aucun fichier généré — alors que `checkModel` passait. La bissection a été décisive : chaque sens **isolément** compile, seule leur combinaison échoue.

Cause : le `change(rxBoolIn)` du périphérique dépend de la tension pilotée par le MCU, et le `change(pinBoolIn[k])` du MCU dépend de celle pilotée par le périphérique. Les deux `when` forment un cycle.

Correction : une **capacité d'entrée `CIn` sur la broche RX** (1 nF par défaut). Physiquement honnête — toute broche d'entrée et tout câble en ont une — et elle donne au nœud un véritable état dynamique, ce qui coupe le cycle. Face aux 100 Ω de sortie, la constante de temps vaut 0,1 µs, soit 0,01 % d'un bit à 1200 bauds.

> **Bénéfice inattendu** : puisque chaque extrémité réceptrice porte désormais sa propre capacité, le réseau R+C artificiel de `PinEcho`/`Uart.Loopback` devient inutile dès qu'un périphérique est en jeu.

### (b) L'octet fantôme, reproduit à l'envers

Le constructeur initialisait `rx_last_level = 1`, au motif que « la ligne est au repos haut ». **Elle ne l'est pas à `t = 0`** : tant que le script n'a pas configuré son UART, la broche du MCU est une *entrée*, et le tirage `RPullUp` se retrouve en diviseur avec la fuite de l'interrupteur ouvert du pont GPIO — le nœud est à ~0,3 V, donc bas.

Vu depuis un état initial à 1, cela ressemble à un front descendant : le décodeur fabriquait un octet fantôme dès le premier point de synchro et restait désynchronisé pour toute la suite. `b'Hi\n'` revenait en `b'*K\xf8'`.

`rx_last_level` doit rester à **0**, ce qui oblige le décodeur à voir d'abord la ligne monter au repos — exactement le correctif déjà appliqué côté microcontrôleur, et pour la même raison.

## 7. Les quatre appareils dérivés

Le test de réussite de la conception : chacun ne redéfinit que des **valeurs de paramètres** et son icône.

| Modèle | Ce qu'il redéfinit | Ce qu'il démontre |
|---|---|---|
| `UartGenericDevice` | rien — tout se règle dans le dialogue | l'appareil à poser quand écrire une classe ne se justifie pas |
| `UartEchoDevice` | `echoEnabled = true` | le partenaire minimal, qui remplace le bouclage artificiel |
| `UartTemperatureSensor` | une table à trois commandes, `useValueInput` | requête/réponse **dans les deux sens** (`{v1}` et `{o1}`) |
| `UartGpsModule` | `periodicEnabled`, `nIn = 3`, gabarit NMEA | l'émission spontanée, et le polling qu'elle impose au script |
| `UartLcd20x2` | tout à `false`, plus `extends Internal.TwoLineTextIcon` | le pendant électrique de `Peripherals.Display` |

Deux exemples exploitent le port de **sortie** : `Examples.Uart.Sensor` montre la capture `{o1}` isolée, et `Examples.Uart.Regulation` referme une boucle de régulation complète — la commande capturée pilote un procédé du premier ordre dont la sortie revient sur l'entrée du même appareil, sans un fil de plus que les deux de la liaison série.

`UartLcd20x2` hérite de **deux** classes : `Internal.PartialUartDevice` pour la mécanique série, `Internal.TwoLineTextIcon` pour les 40 cellules de texte de l'icône 20×2 — les mêmes que `Display`, écrites une seule fois. Ce partage a fait passer `Display.mo` de 159 Ko à 4,3 Ko.

> **Vérifié au passage** : l'héritage d'une annotation `Icon` dont les `DynamicSelect` réfèrent à des variables de la classe de base fonctionne dans cette installation d'OMEdit (`verify_12_display.mos` passe à l'identique après la factorisation).

## 8. Décrire un appareil par un script Python

Basculer `comportement` sur `Script` remplace la table par un fichier `.py`. **Chaque périphérique fourni a son script par défaut** (dossier `Resources/Scripts/Device/`, fichier nommé d'après l'appareil), de comportement équivalent à sa table : le basculement fonctionne immédiatement, et le fichier sert de point de départ. `UartLcd20x2` fait exception (`final comportement = Table`) : un afficheur n'a pas de comportement programmable.

```python
etat = 'ARRET'          # variables de module : l'état de l'appareil,
lectures = 0            # qui persiste d'un appel à l'autre

def on_receive(ligne, t, v):        # une fois par ligne complète reçue
    global etat, lectures
    if ligne == b'START':
        etat = 'MARCHE'; return b'OK\r\n'
    if ligne == b'READ' and etat == 'MARCHE':
        lectures += 1
        return 'VAL=%.2f N=%d\r\n' % (v[0], lectures)
    return b'ERR\r\n'

def on_tick(t, v):                  # toutes les `period` secondes, si définie
    ...

def outputs():                      # relue après chaque gestionnaire -> valueOut
    return (1.0 if etat == 'MARCHE' else 0.0, lectures)
```

| Fonction | Appelée | Reçoit | Retourne |
|---|---|---|---|
| `on_receive(ligne, t, v)` | une fois par ligne complète | `ligne` : `bytes` sans le terminateur ; `t` : temps simulé ; `v` : tuple des grandeurs de `valueIn` | `bytes`, `str` ou `None` — émis après `responseDelay` |
| `on_tick(t, v)` | une fois par `period` — sa seule présence active l'émission périodique | idem | idem, émis aussitôt |
| `outputs()` | après chacune des deux autres, et une fois au chargement | — | un nombre ou une séquence → `valueOut` |

Les trois sont facultatives. Le **contenu** des trames vient du script ; la **temporisation** (`period`, `responseDelay`) reste un paramètre du composant.

**Chargement.** Une fois par **instance**, à la construction, dans un dictionnaire de globales qui lui est propre. Deux instances du même fichier ont donc deux états indépendants, et les variables du script ne peuvent ni écraser ni être écrasées par celles d'un autre appareil ou du `MCU`. `__name__` vaut le nom du fichier : un bloc `if __name__ == '__main__'` n'est pas exécuté.

**Une fois par événement.** Chaque ligne n'est livrée qu'une fois à `on_receive`, chaque période qu'une fois à `on_tick`, même si la simulation réévalue plusieurs fois le même instant. Une machine d'état ne rejoue donc jamais ses transitions — c'est ce que vérifie `verify_19_uart_state_machine.mos`.

**Ce que le script ne peut pas faire.** Ses fonctions s'exécutent sur le thread de la simulation : elles doivent aller au bout sans attendre. Pas de `sleep()` — pour différer une réponse, c'est `responseDelay` qui s'en charge —, et pas d'accès à `machine` ni `time`, qui appartiennent au microcontrôleur : un tel appel lève une exception explicite plutôt que de figer la simulation. Le fichier doit être autonome (son dossier n'est pas ajouté à `sys.path`).

**Journal et erreurs.** `print()` est préfixé du nom du composant. Une exception dans le script arrête la simulation en affichant sa trace et le fichier en cause.

**Pourquoi c'est bon marché.** Aucun second interpréteur ni second thread : les gestionnaires vont au bout de leurs appels, ils n'ont donc pas besoin d'une pile qui leur soit propre. La seule vraie difficulté était que le worker du `MCU` gardait le GIL pendant qu'il attendait son tour — il le rend désormais pendant l'attente (cf. [cycle-de-vie.md](cycle-de-vie.md)). Et le démarrage de CPython est partagé (`pyhost.c`) : un périphérique scripté peut être construit avant le `MCU`, ou exister sans lui.

## 9. Notes pour plus tard

- Le débit du périphérique est **le sien**. Un désaccord avec le microcontrôleur produit des octets faux — c'est voulu : c'est le symptôme exact d'un désaccord de configuration sur un montage réel, et `Examples.Uart.Lcd` permet de le reproduire sans matériel.
- **Plusieurs fichiers par appareil** : le dossier du script n'est pas ajouté à `sys.path`, `sys.path` étant global à l'interpréteur. Un appareil complexe reste pour l'instant un fichier autonome.
