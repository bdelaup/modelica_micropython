# Installation

`MicroPythonMCU` fonctionne sous **Windows 64 bits** avec [OpenModelica](https://openmodelica.org/download/download-windows/) (OMEdit, testé avec la version 1.27.1). Le runtime Python est fourni avec la bibliothèque et le compilateur C est celui d'OpenModelica : rien d'autre à installer, sinon le *Microsoft Visual C++ Redistributable*, presque toujours déjà présent.

## Choisir une version

Chaque version de la bibliothèque est un **tag** du dépôt, de la forme `vX.Y.Z` (par exemple `v0.1.0`). La liste des versions est sur la [page des tags](https://gitlab.com/bdelaup/modelica_micropython3/-/tags). Prendre la plus récente, sauf raison contraire.

## Télécharger une version

1. Sur la [page des tags](https://gitlab.com/bdelaup/modelica_micropython3/-/tags), cliquer sur le bouton de téléchargement (flèche) de la version voulue, puis sur **zip**. Adresse directe, pour `v0.1.0` :

    ```
    https://gitlab.com/bdelaup/modelica_micropython3/-/archive/v0.1.0/modelica_micropython3-v0.1.0.zip
    ```

    Avec git : `git clone --branch v0.1.0 https://gitlab.com/bdelaup/modelica_micropython3.git`

2. Décompresser le zip, de préférence hors d'un dossier synchronisé comme OneDrive. Il contient le dossier `MicroPythonMCU`, qui est la bibliothèque proprement dite (il contient `package.mo`).

## Charger ou installer

Il n'est pas nécessaire d'installer la bibliothèque : il suffit de la **charger** dans OMEdit. Trois façons, de la plus légère à la plus durable.

### Charger la bibliothèque, sans rien installer

Dans OMEdit, *File → Open Model/Library File(s)…*, puis sélectionner `MicroPythonMCU/package.mo`. La bibliothèque apparaît dans l'explorateur, le temps de la session : à refaire à chaque lancement d'OMEdit. En script : `loadFile("C:/chemin/vers/MicroPythonMCU/package.mo");`.

C'est la façon recommandée pour essayer une version, ou pour travailler sur un poste partagé : rien n'est copié en dehors du dossier téléchargé, et plusieurs versions peuvent coexister dans des dossiers différents.

### La charger automatiquement à chaque lancement

Pour ne pas rouvrir le fichier à chaque fois, sans l'installer non plus : *Tools → Options → Libraries*, section *User Libraries*, ajouter le chemin de `MicroPythonMCU/package.mo`. OMEdit la charge alors à chaque démarrage, depuis le dossier téléchargé.

### L'installer comme bibliothèque système

La bibliothèque rejoint alors celles d'OpenModelica et se charge à la demande :

1. Fermer OMEdit.
2. Copier le dossier `MicroPythonMCU` dans le dossier des bibliothèques d'OpenModelica de l'utilisateur :

    ```
    %APPDATA%\.openmodelica\libraries\
    ```

3. Rouvrir OMEdit, puis *File → System Libraries → MicroPythonMCU*. En script : `loadModel(MicroPythonMCU);`.

Pour changer de version, remplacer ce dossier par celui d'une autre version.

## Vérifier

Ouvrir `MicroPythonMCU.Examples.BasicBlink` et le simuler : `GP0` clignote (voir [Premiers pas](premiers-pas.md)).

La **première simulation d'un modèle est plus longue** (une à quelques dizaines de secondes de plus) : OpenModelica compile le runtime C de la bibliothèque avec son propre compilateur, à partir des sources fournies. C'est normal, et c'est ce qui permet d'utiliser n'importe quelle version récente d'OpenModelica.

## Bientôt : installation par le gestionnaire de bibliothèques

L'inscription de la bibliothèque à l'index d'OpenModelica est en cours. Une fois faite, plus besoin de télécharger quoi que ce soit : dans OMEdit, *File → Manage Libraries → Install Library*, ou en script `installPackage(MicroPythonMCU);`. Chaque tag y deviendra une version installable.

## Version de développement

Pour essayer l'état courant, entre deux versions : cloner le [dépôt](https://gitlab.com/bdelaup/modelica_micropython3) sans préciser de tag, ou le télécharger (*Code → zip*), puis procéder comme ci-dessus.
