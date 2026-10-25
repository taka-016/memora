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

# release APKを作成する（online / offline）
release mode='online' *args:
  bash scripts/app/release_android_apk.sh "$@"

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

# Firebaseの初期設定とFirestoreのデプロイを実行する
setup-firebase:
  bash scripts/firebase/setup.sh

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

# 停止中のオフラインDBの予定・個別回・任意ラベルを全消去して新形式へ切り替える
reset-calendar-offline database *args:
  python3 scripts/calendar/reset_offline_calendar.py "$@"

# 指定Firebaseプロジェクトの予定・個別回・任意ラベルを全消去する
reset-calendar-online project *args:
  bash scripts/calendar/reset_online_calendar.sh "$@"

# カレンダー切替で対象外データが保持されることを検証する
check-calendar-reset:
  python3 tools/ci/calendar_reset_test.py
