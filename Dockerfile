# Flutter + Android開発環境（Android専用）
FROM instrumentisto/flutter:3.32.2-androidsdk35-r0

USER root
RUN apt-get update

# 基本パッケージのインストール
RUN apt-get install -y \
    git \
    curl \
    nano \
    vim \
    emacs-nox \
    tree \
    gnupg \
    ca-certificates

# ADBのインストール
RUN apt-get install -y android-tools-adb

# Node.jsの最新版インストール
RUN curl -fsSL https://deb.nodesource.com/setup_current.x | bash -
RUN apt-get install -y nodejs=24.3.0-1nodesource*
RUN npm install -g npm@latest

# 不要なパッケージの削除
RUN rm -rf /var/lib/apt/lists/*

# gemini-cliのインストール
RUN npm install -g @google/gemini-cli

# 作業ディレクトリの設定
WORKDIR /workspace
