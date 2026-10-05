#!/bin/bash
# (Re)construit MicroPythonMCU/Resources/Debugpy/ : le débogueur debugpy
# vendoré, qu'utilise MCU.debugEnabled (cf. requirements.md, décision
# « Débogage du programme (debugpy + VS Code) »). Le résultat est versionné.
#
#   tools/make_debugpy.sh                 # télécharge la roue par pip
#   tools/make_debugpy.sh chemin/vers/debugpy-X.Y.Z-cp312-cp312-win_amd64.whl
#
# Version figée ci-dessous : en changer, c'est rejouer verify_60 à verify_62.
# La roue cp312 win_amd64 correspond à la distribution Python embarquée
# (Resources/PythonRuntime, CPython 3.12 64 bits).
#
# Allègement (~28 Mo -> ~5 Mo) : on retire ce qui ne sert qu'à s'attacher à
# un process par son PID (injection de DLL, winappdbg, symboles .pdb, binaires
# 32 bits et non-Windows), les sources C/C++/Cython des modules compilés, les
# tests et les caches. Le reste est la roue telle quelle.

set -e
VERSION=1.8.20
cd "$(dirname "$0")/.."   # racine du dépôt
DEST="MicroPythonMCU/Resources/Debugpy"

WORK=$(mktemp -d)
trap 'rm -rf "$WORK"' EXIT

if [ -n "$1" ]; then
  WHEEL="$1"
else
  python -m pip download "debugpy==$VERSION" --no-deps --only-binary=:all: \
    --python-version 3.12 --platform win_amd64 -d "$WORK" >/dev/null
  WHEEL=$(ls "$WORK"/debugpy-"$VERSION"-*.whl)
fi
python -m zipfile -e "$WHEEL" "$WORK/x"

PKG="$WORK/x/debugpy"
ATTACH="$PKG/_vendored/pydevd/pydevd_attach_to_process"
rm -rf "$ATTACH/winappdbg" "$ATTACH/common" "$ATTACH/linux_and_mac" "$ATTACH/windows"
find "$ATTACH" -maxdepth 1 -type f ! -name "*.py" ! -name "attach_amd64.dll" ! -name "run_code_on_dllmain_amd64.dll" -delete
find "$PKG" -type d \( -name "__pycache__" -o -name "tests" -o -name "tests_*" \) -prune -exec rm -rf {} +
find "$PKG" -type f \( -name "*.c" -o -name "*.cpp" -o -name "*.h" -o -name "*.hpp" -o -name "*.pyx" \
  -o -name "*.pxd" -o -name "*.pdb" -o -name "*.so" -o -name "*.dylib" -o -name "*.exe" \) -delete

rm -rf "$DEST"
mkdir -p "$DEST"
cp -r "$PKG" "$DEST/"
cp "$WORK"/x/debugpy-"$VERSION".dist-info/licenses/LICENSE "$DEST/LICENSE"
echo "debugpy $VERSION -> $DEST ($(du -sh "$DEST" | cut -f1))"
