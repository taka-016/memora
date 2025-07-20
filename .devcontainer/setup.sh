#!/bin/bash

# 開発環境の状態を確認
flutter doctor

# 初期セットアップ
flutter --version
flutter pub get
flutter build apk --debug
