#!/usr/bin/env bash
# Construit le site de documentation bilingue dans public/ (ce que publie GitLab
# Pages) : public/fr/ (zensical.fr.toml, site complet), public/en/
# (zensical.en.toml, guide utilisateur seulement) et public/index.html, qui
# renvoie vers l'anglais, langue par défaut du site. Appelé tel quel par
# .gitlab-ci.yml.
#
#   ./make_docs.sh              # construction stricte des deux langues
#   ./make_docs.sh serve [en|fr]  # aperçu local d'une langue, anglais par défaut (http://localhost:8000)
#
# Prérequis : pip install zensical. Les images n'existent qu'une fois, dans
# docs/fr/images/ : le site anglais en reçoit une copie (docs/en/images/, ignoré
# par git), refaite à chaque appel.
set -euo pipefail
cd "$(dirname "$0")"

sync_images() {
  rm -rf docs/en/images
  cp -r docs/fr/images docs/en/images
}

case "${1:-build}" in
  build)
    sync_images
    rm -rf public
    zensical build --clean --strict -f zensical.fr.toml
    zensical build --clean --strict -f zensical.en.toml
    cat > public/index.html <<'EOF'
<!doctype html>
<html lang="en">
<head>
<meta charset="utf-8">
<title>MicroPythonMCU</title>
<meta http-equiv="refresh" content="0; url=en/">
<link rel="canonical" href="en/">
</head>
<body>
<p><a href="en/">English documentation</a> · <a href="fr/">Documentation en français</a></p>
</body>
</html>
EOF
    echo "Site construit dans public/ (fr/ et en/)"
    ;;
  serve)
    lang="${2:-en}"
    sync_images
    exec zensical serve -f "zensical.$lang.toml"
    ;;
  *)
    echo "usage: $0 [build | serve [en|fr]]" >&2
    exit 2
    ;;
esac
