#!/usr/bin/env bash
set -euo pipefail

mkdir -p /run/sshd /root/.ssh /run/memora /etc/ssh/sshd_config.d
chmod 700 /root/.ssh /run/memora
key_path=/workspaces/memora/ssh_keys/memora_ed25519.pub
if [[ ! -f "$key_path" ]]; then
  printf '%s\n' 'SSH公開鍵がありません。ホストで bash docker/initialize.sh を実行してください。' >&2
  exit 1
fi
cp "$key_path" /root/.ssh/authorized_keys
chmod 600 /root/.ssh/authorized_keys
ssh-keygen -A
python3 - <<'ENVIRONMENT'
import os
import re
import shlex
from pathlib import Path

skip = {'PWD', 'OLDPWD', 'SHLVL', '_'}
lines = [
    f'export {key}={shlex.quote(value)}\n'
    for key, value in sorted(os.environ.items())
    if key not in skip and re.fullmatch(r'[A-Za-z_][A-Za-z0-9_]*', key)
]
path = Path('/run/memora/environment.sh')
path.write_text(''.join(lines) + 'unset BASH_ENV\n')
path.chmod(0o600)
ENVIRONMENT
printf '%s\n' 'SetEnv BASH_ENV=/run/memora/environment.sh' > /etc/ssh/sshd_config.d/02-memora-env.conf
exec "$@"
