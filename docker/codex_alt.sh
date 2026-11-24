#!/usr/bin/env bash
set -euo pipefail

codex_dir="$HOME/.codex"
alt_dir="$codex_dir/account-alt"
codex_bin="$codex_dir/packages/standalone/current/codex"
if [[ ! -x "$codex_bin" ]]; then
  printf '%s\n' 'Codex CLIがありません。ホストで just dev-up を実行してください。' >&2
  exit 1
fi

mkdir -m 700 -p "$alt_dir"
mkdir -p "$codex_dir"/{sessions,archived_sessions,thread-writer-locks,rules,skills}
for entry in config.toml sessions archived_sessions history.jsonl thread-writer-locks .sqlite-maintenance.lock rules skills; do
  target="$alt_dir/$entry"
  if [[ ! -e "$target" && ! -L "$target" ]]; then
    ln -sT "$codex_dir/$entry" "$target" || [[ -L "$target" ]]
  fi
done

CODEX_HOME="$alt_dir" exec "$codex_bin" \
  -c 'cli_auth_credentials_store="file"' \
  -c "sqlite_home=\"$codex_dir\"" "$@"
