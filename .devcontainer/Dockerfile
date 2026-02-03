# Flutter + Android開発環境（Android専用）
FROM instrumentisto/flutter:3.35.4-androidsdk35-r0

USER root

ENV DEVCONTAINER=true

ARG TZ
ENV TZ="$TZ"

# 基本パッケージのインストール
RUN apt-get update && apt-get install -y --no-install-recommends \
  tzdata \
  git \
  curl \
  nano \
  vim \
  tree \
  ripgrep \
  gnupg \
  ca-certificates \
  tar && \
  apt-get clean && rm -rf /var/lib/apt/lists/*

# Node.jsとnpmのインストール
RUN curl -fsSL https://deb.nodesource.com/setup_24.x | bash - && \
  apt-get update && \
  apt-get install -y nodejs && \
  apt-get clean && rm -rf /var/lib/apt/lists/* && \
  npm install -g npm@11

# bashの履歴を永続化
RUN mkdir -p /commandhistory && \
  touch /commandhistory/.bash_history && \
  echo "export HISTFILE=/commandhistory/.bash_history" >> /etc/bash.bashrc && \
  echo "export PROMPT_COMMAND='history -a'" >> /etc/bash.bashrc

# claude codeのインストール
ARG CLAUDE_CODE_VERSION=latest
RUN npm install -g @anthropic-ai/claude-code@${CLAUDE_CODE_VERSION}

# Codex CLIのインストール
ARG CODEX_VERSION=latest
RUN npm install -g @openai/codex@${CODEX_VERSION}

# VS Code CLIのインストール（code tunnel用）
RUN curl -L "https://code.visualstudio.com/sha/download?build=stable&os=cli-linux-x64" \
  -o /tmp/vscode_cli.tar.gz && \
  tar -xzf /tmp/vscode_cli.tar.gz -C /usr/local/bin && \
  rm /tmp/vscode_cli.tar.gz

# Firebase CLIのインストール
RUN npm install -g firebase-tools

# FlutterFire CLIのインストール
RUN dart pub global activate flutterfire_cli

# UVのインストール
RUN curl -LsSf https://astral.sh/uv/install.sh | sudo env UV_INSTALL_DIR=/usr/local/bin UV_NO_MODIFY_PATH=1 sh

# PM2のインストール
# RUN npm install -g pm2@6.0.10

# Claude Code UIのインストール
# RUN mkdir /app && cd /app && \
#   git clone https://github.com/siteboon/claudecodeui.git && \
#   cd claudecodeui && \
#   npm install && \
#   npm run build

# /root/.gitconfig を削除
RUN rm -f /root/.gitconfig
