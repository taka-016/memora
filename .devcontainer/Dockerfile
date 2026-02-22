# Flutter + Android開発環境
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
  tree \
  tmux \
  build-essential \
  ripgrep \
  fd-find \
  xclip \
  openssh-server \
  procps \
  gnupg \
  ca-certificates && \
  apt-get clean && rm -rf /var/lib/apt/lists/*

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
"syntax on" \
> /root/.config/nvim/init.vim

# Node.jsとnpmのインストール
RUN curl -fsSL https://deb.nodesource.com/setup_24.x | bash - && \
  apt-get update && \
  apt-get install -y nodejs && \
  apt-get clean && rm -rf /var/lib/apt/lists/* && \
  npm install -g npm@11

# claude codeのインストール
ARG CLAUDE_CODE_VERSION=latest
RUN npm install -g @anthropic-ai/claude-code@${CLAUDE_CODE_VERSION}

# Codex CLIのインストール
ARG CODEX_VERSION=latest
RUN npm install -g @openai/codex@${CODEX_VERSION}

# Firebase CLIのインストール
RUN npm install -g firebase-tools

# FlutterFire CLIのインストール
RUN dart pub global activate flutterfire_cli

# code-server インストール
RUN curl -fsSL https://code-server.dev/install.sh | sh

# /root/.gitconfig を削除
RUN rm -f /root/.gitconfig
