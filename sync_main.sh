#!/usr/bin/env bash
set -euo pipefail

script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$script_dir"

git checkout main
git pull
git fetch --prune
LC_ALL=C git for-each-ref \
  --format='%(refname:short) %(upstream:track) %(worktreepath)' refs/heads/ \
  | awk '$2 == "[gone]" && NF == 2 {print $1}' \
  | xargs -r git branch -d
