# Lancer les scripts sous Windows

Les outils du dépôt sont des scripts bash : la suite de vérification (`run_tests.sh`), la construction du site (`make_docs.sh`), la table d'import Python (`make_pyimports.sh`), le débogueur vendoré (`make_debugpy.sh`) et le zip de PulseView (`make_pulseview_zip.sh`). Sous Windows, ils tournent avec le bash de **Git for Windows** (« Git Bash »). Un lanceur `.cmd` du même nom, à côté de son script dans le dossier `tools/`, s'occupe de le trouver : on les lance depuis PowerShell, cmd ou l'Explorateur sans ouvrir Git Bash.

## Prérequis

| Outil | Pour quoi | Où le trouver |
|---|---|---|
| Git for Windows | tous les scripts (Git Bash) | <https://git-scm.com/download/win> |
| OpenModelica | `run_tests`, `make_pyimports` | installation habituelle, plus `OPENMODELICAHOME` (ci-dessous) |
| Python + `pip install zensical` | `make_docs` | Python du poste |
| Python + `pip` | `make_debugpy` | Python du poste |
| 7-Zip + Python | `make_pulseview_zip` | <https://www.7-zip.org> (cherché dans le `PATH` puis dans `Program Files\7-Zip\`) |

## Régler `OPENMODELICAHOME` une fois pour toutes

`run_tests` et `make_pyimports` trouvent `omc` et le compilateur C (MinGW) d'OpenModelica grâce à la variable d'environnement `OPENMODELICAHOME`. Elle doit pointer sur la **racine** de l'installation, c'est-à-dire le dossier qui contient `bin\omc.exe`. Exemple : `D:\Programmes\OpenModelica1.27.1-64bit`. L'installeur d'OpenModelica ne la crée pas toujours.

**En ligne de commande** (PowerShell ou cmd, sans droits administrateur) :

```
setx OPENMODELICAHOME "D:\Programmes\OpenModelica1.27.1-64bit"
```

**Ou par l'interface** : Win+R, taper `rundll32 sysdm.cpl,EditEnvironmentVariables`, puis, dans « Variables utilisateur », cliquer sur **Nouvelle…**. Nom : `OPENMODELICAHOME` ; valeur : le dossier d'installation.

!!! warning "Rouvrir VS Code"
    La variable ne vaut que pour les programmes lancés **après** ce réglage. Le terminal intégré de VS Code hérite de l'environnement de VS Code : ouvrir un nouveau terminal ne suffit pas, il faut **quitter VS Code entièrement et le relancer**. Même chose pour une fenêtre PowerShell déjà ouverte.

**Vérifier**, dans un nouveau terminal PowerShell :

```
echo $env:OPENMODELICAHOME
Test-Path "$env:OPENMODELICAHOME\bin\omc.exe"     # doit afficher True
```

**Changer de version le temps d'une session** (par exemple pour rejouer la suite sous la 1.24.4, cf. [Suite de vérification](tests.md)) : le réglage ne dure que jusqu'à la fermeture de la fenêtre PowerShell.

```
$env:OPENMODELICAHOME = "D:\Programmes\OpenModelica1.24.4-64bit"
.\tools\run_tests.cmd --copy
```

Pour changer de version durablement, refaire `setx` avec l'autre dossier.

Si `OPENMODELICAHOME` est vide mais que `omc` est dans le `PATH` Windows, le lanceur déduit la variable de l'emplacement de `omc`, pour cet appel seulement.

## Les commandes

Dans un terminal PowerShell (celui de VS Code convient), **à la racine du dépôt** :

