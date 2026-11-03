#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
cd "$ROOT_DIR"

show_usage() {
  echo 'Firebaseセットアップ: all / configure / api-key / project / rules / indexes / sync-indexes'
}

if [[ "${1:-}" == '--help' ]]; then
  show_usage
  exit 0
fi

if [[ "$#" -eq 0 ]]; then
  echo '実行する処理を選択してください（複数は空白区切り）。'
  echo '1: すべて実行'
  echo '2: Android設定の生成・更新とAPIキー指定'
  echo '3: ローカル設定のAPIキーだけ更新'
  echo '4: Firebase CLIのプロジェクト選択'
  echo '5: Firestoreルールのデプロイ'
  echo '6: Firestoreインデックスのデプロイ'
  echo '7: Firestoreインデックスの取得'
  read -r -a selections || exit 1
  if [[ "${#selections[@]}" -eq 0 ]]; then exit 1; fi
  set -- "${selections[@]}"
fi

actions=()
for action in "$@"; do
  case "$action" in
    1|all) actions+=(project configure rules indexes sync-indexes) ;;
    2|configure) actions+=(configure) ;;
    3|api-key) actions+=(api-key) ;;
    4|project) actions+=(project) ;;
    5|rules) actions+=(rules) ;;
    6|indexes) actions+=(indexes) ;;
    7|sync-indexes) actions+=(sync-indexes) ;;
    *) echo "不明な処理です: $action" >&2; show_usage; exit 1 ;;
  esac
done

firebase_ready=false
ensure_firebase() {
  if [[ "$firebase_ready" == true ]]; then return; fi
  if ! command -v firebase > /dev/null; then
    echo 'Firebase CLIをインストールしますか？ (y/n)'
    read -r answer
    if [[ "$answer" != y ]]; then
      echo 'Firebase CLIをインストールしてから再実行してください。' >&2
      return 1
    fi
    npm install -g firebase-tools
  fi
  if ! firebase projects:list > /dev/null 2>&1; then
    echo 'Firebaseにログインしてください。Gemini機能とデータ収集は両方ともNoを選択してください。'
    firebase login --no-localhost
  fi
  firebase_ready=true
}

read_api_key() {
  if [[ -z "${FIREBASE_API_KEY:-}" ]]; then
    read -r -s -p 'Firebase用APIキーを入力してください: ' FIREBASE_API_KEY
    echo
  fi
  if [[ ! "$FIREBASE_API_KEY" =~ ^AIza[A-Za-z0-9_-]+$ ]]; then
    echo 'Firebase用APIキーの形式を確認してください。' >&2
    return 1
  fi
  export FIREBASE_API_KEY
}

configure() {
  read_api_key
  ensure_firebase
  if ! dart pub global list | grep -q flutterfire_cli; then
    dart pub global activate flutterfire_cli
  fi
  dart pub global run flutterfire_cli:flutterfire configure --platforms=android
  dart scripts/firebase/set_api_key.dart
}

deploy_indexes() {
  if ! command -v jq > /dev/null; then
    echo 'jqをインストールしてから再実行してください。' >&2
    return 1
  fi
  local config_tmp
  config_tmp="$(mktemp firebase.json.XXXXXX)"
  if jq '.firestore.indexes //= "firestore.indexes.json"' firebase.json > "$config_tmp"; then
    mv "$config_tmp" firebase.json
  else
    rm -f "$config_tmp"
    return 1
  fi
  firebase deploy --only firestore:indexes
}

sync_indexes() {
  local indexes_tmp
  indexes_tmp="$(mktemp firestore.indexes.json.XXXXXX)"
  if firebase firestore:indexes > "$indexes_tmp"; then
    mv "$indexes_tmp" firestore.indexes.json
  else
    rm -f "$indexes_tmp"
    return 1
  fi
}

for action in "${actions[@]}"; do
  case "$action" in
    configure) configure ;;
    api-key)
      read_api_key
      dart scripts/firebase/set_api_key.dart
      ;;
    project) ensure_firebase; firebase use --add ;;
    rules) ensure_firebase; firebase deploy --only firestore:rules ;;
    indexes) ensure_firebase; deploy_indexes ;;
    sync-indexes) ensure_firebase; sync_indexes ;;
  esac
done

echo 'セットアップ完了！'
