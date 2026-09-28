# Publier une version et la documentation

La documentation est publiée automatiquement par GitLab. Les versions de la bibliothèque se livrent à la main, avec deux scripts du dépôt. Le **pourquoi** de ce partage est dans [`requirements.md`](https://gitlab.com/bdelaup/modelica_micropython3/-/blob/main/requirements.md), décision « Publication de la documentation et livraison des versions ».

## La documentation

Le site est construit par [Zensical](https://zensical.org/) en deux langues, chacune décrite par sa configuration :

| Langue | Pages | Configuration | Adresse | Contenu |
|---|---|---|---|---|
| Français | `docs/fr/` | [`zensical.fr.toml`](https://gitlab.com/bdelaup/modelica_micropython3/-/blob/main/zensical.fr.toml) | `/fr/` | Guide utilisateur et référence interne |
| Anglais | `docs/en/` | [`zensical.en.toml`](https://gitlab.com/bdelaup/modelica_micropython3/-/blob/main/zensical.en.toml) | `/en/` | Guide utilisateur seulement |

[`make_docs.sh`](https://gitlab.com/bdelaup/modelica_micropython3/-/blob/main/make_docs.sh) construit les deux dans `public/`, plus `public/index.html`, qui renvoie vers la langue du navigateur. À chaque push sur `main`, le job `pages` de [`.gitlab-ci.yml`](https://gitlab.com/bdelaup/modelica_micropython3/-/blob/main/.gitlab-ci.yml) l'exécute et publie le résultat sur GitLab Pages, sur un runner partagé de GitLab : rien à installer ni à lancer.

Adresse : <https://bdelaup.gitlab.io/modelica_micropython3/>

### Réglages GitLab (une seule fois)

- *Deploy → Pages* : décocher **Use unique domain**. Sinon GitLab publie le site à une adresse générée, différente de `site_url` dans les configurations.
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

puis <http://localhost:8000>. La page se recharge à chaque enregistrement. `./make_docs.sh` seul fait la construction complète et stricte, comme la CI.

## Livrer une version

### Les trois archives

`make_release.sh` construit la release dans `dist/MicroPythonMCU` (runtime C précompilé, sans sources C). `make_packages.sh` en tire trois archives dans `dist/packages` :

| Archive | Contenu | Pour qui |
|---|---|---|
| `MicroPythonMCU-<v>-lib-om<OM>-win64.zip` | Dossier `MicroPythonMCU <v>` à décompresser dans `%APPDATA%\.openmodelica\libraries`, sans les `.mos` ni `run_all.sh` | Élèves et enseignants (voir [Installation](../guide/installation.md)) |
| `MicroPythonMCU-<v>-om<OM>-win64.zip` | La release telle que la suite l'a testée, suite de vérification comprise | Vérifier une installation |
| `MicroPythonMCU-<v>-src.zip` | Le module du dépôt, sources C comprises | Modifier la bibliothèque, autre version d'OpenModelica |

`<OM>` est la version d'OpenModelica dont la toolchain a compilé le runtime. Les archives précompilées ne valent que pour elle. Avant de zipper la variante `-lib`, `make_packages.sh` la charge par son numéro de version (`loadModel(MicroPythonMCU, {"<v>"})`) et simule `Examples.BasicBlink` : c'est la seule variante que la suite ne teste pas telle quelle.

### Numéro de version

Le dépôt ne porte pas de numéro de version : **le tag `vX.Y.Z` fait foi**. `make_release.sh` injecte `version = "X.Y.Z"` dans l'annotation de `package.mo` de la release seulement. Il prend `VERSION` s'il est positionné, sinon `git describe` : `1.3.0` sur le commit du tag `v1.3.0`, `1.3.0-2-gabc1234` deux commits plus loin, `0.0.0-gabc1234` avant le premier tag, suffixe `-dirty` si le dépôt a des modifications non commitées.

| Changement | Exemple | Version |
|---|---|---|
| Un modèle ou un script existant d'un utilisateur peut cesser de fonctionner | paramètre renommé, connecteur supprimé, comportement du shim modifié | **majeure** : `1.3.0` → `2.0.0` |
| Nouvelle fonction, sans rien casser | nouveau périphérique, nouvelle méthode `machine` | **mineure** : `1.3.0` → `1.4.0` |
| Correction | bug du runtime, documentation | **correctif** : `1.3.0` → `1.3.1` |

### Procédure

Dans Git Bash, à la racine du dépôt :

1. Partir d'un dépôt propre : tout commité (`git status` vide). `make_release.sh` embarque aussi les fichiers non suivis et non ignorés, un dossier de brouillon se retrouverait dans l'archive.
2. Construire, tester et empaqueter, avec la version d'OpenModelica visée et le numéro choisi :

    ```
    export OPENMODELICAHOME="D:/Programmes/OpenModelica1.27.1-64bit"
    export VERSION=1.3.0
    MicroPythonMCU/Resources/Verification/run_all.sh --release
    ./make_packages.sh
    ```

    La suite doit afficher `27/27 PASS`. `make_packages.sh` s'arrête si le test de fumée échoue.
3. Poser et pousser le tag :

    ```
    git tag -a v1.3.0 -m "Nouveautés de la version"
    git push origin v1.3.0
    ```

4. Créer la release dans GitLab : *Deploy → Releases → New release*, choisir le tag `v1.3.0`, écrire les notes, puis **glisser les trois zips de `dist/packages` dans la zone des notes**. GitLab les téléverse et insère leurs liens de téléchargement.
5. Vérifier la release en téléchargeant l'archive `-lib` et en suivant [Installation](../guide/installation.md).
