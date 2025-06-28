#!/bin/bash

# .envがあれば読み込む
if [ -f "/workspaces/memora/.devcontainer/.env" ]; then
  export $(grep -v '^#' .devcontainer/.env | xargs)
  echo "Loaded GH_TOKEN from .env"
fi

# GitHub CLI ログイン
echo "$GH_TOKEN" | gh auth login --with-token
gh auth status

# 開発環境の状態を確認
flutter doctor

# 初期セットアップ
flutter --version
flutter pub get
flutter build apk --debug
