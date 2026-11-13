#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
source "$ROOT_DIR/scripts/app/app_mode_arguments.sh"
cd "$ROOT_DIR"

action="$1"
shift
app_mode="$(resolve_memora_app_mode "${1:-}")"
if [ "$#" -gt 0 ]; then shift; fi
validate_memora_app_arguments "$@"
validate_memora_build_number_arguments "$app_mode" "$@"

case "$action" in
  run) flutter_arguments=(run) ;;
  build) flutter_arguments=(build apk --debug) ;;
  *) echo 'run、buildのいずれかを指定してください。' >&2; exit 1 ;;
esac
if [[ "$app_mode" == online ]]; then
  build_number="$(dart scripts/firebase/manage_app_release.dart current)"
  export MEMORA_ONLINE_BUILD_NUMBER="$build_number"
  if [[ "$action" == build ]]; then
    flutter_arguments+=("--build-number=$build_number")
  fi
fi
exec flutter "${flutter_arguments[@]}" --flavor "$app_mode" "$@" "--dart-define=MEMORA_APP_MODE=$app_mode"
