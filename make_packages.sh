#!/bin/bash
# Empaquette la release construite par make_release.sh (dist/MicroPythonMCU) en
# trois archives téléchargeables, dans dist/packages :
#
#   MicroPythonMCU-<v>-src.zip               le module avec ses sources C, compilé
#                                            à la volée par omc (comme le dépôt)
#   MicroPythonMCU-<v>-om<om>-win64.zip      la release telle que la suite l'a
#                                            testée : runtime précompilé, suite
#                                            de vérification comprise
#   MicroPythonMCU-<v>-lib-om<om>-win64.zip  la même, prête à installer : dossier
#                                            « MicroPythonMCU <v> » à déposer dans
#                                            les bibliothèques d'OpenModelica, sans
#                                            les .mos ni run_all.sh
#
# ainsi que dist/packages/release.env (version et noms des archives). <om> est
# la version d'OpenModelica dont la toolchain a compilé le .a. Procédure de
# livraison complète : docs/publication.md.
#
#   ./make_release.sh && ./make_packages.sh
#   MicroPythonMCU/Resources/Verification/run_all.sh --release && ./make_packages.sh
#
# Avant de zipper la variante bibliothèque, un test de fumée la charge par son
# numéro de version depuis un dossier de bibliothèques temporaire et simule
# Examples.BasicBlink : c'est la seule variante que la suite ne teste pas telle
# quelle (nom de dossier versionné, chargement par loadModel).
#
# La variante sources est prise dans l'état courant du dépôt (fichiers suivis ou
# nouveaux, jamais les ignorés), avec le package.mo versionné de la release :
# lancer ce script juste après make_release.sh, sans modifier le dépôt entre-temps.

set -e
cd "$(dirname "$0")"
ROOT=$(pwd)
DIST="$ROOT/dist"
OUT="$DIST/packages"

if [ ! -f "$DIST/release.env" ] || [ ! -d "$DIST/MicroPythonMCU" ]; then
  echo "dist/ absent ou incomplet : lancer d'abord make_release.sh (ou run_all.sh --release)" >&2; exit 2
fi
. "$DIST/release.env"

if [ -z "$OPENMODELICAHOME" ]; then
  echo "OPENMODELICAHOME non positionné (cf. docs/tests.md)" >&2; exit 2
fi
OMH=$(cygpath -u "$OPENMODELICAHOME" 2>/dev/null || echo "$OPENMODELICAHOME")
export PATH="$OMH/bin:$OMH/tools/msys/ucrt64/bin:$PATH"

# Le tar de Git Bash (GNU) ne sait pas écrire de zip ; celui de Windows (bsdtar,
# livré depuis Windows 10) si, et le zip est ce qu'un utilisateur Windows ouvre
# sans outil supplémentaire.
BSDTAR="$(cygpath -u "${SYSTEMROOT:-C:\\Windows}")/System32/tar.exe"
zipdir() {  # zipdir <archive.zip> <dossier de départ> <entrée>...
  local out=$1 dir=$2; shift 2
  "$BSDTAR" -a -cf "$(cygpath -w "$out")" -C "$(cygpath -w "$dir")" "$@"
}

PKG_SRC="MicroPythonMCU-$VERSION-src.zip"
PKG_BIN="MicroPythonMCU-$VERSION-om$OM_VERSION-win64.zip"
PKG_LIB="MicroPythonMCU-$VERSION-lib-om$OM_VERSION-win64.zip"

WORK=$(mktemp -d)
trap 'rm -rf "$WORK"' EXIT
rm -rf "$OUT"
mkdir -p "$OUT"

# 1. Sources : le dépôt, avec le package.mo versionné (make_release.sh n'y touche
#    qu'à l'annotation version, contrairement aux Internal/*.mo qu'il réécrit).
mkdir "$WORK/src"
git ls-files -co --exclude-standard -z MicroPythonMCU | tar --null -T - -cf - | tar -xf - -C "$WORK/src"
cp "$DIST/MicroPythonMCU/package.mo" "$WORK/src/MicroPythonMCU/package.mo"
zipdir "$OUT/$PKG_SRC" "$WORK/src" MicroPythonMCU

# 2. Release testée, telle quelle.
zipdir "$OUT/$PKG_BIN" "$DIST" MicroPythonMCU BUILD_INFO.txt

# 3. Bibliothèque à installer : dossier nommé selon la convention Modelica
#    « <nom> <version> », pour que loadModel(MicroPythonMCU, {"<v>"}) et
#    uses(MicroPythonMCU(version = "<v>")) la trouvent. Les .py de Verification
#    restent : cinq exemples y prennent leur script.
mkdir "$WORK/lib"
LIBDIR="$WORK/lib/MicroPythonMCU $VERSION"
cp -r "$DIST/MicroPythonMCU" "$LIBDIR"
rm -f "$LIBDIR"/Resources/Verification/*.mos "$LIBDIR/Resources/Verification/run_all.sh"
cp "$DIST/BUILD_INFO.txt" "$LIBDIR/"

mkdir "$WORK/smoke"
cat > "$WORK/smoke/smoke.mos" <<EOF
setModelicaPath("$(cygpath -m "$WORK/lib");" + getModelicaPath()); getErrorString();
ok := loadModel(MicroPythonMCU, {"$VERSION"}); getErrorString();
simulate(MicroPythonMCU.Examples.BasicBlink, stopTime = 1.0, fileNamePrefix = "Smoke"); getErrorString();
v := val(mcu.GP0.v, 0.5, "Smoke_res.mat");
if ok and v > 2.0 then print("PASS: bibliothèque chargée par version et simulée\n"); else print("FAIL: test de fumée de la bibliothèque (chargée=" + String(ok) + ", GP0=" + String(v) + " V)\n"); end if;
EOF
# Journal nommé autrement que le fileNamePrefix : omc écrit Smoke.log, et Windows
# ne distingue pas la casse.
(cd "$WORK/smoke" && omc smoke.mos > omc_output.txt 2>&1) || true
if ! grep -q '^PASS' "$WORK/smoke/omc_output.txt"; then
  echo "Test de fumée de la variante bibliothèque en échec :" >&2
  tail -n 20 "$WORK/smoke/omc_output.txt" >&2
  exit 1
fi
grep '^PASS' "$WORK/smoke/omc_output.txt"
zipdir "$OUT/$PKG_LIB" "$WORK/lib" "MicroPythonMCU $VERSION"

{
  cat "$DIST/release.env"
  echo "PKG_SRC=$PKG_SRC"
  echo "PKG_BIN=$PKG_BIN"
  echo "PKG_LIB=$PKG_LIB"
} > "$OUT/release.env"

echo "Archives de la version $VERSION (OpenModelica $OM_VERSION) dans $OUT :"
(cd "$OUT" && ls -lh -- *.zip | awk '{print "  " $5 "  " $NF}')
