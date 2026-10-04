#!/bin/bash
# Régénère MicroPythonMCU/Resources/Include/pyimports.h : la liste des symboles
# de python312.dll qu'utilise le runtime C. pyhost.c en tire sa table d'import,
# remplie par GetProcAddress après avoir chargé la DLL de Resources/PythonRuntime
# par son chemin absolu - le modèle n'est plus lié à python312 (cf.
# requirements.md, décision « Distribution Python embarquée »).
#
#   ./make_pyimports.sh
#
# À relancer quand le code C se met à utiliser une nouvelle fonction ou donnée
# de l'API Python : la simulation échoue alors à l'édition de liens avec
# « undefined reference to `__imp_PyXxx' ». Le fichier produit est versionné.
#
# Méthode : les trois chapeaux sont compilés en une unité, sans la table
# (PYHOST_NO_IMPORT_TABLE) et sans optimisation (aucune référence élaguée) ;
# les références __imp_* restées non résolues sont les symboles importés, dont
# on ne garde que ceux que python312.dll exporte (les autres viennent de
# kernel32, du runtime C ou d'OpenModelica).

set -e
cd "$(dirname "$0")"
ROOT=$(pwd)
INC="$ROOT/MicroPythonMCU/Resources/Include"
DLL="$ROOT/MicroPythonMCU/Resources/PythonRuntime/python312.dll"
OUT="$INC/pyimports.h"

if [ -z "$OPENMODELICAHOME" ]; then
  echo "OPENMODELICAHOME non positionné (cf. docs/fr/interne/outils-windows.md)" >&2; exit 2
fi
OMH=$(cygpath -u "$OPENMODELICAHOME" 2>/dev/null || echo "$OPENMODELICAHOME")
BIN="$OMH/tools/msys/ucrt64/bin"
export PATH="$BIN:$PATH"   # cc1 a besoin des DLL du toolchain

WORK=$(mktemp -d)
trap 'rm -rf "$WORK"' EXIT

cat > "$WORK/all.c" <<'EOF'
#include "PyRuntimeImpl.c"
#include "UartDeviceImpl.c"
#include "I2cDeviceImpl.c"
EOF
"$BIN/gcc" -O0 -DPYHOST_NO_IMPORT_TABLE -I"$INC" -I"$OMH/include/omc/c" \
  -c -o "$WORK/all.o" "$WORK/all.c"

"$BIN/nm" -u "$WORK/all.o" | sed -n 's/^ *U __imp_//p' | sort -u > "$WORK/used"
# Table des exports : lignes "[   2] +base[   3]  0002 PyArg_ParseTuple".
"$BIN/objdump" -p "$DLL" | awk '/^\s*\[ *[0-9]+\] \+base\[/ { print $NF }' | sort -u > "$WORK/exported"
comm -12 "$WORK/used" "$WORK/exported" > "$WORK/imports"

if [ ! -s "$WORK/imports" ]; then
  echo "aucun symbole Python trouvé : compilation ou lecture des exports en échec ?" >&2; exit 1
fi

{
  echo "/* GÉNÉRÉ par make_pyimports.sh - ne pas modifier à la main."
  echo "   Symboles de python312.dll utilisés par le runtime C : pyhost.c définit"
  echo "   pour chacun le pointeur __imp_<nom> que le code compilé lit (l'API Python"
  echo "   est déclarée dllimport), et le remplit par GetProcAddress. */"
  echo "#define PYHOST_IMPORTS(X) \\"
  sed 's/.*/    X(&) \\/' "$WORK/imports"
  echo "    /* fin */"
} > "$OUT"

echo "$OUT : $(wc -l < "$WORK/imports") symboles"
