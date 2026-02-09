#!/bin/bash

# .claude/.config.jsonの存在を確認し、なければ初期化
[ -f ~/.claude/.config.json ] || echo '{}' > ~/.claude/.config.json

bash ./generate_ssh_public_key.sh

# 開発環境の状態を確認
flutter doctor

# flutter初期セットアップ
flutter --version
flutter pub get
dart pub global activate very_good_cli
