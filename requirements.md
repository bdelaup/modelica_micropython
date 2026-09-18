# Requirements

Document vivant décrivant le besoin, les choix d'architecture, le périmètre de la v0 et le reste à faire. À tenir à jour au fil des décisions.

## Besoin

**Objectif** : étendre la simulation de systèmes physiques dans OpenModelica en y intégrant la simulation de l'exécution de programmes informatiques (logiciel embarqué). Il s'agit de fournir, sous forme de bibliothèque OpenModelica, un modèle de microcontrôleur programmable, dont le comportement est piloté par un script Python écrit par l'utilisateur et **compatible avec MicroPython**.

**Pourquoi** : cela permet de modéliser des systèmes complexes couplant matériel et logiciel — de programmer une « intelligence » (logique de pilotage) qui contrôle un système physique simulé, et de la tester numériquement avant tout passage sur un prototype réel.

**Public visé / cas d'usage** :
- Pédagogique (Lycée Jules Haag) : les élèves testent leur code de pilotage sur le système numérique avant de le déployer sur le prototype physique.
- Industriel : même logique de jumeau numérique pour valider un logiciel embarqué avant déploiement sur matériel réel.

**Contrainte clé** : le script Python écrit par l'utilisateur pour piloter le microcontrôleur simulé doit rester compatible avec MicroPython, afin d'être directement portable vers un microcontrôleur physique.

**Carte cible de référence** : Raspberry Pi Pico (RP2040). L'API `machine`/`time` exposée par le modèle simulé doit coller à ce portage MicroPython précis plutôt qu'à une API générique, pour rester fidèle à une carte réelle et garantir la portabilité du code.

**Contrainte de synchronisation temporelle** : l'exécution du script Python doit rester synchrone avec la durée des steps de simulation Modelica (le temps simulé et l'avancement du script ne doivent pas diverger). Les attentes du script (`sleep`) doivent être « condensées » : si le script attend 1 heure, la simulation ne doit pas avoir besoin d'exécuter réellement 1 heure de temps de calcul pour l'y amener — le temps d'attente doit pouvoir être avancé virtuellement plutôt qu'exécuté pas à pas.

## Choix architecturaux

*Pour chaque décision d'architecture, dupliquer le modèle suivant :*

*Principe : ces décisions sont provisoires, pas gravées dans le marbre. Si le maintien d'un choix s'avère induire une complexité disproportionnée par rapport au bénéfice attendu (à l'implémentation ou à l'usage), il faut le remettre en question plutôt que s'y tenir par principe. Documenter alors le changement dans la décision concernée (nouveau choix retenu, raison du changement, éventuellement déplacer l'ancien choix en alternative) plutôt que d'effacer l'historique — pour garder la trace de ce qui a été essayé et pourquoi ça n'a pas tenu.*

### Décision : [nom de la décision]

- **Choix retenu** :
- **Alternatives envisagées** :
  - Alternative A — avantages / inconvénients :
  - Alternative B — avantages / inconvénients :
- **Notes pour plus tard** :

### Décision : Mécanisme d'exécution du script Python pendant la simulation

