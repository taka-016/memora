set shell := ['bash', '-euo', 'pipefail', '-c']
set positional-arguments

# 利用できるタスクを表示する
default:
  @just --list

# アプリを実行する（online / offline、オンラインはFirestoreの現在の番号を使用）
run mode='online' *args:
  bash scripts/app/run_flutter_app.sh run "$@"

# debug APKをビルドする（online / offline、オンラインはFirestoreの現在の番号を使用）
build mode='online' *args:
  bash scripts/app/run_flutter_app.sh build "$@"

# release APKを作成する（online / offline、オンラインは毎回Firestoreで採番）
release mode='online' *args:
  bash scripts/app/release_android_apk.sh "$@"

# 指定したビルド番号未満を利用停止にする（配布後に実行、0で解除）
require-update number:
  dart scripts/firebase/manage_app_release.dart require-update "$@"

# メンテナンスによる利用停止を切り替える（on / off）
maintenance state:
  dart scripts/firebase/manage_app_release.dart maintenance "$@"

# フォーマット・コード生成・解析・テストを実行する（online / offline）
check mode='online' *args:
  bash scripts/app/check.sh "$@"

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

# 開発コンテナへ入る（ホストで実行）
dev-shell:
  docker compose exec dev bash

# エミュレータを起動する（開発コンテナで実行）
emulator-up:
  docker compose up -d --wait emulator

# エミュレータを停止する（開発コンテナで実行）
emulator-stop:
  docker compose stop emulator

# 開発環境の起動・SSH・データ保持を検証する（ホストで実行）
test-dev *configs:
  bash scripts/test/dev.sh "$@"

# エミュレータ環境を検証する（開発コンテナで実行）
test-emulator:
  bash scripts/test/emulator.sh

# Android側のカレンダーウィジェットの予定統合を検証する
test-calendar-widget:
  ./android/gradlew -p android :app:testOnlineDebugUnitTest --console=plain

# configure: 設定生成、api-key: キー更新、project: プロジェクト選択
# rules / indexes: 各デプロイ、sync-indexes: インデックス取得
# gcloud-auth: Google Cloud認証
# Firebase・Google Cloudの設定を行う（引数なし: メニュー、all: 全処理、複数指定可）
setup-cloud *actions:
  bash scripts/cloud/setup.sh "$@"

# SSH鍵を作成する（省略時はssh_keys/memora_ed25519）
ssh-key *args:
  bash scripts/dev/generate_ssh_public_key.sh "$@"

alias sm := sync-main

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
