#!/bin/bash

# .claude/.config.jsonの存在を確認し、なければ初期化
# [ -f ~/.claude/.config.json ] || echo '{}' > ~/.claude/.config.json

# codexインストール
if [ ! -x /root/.codex/packages/standalone/current/codex ]; then
  curl -fsSL https://chatgpt.com/codex/install.sh | sh
fi

# PATH設定
if ! grep -qxF 'export PATH="/root/.codex/packages/standalone/current:$PATH"' /root/.bashrc; then
  echo 'export PATH="/root/.codex/packages/standalone/current:$PATH"' >> /root/.bashrc
fi

# SSH鍵を生成
bash ./generate_ssh_public_key.sh

# 開発環境の状態を確認
flutter doctor

# flutter初期セットアップ
flutter --version
flutter pub get
dart pub global activate very_good_cli
