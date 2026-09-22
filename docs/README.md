# Documentation d'implémentation — MicroPythonMCU

Cette documentation explique **comment** la bibliothèque `MicroPythonMCU` est construite : l'arborescence du dépôt, comment CPython s'intègre à OpenModelica, et ce qui se passe concrètement à l'instanciation puis à chaque pas de temps de la simulation.

Pour le **pourquoi** (besoin, décisions d'architecture avec alternatives, restrictions de la v0, TODO), voir [`requirements.md`](../requirements.md) à la racine du dépôt — c'est le document de référence pour les choix et leurs justifications. Cette documentation-ci se concentre sur le fonctionnement interne une fois ces choix faits.

## Sommaire

1. [architecture.md](architecture.md) — arborescence du dépôt, rôle de chaque fichier/dossier, vue d'ensemble des composants.
2. [integration-python.md](integration-python.md) — comment CPython est compilé et lié dans l'exécutable de simulation généré par OpenModelica, la distribution Python embarquée, le shim `machine`/`time`.
3. [cycle-de-vie.md](cycle-de-vie.md) — ce qui se passe à l'instanciation (construction de `PyRuntime`, démarrage du thread) et à chaque pas de temps (le protocole de synchronisation entre le solveur Modelica et le script Python), plus les pièges rencontrés en cours d'implémentation.
4. [api-machine.md](api-machine.md) — référence de l'API `machine`/`time` telle qu'exposée au script utilisateur (côté « qui écrit un script », pas « comment c'est câblé »). Le shim lui-même est un vrai fichier de la bibliothèque : [`Resources/Scripts/_shim/machine_time_shim.py`](../MicroPythonMCU/Resources/Scripts/_shim/machine_time_shim.py).
5. [tests.md](tests.md) — comment relancer la suite de vérification (`Resources/Verification/*.mos`) de façon reproductible, ce que vérifie chaque script, et comment en ajouter un nouveau.
6. [peripherique-display.md](peripherique-display.md) — le périphérique d'affichage pédagogique `Peripherals.Display` (`machine.Display`) : pourquoi il est modélisé en connecteur logique causal plutôt qu'électrique, comment le texte s'affiche réellement sur son icône, le déroulé d'un envoi.
7. [peripherique-uart.md](peripherique-uart.md) — la liaison série électrique réelle `machine.UART` : pourquoi elle reste dans le domaine électrique (à l'inverse de `Display`), le partage émission-continue-Modelica / réception-décodée-en-C, la trame 8N1 et le câblage de bouclage.

Voir aussi [`requirements-archive.md`](../requirements-archive.md) à la racine du dépôt : récits de débogage déjà refermés et propositions abandonnées, extraits de `requirements.md` pour garder ce dernier concentré sur l'architecture actuelle — consultation ponctuelle seulement.

## Convention pour les captures d'écran

Certains emplacements sont marqués `<!-- TODO screenshot: ... -->` : ce sont des captures à prendre dans OMEdit (icône ou schéma d'un modèle) et à déposer dans `docs/images/` sous le nom indiqué, puis à référencer avec `![description](images/nom.png)` à la place du commentaire.
