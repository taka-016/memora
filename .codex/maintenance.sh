#!/bin/bash

# PATH設定
export PATH="/opt/flutter/bin:$PATH"
export PATH="$PATH:$HOME/.pub-cache/bin"

# install dependencies
flutter pub get
dart pub global activate very_good_cli

# Copy dummy .env file
cp .env.example .env

# Copy dummy firebase_options.dart
cp ./tools/ci/firebase_options.dummy.dart ./lib/firebase_options.dart

# Run build_runner to generate necessary files
dart run build_runner build --delete-conflicting-outputs
