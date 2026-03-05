#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
cd "$ROOT_DIR"

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

flutter build apk --release "$@"

apk_dir="$ROOT_DIR/build/app/outputs/flutter-apk"
source_apk="$apk_dir/app-release.apk"
target_apk="$apk_dir/memora-${build_name}.apk"

if [ ! -f "$source_apk" ]; then
  echo "ビルド成果物が見つかりません: $source_apk" >&2
  exit 1
fi

cp -f "$source_apk" "$target_apk"

echo "リリースAPKを作成しました: $target_apk"
