#!/bin/bash
# Construit la version distribuée de la bibliothèque dans dist/MicroPythonMCU :
# le runtime C est précompilé une fois pour toutes en
# Resources/Library/win64/libmicropythonmcu.a, et les sources C ne sont pas
# livrées. Outil de DISTRIBUTION (make_packages.sh en tire ensuite les archives
# téléchargeables, cf. docs/fr/interne/publication.md), et support de la
# NON-RÉGRESSION : run_all.sh --release
# l'appelle puis lance la suite dans dist/, pour tester ce qui est réellement
# livré. Il n'accélère pas les tests : le gain de compilation mesuré est
# négligeable (~0,3 s par modèle, le fichier principal généré par omc reste le
# plus long à compiler, en parallèle) - pendant le travail, la suite tourne sur
# le dépôt.
#
#   ./make_release.sh
#   MicroPythonMCU/Resources/Verification/run_all.sh --release   # release + suite
#
# Numéro de version : $VERSION s'il est fourni (livraison : export VERSION=X.Y.Z),
# sinon déduit de git describe (1.2.0 sur un tag, 1.2.0-3-gabc1234 trois commits
# plus loin, 0.0.0-gabc1234 avant le premier tag ; suffixe -dirty si le dépôt a
# des modifications non commitées). Il est injecté dans l'annotation version de
# package.mo de la release seulement : le dépôt n'en porte pas, le tag fait foi.
# Il est aussi écrit dans dist/release.env, avec la version d'OpenModelica, pour
# make_packages.sh.
#
# Le dépôt reste la version de développement (sources C incluses à la volée par
# les annotations Include) ; dist/ est ignoré par git et se reconstruit à la
# demande. La release ne contient pas les sources C : pour recompiler, on repart
# du dépôt. Elle garde Resources/Verification (la suite s'exécute dedans).
#
# La release est assemblée dans un dossier temporaire, puis seuls les fichiers
# dont le contenu a changé sont recopiés dans dist/ : le dépôt vit dans OneDrive,
# qui verrouille brièvement chaque fichier nouveau ou modifié le temps de le
# téléverser (« Device or resource busy ») - autant ne rien réécrire d'inutile.

set -e
cd "$(dirname "$0")"
ROOT=$(pwd)
DIST="$ROOT/dist"
LIB="$DIST/MicroPythonMCU"

# Toolchain d'OpenModelica : le .a doit être produit par le même compilateur que
# celui qui liera les modèles.
if [ -z "$OPENMODELICAHOME" ]; then
  echo "OPENMODELICAHOME non positionné (cf. docs/fr/interne/tests.md)" >&2; exit 2
fi
OMH=$(cygpath -u "$OPENMODELICAHOME" 2>/dev/null || echo "$OPENMODELICAHOME")
CC="$OMH/tools/msys/ucrt64/bin/clang"
AR="$OMH/tools/msys/ucrt64/bin/llvm-ar"
OM_VERSION=$("$OMH/bin/omc" --version | sed -E 's/^[^0-9]*([0-9][0-9.]*).*/\1/')

if [ -z "$VERSION" ]; then
  VERSION=$(git describe --tags --match 'v[0-9]*' --dirty 2>/dev/null | sed 's/^v//')
  [ -n "$VERSION" ] || VERSION="0.0.0-g$(git describe --always --dirty)"
fi

WORK=$(mktemp -d)
trap 'rm -rf "$WORK"' EXIT
STAGE="$WORK/MicroPythonMCU"

# 1. Copie des fichiers du dépôt (suivis ou nouveaux, jamais les ignorés : pas
#    d'artefact de compilation ni de copie de système de fichiers).
git ls-files -co --exclude-standard -z MicroPythonMCU | tar --null -T - -cf - | tar -xf - -C "$WORK"
sed -i "s/^  uses(Modelica(/  version = \"$VERSION\",\n  uses(Modelica(/" "$STAGE/package.mo"
if [ "$(grep -c '^  version = ' "$STAGE/package.mo")" != 1 ]; then
  echo "package.mo : annotation version non injectée (ligne uses(Modelica(...)) introuvable ?)" >&2; exit 1
fi

# 2. Runtime C compilé en UNE unité, comme lorsqu'omc inclut les chapeaux dans un
#    même fichier : les parties partagées (pyhost.c, uartcore.c, devscript.c) n'y
#    existent qu'une fois, grâce à leurs gardes d'inclusion.
INC="$ROOT/MicroPythonMCU/Resources/Include"
cat > "$WORK/micropythonmcu.c" <<'EOF'
#include "PyRuntimeImpl.c"
#include "UartDeviceImpl.c"
#include "I2cDeviceImpl.c"
#include "StringToCharCodes.c"
EOF
"$CC" -O2 -msse2 -mfpmath=sse -mstackrealign -I"$INC" -I"$OMH/include/omc/c" \
  -c -o "$WORK/micropythonmcu.o" "$WORK/micropythonmcu.c"
mkdir -p "$STAGE/Resources/Library/win64"   # absent du dépôt, qui ne lie aucune bibliothèque
"$AR" rcsD "$STAGE/Resources/Library/win64/libmicropythonmcu.a" "$WORK/micropythonmcu.o"

