# 開発環境の準備と操作
#
# ホストにDocker Engine・Compose・Git・SSHクライアント・just 1.59.0を用意し、
# ~/.gitconfigを設定する。WSL2でも利用できる。初回の構築にはインターネット接続が必要。
#
# ホストでjust dev-up → just dev-shellを実行し、以降のアプリ操作は開発コンテナで行う。
# 開発コンテナにはjustが含まれる。作業ディレクトリは/workspaces/memora。
# タスク一覧はjust、個別の処理はjust --show <タスク名>で確認できる。
#
# アプリの初期設定（開発コンテナで実行）:
#   cp .env.example .env
#   .envのGOOGLE_PLACES_APIKEYを設定する。
#   flutter pub get
#   dart run build_runner build --delete-conflicting-outputs
#   成功後、機密情報を含む.envをrm .envで削除する。
# Google Cloud ConsoleでMaps SDK for AndroidとPlaces API (New)を有効にし、
# android/local.propertiesにもMAPS_API_KEY=<APIキー>を設定してアプリを再ビルドする。
# オンライン版のFirebase初期設定はsetup-firebaseを参照する。
#
# run・build・release・checkの第1引数はonline / offline、省略時はonline。
# 両モードは同じ端末にインストールできるが、データは共有しない。
# 機能の違いはdocs/usecase_diagram.mdを参照する。

set shell := ['bash', '-euo', 'pipefail', '-c']
set positional-arguments

# 利用できるタスクを表示する
default:
  @just --list

# アプリを実行する（online / offline）
run mode='online' *args:
  #!/usr/bin/env bash
  set -euo pipefail
  source scripts/app/app_mode_arguments.sh
  app_mode="$(resolve_memora_app_mode "$1")"
  shift
  validate_memora_app_arguments "$@"
  exec flutter run --flavor "$app_mode" "--dart-define=MEMORA_APP_MODE=$app_mode" "$@"

# debug APKをビルドする（online / offline）
build mode='online' *args:
  #!/usr/bin/env bash
  set -euo pipefail
  source scripts/app/app_mode_arguments.sh
  app_mode="$(resolve_memora_app_mode "$1")"
  shift
  validate_memora_app_arguments "$@"
  exec flutter build apk --debug --flavor "$app_mode" "--dart-define=MEMORA_APP_MODE=$app_mode" "$@"

# 出力先: build/app/outputs/flutter-apk/memora-<version>-<mode>.apk
# インストール例（生成したバージョンに合わせる）:
#   adb install -r build/app/outputs/flutter-apk/memora-1.0.0-online.apk
#   adb install -r build/app/outputs/flutter-apk/memora-1.0.0-offline.apk
# 初期化: adb shell pm clear <application ID>
# 削除: adb uninstall <application ID>
# application IDはcom.example.memora / com.example.memora.offline。どちらも対象のデータを削除する。

# release APKを作成する（online / offline）
release mode='online' *args:
  bash scripts/app/release_android_apk.sh "$@"

# テスト対象や追加オプションはモードの後に指定する。
# 例: just check offline test/unit/

# フォーマット・コード生成・解析・テストを実行する（online / offline）
check mode='online' *args:
  bash scripts/app/check.sh "$@"

# コンテナへ渡す環境変数は初回起動時に作成されるdocker/.envに設定する。
# アプリのコード生成用.envとは別のファイル。
# 停止後の再起動にもdev-upを使用する。

# 開発コンテナを起動する（ホストで実行）
dev-up:
  #!/usr/bin/env bash
  set -euo pipefail
  if [[ ! -f docker/.env ]]; then
    (umask 077; touch docker/.env)
  fi
  bash scripts/dev/generate_ssh_public_key.sh
  docker compose up -d --build --wait --wait-timeout 120 dev
  docker compose exec -T dev bash -c '
    if [[ ! -f /var/lib/memora/setup-complete ]]; then
      bash scripts/dev/setup.sh
    fi
  '

# 開発コンテナを停止する（ホストで実行）
dev-stop:
  docker compose stop dev

# SSHを使う場合（VS Code Remote-SSHでも利用可能）:
#   ssh -i ssh_keys/memora_ed25519 -p 2222 root@localhost
#   接続後、cd /workspaces/memoraを実行する。

# 開発コンテナへ入る（ホストで実行）
dev-shell:
  docker compose exec dev bash

# ホストはx86_64のLinuxとし、Dockerから/dev/kvmにアクセスできること。
# WSL2でもDocker Engineを動かす環境でls -l /dev/kvmを確認する。
# 外部通信とGoogleサービスは利用できないため、オフライン版の確認に使用する。
# 起動後、開発コンテナでADBを接続し、端末IDを指定してアプリを実行する。
#   emulator_serial=localfilesystem:/root/.android/memora-adb/adbd.sock
#   adb connect "$emulator_serial"
#   just run offline -d "$emulator_serial"
#   adb -s "$emulator_serial" exec-out screencap -p > /tmp/memora-screen.png

# エミュレータを起動する（開発コンテナで実行）
emulator-up:
  docker compose up -d --wait emulator

# just runを終了し、adb disconnect "$emulator_serial"を実行してから停止する。
# 端末内のデータは次回起動時も残る。

# エミュレータを停止する（開発コンテナで実行）
emulator-stop:
  docker compose stop emulator

# 開発環境の起動・SSH・データ保持を検証する（ホストで実行）
test-dev *configs:
  bash scripts/test/dev.sh "$@"

# 検証終了時にエミュレータは停止する。

# エミュレータ環境を検証する（開発コンテナで実行）
test-emulator:
  bash scripts/test/emulator.sh

# https://console.firebase.google.com/ でプロジェクトを作成し、
# Authentication（Google・メールアドレス/パスワード）とFirestore Database（本番モード）を有効にする。
# Identity Toolkit APIとToken Service APIを有効にし、必要に応じてFirestoreのルールを設定する。
# 画面の案内に従ってログインし、対象プロジェクトを選択する。
# lib/firebase_options.dartとfirebase.jsonを設定し、Firestoreのルールとインデックスをデプロイする。

# Firebaseの初期設定とFirestoreのデプロイを実行する
setup-firebase:
  bash scripts/firebase/setup.sh

# SSH鍵を作成する（省略時はssh_keys/memora_ed25519）
ssh-key *args:
  bash scripts/dev/generate_ssh_public_key.sh "$@"

# mainを更新し、追跡先が削除されたローカルブランチを整理する
sync-main:
  #!/usr/bin/env bash
  set -euo pipefail
  git checkout main
  git pull
  git fetch --prune
  LC_ALL=C git for-each-ref \
    --format='%(refname:short) %(upstream:track) %(worktreepath)' refs/heads/ \
    | awk '$2 == "[gone]" && NF == 2 {printf "%s%c", $1, 0}' \
    | xargs -0 -r git branch -d
