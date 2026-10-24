#!/usr/bin/env bash
set -euo pipefail

cd "$(dirname "$0")/../.."
compose=(docker compose -f compose.yaml)
if "${compose[@]}" config --services | grep -qx emulator; then
  printf '%s\n' '通常起動にエミュレータが含まれています' >&2
  exit 1
fi
unset ADB_SERVER_SOCKET
serial=localfilesystem:/root/.android/memora-adb/adbd.sock
screenshot=''
cleanup() {
  if [[ -n "$screenshot" ]]; then
    rm -f "$screenshot"
  fi
  adb disconnect "$serial" >/dev/null 2>&1 || true
  "${compose[@]}" stop emulator
}
trap cleanup EXIT
"${compose[@]}" up --build --detach --wait --wait-timeout 300 emulator
adb connect "$serial"
adb_command() {
  adb -s "$serial" "$@"
}

[[ "$(adb_command shell getprop sys.boot_completed | tr -d '\r')" == 1 ]]
[[ "$("${compose[@]}" exec -T emulator ls /sys/class/net)" == lo ]]
[[ -z "$(adb_command shell pm list packages com.google.android.gms)" ]]

screenshot="$(mktemp)"
adb_command exec-out screencap -p > "$screenshot"
[[ "$(od -An -tx1 -N8 "$screenshot" | tr -d ' \n')" == 89504e470d0a1a0a ]]

adb_command shell 'printf memora-forward | toybox nc -l -p 45678 -w 20' &
listener_pid=$!
port="$(adb_command forward tcp:0 tcp:45678)"
python3 - "$port" <<'PYTHON'
import socket
import sys
import time

for attempt in range(40):
    try:
        with socket.create_connection(('127.0.0.1', int(sys.argv[1])), timeout=2) as connection:
            assert connection.recv(64) == b'memora-forward'
        break
    except (OSError, AssertionError):
        if attempt == 39:
            raise
        time.sleep(0.25)
PYTHON
wait "$listener_pid"
adb_command forward --remove "tcp:$port"

marker="memora-compose-${RANDOM}"
adb_command shell "echo '$marker' > /data/local/tmp/memora-compose-test"
adb_command shell sync
"${compose[@]}" restart emulator
"${compose[@]}" up --detach --wait --wait-timeout 300 emulator
adb disconnect "$serial"
adb connect "$serial"
[[ "$(adb_command shell cat /data/local/tmp/memora-compose-test | tr -d '\r')" == "$marker" ]]
adb_command shell rm /data/local/tmp/memora-compose-test
printf '%s\n' 'Android起動・ADB操作・画面取得・通信隔離・Flutter用ポート転送・再起動後のデータ保持を確認しました'
