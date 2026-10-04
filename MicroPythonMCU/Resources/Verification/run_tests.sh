#!/bin/bash
# Lance les scénarios de vérification (verify_*.mos) en parallèle, avec une barre
# de progression (une ligne par script terminé si la sortie n'est pas un
# terminal), puis affiche un récapitulatif PASS/FAIL avec la durée de chaque
# script. Voir docs/fr/interne/tests.md.
#
#   ./run_tests.sh                       # toute la suite, 4 exécutions simultanées
#   ./run_tests.sh -j 2                  # 2 exécutions simultanées
#   ./run_tests.sh verify_08_pwm.mos ... # seulement ces scripts
#   ./run_tests.sh -k                    # garder artefacts de compilation et journaux
#   ./run_tests.sh --copy                # sur une copie des fichiers suivis par git,
#                                        # hors du dépôt (avant de poser un tag)
#
# Code de sortie : 0 si tout passe, 1 sinon (2 si la suite n'a pas pu démarrer).
#
# Pendant le travail, la suite tourne dans le dépôt. Avant de poser un tag,
# --copy la lance sur ce que le tag livrera : les seuls fichiers suivis par git
# (modifications non commitées comprises), copiés dans un dossier temporaire hors
# du dépôt. Un fichier nécessaire mais jamais ajouté à git y fait échouer la
# suite au lieu de manquer aux utilisateurs, et aucun artefact n'est écrit dans
# le dépôt (synchronisé par OneDrive). La copie prend une demi-seconde.
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
COPY=0
# getopts ne connaît pas les options longues : --copy est retiré à part.
ARGS=()
for a in "$@"; do
  if [ "$a" = "--copy" ]; then COPY=1; else ARGS+=("$a"); fi
done
set -- "${ARGS[@]}"
while getopts "j:kh" opt; do
  case $opt in
    j) JOBS=$OPTARG ;;
    k) KEEP=1 ;;
    *) sed -n '2,15p' "$0" | sed 's/^# \{0,1\}//'; exit 2 ;;
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
  echo "omc introuvable : l'ajouter au PATH ou positionner OPENMODELICAHOME (cf. docs/fr/interne/outils-windows.md)" >&2
  exit 2
fi

# --copy : copier les fichiers de MicroPythonMCU/ suivis par git dans un dossier
# temporaire, puis déléguer à la copie de ce script, avec les mêmes options et
# les mêmes scripts. Le résultat rappelle sur quoi il a tourné.
if [ $COPY -eq 1 ]; then
  ROOT=$(git rev-parse --show-toplevel 2>/dev/null) || {
    echo "--copy se lance depuis un dépôt git" >&2; exit 2; }
  WORK=$(mktemp -d)
  (cd "$ROOT" && git ls-files -c -z MicroPythonMCU | tar --null --ignore-failed-read -T - -cf -) \
    | tar -xf - -C "$WORK" || { echo "Copie en échec : suite non lancée" >&2; exit 2; }
  untracked=$(cd "$ROOT" && git ls-files -o --exclude-standard MicroPythonMCU)
  if [ -n "$untracked" ]; then
    echo "Non copiés (jamais ajoutés à git, donc absents d'un tag) :"
    echo "$untracked" | sed 's/^/  /'
    echo
  fi
  FWD=(-j "$JOBS")
  [ $KEEP -eq 1 ] && FWD+=(-k)
  "$WORK/MicroPythonMCU/Resources/Verification/run_tests.sh" "${FWD[@]}" "$@"
  status=$?
  echo
  echo "Suite exécutée sur une copie des fichiers suivis : commit $(cd "$ROOT" && git rev-parse --short HEAD)$(cd "$ROOT" && git diff --quiet HEAD -- MicroPythonMCU || echo ' + modifications non commitées')"
  if [ $KEEP -eq 1 ]; then echo "Copie conservée : $WORK"; else rm -rf "$WORK"; fi
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
    # écrit puis renommé : le suivi de progression ne lit jamais un .res à moitié écrit
    echo "${status:-ERREUR} $(( (e - s) / 1000000 ))" > "$LOGS/$t.tmp" && mv "$LOGS/$t.tmp" "$LOGS/$t.res"
  done
}

# Suivi de progression, en tâche de fond : relève les .res au fil des scripts
# terminés. Sur un terminal, une barre redessinée sur une seule ligne ; sinon
# (sortie redirigée vers un fichier), une ligne par script terminé, barre en
# tête. S'arrête quand tous les scripts ont un résultat, ou quand les chaînes
# sont finies (fichier "done") : un script sans résultat ne le bloque pas.
progress() {
  local total=$1 n=0 fails=0 seen=" " f t st ms fill bar el tty=0 last=0
  [ -t 1 ] && tty=1
  while :; do
    [ -e "$LOGS/done" ] && last=1     # relevé AVANT le passage : le dernier résultat est encore lu
    for f in "$LOGS"/*.res; do
      [ -e "$f" ] || continue
      t=$(basename "$f" .res)
      case "$seen" in *" $t "*) continue ;; esac
      seen="$seen$t "
      n=$((n + 1))
      read -r st ms < "$f"
      [ "$st" = "PASS" ] || fails=$((fails + 1))
      fill=$((n * 30 / total))
      bar=$(printf '%*s' "$fill" '' | tr ' ' '#')$(printf '%*s' $((30 - fill)) '' | tr ' ' '-')
      el=$(( ($(date +%s%N) - START) / 1000000000 ))
      if [ $tty -eq 1 ]; then
        printf "\r[%s] %d/%d  %d échec(s)  %d s  %-40s" "$bar" "$n" "$total" "$fails" "$el" "$t"
      else
        printf "[%s] %2d/%d  %-6s %6.1f s  %s\n" "$bar" "$n" "$total" "$st" "$(awk "BEGIN{print $ms/1000}")" "$t"
      fi
    done
    [ $n -ge "$total" ] && break
    [ $last -eq 1 ] && break
    sleep 1
  done
  [ $tty -eq 1 ] && printf "\r%-110s\r" ""
}

START=$(date +%s%N)
echo "${#TESTS[@]} script(s), ${#ORDER[@]} chaîne(s), $JOBS en parallèle..."
progress "${#TESTS[@]}" &
PROGRESS=$!
running=0
PIDS=()
for k in "${ORDER[@]}"; do
  if [ $running -ge "$JOBS" ]; then wait -n; running=$((running - 1)); fi
  run_chain "${CHAINS[$k]}" &
  PIDS+=($!)
  running=$((running + 1))
done
wait "${PIDS[@]}"
touch "$LOGS/done"
wait "$PROGRESS"
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
