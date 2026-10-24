#!/usr/bin/env bash
set -euo pipefail

cd "$(dirname "$0")/.."
compose=(docker compose -p memora-dev-check -f compose.yaml)
for config in "$@"; do
  compose+=(-f "$config")
done
override="$(mktemp --suffix=.yaml)"
cat > "$override" <<'YAML'
services:
  dev:
    environment:
      MEMORA_SSH_ENV_CHECK: 'memora ssh check'
    ports: !override
      - '127.0.0.1::22'
YAML
compose+=(-f "$override")
cleanup() {
  "${compose[@]}" down --remove-orphans
  rm -f "$override"
}
trap cleanup EXIT
"${compose[@]}" up --build --detach --wait --wait-timeout 120 dev
"${compose[@]}" exec -T dev bash docker/setup.sh
"${compose[@]}" exec -T dev bash -s <<'BASH'
set -euo pipefail
ssh-keygen -q -t ed25519 -N '' -f /tmp/memora-test-key
cat /tmp/memora-test-key.pub >> /root/.ssh/authorized_keys
ssh -i /tmp/memora-test-key -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null root@127.0.0.1 '
  set -e
  cd /workspaces/memora
  test "$MEMORA_SSH_ENV_CHECK" = "memora ssh check"
  flutter --version
  sdkmanager --list_installed >/dev/null
  gh --version
  docker version --format "{{.Server.Os}}"
  docker compose version
  docker buildx version
  command -v codex
  command -v firebase
  command -v flutterfire
  command -v very_good
'
ssh -tt -i /tmp/memora-test-key -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null root@127.0.0.1 <<'LOGIN'
set -e
test "$MEMORA_SSH_ENV_CHECK" = 'memora ssh check'
command -v flutter
exit
LOGIN
BASH
fingerprint="$("${compose[@]}" exec -T dev ssh-keygen -lf /etc/ssh/ssh_host_ed25519_key.pub)"
"${compose[@]}" exec -T dev bash -c 'echo memora-dev-check > /root/.android/memora-dev-check'
"${compose[@]}" up --detach --force-recreate --wait --wait-timeout 120 dev
[[ "$("${compose[@]}" exec -T dev ssh-keygen -lf /etc/ssh/ssh_host_ed25519_key.pub)" == "$fingerprint" ]]
[[ "$("${compose[@]}" exec -T dev cat /root/.android/memora-dev-check)" == memora-dev-check ]]
"${compose[@]}" exec -T dev rm /root/.android/memora-dev-check
printf '%s\n' '開発環境の起動・セットアップ・SSH・各CLI・Docker接続・再作成後の保持を確認しました'
