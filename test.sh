#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$ROOT_DIR/tools/ci/app_mode_arguments.sh"
cd "$ROOT_DIR"

app_mode="$(resolve_memora_app_mode "${1:-}")"
if [ "$#" -gt 0 ]; then
  shift
fi
validate_memora_app_arguments "$@"

dart pub global run very_good_cli:very_good test \
  "--dart-define=MEMORA_APP_MODE=$app_mode" \
  "$@"
