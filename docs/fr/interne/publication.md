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

puis <http://localhost:8000>. La page se recharge à chaque enregistrement. `./make_docs.sh` seul fait la construction complète et stricte, comme la CI.

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

    Toutes les lignes doivent être `PASS`.
3. Poser et pousser le tag :

    ```
    git tag -a v1.3.0 -m "Nouveautés de la version"
    git push origin v1.3.0
    ```

4. Vérifier : télécharger le zip du tag depuis la [page des tags](https://gitlab.com/bdelaup/modelica_micropython3/-/tags) et suivre [Installation](../guide/installation.md).

Les notes de version, si on en veut, se rédigent dans le message du tag ou dans une *Release* GitLab créée sur ce tag, sans fichier joint.

## Mettre à jour un composant vendoré

- **Débogueur `debugpy`** (`Resources/Debugpy/`, utilisé par `MCU.debugEnabled`) : changer `VERSION` dans `make_debugpy.sh`, puis lancer `./make_debugpy.sh` à la racine (pip télécharge la roue `cp312` `win_amd64`, le script l'allège et remplace le dossier). Rejouer `verify_60` à `verify_63` et faire un essai dans VS Code avant de livrer : la bibliothèque s'appuie sur quelques rouages internes de pydevd (`_WaitForConnectionThread`, lecteur `reader.sock`, `FilesFiltering._get_default_library_roots`), cf. `cycle-de-vie.md`, section 5.
