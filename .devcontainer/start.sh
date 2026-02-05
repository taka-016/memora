#!/bin/bash

# Claude Code UIの起動
# (cd /app/claudecodeui && pm2 start npm --name claudecodeui -- start)

if command -v code >/dev/null 2>&1; then
  code serve-web --host 0.0.0.0 --port 8000 --without-connection-token >/tmp/code-serve-web.log 2>&1 &
fi
