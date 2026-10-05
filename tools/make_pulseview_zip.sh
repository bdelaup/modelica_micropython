#!/bin/bash
# Fabrique le zip de la copie portable de PulseView que télécharge
# get_pulseview.cmd, à partir du build nightly officiel de sigrok.org (cf.
# requirements.md, décision « Distribution de PulseView »). Ni le zip ni rien
# de PulseView n'est suivi par git : le zip est publié à part, dans le
# registre de paquets (Generic Package Registry) du projet GitLab.
#
#   tools/make_pulseview_zip.sh                        # nightly du jour -> zip + empreinte
#   tools/make_pulseview_zip.sh --installer setup.exe  # à partir d'un installeur déjà téléchargé
#   tools/make_pulseview_zip.sh --upload               # dépose le zip DÉJÀ fabriqué (GITLAB_TOKEN)
#
# Fabrication et dépôt sont séparés : entre les deux, on valide ce PulseView
# (session .pvs), et c'est exactement ce zip-là qui est déposé, celui dont
# get_pulseview.cmd porte l'empreinte - le nightly a pu changer entre-temps.
#
# Étapes : téléchargement de l'installeur Windows 64 bits (NSIS), extraction
# SANS l'exécuter par 7-Zip (aucun droit administrateur, rien d'installé),
# retrait de ce qui ne sert pas à lire un VCD (exemples, pilotes USB zadig,
# désinstalleur), version lue par « pulseview --version », zip par le tar.exe
# de Windows (bsdtar ; le tar de Git Bash n'écrit pas de zip), réécriture de
# PV_VERSION et PV_SHA256 dans get_pulseview.cmd, à committer.
#
# Version du paquet : <version de PulseView>-<date du build>, par exemple
# 0.5.0-e2fe9df-20261005. Le nightly est recompilé chaque jour avec les
# bibliothèques sigrok du moment, souvent sans que la version de PulseView
# change : la date (Last-Modified du serveur) distingue deux builds.
#
# Prérequis : 7-Zip (https://www.7-zip.org, dans le PATH ou dans Program
# Files), Python (réécriture de get_pulseview.cmd). Pour --upload :
# GITLAB_TOKEN, jeton d'accès personnel ou de projet, portée « api », rôle
# Developer au moins. Le projet étant public, le téléchargement est anonyme.

set -e
NIGHTLY_URL="https://sigrok.org/download/binary/pulseview/pulseview-NIGHTLY-x86_64-release-installer.exe"
PROJECT_API="https://gitlab.com/api/v4/projects/bdelaup%2Fmodelica_micropython3"
cd "$(dirname "$0")/.."   # racine du dépôt
WINTAR="$(cygpath "$SYSTEMROOT")/System32/tar.exe"

UPLOAD=0
INSTALLER=""
while [ $# -gt 0 ]; do
  case "$1" in
    --upload) UPLOAD=1 ;;
    --installer) shift; INSTALLER="$1" ;;
    *) echo "usage: $0 [--installer setup.exe] | --upload" >&2; exit 2 ;;
  esac
  shift
done

# Dépôt : le zip désigné par get_pulseview.cmd, s'il a bien l'empreinte
# attendue - jamais un zip refait à la volée
if [ "$UPLOAD" = 1 ]; then
  if [ -z "$GITLAB_TOKEN" ]; then
    echo "--upload : GITLAB_TOKEN vide (jeton GitLab, portée api)" >&2
    exit 1
  fi
  VERSION=$(sed -n 's/^set "PV_VERSION=\(.*\)"\r*$/\1/p' get_pulseview.cmd)
  EXPECTED=$(sed -n 's/^set "PV_SHA256=\(.*\)"\r*$/\1/p' get_pulseview.cmd)
  FILE="pulseview-$VERSION-win64-portable.zip"
  if [ ! -f "$FILE" ]; then
    echo "$FILE absent : le fabriquer d'abord (tools/make_pulseview_zip.sh)" >&2
    exit 1
  fi
  SHA=$(sha256sum "$FILE" | cut -d' ' -f1)
  if [ "$SHA" != "$EXPECTED" ]; then
    echo "$FILE : empreinte $SHA, get_pulseview.cmd attend $EXPECTED - refaire le zip" >&2
    exit 1
  fi
  URL="$PROJECT_API/packages/generic/pulseview/$VERSION/$FILE"
  curl --fail --show-error --progress-bar --header "PRIVATE-TOKEN: $GITLAB_TOKEN" --upload-file "$FILE" "$URL"
  echo
  echo "Déposé : $URL"
  echo "Reste à committer get_pulseview.cmd"
  exit 0
fi

# 7-Zip : dans le PATH, sinon à son emplacement d'installation habituel
SEVENZIP=$(command -v 7z || true)
for d in "$ProgramW6432" "$PROGRAMFILES" "$LOCALAPPDATA/Programs"; do
  if [ -z "$SEVENZIP" ] && [ -n "$d" ] && [ -x "$(cygpath -u "$d")/7-Zip/7z.exe" ]; then
    SEVENZIP="$(cygpath -u "$d")/7-Zip/7z.exe"
  fi
