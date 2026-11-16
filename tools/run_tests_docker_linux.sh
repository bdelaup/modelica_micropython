#!/bin/bash
# Run the verification suite in a disposable Linux container. Arguments have
# the same meaning as in run_tests.sh; -k keeps the container for inspection.

set -o pipefail
ROOT=$(cd "$(dirname "$0")/.." && pwd) || exit 2
if ! command -v docker >/dev/null 2>&1; then
  echo "Docker introuvable : installer Docker Desktop." >&2
  exit 2
fi

COPY=0
KEEP=0
PARSE_ARGS=()
for arg in "$@"; do
  if [ "$arg" = "--copy" ]; then COPY=1; else PARSE_ARGS+=("$arg"); fi
done
OPTIND=1
while getopts ":j:kh" opt "${PARSE_ARGS[@]}"; do
  [ "$opt" = "k" ] && KEEP=1
done

HOST_ROOT=$(cygpath -w "$ROOT") || exit 2
NAME="micropythonmcu-tests-$(date +%Y%m%d%H%M%S)-$$"
DOCKER_ARGS=(--name "$NAME" --mount "type=bind,source=$HOST_ROOT,target=/src,readonly")
[ "$KEEP" -eq 0 ] && DOCKER_ARGS+=(--rm)

ARCHIVE=""
cleanup() {
  [ -n "$ARCHIVE" ] && rm -f -- "$ARCHIVE"
}
interrupt() {
  trap - INT TERM
  docker stop -t 2 "$NAME" >/dev/null 2>&1
  cleanup
  exit 130
}
trap interrupt INT TERM

if [ "$COPY" -eq 1 ]; then
  if ! git -C "$ROOT" rev-parse --show-toplevel >/dev/null 2>&1; then
    echo "--copy se lance depuis un depot git." >&2
    exit 2
  fi
  ARCHIVE=$(mktemp "${TMPDIR:-/tmp}/micropythonmcu-tracked-XXXXXXXX.tar") || exit 2
  if ! (cd "$ROOT" && git ls-files -c -z -- MicroPythonMCU |
      tar --null --ignore-failed-read -T - -cf "$ARCHIVE"); then
    echo "Copie des fichiers suivis en echec : suite non lancee." >&2
    cleanup
    exit 2
  fi
  untracked=$(git -C "$ROOT" ls-files -o --exclude-standard -- MicroPythonMCU)
  if [ -n "$untracked" ]; then
    echo "Non copies (jamais ajoutes a git, donc absents d'un tag) :"
    echo "$untracked" | sed 's/^/  /'
    echo
  fi
  HOST_ARCHIVE=$(cygpath -w "$ARCHIVE") || { cleanup; exit 2; }
  DOCKER_ARGS+=(--mount "type=bind,source=$HOST_ARCHIVE,target=/tracked.tar,readonly")
fi

MSYS_NO_PATHCONV=1 docker run "${DOCKER_ARGS[@]}" micropythonmcu-dev bash -c '
  set -e
  if [ "$1" = 1 ]; then
    tar -xf /tracked.tar -C /tmp
  else
    cp -r /src/MicroPythonMCU /tmp/MicroPythonMCU
  fi
  shift
  cd /tmp/MicroPythonMCU/Resources/Verification
  exec bash run_tests.sh "$@"
' bash "$COPY" "${PARSE_ARGS[@]}"
status=$?
trap - INT TERM
cleanup

if [ "$COPY" -eq 1 ]; then
  revision=$(git -C "$ROOT" rev-parse --short HEAD)
  if ! git -C "$ROOT" diff --quiet HEAD -- MicroPythonMCU; then
    revision="$revision + modifications non commitees"
  fi
  echo "Suite executee sur une copie des fichiers suivis : commit $revision"
fi

if [ "$KEEP" -eq 1 ] && docker container inspect "$NAME" >/dev/null 2>&1; then
  echo
  echo "Conteneur conserve : $NAME"
  echo "Recuperer un fichier : docker cp ${NAME}:/chemin/dans/le/conteneur chemin-local"
  echo "Supprimer le conteneur apres inspection : docker rm $NAME"
fi
exit "$status"
