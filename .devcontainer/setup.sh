#!/bin/bash

# gemini-cliのインストール
npm install -g @google/gemini-cli

# claude codeのインストール
npm install -g @anthropic-ai/claude-code

# Firebase CLIのインストール
npm install -g firebase-tools

# FlutterFire CLIのインストール
dart pub global activate flutterfire_cli

# 開発環境の状態を確認
flutter doctor

# 初期セットアップ
flutter --version
flutter pub get
dart pub global activate very_good_cli
flutter build apk --debug
