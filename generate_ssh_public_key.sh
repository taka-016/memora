#!/usr/bin/env bash
set -euo pipefail

script_dir="$(cd "$(dirname "$0")" && pwd)"
key_path="${1:-${script_dir}/devcontainer_ed25519}"

if [[ -f "${key_path}" ]]; then
  echo "既に鍵が存在します: ${key_path}"
else
  ssh-keygen -t ed25519 -f "${key_path}" -C "devcontainer-ssh" -N ""
fi
