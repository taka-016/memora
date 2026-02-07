#!/bin/bash

set -euo pipefail

mkdir -p /var/run/sshd

key_path="$(cd "$(dirname "$0")/.." && pwd)/devcontainer_ed25519"
if [[ -f "${key_path}.pub" ]]; then
  mkdir -p /root/.ssh
  chmod 700 /root/.ssh
  cp "${key_path}.pub" /root/.ssh/authorized_keys
  chmod 600 /root/.ssh/authorized_keys
fi

/usr/sbin/sshd

code-server /workspaces --bind-addr 0.0.0.0:8080 --auth none
