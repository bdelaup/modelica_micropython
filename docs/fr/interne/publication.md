# Publier une version et la documentation

La documentation est publiée automatiquement par GitLab. Les versions de la bibliothèque se livrent à la main, avec deux scripts du dépôt. Le **pourquoi** de ce partage est dans [`requirements.md`](https://gitlab.com/bdelaup/modelica_micropython3/-/blob/main/requirements.md), décision « Publication de la documentation et livraison des versions ».

## La documentation

Le site est construit par [Zensical](https://zensical.org/) en deux langues, chacune décrite par sa configuration :

| Langue | Pages | Configuration | Adresse | Contenu |
|---|---|---|---|---|
| Français | `docs/fr/` | [`zensical.fr.toml`](https://gitlab.com/bdelaup/modelica_micropython3/-/blob/main/zensical.fr.toml) | `/fr/` | Guide utilisateur et référence interne |
| Anglais | `docs/en/` | [`zensical.en.toml`](https://gitlab.com/bdelaup/modelica_micropython3/-/blob/main/zensical.en.toml) | `/en/` | Guide utilisateur seulement |

[`make_docs.sh`](https://gitlab.com/bdelaup/modelica_micropython3/-/blob/main/make_docs.sh) construit les deux dans `public/`, plus `public/index.html`, qui renvoie vers l'anglais, **langue par défaut** du site. À chaque push sur `main`, le job `pages` de [`.gitlab-ci.yml`](https://gitlab.com/bdelaup/modelica_micropython3/-/blob/main/.gitlab-ci.yml) l'exécute et publie le résultat sur GitLab Pages, sur un runner partagé de GitLab : rien à installer ni à lancer.

Adresse : <https://bdelaup.gitlab.io/modelica_micropython3/>

### Réglages GitLab (une seule fois)

- *Deploy → Pages* : décocher **Use unique domain** (recommandé). Coché, GitLab publie le site à la racine d'une adresse générée (`https://modelica-micropython3-a705bd.gitlab.io/fr/`, sans le préfixe `/modelica_micropython3/`) et y redirige `bdelaup.gitlab.io/modelica_micropython3/…`. Le site fonctionne dans les deux cas, car les liens du sélecteur de langue sont relatifs (`../en/` dans `extra.alternate`) ; seules les adresses affichées diffèrent de `site_url`. Ne pas écrire de lien absolu commençant par `/modelica_micropython3/` : il casse sur le domaine unique.
- *Settings → General → Visibility, project features, permissions → Pages* : **Everyone** pour que le site soit public, même si le dépôt ne l'est pas.

### Écrire une page

- Une nouvelle page se crée dans `docs/fr/`, puis s'ajoute à `nav` dans `zensical.fr.toml`, sinon elle n'apparaît pas dans le menu.
- **Page du guide utilisateur** (`docs/fr/guide/`, `docs/fr/index.md`) : sa traduction va dans `docs/en/`, **au même chemin**, et s'ajoute à `nav` dans `zensical.en.toml`. Le sélecteur de langue retrouve la page correspondante par ce chemin (il lit le `sitemap.xml` de l'autre langue) ; sans traduction, il ramène à l'accueil de l'autre langue. La référence interne (`docs/fr/interne/`) n'est pas traduite.
- **Images** : uniquement dans `docs/fr/images/`. `make_docs.sh` en fait une copie dans `docs/en/images/` (ignorée par git) avant de construire le site anglais : une page anglaise les référence donc par le même chemin relatif que son original.
- Entre pages d'une même langue, liens relatifs ordinaires : `[Installation](../guide/installation.md)`. Une page anglaise qui renvoie vers la référence interne utilise une URL absolue (`https://bdelaup.gitlab.io/modelica_micropython3/fr/interne/...`).
- Vers un fichier du dépôt **hors de `docs/`**, lien absolu vers GitLab : `https://gitlab.com/bdelaup/modelica_micropython3/-/blob/main/requirements.md`. Un lien relatif `../requirements.md` fonctionne dans GitLab, mais pas sur le site.
- La construction est stricte (`--strict`) : un lien cassé vers une page fait échouer le job `pages`, et le site en ligne reste alors celui d'avant.
- Illustrations attendues et conventions (formats, tailles, nommage) : [`docs/ILLUSTRATIONS.md`](https://gitlab.com/bdelaup/modelica_micropython3/-/blob/main/docs/ILLUSTRATIONS.md). Les courbes de simulation sont générées par `python docs/figures/make_figures.py`, qui simule les exemples avec omc.

### Aperçu local

```
pip install zensical
./make_docs.sh serve fr      # ou en
```

puis <http://localhost:8000>. La page se recharge à chaque enregistrement. `./make_docs.sh` seul fait la construction complète et stricte, comme la CI. Depuis PowerShell : `.\make_docs.cmd serve fr` et `.\make_docs.cmd` (cf. [Lancer les scripts sous Windows](outils-windows.md)).

## Livrer une version

Une version est un **tag** `vX.Y.Z` du dépôt, rien de plus : les utilisateurs téléchargent l'arbre du dépôt à ce tag (zip proposé par GitLab ou `git clone --branch`), voir [Installation](../guide/installation.md). Le runtime C y est livré en sources, compilées par omc à la première simulation : la même version sert donc toutes les versions d'OpenModelica. C'est aussi ce que distribuera l'index d'OpenModelica (`installPackage`) une fois la bibliothèque inscrite.

### Numéro de version

Le dépôt ne porte pas de numéro de version : **le tag fait foi**.

Tant que les versions sont en `0.x`, l'API n'est pas déclarée stable : une rupture de compatibilité ne fait monter que la mineure (`0.2.0` → `0.3.0`). `1.0.0` sera posée une fois la bibliothèque éprouvée en usage réel ; le tableau ci-dessous s'applique pleinement à partir de là.

| Changement | Exemple | Version |
|---|---|---|
| Un modèle ou un script existant d'un utilisateur peut cesser de fonctionner | paramètre renommé, connecteur supprimé, comportement du shim modifié | **majeure** : `1.3.0` → `2.0.0` |
| Nouvelle fonction, sans rien casser | nouveau périphérique, nouvelle méthode `machine` | **mineure** : `1.3.0` → `1.4.0` |
| Correction | bug du runtime, documentation | **correctif** : `1.3.0` → `1.3.1` |

### Procédure

Dans Git Bash, à la racine du dépôt :

1. Partir d'un dépôt propre : tout commité (`git status` vide).
2. Passer la suite de vérification sur ce que livrera le tag (cf. [Suite de vérification](tests.md)) :

    ```
    export OPENMODELICAHOME="D:/Programmes/OpenModelica1.27.1-64bit"
    MicroPythonMCU/Resources/Verification/run_tests.sh --copy
    ```

    Depuis PowerShell, l'équivalent est `.\run_tests.cmd --copy`, avec `OPENMODELICAHOME` déjà réglé (cf. [Lancer les scripts sous Windows](outils-windows.md)). Toutes les lignes doivent être `PASS`.
3. Poser et pousser le tag :

    ```
    git tag -a v1.3.0 -m "Nouveautés de la version"
    git push origin v1.3.0
    ```

4. Vérifier : télécharger le zip du tag depuis la [page des tags](https://gitlab.com/bdelaup/modelica_micropython3/-/tags) et suivre [Installation](../guide/installation.md).

Les notes de version, si on en veut, se rédigent dans le message du tag ou dans une *Release* GitLab créée sur ce tag, sans fichier joint.

## Mettre à jour un composant vendoré

- **Débogueur `debugpy`** (`Resources/Debugpy/`, utilisé par `MCU.debugEnabled`) : changer `VERSION` dans `make_debugpy.sh`, puis lancer `./make_debugpy.sh` à la racine, ou `.\make_debugpy.cmd` depuis PowerShell (pip télécharge la roue `cp312` `win_amd64`, le script l'allège et remplace le dossier). Rejouer `verify_60` à `verify_63` et faire un essai dans VS Code avant de livrer : la bibliothèque s'appuie sur quelques rouages internes de pydevd (`_WaitForConnectionThread`, lecteur `reader.sock`, `FilesFiltering._get_default_library_roots`), cf. `cycle-de-vie.md`, section 5.

## PulseView, copie portable

PulseView n'est **pas** dans le dépôt git : un binaire tiers de 50 Mo alourdirait l'historique de tous, alors qu'il reste facultatif (décision « Distribution de PulseView » de `requirements.md`). Sa copie portable voyage sous forme de zip, publié à part dans le **registre de paquets** du projet GitLab.

### La chaîne complète

```
sigrok.org                    mainteneur                       GitLab                         élève
nightly Windows   ──────►  make_pulseview_zip.sh  ──────►  registre de paquets  ──────►  get_pulseview.cmd
(installeur NSIS)          (extrait, trie, zippe,           pulseview/<version>/           (télécharge, vérifie,
                            réécrit get_pulseview.cmd)      pulseview-…-portable.zip        décompresse en PulseView/)
```

1. **sigrok.org** publie chaque jour un installeur Windows de PulseView, le *nightly* : <https://sigrok.org/download/binary/pulseview/pulseview-NIGHTLY-x86_64-release-installer.exe>. C'est la version que le projet sigrok recommande ; la dernière version numérotée (0.4.2) est bien plus ancienne. L'adresse ne change pas, son contenu si.
2. **`make_pulseview_zip.sh`** (mainteneur, à la racine) en tire un zip portable et l'empreinte de ce zip ; `make_pulseview_zip.sh --upload` le dépose, une fois validé.
3. **Le registre de paquets GitLab** (*Deploy → Package registry*) garde chaque zip sous son numéro de version. Le projet étant public, le téléchargement est anonyme.
4. **`get_pulseview.cmd`** (élève, à la racine) contient l'adresse et l'empreinte du zip **en dur**. Il le télécharge, vérifie l'empreinte et le décompresse dans `PulseView/`, à côté de `MicroPythonMCU`, où la sonde le trouve d'elle-même (`pulseViewPath` vide, cf. [Analyse des trames](analyse-trames.md)).

Le point clé : `get_pulseview.cmd` désigne **un** zip précis, figé par son empreinte. Un élève qui télécharge la bibliothèque à un tag reçoit le PulseView validé avec ce tag, pas le nightly du jour, qui pourrait casser la session `.pvs`.

### Ce que fait `make_pulseview_zip.sh`

| Étape | Détail |
|---|---|
| 1. Téléchargement | L'installeur nightly, par `curl -R` : le fichier prend la date du serveur (`Last-Modified`), qui date le build. `--installer setup.exe` part d'un installeur déjà téléchargé (sa date de modification sert alors de date de build). |
| 2. Extraction | Par **7-Zip**, qui ouvre l'installeur NSIS **sans l'exécuter** : rien n'est installé, aucun droit administrateur n'est demandé. |
| 3. Tri | Retrait des exemples (`examples/`), des outils de pilote USB `zadig*.exe` (inutiles pour lire un VCD), du désinstalleur et du dossier interne `$PLUGINSDIR`. Reste ≈ 48 Mo, ≈ 24 Mo compressés. |
| 4. Version | Lue par `pulseview.exe --version` (`PulseView 0.5.0-git-e2fe9df`). Le lancer compile les décodeurs Python, dont les `__pycache__` sont retirés ensuite. |
| 5. Licence | Ajout de `PulseView/SOURCES.txt` : origine des fichiers, adresses des sources de PulseView, libsigrok et libsigrokdecode, et sortie complète de `--version` (version exacte de chaque bibliothèque). Avec `COPYING`, fourni par l'installeur, c'est ce que demande la GPLv3 pour redistribuer le binaire. |
| 6. Zip | `pulseview-<version>-win64-portable.zip` à la racine (ignoré par git), par le `tar.exe` de Windows : le `tar` de Git Bash ne sait pas écrire un zip. Le zip contient un seul dossier, `PulseView/`. |
| 7. `get_pulseview.cmd` | `PV_VERSION` et `PV_SHA256` réécrits, fins de ligne CRLF conservées. |
| Dépôt, à part | `--upload` ne fabrique rien : il dépose le zip **déjà fabriqué** que désigne `get_pulseview.cmd`, après avoir vérifié que son empreinte est bien `PV_SHA256`. Ainsi, c'est exactement le zip validé qui part, même si le nightly a changé entre-temps. |

**Numéro de version** : `<version de PulseView>-<date du build>`, par exemple `0.5.0-e2fe9df-20261005`. Le nightly est recompilé avec les bibliothèques sigrok du moment, souvent sans que la version de PulseView elle-même change. La date distingue deux builds, et le registre range chacun sous son propre numéro.

### Prérequis (une seule fois)

- **7-Zip** (<https://www.7-zip.org>) : le script le cherche dans le `PATH`, puis dans `Program Files\7-Zip\`.
- **Python** du poste, pour réécrire `get_pulseview.cmd`.
- **Le registre de paquets activé** : *Settings → General → Visibility, project features, permissions → Package registry*.
- **Un jeton d'accès GitLab**, pour le dépôt : *Settings → Access tokens* (jeton de projet) ou *Preferences → Access tokens* (jeton personnel), portée `api`, rôle Developer au moins. Le garder hors du dépôt.

### Publier un nouveau PulseView

À faire quand on veut un PulseView plus récent, **pas** à chaque tag de la bibliothèque.

1. Fabriquer le zip, sans le publier :

    ```
    ./make_pulseview_zip.sh                  # Git Bash
    .\make_pulseview_zip.cmd                 # PowerShell
    ```

    Le script affiche la version, la taille et l'empreinte, et réécrit `get_pulseview.cmd`.
2. **Valider ce PulseView** avant de le publier : remplacer le dossier `PulseView/` de la racine par le contenu du zip (le dossier est ignoré par git), simuler `Examples.Analyzer.UartLink` et `Examples.Analyzer.I2cBus` avec `openPulseView = true`, et vérifier que les décodeurs se chargent depuis la session `.pvs`, sans réglage. Le format de cette session n'est pas documenté : c'est lui qui risque de casser d'une version à l'autre.
3. Déposer ce zip :

    ```
    GITLAB_TOKEN=glpat-... ./make_pulseview_zip.sh --upload
    ```

    Depuis PowerShell : `$env:GITLAB_TOKEN = "glpat-..."`, puis `.\make_pulseview_zip.cmd --upload`. Rien n'est refait : le script dépose le zip de l'étape 1, après avoir vérifié son empreinte.
4. Essayer `get_pulseview.cmd` dans un dossier vierge (une copie du dépôt hors OneDrive, par exemple) : téléchargement, empreinte, décompression.
5. Committer `get_pulseview.cmd`. Le zip, lui, n'est jamais committé.

Les anciens zips restent dans le registre : un tag plus ancien continue de télécharger le sien. On peut supprimer ceux qu'aucun tag ne désigne plus (*Package registry → pulseview →* version → *Delete*).

### En cas de problème

| Message | Cause, remède |
|---|---|
| `7-Zip introuvable` | Installer 7-Zip, ou l'ajouter au `PATH`. |
| `Pas de pulseview.exe dans l'installeur` | sigrok a changé la structure de son installeur : ouvrir l'installeur avec 7-Zip et adapter l'étape 3 du script. |
| `Version de PulseView illisible` | `pulseview.exe --version` n'affiche plus `PulseView <version>` : adapter l'étape 4. |
| `… absent : le fabriquer d'abord` (avec `--upload`) | Le zip désigné par `get_pulseview.cmd` n'est pas à la racine : refaire l'étape 1. |
| `… empreinte …, get_pulseview.cmd attend …` (avec `--upload`) | Le zip à la racine n'est pas celui que désigne `get_pulseview.cmd` (`get_pulseview.cmd` revenu à une version committée, par exemple) : refaire l'étape 1. |
| `curl: (22) … 401` ou `403` au dépôt | Jeton absent, expiré, de mauvaise portée (il faut `api`) ou de rôle insuffisant. |
| `curl: (22) … 404` au dépôt | Registre de paquets désactivé sur le projet. |
| Côté élève : `empreinte SHA-256 obtenue … attendue …` | `get_pulseview.cmd` désigne un autre zip que celui déposé (zip refait après coup sans redéposer, ou fichier modifié dans le registre). Redéposer le zip dont l'empreinte est dans `get_pulseview.cmd`, ou refaire les étapes 1 à 5. |
| Côté élève : `Echec du telechargement` | Paquet pas encore déposé, nom de version différent, ou poste sans accès à `gitlab.com` (proxy du lycée). En dernier recours : copier le dossier `PulseView/` à la main, ou utiliser un partage réseau et `MICROPYTHONMCU_PULSEVIEW`. |
