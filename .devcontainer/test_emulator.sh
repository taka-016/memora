#!/usr/bin/env bash
set -euo pipefail

cd "$(dirname "$0")"
compose=(docker compose -f compose.yaml)
"${compose[@]}" up --build --detach --wait --wait-timeout 300 emulator
adb_command() {
  "${compose[@]}" exec -T emulator adb -s 127.0.0.1:5555 "$@"
}

[[ "$(adb_command shell getprop sys.boot_completed | tr -d '\r')" == 1 ]]
[[ "$("${compose[@]}" exec -T emulator ls /sys/class/net)" == lo ]]
[[ -z "$(adb_command shell pm list packages com.google.android.gms)" ]]

screenshot="$(mktemp)"
trap 'rm -f "$screenshot"' EXIT
adb_command exec-out screencap -p > "$screenshot"
[[ "$(od -An -tx1 -N8 "$screenshot" | tr -d ' \n')" == 89504e470d0a1a0a ]]

marker="memora-compose-${RANDOM}"
adb_command shell "echo '$marker' > /data/local/tmp/memora-compose-test"
"${compose[@]}" restart emulator
"${compose[@]}" up --detach --wait --wait-timeout 300 emulator
[[ "$(adb_command shell cat /data/local/tmp/memora-compose-test | tr -d '\r')" == "$marker" ]]
adb_command shell rm /data/local/tmp/memora-compose-test
printf '%s\n' 'Android起動・ADB操作・画面取得・通信隔離・再起動後のデータ保持を確認しました'
