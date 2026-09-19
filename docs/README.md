# Documentation d'implémentation — MicroPythonMCU

Cette documentation explique **comment** la bibliothèque `MicroPythonMCU` est construite : l'arborescence du dépôt, comment CPython s'intègre à OpenModelica, et ce qui se passe concrètement à l'instanciation puis à chaque pas de temps de la simulation.

Pour le **pourquoi** (besoin, décisions d'architecture avec alternatives, restrictions de la v0, TODO), voir [`requirements.md`](../requirements.md) à la racine du dépôt — c'est le document de référence pour les choix et leurs justifications. Cette documentation-ci se concentre sur le fonctionnement interne une fois ces choix faits.

## Sommaire

1. [architecture.md](architecture.md) — arborescence du dépôt, rôle de chaque fichier/dossier, vue d'ensemble des composants.
2. [integration-python.md](integration-python.md) — comment CPython est compilé et lié dans l'exécutable de simulation généré par OpenModelica, la distribution Python embarquée, le shim `machine`/`time`.
3. [cycle-de-vie.md](cycle-de-vie.md) — ce qui se passe à l'instanciation (construction de `PyRuntime`, démarrage du thread) et à chaque pas de temps (le protocole de synchronisation entre le solveur Modelica et le script Python), plus les pièges rencontrés en cours d'implémentation.

## Convention pour les captures d'écran

Certains emplacements sont marqués `<!-- TODO screenshot: ... -->` : ce sont des captures à prendre dans OMEdit (icône ou schéma d'un modèle) et à déposer dans `docs/images/` sous le nom indiqué, puis à référencer avec `![description](images/nom.png)` à la place du commentaire.
