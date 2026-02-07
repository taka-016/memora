#!/usr/bin/env bash
set -euo pipefail

key_path="${1:-$HOME/.ssh/devcontainer_ed25519}"

if [[ -f "${key_path}" ]]; then
  echo "既に鍵が存在します: ${key_path}"
else
  ssh-keygen -t ed25519 -f "${key_path}" -C "devcontainer-ssh" -N ""
fi

echo "公開鍵:"
cat "${key_path}.pub"
