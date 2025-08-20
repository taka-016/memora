# Flutter + Android開発環境（Android専用）
FROM instrumentisto/flutter:3.32.2-androidsdk35-r0

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
  less \
  git \
  procps \
  sudo \
  fzf \
  zsh \
  man-db \
  unzip \
  gnupg2 \
  gh \
  iptables \
  ipset \
  iproute2 \
  dnsutils \
  aggregate \
  jq && \
  apt-get clean && rm -rf /var/lib/apt/lists/*

# Node.jsとnpmのインストール
RUN curl -fsSL https://deb.nodesource.com/setup_24.x | bash - && \
  apt-get update && \
  apt-get install -y nodejs && \
  apt-get clean && rm -rf /var/lib/apt/lists/* && \
  npm install -g npm@11

# bashの履歴を永続化
RUN SNIPPET="export PROMPT_COMMAND='history -a' && export HISTFILE=/commandhistory/.bash_history" \
  && mkdir /commandhistory \
  && touch /commandhistory/.bash_history

# Git Delta のインストール
ARG GIT_DELTA_VERSION=0.18.2
RUN ARCH=$(dpkg --print-architecture) && \
  wget "https://github.com/dandavison/delta/releases/download/${GIT_DELTA_VERSION}/git-delta_${GIT_DELTA_VERSION}_${ARCH}.deb" && \
  sudo dpkg -i "git-delta_${GIT_DELTA_VERSION}_${ARCH}.deb" && \
  rm "git-delta_${GIT_DELTA_VERSION}_${ARCH}.deb"

# zsh設定
ENV SHELL=/bin/zsh
ARG ZSH_IN_DOCKER_VERSION=1.2.0
RUN git clone --depth 1 https://github.com/junegunn/fzf.git /tmp/fzf && \
    mkdir -p /usr/share/doc/fzf/examples && \
    cp /tmp/fzf/shell/* /usr/share/doc/fzf/examples/ && \
    rm -rf /tmp/fzf
RUN sh -c "$(wget -O- https://github.com/deluan/zsh-in-docker/releases/download/v${ZSH_IN_DOCKER_VERSION}/zsh-in-docker.sh)" -- \
  -p git \
  -p fzf \
  -a "source /usr/share/doc/fzf/examples/key-bindings.zsh" \
  -a "source /usr/share/doc/fzf/examples/completion.zsh" \
  -a "export PROMPT_COMMAND='history -a' && export HISTFILE=/commandhistory/.bash_history" \
  -x

# /root/.local/binをPATHに追加
ENV PATH="/root/.local/bin:$PATH"

# claude codeのインストール
ARG CLAUDE_CODE_VERSION=latest
RUN npm install -g @anthropic-ai/claude-code@${CLAUDE_CODE_VERSION}

# Firebase CLIのインストール
RUN npm install -g firebase-tools

# FlutterFire CLIのインストール
RUN dart pub global activate flutterfire_cli

# UVのインストール
RUN curl -LsSf https://astral.sh/uv/install.sh | sh

# /root/.gitconfig を削除
RUN rm -f /root/.gitconfig
