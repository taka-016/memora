#!/bin/bash

# Claude Code UIの起動
# (cd /app/claudecodeui && pm2 start npm --name claudecodeui -- start)

# ホストからマウントしたSSH鍵をセットアップ
if [ -d /root/.ssh-localhost ]; then
  cp -r /root/.ssh-localhost/. /root/.ssh/
  chmod 700 /root/.ssh
  find /root/.ssh -type f -exec chmod 600 {} \;
  find /root/.ssh -type d -exec chmod 700 {} \;
fi
