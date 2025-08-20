#!/bin/bash

# .claude/.config.jsonの存在を確認し、なければ初期化
[ -f ~/.claude/.config.json ] || echo '{}' > ~/.claude/.config.json

# 開発環境の状態を確認
flutter doctor

# flutter初期セットアップ
flutter --version
flutter pub get
dart pub global activate very_good_cli

# Serena MCPのセットアップ
claude mcp add serena -- uvx --from git+https://github.com/oraios/serena serena-mcp-server --context ide-assistant --project $(pwd) --enable-web-dashboard false

# Flutterビルドをバックグラウンドで実行
nohup bash .devcontainer/flutter_build.sh > /tmp/flutter_build.log 2>&1 &

sleep 10