# 3. Sources C retirées : seuls restent les en-têtes publics, inclus par le code
#    généré à la place des sources.
find "$STAGE/Resources/Include" -mindepth 1 -maxdepth 1 \
  ! -name PyRuntimeImpl.h ! -name UartDeviceImpl.h ! -name I2cDeviceImpl.h \
  -exec rm -rf {} +

# 4. Annotations des fonctions externes : en-tête au lieu de la source, et
#    bibliothèque précompilée ajoutée au Library = "-lwinpthread" des sources (un
#    seul Library par annotation : il devient un tableau), LibraryDirectory à la
#    suite de chaque IncludeDirectory. Pas
#    de python312 à lier : le .a charge lui-même la DLL de Resources/PythonRuntime
#    (pyhost.c). StringToCharCodes n'a pas d'en-tête : son prototype tient dans
#    l'annotation.
for f in "$STAGE"/Internal/*.mo; do
  sed -i \
    -e 's/Include = "#include \\"\(PyRuntimeImpl\|UartDeviceImpl\|I2cDeviceImpl\)\.c\\""/Include = "#include \\"\1.h\\""/' \
    -e 's/Include = "#include \\"StringToCharCodes\.c\\""/Include = "void string_to_char_codes(const char* s, int n, int* codes);"/' \
    -e 's/Library = "-lwinpthread"/Library = {"micropythonmcu", "-lwinpthread"}/' \
    -e 's/IncludeDirectory = "modelica:\/\/MicroPythonMCU\/Resources\/Include")/IncludeDirectory = "modelica:\/\/MicroPythonMCU\/Resources\/Include",\n      LibraryDirectory = "modelica:\/\/MicroPythonMCU\/Resources\/Library\/win64")/' \
    "$f"
done
if grep -rn 'Impl\.c\|StringToCharCodes\.c' "$STAGE" --include=*.mo; then
  echo "Annotation non convertie ci-dessus : la release incluerait une source absente" >&2; exit 1
fi
if [ "$(grep -rc 'IncludeDirectory' "$STAGE"/Internal/*.mo | awk -F: '{s+=$2} END {print s}')" != \
     "$(grep -rc 'Library = {"micropythonmcu", "-lwinpthread"}' "$STAGE"/Internal/*.mo | awk -F: '{s+=$2} END {print s}')" ]; then
  echo "Annotation IncludeDirectory sans Library = {\"micropythonmcu\", \"-lwinpthread\"} : la release ne lierait pas son runtime" >&2; exit 1
fi

# 5. Synchronisation vers dist/ : copie des seuls fichiers changés, suppression
#    de ceux qui n'existent plus. Nouvelles tentatives si OneDrive tient un
#    fichier verrouillé.
retry() {
  local i
  for i in 1 2 3 4 5 6 7 8 9 10; do "$@" 2>/dev/null && return 0; sleep 1; done
  "$@"
}
#    Comparaison par empreintes calculées en une passe (lancer un processus par
#    fichier coûte cher sous Windows : ~20 s pour les ~420 fichiers).
mkdir -p "$LIB"
hashes() { (cd "$1" && find . -type f -print0 | xargs -0 md5sum | sed 's/^\\//' | sort -k2); }
hashes "$STAGE" > "$WORK/stage.md5"
hashes "$LIB" > "$WORK/dist.md5"
# Fichiers nouveaux ou modifiés : lignes (empreinte + chemin) absentes de dist/.
comm -23 <(sort "$WORK/stage.md5") <(sort "$WORK/dist.md5") | cut -c35- > "$WORK/copy.lst"
# Fichiers disparus : chemins de dist/ absents de la release.
comm -13 <(cut -c35- "$WORK/stage.md5" | sort) <(cut -c35- "$WORK/dist.md5" | sort) > "$WORK/remove.lst"
if [ -s "$WORK/copy.lst" ]; then
  retry sh -c 'tar -C "$1" -cf - -T "$2" | tar -xf - -C "$3"' _ "$STAGE" "$WORK/copy.lst" "$LIB"
fi
if [ -s "$WORK/remove.lst" ]; then
  tr '\n' '\0' < "$WORK/remove.lst" > "$WORK/remove0.lst"
  (cd "$LIB" && retry xargs -0 -a "$WORK/remove0.lst" rm -f)
  find "$LIB" -depth -mindepth 1 -type d -empty -delete 2>/dev/null || true
fi
changed=$(wc -l < "$WORK/copy.lst")
removed=$(wc -l < "$WORK/remove.lst")

# 6. Traçabilité : de quel état du dépôt vient cette release.
{
  echo "MicroPythonMCU - version distribuée (runtime C précompilé)"
  echo "Version      : $VERSION"
  echo "Construite le : $(date '+%Y-%m-%d %H:%M')"
  echo "Commit       : $(git rev-parse --short HEAD)$(git diff --quiet HEAD -- MicroPythonMCU || echo ' + modifications non commitées')"
  echo "Compilateur  : $("$CC" --version | head -1)"
  echo "OpenModelica : $OM_VERSION"
} > "$DIST/BUILD_INFO.txt"
printf 'VERSION=%s\nOM_VERSION=%s\n' "$VERSION" "$OM_VERSION" > "$DIST/release.env"

echo "Release $VERSION à jour : $LIB ($changed fichier(s) copié(s), $removed supprimé(s))"
