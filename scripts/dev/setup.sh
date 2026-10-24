#!/usr/bin/env bash
set -euo pipefail

cd "$(dirname "$0")/../.."
if [[ ! -x /root/.codex/packages/standalone/current/codex ]]; then
  curl -fsSL https://chatgpt.com/codex/install.sh | sh
fi
flutter doctor
flutter --version
flutter pub get
dart pub global activate very_good_cli
mkdir -p /var/lib/memora
touch /var/lib/memora/setup-complete
