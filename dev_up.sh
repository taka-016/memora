#!/usr/bin/env bash
set -euo pipefail

cd "$(dirname "${BASH_SOURCE[0]}")"
bash docker/initialize.sh
docker compose up -d --build --wait --wait-timeout 120 dev
docker compose exec -T dev bash -c '
  if [[ ! -f /var/lib/memora/setup-complete ]]; then
    bash docker/setup.sh
  fi
'
