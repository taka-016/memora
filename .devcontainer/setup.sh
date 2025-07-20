#!/bin/bash

# gpg無効化
git config --local --unset commit.gpgsign

# 開発環境の状態を確認
flutter doctor

# 初期セットアップ
flutter --version
flutter pub get
flutter build apk --debug
