# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## État du dépôt

Ce dépôt ne contient encore aucun code : aucun fichier Modelica (`.mo`), Python ou MicroPython n'existe. Le `README.md` présent est le template GitLab par défaut, jamais rempli. Il n'y a ni manifeste de dépendances (pas de `requirements.txt`, `pyproject.toml`, `Package.mo`, etc.) ni configuration de build, lint ou test à ce jour. Le cadrage du projet est en revanche déjà entamé dans `requirements.md`.

## Projet

Bibliothèque OpenModelica fournissant un modèle de microcontrôleur programmable : son comportement est piloté par un script Python écrit par l'utilisateur et compatible MicroPython, avec la carte Raspberry Pi Pico (RP2040) comme référence d'API. Objectif : simuler dans Modelica le couplage matériel/logiciel d'un système embarqué (jumeau numérique), pour un usage pédagogique (Lycée Jules Haag) et industriel.

**`requirements.md` est la source de vérité du cadrage** (besoin détaillé, choix architecturaux avec alternatives, restrictions de la v0, TODO vers la version exhaustive) — le consulter avant de modifier le périmètre ou l'architecture, et le tenir à jour au fil des décisions plutôt que de dupliquer son contenu ici.

## Stack technique prévue

- **Modelica** : OpenModelica / OMEdit. Le serveur MCP `MCP-OpenModelica` est disponible dans l'environnement pour interagir directement avec les classes chargées dans OMEdit (créer/modifier des classes, composants, connexions, lancer des simulations, tracer des courbes, etc.) — préférer ces outils à l'édition à l'aveugle des fichiers `.mo` une fois qu'ils existeront.
- **MicroPython** : exécution en simulateur/host pour l'instant, aucune cible matérielle physique définie — pas de contraintes d'upload/flash à ce stade. Le mécanisme d'exécution du script (interprétation, synchronisation avec le temps de simulation) n'est pas encore choisi — voir la décision correspondante dans `requirements.md`.

## Note pour les futures instances

Ce fichier doit être mis à jour dès que du code réel, une structure de dossiers, des dépendances ou des commandes de build/test/lint apparaissent dans le dépôt. Ne pas laisser ces sections devenir obsolètes ni inventer des détails absents du code ou de `requirements.md`.
