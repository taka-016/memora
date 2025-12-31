#!/bin/bash

# 環境変数
export DEBIAN_FRONTEND=noninteractive
export FLUTTER_VERSION=3.35.4
export TZ=Asia/Tokyo

# パッケージインストール
sudo apt-get update -y
sudo apt-get install -y --no-install-recommends \
  git \
  gh \
  curl \
  wget \
  unzip \
  tree \
  jq \
  ripgrep \
  xz-utils \
  ca-certificates \
  tzdata && \
  rm -rf /var/lib/apt/lists/*

# Node.jsとnpm
curl -fsSL https://deb.nodesource.com/setup_24.x | sudo bash - && \
  apt-get update -y && \
  apt-get install -y nodejs && \
  npm install -g npm@11 && \
  rm -rf /var/lib/apt/lists/*

# タイムゾーン設定
sudo ln -snf /usr/share/zoneinfo/$TZ /etc/localtime && \
  echo $TZ | sudo tee /etc/timezone

# Flutterのダウンロードとインストール
cd /opt
sudo wget -q https://storage.googleapis.com/flutter_infra_release/releases/stable/linux/flutter_linux_${FLUTTER_VERSION}-stable.tar.xz && \
  tar xf flutter_linux_${FLUTTER_VERSION}-stable.tar.xz && \
  rm flutter_linux_${FLUTTER_VERSION}-stable.tar.xz

# Gitセーフ設定
git config --global --add safe.directory /opt/flutter

# 不要なキャッシュを削除して軽量化
sudo rm -rf /opt/flutter/bin/cache/artifacts/engine/android* \
  /opt/flutter/bin/cache/artifacts/engine/linux* \
  /opt/flutter/bin/cache/artifacts/engine/windows* \
  /opt/flutter/bin/cache/artifacts/engine/darwin* \
  /opt/flutter/bin/cache/artifacts/engine/ios* \
  /opt/flutter/bin/cache/artifacts/engine/web* \
  /opt/flutter/bin/cache/flutter_web_sdk \
  /opt/flutter/packages/*/example \
  /opt/flutter/packages/*/snippets

# Flutterの初期設定 (非対応プラットフォームを無効化)
export PATH="/opt/flutter/bin:$PATH"
flutter config --no-analytics \
  --no-enable-android \
  --no-enable-ios \
  --no-enable-web \
  --no-enable-linux-desktop \
  --no-enable-macos-desktop \
  --no-enable-windows-desktop

# PATH永続化 (.bashrc先頭に追加)
sed -i '1iexport PATH="/opt/flutter/bin:$PATH"\nexport PATH="$PATH:$HOME/.pub-cache/bin"' ~/.bashrc

# 作業ディレクトリへ移動
cd /workspace/memora

# メンテナンス用セットアップスクリプト実行
source ./.codex/maintenance.sh
