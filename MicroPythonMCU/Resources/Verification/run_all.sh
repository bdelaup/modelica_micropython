#!/bin/bash
# Lance les scénarios de vérification (verify_*.mos) en parallèle et affiche un
# récapitulatif PASS/FAIL avec la durée de chaque script. Voir docs/fr/interne/tests.md.
#
#   ./run_all.sh                       # toute la suite, 4 exécutions simultanées
#   ./run_all.sh -j 2                  # 2 exécutions simultanées
#   ./run_all.sh verify_08_pwm.mos ... # seulement ces scripts
#   ./run_all.sh -k                    # garder artefacts de compilation et journaux
#   ./run_all.sh --release             # non-régression : construit la release
#                                      # locale (make_release.sh) et y lance la suite
#
# Code de sortie : 0 si tout passe, 1 sinon (2 si la suite n'a pas pu démarrer).
#
# Pendant le travail, la suite tourne sur le dépôt (sources C incluses à la
# volée). La NON-RÉGRESSION après une modification qui le mérite se fait avec
# --release, sur ce qui est réellement livré : runtime C précompilé, en-têtes
# publics, annotations réécrites par make_release.sh - des défauts que la suite
# sur le dépôt ne peut pas voir. Même durée de suite dans les deux cas (cf.
# requirements.md, décision « Structure du package et interface C »).
#
# Les .mos restent autonomes et lançables un par un (omc verify_0X_....mos) ; ce
# script ne fait que les orchestrer. Deux scripts qui partagent des fichiers ne
# doivent pas tourner en même temps : ceux qui ont le même fileNamePrefix
# (mêmes BasicBlink.exe, BasicBlink_res.mat...) et ceux qui manipulent les
# copies de système de fichiers (ils effacent tous les dossiers mcu_datalogger_*
# et écrivent fs_copies.txt). Ils sont regroupés automatiquement en une chaîne
# exécutée séquentiellement ; les chaînes, elles, tournent en parallèle.

JOBS=4
KEEP=0
RELEASE=0
# getopts ne connaît pas les options longues : --release est retiré à part.
ARGS=()
for a in "$@"; do
  if [ "$a" = "--release" ]; then RELEASE=1; else ARGS+=("$a"); fi
done
set -- "${ARGS[@]}"
while getopts "j:kh" opt; do
  case $opt in
    j) JOBS=$OPTARG ;;
    k) KEEP=1 ;;
    *) sed -n '2,13p' "$0" | sed 's/^# \{0,1\}//'; exit 2 ;;
  esac
done
shift $((OPTIND - 1))

cd "$(dirname "$0")" || exit 2

# omc absent du PATH mais OPENMODELICAHOME positionné : compléter le PATH (omc et
# le toolchain MinGW qu'il appelle pour compiler), cf. docs/fr/interne/tests.md.
if ! command -v omc >/dev/null 2>&1 && [ -n "$OPENMODELICAHOME" ]; then
  OMH=$(cygpath -u "$OPENMODELICAHOME" 2>/dev/null || echo "$OPENMODELICAHOME")
  export PATH="$OMH/bin:$OMH/tools/msys/ucrt64/bin:$PATH"
fi
if ! command -v omc >/dev/null 2>&1; then
  echo "omc introuvable : l'ajouter au PATH ou positionner OPENMODELICAHOME (cf. docs/fr/interne/tests.md)" >&2
  exit 2
fi

