# Installation

`MicroPythonMCU` fonctionne sous **Windows 64 bits** avec [OpenModelica](https://openmodelica.org/download/download-windows/) (OMEdit). Le runtime Python est fourni avec la bibliothèque : rien d'autre à installer, sinon le *Microsoft Visual C++ Redistributable*, presque toujours déjà présent.

## Choisir une archive

Chaque version est publiée sur la [page des releases](https://gitlab.com/bdelaup/modelica_micropython3/-/releases) avec trois archives :

| Archive | Contenu | Pour qui |
|---|---|---|
| `MicroPythonMCU-<version>-lib-om<OM>-win64.zip` | La bibliothèque prête à installer, runtime précompilé | **Élèves et enseignants : c'est celle-ci** |
| `MicroPythonMCU-<version>-om<OM>-win64.zip` | La même, avec la suite de vérification (`Resources/Verification`) | Vérifier une installation, utilisateurs avancés |
| `MicroPythonMCU-<version>-src.zip` | Le module avec ses sources C, compilées à chaque simulation | Modifier la bibliothèque, ou utiliser une autre version d'OpenModelica |

`<OM>` est la version d'OpenModelica avec laquelle le runtime a été compilé (par exemple `1.27.1`). Les deux archives précompilées demandent **cette version-là** d'OpenModelica. Avec une autre version, prenez l'archive des sources : omc recompile alors le runtime avec sa propre toolchain.

## Installer la bibliothèque (archive `-lib`)

1. Fermer OMEdit.
2. Décompresser l'archive dans le dossier des bibliothèques d'OpenModelica de l'utilisateur :

    ```
    %APPDATA%\.openmodelica\libraries\
    ```

    Il doit y apparaître un dossier `MicroPythonMCU <version>` (par exemple `MicroPythonMCU 1.0.0`), qui contient directement `package.mo`.
3. Rouvrir OMEdit, puis *File → System Libraries → MicroPythonMCU*. En script : `loadModel(MicroPythonMCU);`.
4. Vérifier : ouvrir `MicroPythonMCU.Examples.BasicBlink` et le simuler. `GP0` clignote.

Plusieurs versions peuvent cohabiter dans ce dossier. Un modèle qui déclare `uses(MicroPythonMCU(version = "1.0.0"))` (OMEdit l'ajoute de lui-même lorsqu'on utilise la bibliothèque) charge la version qu'il demande.

## Utiliser les autres archives

Décompresser l'archive n'importe où (de préférence hors d'un dossier synchronisé comme OneDrive), puis dans OMEdit : *File → Open Model/Library File(s)…* et sélectionner `MicroPythonMCU/package.mo`.

La suite de vérification de l'archive compilée se lance comme décrit dans [Suite de vérification](tests.md).

## Version de développement

Pour essayer l'état courant, entre deux versions publiées : cloner ou télécharger le [dépôt](https://gitlab.com/bdelaup/modelica_micropython3) (*Code → Download source code → zip*) et ouvrir `MicroPythonMCU/package.mo` dans OMEdit, comme l'archive des sources.
