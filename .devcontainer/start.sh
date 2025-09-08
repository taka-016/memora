#!/bin/bash

# Claude Code UIの起動
(cd /app/claudecodeui && pm2 start npm --name claudecodeui -- start)