#!/usr/bin/env bash
set -euo pipefail

root_dir="$(cd "$(dirname "$0")/.." && pwd)"
if [[ ! -f "$root_dir/docker/.env" ]]; then
  (umask 077; touch "$root_dir/docker/.env")
fi
bash "$root_dir/generate_ssh_public_key.sh"
