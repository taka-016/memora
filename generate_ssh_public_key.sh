#!/usr/bin/env bash
set -euo pipefail

script_dir="$(cd "$(dirname "$0")" && pwd)"
key_path="${1:-${script_dir}/devcontainer_ed25519}"

if [[ -f "${key_path}" ]]; then
  if [[ -f "${key_path}.pub" ]]; then
    echo "既に鍵が存在します: ${key_path}"
  else
    echo "公開鍵が存在しないため再生成します: ${key_path}.pub"
    ssh-keygen -y -f "${key_path}" \
      | awk '{printf "%s %s %s\n", $1, $2, "devcontainer-ssh"}' \
      > "${key_path}.pub"
  fi
else
  ssh-keygen -t ed25519 -f "${key_path}" -C "devcontainer-ssh" -N ""
fi