| Commande | Effet |
|---|---|
| `.\tools\run_tests.cmd` | toute la suite de vérification, dans le dépôt |
| `.\tools\run_tests.cmd --copy` | la suite sur une copie des fichiers suivis par git, hors du dépôt : **à faire avant un tag** |
| `.\tools\run_tests.cmd verify_08_pwm.mos verify_09_import.mos` | seulement ces scénarios |
| `.\tools\run_tests.cmd -j 2 -k` | 2 exécutions simultanées, artefacts et journaux gardés |
| `.\tools\make_docs.cmd` | construit le site dans `public/` (comme la CI, en `--strict`) |
| `.\tools\make_docs.cmd serve fr` | aperçu local du site français sur <http://localhost:8000> (Ctrl+C pour arrêter) ; `serve en` pour l'anglais |
| `.\tools\make_pyimports.cmd` | régénère `Resources/Include/pyimports.h` |
| `.\tools\make_debugpy.cmd` | reconstruit `Resources/Debugpy/` |
| `.\tools\make_pulseview_zip.cmd` | fabrique le zip de la copie portable de PulseView à partir du nightly de sigrok.org ; `--upload` dépose ce zip dans le registre GitLab (cf. [Publier](publication.md#pulseview-copie-portable)) |

`get_pulseview.cmd`, lui, reste à la racine du dépôt : ce n'est pas un lanceur de script bash, il s'adresse aux utilisateurs, qui n'ont pas forcément Git Bash, et n'utilise que des outils de Windows (`curl.exe`, `certutil`, `tar.exe`).

Les options sont celles des scripts `.sh` ; leur en-tête les décrit toutes. Le code de sortie est celui du script : `$LASTEXITCODE` vaut 0 si tout passe.

Le préfixe `.\` est **obligatoire** dans PowerShell, qui ne cherche pas les commandes dans le dossier courant. Dans cmd, `tools\run_tests.cmd` suffit.

Un **double-clic** sur un `.cmd` dans l'Explorateur lance aussi le script, sans argument. La fenêtre attend une touche à la fin, le temps de lire le récapitulatif.

### Autre façon : un terminal Git Bash

Dans VS Code, la flèche `˅` à côté du `+` du panneau Terminal propose **Git Bash** (« Select Default Profile » pour l'ouvrir par défaut). On y lance directement les `.sh` :

```
tools/make_docs.sh serve fr
MicroPythonMCU/Resources/Verification/run_tests.sh --copy
```

`OPENMODELICAHOME` y est la même variable Windows.

## Comment marchent les lanceurs

Chaque lanceur (`run_tests.cmd`, `make_docs.cmd`, etc.) se contente d'appeler `gitbash.cmd`, rangé avec eux dans `tools/`, avec le chemin de son script. `gitbash.cmd <script.sh> [arguments…]` peut aussi servir à lancer n'importe quel autre script bash. Il :

- prend le `bash.exe` de Git for Windows, cherché à côté du `git` du `PATH`, puis dans `Program Files\Git` et `%LOCALAPPDATA%\Programs\Git`. Il n'utilise **jamais** le `bash` du `PATH` (voir les pièges) ;
- passe le chemin du script avec des `/` : les scripts retrouvent leur dossier par `dirname "$0"`, qui ne reconnaît pas les `\` ;
- passe la console en UTF-8 le temps du script, pour que les accents s'affichent correctement, puis remet la page de codes d'origine ;
- renvoie le code de sortie du script.

## Pièges

- **`bash` dans PowerShell n'est pas Git Bash.** C'est `C:\Windows\system32\bash.exe`, c'est-à-dire WSL (Linux), qui n'a ni `omc` Windows ni MinGW : les scripts y échouent. D'où les lanceurs, qui désignent Git Bash par son chemin.
- **Pas de lanceur `.ps1`.** La politique d'exécution par défaut de Windows (`Restricted`) bloque les scripts PowerShell ; les `.cmd` passent partout.
- **Fins de ligne.** Les `.sh` doivent rester en LF (bash échoue sur `$'\r': command not found`) et les `.cmd` en CRLF. `.gitattributes` l'impose à chaque extraction ; dans VS Code, ne pas changer l'indicateur LF/CRLF de la barre d'état de ces fichiers.
- **Arguments contenant `=`, `;` ou `,`** : cmd les traite comme des séparateurs. Écrire `-j 2`, pas `-j=2`.
- **`*.bat` est ignoré par git** (artefacts de compilation d'OpenModelica) : un nouveau lanceur doit être en `.cmd`.
- **Suite lente ou `Permission denied` dans OneDrive** : voir [Suite de vérification](tests.md). `--copy` la fait tourner hors du dossier synchronisé.
