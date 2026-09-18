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

### Décision : [nom de la décision]

- **Choix retenu** :
- **Alternatives envisagées** :
  - Alternative A — avantages / inconvénients :
  - Alternative B — avantages / inconvénients :
- **Notes pour plus tard** :

### Décision : Mécanisme d'exécution du script Python pendant la simulation

- **Choix retenu** : à décider — non tranché à ce stade.
- **Alternatives envisagées** : à explorer (ex. interpréteur Python réel appelé depuis Modelica à chaque pas de simulation, génération de code, FMI/co-simulation avec un process Python séparé, etc.).
- **Notes pour plus tard** : c'est la décision d'architecture la plus structurante du projet ; à traiter en priorité avant d'écrire la première brique de la v0. Doit satisfaire la contrainte de synchronisation temporelle (cf. Besoin) : le mécanisme retenu doit permettre de suspendre l'exécution sur un `sleep` et d'avancer le temps simulé sans exécuter réellement l'attente — ce qui oriente vers une exécution interruptible/pilotée par événements plutôt qu'un simple appel bloquant à un interpréteur.

## Restrictions version 0

*Lister ici les limitations volontairement acceptées pour une v0 dont le seul but est de démontrer que ça peut marcher (preuve de concept). Périmètre réduit assumé, pas encore la version cible.*

- Le microcontrôleur simulé n'expose que des GPIO simples (entrées/sorties numériques). Pas d'ADC, PWM, I2C, UART, timers, interruptions, etc. pour cette version.

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
