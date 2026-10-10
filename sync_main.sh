#!/usr/bin/env bash
set -eu

script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$script_dir"

git checkout main
git pull
git fetch --prune
git branch -vv | grep ': gone]' | awk '{print $1}' | xargs -r git branch -D
