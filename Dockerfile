# Flutter + Android開発環境（Android専用）
FROM instrumentisto/flutter:3.32.2-androidsdk35-r0

# パッケージのインストール
USER root
RUN apt-get update && apt-get install -y android-tools-adb
RUN apt-get install -y \
    git \
    curl \
    nano \
    vim \
    emacs-nox
RUN rm -rf /var/lib/apt/lists/*

# 作業ディレクトリの設定
WORKDIR /workspace
