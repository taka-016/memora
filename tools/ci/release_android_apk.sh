#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
source "$ROOT_DIR/tools/ci/app_mode_arguments.sh"
cd "$ROOT_DIR"

app_mode="$(resolve_memora_app_mode "${1:-}")"
if [ "$#" -gt 0 ]; then
  shift
fi
validate_memora_app_arguments "$@"

build_name=''
prev=''
for arg in "$@"; do
  if [ "$prev" = '--build-name' ]; then
    build_name="$arg"
    prev=''
    continue
  fi

  case "$arg" in
    --build-name=*)
      build_name="${arg#--build-name=}"
      ;;
    --build-name)
      prev='--build-name'
      ;;
  esac
done

if [ -z "$build_name" ]; then
  version_line="$(awk '/^version:/ {print $2; exit}' pubspec.yaml)"
  build_name="${version_line%%+*}"
fi

if [ -z "$build_name" ]; then
  echo 'バージョン情報を取得できませんでした。pubspec.yaml または --build-name を確認してください。' >&2
  exit 1
fi

build_arguments=()
while [ "$#" -gt 0 ]; do
  case "$1" in
    --dart-define)
      build_arguments+=("$1")
      shift
      if [ "$#" -gt 0 ]; then
        build_arguments+=("$1")
        shift
      fi
      ;;
    *)
      build_arguments+=("$1")
      shift
      ;;
  esac
done

flutter build apk \
  --release \
  --flavor "$app_mode" \
  "${build_arguments[@]}" \
  "--dart-define=MEMORA_APP_MODE=$app_mode"

apk_dir="$ROOT_DIR/build/app/outputs/flutter-apk"
source_apk="$apk_dir/app-${app_mode}-release.apk"
target_apk="$apk_dir/memora-${build_name}-${app_mode}.apk"

if [ ! -f "$source_apk" ]; then
  echo "ビルド成果物が見つかりません: $source_apk" >&2
  exit 1
fi

cp -f "$source_apk" "$target_apk"

echo "MEMORA_APP_MODE=${app_mode}"
echo "リリースAPKを作成しました: $target_apk"
