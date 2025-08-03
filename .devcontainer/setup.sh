#!/bin/bash

# 開発環境の状態を確認
flutter doctor

# 初期セットアップ
flutter --version
flutter pub get
dart pub global activate very_good_cli

# Flutterビルドをバックグラウンドで実行
nohup bash .devcontainer/flutter_build.sh > /tmp/flutter_build.log 2>&1 &

sleep 10