done
if [ -z "$SEVENZIP" ]; then
  echo "7-Zip introuvable : l'installer (https://www.7-zip.org), il ouvre l'installeur sans l'exécuter" >&2
  exit 1
fi

WORK=$(mktemp -d)
trap 'rm -rf "$WORK"' EXIT

# 1. Installeur. curl -R donne au fichier la date du serveur (Last-Modified),
#    qui date le build.
if [ -z "$INSTALLER" ]; then
  echo "Téléchargement du nightly : $NIGHTLY_URL"
  INSTALLER="$WORK/pulseview-installer.exe"
  curl --fail --location --remote-time --progress-bar --output "$INSTALLER" "$NIGHTLY_URL"
fi
BUILD_DATE=$(date -r "$INSTALLER" +%Y%m%d)

# 2. Extraction sans exécution, puis tri
#    Directement sous le nom final : un renommage après le lancement de
#    pulseview.exe (étape 3) échoue, un fichier y reste un instant verrouillé.
X="$WORK/PulseView"
"$SEVENZIP" x -y -o"$(cygpath -w "$X")" "$(cygpath -w "$INSTALLER")" > "$WORK/7z.log" \
  || { cat "$WORK/7z.log" >&2; exit 1; }
if [ ! -f "$X/pulseview.exe" ]; then
  echo "Pas de pulseview.exe dans l'installeur : son contenu a changé" >&2
  exit 1
fi
rm -rf "$X/\$PLUGINSDIR" "$X/Uninstall.exe" "$X/examples" "$X"/zadig*.exe

# 3. Version : « PulseView 0.5.0-git-e2fe9df » -> 0.5.0-e2fe9df. Le lancer
#    compile les décodeurs Python : leurs __pycache__ sont retirés ensuite.
"$X/pulseview.exe" --version 2>/dev/null | grep -v "^sr: " > "$WORK/version.txt" || true
PV=$(sed -n 's/^PulseView \([^ ]*\).*/\1/p' "$WORK/version.txt" | head -1 | tr -d '\r')
if [ -z "$PV" ]; then
  echo "Version de PulseView illisible (pulseview.exe --version)" >&2
  exit 1
fi
find "$X" -type d -name __pycache__ -prune -exec rm -rf {} +
VERSION="$(echo "$PV" | sed 's/-git-/-/')-$BUILD_DATE"
FILE="pulseview-$VERSION-win64-portable.zip"

# 4. GPLv3 : COPYING est dans l'installeur ; on y joint où trouver les sources
#    et la version exacte de chaque bibliothèque
{
  echo "PulseView $PV, Windows nightly build of $BUILD_DATE (sigrok project),"
  echo "redistributed unchanged for MicroPythonMCU (https://gitlab.com/bdelaup/modelica_micropython3)."
  echo "Files of the official installer $NIGHTLY_URL"
  echo "without the examples, the zadig USB driver tools and the uninstaller."
  echo
  echo "PulseView, libsigrok and libsigrokdecode are free software under the GNU GPL"
  echo "version 3 (see COPYING). Their source code, at the versions listed below:"
  echo "  https://sigrok.org/gitweb/?p=pulseview.git"
  echo "  https://sigrok.org/gitweb/?p=libsigrok.git"
  echo "  https://sigrok.org/gitweb/?p=libsigrokdecode.git"
  echo "  mirror: https://github.com/sigrokproject"
  echo
  echo "Output of pulseview --version:"
  tr -d '\r' < "$WORK/version.txt"
} > "$X/SOURCES.txt"

# 5. Zip à la racine (ignoré par git)
rm -f pulseview-*-win64-portable.zip
"$WINTAR" -a -c -f "$(cygpath -w "$PWD/$FILE")" -C "$(cygpath -w "$WORK")" PulseView
SHA=$(sha256sum "$FILE" | cut -d' ' -f1)
SIZE=$(du -m "$FILE" | cut -f1)

# 6. get_pulseview.cmd est en CRLF (.gitattributes) : réécriture par Python,
#    qui garde les fins de ligne (sed -i de Git Bash les perdrait)
python - "$VERSION" "$SHA" <<'EOF'
import re, sys
version, sha = sys.argv[1], sys.argv[2]
path = "get_pulseview.cmd"
s = open(path, encoding="ascii", newline="").read()
s = re.sub(r'set "PV_VERSION=[^"]*"', 'set "PV_VERSION=%s"' % version, s, count=1)
s = re.sub(r'set "PV_SHA256=[^"]*"', 'set "PV_SHA256=%s"' % sha, s, count=1)
open(path, "w", encoding="ascii", newline="").write(s)
EOF

echo "PulseView $PV, build du $BUILD_DATE"
echo "$FILE : $SIZE Mo, SHA-256 $SHA"
echo "get_pulseview.cmd mis à jour (PV_VERSION, PV_SHA256) : à committer une fois le zip déposé"
echo "Valider ce PulseView, puis le déposer : GITLAB_TOKEN=... tools/make_pulseview_zip.sh --upload"