- **Choix retenu** : CPython embarqué (via l'API C de Python) dans un thread du process de simulation, appelé depuis Modelica via l'interface *External Object* d'OpenModelica. Un shim Python (`machine`, `time`, ...) imite l'API MicroPython du Raspberry Pi Pico (RP2040). `time.sleep(x)` est intercepté : le thread se bloque sur une condition variable en publiant « réveil demandé à t+x » ; à chaque step de communication, le solveur Modelica lit cette demande et, s'il n'y a rien d'autre à observer entre-temps, avance directement son temps simulé jusqu'à ce point (traitement en événement discret) avant de réveiller le thread. Les GPIO forment un état partagé lu/écrit des deux côtés à chaque step.
- **Alternatives envisagées** :
  - Vrai MicroPython embarqué (port *unix*), avec un module natif `machine` réécrit pour dialoguer avec le modèle Modelica — avantage : fidélité maximale, c'est littéralement MicroPython ; inconvénient : intégration plus lourde (compiler/embarquer le port, écrire un module C dédié). Gardée comme piste de repli.
  - Process Python séparé communiquant via FMI/IPC (socket, pipe, FMU) — avantage : découplage propre, portable vers d'autres outils compatibles FMI ; inconvénient : latence d'IPC et contrôle plus grossier du pas de temps, ce qui complique la compression fine des `sleep`.
- **Notes pour plus tard** : le shim `machine`/`time` devra être confronté à la documentation officielle MicroPython RP2040 pour limiter les écarts de comportement avec le vrai MicroPython. Si des tests (notamment avec les élèves) révèlent des incompatibilités bloquantes, envisager de migrer vers l'alternative « vrai MicroPython embarqué ».

### Décision : Conception du shim `machine`/`time` (v0)

- **Choix retenu** :
  - Module `time` : `sleep(s)`, `sleep_ms(ms)`, `sleep_us(us)`, `ticks_ms()`, `ticks_us()`, `ticks_diff(a, b)` — toutes basées sur l'horloge simulée partagée (celle avancée par le mécanisme de compression des `sleep`), jamais sur l'horloge système, pour rester cohérentes avec la synchronisation temps script / temps de simulation.
  - Module `machine` : classe `Pin(id, mode=Pin.OUT, pull=None)`, avec les constantes `Pin.IN`, `Pin.OUT`, `Pin.PULL_UP`, `Pin.PULL_DOWN` et les méthodes `.value([x])`, `.on()`, `.off()` — repris tel quel de l'API `machine.Pin` de MicroPython sur RP2040. Aucune autre classe `machine.*` en v0 (cohérent avec la restriction GPIO simples ci-dessous).
  - Numérotation des GPIO alignée sur celle du Raspberry Pi Pico (`GP0` à `GP28`), pour que le code reste portable tel quel.
  - État partagé : chaque `Pin` lit/écrit une structure protégée par la même primitive de synchronisation que les `sleep` ; côté Modelica, cet état est exposé comme des connecteurs booléens indexés par numéro de GPIO, lus/écrits à chaque step de communication.
- **Alternatives envisagées** :
  - Exposer dès la v0 un `Pin` « riche » avec toutes les méthodes RP2040 (dont `irq()`) — écarté : hors périmètre de la v0 (restriction GPIO simples).
  - Définir des noms de fonctions maison plutôt que de coller à l'API MicroPython existante — écarté : casserait la contrainte de portabilité du code vers un microcontrôleur réel.
- **Notes pour plus tard** : étendre le shim avec ADC/PWM/Timer/I2C/SPI/UART au fur et à mesure (cf. TODO), en gardant le même principe (état partagé, synchronisé au step de communication, API calquée sur MicroPython RP2040).

### Décision : Interface GPIO côté Modelica (connecteurs et fréquence de synchro)

- **Choix retenu** :
  - Chaque broche GPIO du modèle expose un connecteur de type `Modelica.Electrical.Digital` (logique multi-niveaux 0/1/haute impédance `Z`/...), plutôt qu'un connecteur maison. Une broche en mode `Pin.OUT` pilote le connecteur ; en mode `Pin.IN`, elle passe en haute impédance et lit la valeur résolue par le circuit externe — cohérent avec le comportement électrique réel et directement connectable aux autres composants de la bibliothèque standard.
  - Trois sources déclenchent un point de synchro (appel à `PyRuntime_sync`) : (1) le réveil d'un `sleep`, (2) un tick périodique minimal (période configurable, pour garder les écritures de sortie fraîches même si le script ne dort jamais), et (3) un `when` déclenché sur **toute transition d'une broche d'entrée** — ainsi aucun changement d'état en entrée ne peut se produire sans que le script soit sollicité, sans pour autant accrocher la synchro aux évaluations internes du solveur (essais d'intégration, itérations de Newton, etc., qui n'ont pas de sens physique garanti et casseraient la compression des `sleep`). C'est Modelica lui-même, via son mécanisme d'événements (`when`/franchissement de seuil), qui détecte ces transitions de façon fiable et peu coûteuse.
- **Alternatives envisagées** :
  - Paire de connecteurs causaux `BooleanInput`/`BooleanOutput` par broche, à choisir manuellement selon le câblage — écartée : ne gère ni le changement dynamique de direction (IN/OUT décidé par le script à l'exécution), ni la résolution de bus si plusieurs composants pilotent le même fil.
  - Synchro uniquement aux points sleep/réveil, sans tick périodique — écartée : un script en boucle serrée sans `sleep` rendrait ses écritures GPIO invisibles côté Modelica jusqu'à son prochain sleep, ce qui casserait la fidélité de la simulation dans ce cas.
  - Entrée lue comme un simple instantané au moment du sync, sans `when` de transition dédié — écartée : une transition en entrée strictement comprise entre deux syncs (sleep/tick) serait alors invisible pour le script, ce qui est incompatible avec la propriété recherchée (« aucun changement d'état sans que le script soit sollicité ») et gênerait la future implémentation des interruptions (cf. TODO).
  - Historique des fronts accumulés côté Modelica (file consultée par le script à son prochain sync) — écartée pour l'instant : ajoute un état et une API supplémentaires au shim pour un besoin déjà couvert plus simplement par la synchro événementielle par transition.
- **Notes pour plus tard** : la période du tick de synchro minimal est un paramètre à calibrer (compromis fidélité / coût de simulation). Si les entrées changent très fréquemment, la synchro par transition peut multiplier les appels à `PyRuntime_sync` — surveiller le coût de simulation dans ce cas. Vérifier l'API exacte de `Modelica.Electrical.Digital` (classes de connecteurs, niveaux logiques disponibles) au moment de l'implémentation, via les outils MCP-OpenModelica. Base naturelle pour les futures interruptions sur changement de pin (cf. TODO).

**Précision (conséquence directe des choix ci-dessus)** : entre deux points de synchro, une broche pilotée par le script (`Pin.OUT`) garde sa dernière valeur (échantillonné-bloqué, pas de variation continue côté sortie). Une broche en lecture (`Pin.IN`) déclenche elle-même un sync dès qu'elle change (cf. ci-dessus) ; en dehors de ces transitions, ce que voit le script reste la dernière valeur connue — le solveur peut évaluer le modèle plusieurs fois entre deux événements (pas variable), ça n'affecte pas ce que voit le script.

### Décision : Source du script Python fourni au modèle

- **Choix retenu** : paramètre `String` = chemin vers un fichier `.py` externe. La bibliothèque fournit un fichier de démonstration par défaut dans son arborescence (ex. `Resources/Scripts/demo.py`), utilisé comme valeur par défaut du paramètre, pour qu'un modèle fraîchement déposé fonctionne sans configuration.
- **Alternatives envisagées** :
  - Script inline en paramètre `String` du modèle — modèle autonome/portable en un seul fichier, mais édition de code Python dans une chaîne Modelica peu confortable (pas de coloration syntaxique, échappement des guillemets). Non retenu comme choix par défaut, pourrait devenir une option plus tard.
  - Fichier externe avec repli sur script inline si aucun chemin n'est fourni — écarté pour limiter la surface de la v0.
- **Notes pour plus tard** : envisager le support du script inline en option, une fois le mécanisme fichier externe validé.

### Décision : Connecteurs GPIO exposés par le modèle

- **Choix retenu** : tableau fixe de connecteurs GPIO (pas de connecteurs conditionnels), restreint à **8 broches pour la v0** (au lieu des 29 broches réelles du Pico).
- **Alternatives envisagées** :
  - Connecteurs activables un par un (pattern `use_pX`, comme dans la bibliothèque standard Modelica pour des entrées/sorties optionnelles) — icône plus lisible en TP, mais implémentation plus complexe (connecteurs conditionnels). Écarté pour la v0, à reconsidérer pour la version exhaustive.
- **Notes pour plus tard** : passer à 29 broches (numérotation complète `GP0`–`GP28`) et/ou au pattern `use_pX` lors de l'extension au-delà de la v0.

### Décision : Structure du package et interface C du runtime Python

- **Choix retenu** (proposition à affiner à l'implémentation) :
  ```
  MicroPythonMCU (package racine)
  ├── Pico              -- model exposant les 8 connecteurs GPIO v0 (style Modelica.Electrical.Digital)
  ├── Interfaces         -- connecteurs réutilisés/étendus depuis Modelica.Electrical.Digital
  ├── Internal
  │   └── PyRuntime      -- External Object encapsulant le thread CPython + le shim machine/time
  └── Resources
      └── Scripts
          └── demo.py    -- script de démonstration par défaut (ex. clignotement sur GP0)
  ```
  Interface C de l'External Object `PyRuntime` :
  - `PyRuntime_new(scriptPath) → handle` (constructeur externe : démarre le thread CPython, charge le script).
  - `PyRuntime_destroy(handle)` (destructeur externe : arrête le thread proprement).
  - `PyRuntime_sync(handle, currentTime, pinValues[8]) → (pinValues[8], pinIsOutput[8], nextWakeTime)` : appelée depuis un `when` Modelica aux points de synchro (sleep/réveil + tick périodique, cf. décision précédente) ; transmet l'état d'entrée résolu des broches, réveille le thread jusqu'à son prochain point de blocage, renvoie les valeurs pilotées, la direction courante de chaque broche et la prochaine heure de réveil demandée.
- **Notes pour plus tard** : cette signature est une première proposition, à valider/ajuster une fois l'implémentation de l'External Object commencée (notamment le format exact des valeurs logiques `Modelica.Electrical.Digital`).

### Décision : Multi-instances (plusieurs microcontrôleurs dans un même modèle)

- **Choix retenu** : une seule instance de microcontrôleur en v0. Pas de sous-interpréteurs CPython pour cette version.
- **Alternatives envisagées** :
  - Support multi-instances dès la v0, via des sous-interpréteurs CPython (`Py_NewInterpreter`) pour isoler l'état (`sys.modules`, etc.) de chaque script — écarté : complexité disproportionnée pour une preuve de concept, et CPython embarque mal plusieurs interpréteurs vraiment isolés (verrou global GIL, état de modules partagé par défaut).
- **Notes pour plus tard** : le multi-instances nécessitera l'isolation par sous-interpréteur (chaque instance avec son propre état de modules, en évitant tout singleton global dans le shim `machine`/`time`).

### Décision : Comportement en cas d'exception non gérée dans le script

- **Choix retenu** : arrêt de la simulation, avec la trace Python (traceback) remontée comme erreur Modelica claire et lisible pour l'utilisateur.
- **Alternatives envisagées** :
  - Figer les sorties GPIO à leur dernière valeur et laisser le reste de la simulation continuer (mime un crash matériel réaliste) — écarté : moins pédagogique, plus difficile à diagnostiquer pour un élève.
- **Notes pour plus tard** : le mode « figer et continuer » pourrait redevenir pertinent dans une version orientée réalisme industriel, au-delà du cadre pédagogique actuel.

### Décision : Protection contre un script qui ne rend jamais la main

- **Choix retenu** : aucune protection/timeout en v0 (le risque de blocage de la simulation est accepté). Principe de conception retenu dès maintenant : tout appel à une API surchargée du shim (`machine.*`, `time.*`) doit être un point de synchronisation potentiel avec Modelica — pas seulement `sleep()`. Ce point de passage unique facilite l'ajout ultérieur d'une protection, même si une boucle strictement CPU-bound sans aucun appel au shim resterait indétectable par ce mécanisme.
- **Alternatives envisagées** :
  - Timeout configurable dès la v0, avec arrêt en erreur si le script ne se synchronise pas dans un délai donné — écarté pour la v0, à reconsidérer pour la version exhaustive.
- **Notes pour plus tard** : implémenter un timeout mou basé sur ce principe (vérification du temps réel écoulé à chaque appel au shim) pour la version exhaustive.

### Décision : Cycle de vie du script lors d'une relance (reset) de la simulation

- **Choix retenu** : chaque relance de la simulation recrée l'External Object depuis zéro ; le script redémarre intégralement, comme un power-cycle d'un vrai microcontrôleur.
- **Alternatives envisagées** :
  - Conserver l'état Python entre les relances — écarté : moins fidèle au comportement d'un vrai microcontrôleur, complexité inutile.
- **Notes pour plus tard** : comportement cohérent avec le cycle de vie standard (constructeur/destructeur) d'un External Object Modelica, pas d'action spécifique à prévoir.

### Décision : Sortie des print() et des erreurs du script

- **Choix retenu** : rediriger `stdout`/`stderr` du script Python vers les messages OpenModelica (`ModelicaFormatMessage`/`ModelicaError`), pour qu'ils apparaissent directement dans le journal de simulation d'OMEdit — même endroit que les erreurs d'exécution (cf. décision sur les exceptions non gérées), sans fenêtre supplémentaire à chercher.
- **Alternatives envisagées** :
  - Fichier de log séparé à côté du script — garde le journal de simulation « propre » si le script produit beaucoup de sortie, mais moins immédiat pour l'élève (fichier à ouvrir manuellement). Écarté pour la v0.
  - Les deux en parallèle — plus complet mais plus de travail d'implémentation dès la v0. Écarté pour la v0.
- **Notes pour plus tard** : si le volume de sortie devient gênant dans le journal de simulation (scripts très verbeux), reconsidérer un fichier de log séparé en complément.

## Restrictions version 0

*Lister ici les limitations volontairement acceptées pour une v0 dont le seul but est de démontrer que ça peut marcher (preuve de concept). Périmètre réduit assumé, pas encore la version cible.*

- Le microcontrôleur simulé n'expose que des GPIO simples (entrées/sorties numériques). Pas d'ADC, PWM, I2C, UART, timers, interruptions, etc. pour cette version.
- Seulement 8 broches GPIO exposées (au lieu des 29 du Raspberry Pi Pico réel), en tableau fixe (pas de connecteurs activables individuellement).
- Le script Python doit être fourni via un fichier externe (chemin `.py`) ; pas de script inline en paramètre pour cette version.
- Une seule instance de microcontrôleur par simulation (pas de multi-instances).
- Aucune protection contre un script qui ne rend jamais la main (boucle infinie sans appel à une API du shim) : la simulation peut rester bloquée dans ce cas.

## Vérification de la v0

*Scénarios concrets et critères de succès permettant de dire que la v0 « marche ». Chaque scénario teste une décision de la section « Choix architecturaux ».*

**Moyen d'exécution retenu** : chaque scénario est écrit comme un script OpenModelica Compiler (`.mos`), exécutable en ligne de commande via `omc <scénario>.mos` — reproductible et scriptable indépendamment de cette session (portable vers une éventuelle CI plus tard). Pendant le développement interactif, ces mêmes scénarios peuvent aussi être rejoués via les outils MCP-OpenModelica déjà connectés (`simulate`, `plot`, `getSimulationResultVariables`, `checkModel`), sans réécrire de script à chaque itération.

**Scénarios** :

- [ ] **Clignotement de base** : `demo.py` configure `GP0` en sortie et alterne `on()`/`off()` avec `sleep(1)` entre les deux. Succès : la trace de simulation de `GP0` montre un créneau périodique de la bonne période. Vérifie le shim `machine`/`time` et la boucle de synchro de base.
- [ ] **Compression du `sleep`** : variante avec un `sleep` long (ex. 1 h simulée) avant un toggle. Succès : le temps réel d'exécution de la simulation reste de l'ordre de la seconde, pas de l'ordre de l'heure. Vérifie la contrainte de synchronisation temporelle — le cœur de la valeur du projet.
- [ ] **Réactivité en entrée** : `GP1` en entrée, piloté depuis Modelica par une source qui bascule à un instant donné pendant que le script est en `sleep`. Succès : le script réagit (ex. `print()`) sans attendre le tick périodique ni la fin du sleep en cours. Vérifie la synchro événementielle sur transition (option retenue pour l'interface GPIO).
- [ ] **Erreur du script** : un script qui lève une exception volontaire (ex. division par zéro) doit arrêter la simulation. Succès : le traceback Python est visible dans le journal de simulation. Vérifie la gestion des erreurs et la redirection `stdout`/`stderr`.
- [ ] **Reset** : relancer la simulation deux fois de suite. Succès : le script redémarre proprement à chaque relance, sans état résiduel de la précédente exécution. Vérifie le cycle de vie de l'External Object.
- [ ] **Lisibilité visuelle de l'icône et du diagramme** : l'icône du bloc microcontrôleur (telle qu'affichée dans un schéma Modelica) doit rester lisible à taille normale — connecteurs GPIO visibles et correctement étiquetés, pas de chevauchement d'éléments, identité visuelle claire (reconnaissable comme un microcontrôleur, cohérente avec le style de la bibliothèque standard). Vérifié par rendu via les outils MCP-OpenModelica (`iconDiagram`/`classDiagram`) et inspection visuelle directe de l'image obtenue, en complément d'une relecture par un humain dans OMEdit.

## TODO vers une version exhaustive

*Liste à cocher, tenue à jour, de ce qu'il reste à faire pour passer de la v0 à une version complète.*

- [ ] Choisir le mécanisme d'exécution du script Python (doit permettre de suspendre l'exécution sur un `sleep` et d'avancer le temps simulé sans exécuter réellement l'attente)
- [ ] Implémenter le modèle de microcontrôleur v0 dans OpenModelica (GPIO simples, API façon RP2040)
- [ ] Implémenter le mécanisme de synchronisation temps script / temps de simulation, avec compression des `sleep`
- [ ] ADC (entrées analogiques)
- [ ] PWM (sorties modulées)
- [ ] Timers / délais / interruptions (time.sleep, machine.Timer, IRQ sur changement de pin)
- [ ] Bus I2C
- [ ] Bus SPI
- [ ] Bus UART
- [ ] Étendre à 29 broches GPIO (numérotation complète `GP0`–`GP28`)
- [ ] Envisager le pattern de connecteurs GPIO activables (`use_pX`) pour alléger l'icône
- [ ] Support optionnel du script Python inline (en plus du fichier externe)
- [ ] Créer et fournir le script de démonstration par défaut (`Resources/Scripts/demo.py`)
- [ ] Support multi-instances (isolation par sous-interpréteurs CPython, éliminer les singletons globaux dans le shim)
- [ ] Timeout mou basé sur les appels au shim (protection contre un script qui ne rend jamais la main)
- [ ] Créer les scripts de démonstration nécessaires aux scénarios de vérification v0 (sleep long, réactivité entrée, erreur volontaire)
- [ ] Écrire les scripts `.mos` de vérification (un par scénario v0), exécutables via `omc`
- [ ] Étendre la vérification visuelle (icône/diagramme) à chaque nouveau composant ajouté au-delà de la v0 (ADC, PWM, etc.)
