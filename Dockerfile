# Flutter + Android開発環境（Android専用）
FROM instrumentisto/flutter:3.32.2-androidsdk35-r0

USER root

# 基本パッケージのインストール
RUN apt-get update && apt-get install -y \
  tzdata \
  git \
  curl \
  nano \
  vim \
  emacs-nox \
  tree \
  ripgrep \
  gnupg \
  ca-certificates

# Node.jsとnpmのインストール
RUN curl -fsSL https://deb.nodesource.com/setup_24.x | bash - && \
  apt-get update && \
  apt-get install -y nodejs && \
  npm install -g npm@11

# claude codeのインストール
RUN npm install -g @anthropic-ai/claude-code

# Firebase CLIのインストール
RUN npm install -g firebase-tools

# Install FlutterFire CLI
RUN dart pub global activate flutterfire_cli

# uvのインストール
RUN curl -LsSf https://astral.sh/uv/install.sh | sh

# タイムゾーンをJSTに設定
RUN ln -snf /usr/share/zoneinfo/Asia/Tokyo /etc/localtime \
  && echo "Asia/Tokyo" > /etc/timezone \
  && dpkg-reconfigure -f noninteractive tzdata

# /root/.gitconfig を削除
RUN rm -f /root/.gitconfig
