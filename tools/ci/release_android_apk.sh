#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
cd "$ROOT_DIR"

build_name=''
app_mode='auto'
prev=''
for arg in "$@"; do
  if [ "$prev" = '--build-name' ]; then
    build_name="$arg"
    prev=''
    continue
  fi

  if [ "$prev" = '--dart-define' ]; then
    case "$arg" in
      MEMORA_APP_MODE=*)
        app_mode="${arg#MEMORA_APP_MODE=}"
        ;;
    esac
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
    --dart-define=MEMORA_APP_MODE=*)
      app_mode="${arg#--dart-define=MEMORA_APP_MODE=}"
      ;;
    --dart-define)
      prev='--dart-define'
      ;;
  esac
done

case "$app_mode" in
  auto|online|offline)
    ;;
  *)
    echo 'MEMORA_APP_MODEにはauto、online、offlineのいずれかを指定してください。' >&2
    exit 1
    ;;
esac

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
target_apk="$apk_dir/memora-${build_name}-${app_mode}.apk"

if [ ! -f "$source_apk" ]; then
  echo "ビルド成果物が見つかりません: $source_apk" >&2
  exit 1
fi

cp -f "$source_apk" "$target_apk"

echo "MEMORA_APP_MODE=${app_mode}"
echo "リリースAPKを作成しました: $target_apk"