# --release : reconstruire dist/ depuis l'état COURANT du dépôt (modifications
# non commitées comprises), puis déléguer à la copie de ce script dans la
# release, avec les mêmes options et les mêmes scripts. BUILD_INFO.txt est
# réaffiché après le récapitulatif : un résultat doit dire sur quoi il a tourné.
if [ $RELEASE -eq 1 ]; then
  ROOT=$(cd ../../.. && pwd)
  if [ ! -f "$ROOT/make_release.sh" ]; then
    echo "--release se lance depuis le dépôt (make_release.sh introuvable) - dans une release, lancer ./run_all.sh sans --release" >&2
    exit 2
  fi
  s=$(date +%s%N)
  "$ROOT/make_release.sh" || { echo "Construction de la release en échec : suite non lancée" >&2; exit 2; }
  printf "Release construite en %.1f s\n\n" "$(awk "BEGIN{print ($(date +%s%N)-$s)/1e9}")"
  FWD=(-j "$JOBS")
  [ $KEEP -eq 1 ] && FWD+=(-k)
  "$ROOT/dist/MicroPythonMCU/Resources/Verification/run_all.sh" "${FWD[@]}" "$@"
  status=$?
  echo
  echo "Suite exécutée sur la release locale :"
  sed 's/^/  /' "$ROOT/dist/BUILD_INFO.txt"
  exit $status
fi

if [ $# -gt 0 ]; then TESTS=("$@"); else TESTS=(verify_*.mos); fi

# Clé de chaîne : "fs" pour les scripts qui touchent aux copies de système de
# fichiers, sinon le premier fileNamePrefix du script.
chain_key() {
  if grep -q "mcu_datalogger" "$1"; then echo "fs"; return; fi
  grep -m1 -o 'fileNamePrefix = "[A-Za-z0-9_]*"' "$1" | cut -d'"' -f2
}

declare -A CHAINS
ORDER=()
for t in "${TESTS[@]}"; do
  [ -f "$t" ] || { echo "Script introuvable : $t" >&2; exit 2; }
  k=$(chain_key "$t")
  [ -n "$k" ] || k="$t"
  [ -n "${CHAINS[$k]}" ] || ORDER+=("$k")
  CHAINS[$k]="${CHAINS[$k]} $t"
done

LOGS=$(mktemp -d)

run_chain() {
  local t s e status
  for t in $1; do
    s=$(date +%s%N)
    omc "$t" > "$LOGS/$t.log" 2>&1
    e=$(date +%s%N)
    status=$(grep -m1 -oE '^(PASS|FAIL)' "$LOGS/$t.log")
    echo "${status:-ERREUR} $(( (e - s) / 1000000 ))" > "$LOGS/$t.res"
  done
}

START=$(date +%s%N)
echo "${#TESTS[@]} script(s), ${#ORDER[@]} chaîne(s), $JOBS en parallèle..."
running=0
for k in "${ORDER[@]}"; do
  if [ $running -ge "$JOBS" ]; then wait -n; running=$((running - 1)); fi
  run_chain "${CHAINS[$k]}" &
  running=$((running + 1))
done
wait
END=$(date +%s%N)

failed=0
for t in "${TESTS[@]}"; do
  read -r status ms < "$LOGS/$t.res"
  printf "%-6s %6.1f s  %s\n" "$status" "$(awk "BEGIN{print $ms/1000}")" "$t"
  [ "$status" = "PASS" ] || failed=$((failed + 1))
done
printf "Durée totale : %.1f s - %d/%d PASS\n" "$(awk "BEGIN{print ($END-$START)/1e9}")" $(( ${#TESTS[@]} - failed )) ${#TESTS[@]}

for t in "${TESTS[@]}"; do
  read -r status ms < "$LOGS/$t.res"
  if [ "$status" != "PASS" ]; then
    echo; echo "--- $t ($status), fin du journal :"; tail -n 15 "$LOGS/$t.log"
  fi
done

if [ $KEEP -eq 1 ]; then
  echo; echo "Journaux conservés dans $LOGS ; artefacts laissés dans ce dossier."
else
  # Artefacts de compilation et de simulation : tous nommés d'après le
  # fileNamePrefix du script (Prefix.exe, Prefix_res.mat, Prefix_01exo.c...).
  for t in "${TESTS[@]}"; do
    for p in $(grep -o 'fileNamePrefix = "[A-Za-z0-9_]*"' "$t" | cut -d'"' -f2 | sort -u); do
      rm -rf "$p".* "$p"_*
    done
  done
  rm -rf fs_copies.txt mcu_datalogger_* "$LOGS"
fi

[ $failed -eq 0 ]
