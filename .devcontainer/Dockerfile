# Flutter + Android開発環境
FROM ubuntu:24.04

USER root

ENV DEVCONTAINER=true

ARG DEBIAN_FRONTEND=noninteractive
ARG TZ
ENV TZ="$TZ"

ARG FLUTTER_VERSION=3.44.4
ARG ANDROID_SDK_TOOLS_VERSION=14742923
ARG ANDROID_PLATFORM_VERSION=36
ARG ANDROID_BUILD_TOOLS_VERSION=36.0.0
ARG ANDROID_NDK_VERSION=28.2.13676358

ENV FLUTTER_HOME=/opt/flutter
ENV ANDROID_HOME=/opt/android-sdk-linux
ENV ANDROID_SDK_ROOT=/opt/android-sdk-linux
ENV PATH="${FLUTTER_HOME}/bin:${ANDROID_HOME}/cmdline-tools/latest/bin:${ANDROID_HOME}/platform-tools:${ANDROID_HOME}/emulator:/root/.pub-cache/bin:${PATH}"

# 基本パッケージのインストール
RUN apt-get update && apt-get install -y --no-install-recommends \
  tzdata \
  git \
  curl \
  nano \
  tree \
  tmux \
  build-essential \
  ripgrep \
  fd-find \
  xclip \
  openssh-server \
  procps \
  gnupg \
  ca-certificates \
  unzip \
  xz-utils \
  openjdk-17-jdk && \
  apt-get clean && rm -rf /var/lib/apt/lists/*

# Flutter SDKのインストール
RUN curl -fsSL "https://storage.googleapis.com/flutter_infra_release/releases/stable/linux/flutter_linux_${FLUTTER_VERSION}-stable.tar.xz" \
  -o /tmp/flutter.tar.xz && \
  tar -xf /tmp/flutter.tar.xz -C /opt && \
  rm -f /tmp/flutter.tar.xz && \
  git config --global --add safe.directory "$FLUTTER_HOME" && \
  flutter config --no-analytics

# Android SDKのインストール
RUN mkdir -p "$ANDROID_HOME/cmdline-tools" && \
  curl -fsSL "https://dl.google.com/android/repository/commandlinetools-linux-${ANDROID_SDK_TOOLS_VERSION}_latest.zip" \
  -o /tmp/android-commandline-tools.zip && \
  unzip -q /tmp/android-commandline-tools.zip -d /tmp/android-commandline-tools && \
  mv /tmp/android-commandline-tools/cmdline-tools "$ANDROID_HOME/cmdline-tools/latest" && \
  rm -rf /tmp/android-commandline-tools /tmp/android-commandline-tools.zip

RUN yes | sdkmanager --licenses >/dev/null && \
  sdkmanager \
  "platforms;android-$ANDROID_PLATFORM_VERSION" \
  "build-tools;$ANDROID_BUILD_TOOLS_VERSION" \
  "platform-tools" \
  "ndk;$ANDROID_NDK_VERSION"

# sshdの鍵認証設定
RUN mkdir -p /etc/ssh/sshd_config.d && \
  cat <<'EOF' >/etc/ssh/sshd_config.d/01-key-auth.conf
PasswordAuthentication no
KbdInteractiveAuthentication no
ChallengeResponseAuthentication no
PubkeyAuthentication yes
EOF

# bashの履歴を永続化
RUN mkdir -p /commandhistory && \
  touch /commandhistory/.bash_history && \
  echo "export HISTFILE=/commandhistory/.bash_history" >> /etc/bash.bashrc && \
  echo "export PROMPT_COMMAND='history -a'" >> /etc/bash.bashrc

# fdfind→fd
RUN ln -s $(which fdfind) /usr/local/bin/fd

# Neovimのインストール
RUN curl -LO https://github.com/neovim/neovim/releases/latest/download/nvim-linux-x86_64.tar.gz \
 && tar xzf nvim-linux-x86_64.tar.gz \
 && mv nvim-linux-x86_64 /opt/nvim \
 && ln -s /opt/nvim/bin/nvim /usr/local/bin/nvim
RUN echo 'alias vim=nvim' >> /root/.bashrc
RUN mkdir -p /root/.config/nvim
RUN printf '%s\n' \
"set number" \
"set relativenumber" \
"set tabstop=2" \
"set shiftwidth=2" \
"set expandtab" \
"set smartindent" \
"set clipboard=unnamedplus" \
"set ignorecase" \
"set smartcase" \
"set incsearch" \
"set hlsearch" \
"set mouse=a" \
"syntax on" \
> /root/.config/nvim/init.vim

# Node.jsとnpmのインストール
RUN curl -fsSL https://deb.nodesource.com/setup_24.x | bash - && \
  apt-get update && \
  apt-get install -y nodejs && \
  apt-get clean && rm -rf /var/lib/apt/lists/* && \
  npm install -g npm@11

# claude codeのインストール
# ARG CLAUDE_CODE_VERSION=latest
# RUN npm install -g @anthropic-ai/claude-code@${CLAUDE_CODE_VERSION}

# Codex CLIのインストール
# ARG CODEX_VERSION=latest
# RUN npm install -g @openai/codex@${CODEX_VERSION}

# Firebase CLIのインストール
RUN npm install -g firebase-tools

# FlutterFire CLIのインストール
RUN dart pub global activate flutterfire_cli

# /root/.gitconfig を削除
RUN rm -f /root/.gitconfig
