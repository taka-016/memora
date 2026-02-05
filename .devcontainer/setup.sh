#!/bin/bash

# .claude/.config.jsonの存在を確認し、なければ初期化
[ -f ~/.claude/.config.json ] || echo '{}' > ~/.claude/.config.json

# 開発環境の状態を確認
flutter doctor

# flutter初期セットアップ
flutter --version
flutter pub get
dart pub global activate very_good_cli

# code-serverをPM2で起動し、プロセス定義を保存
pm2 start .devcontainer/pm2-code-server.json && pm2 save
