#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/../.."
source scripts/test/firestore_reads/process.sh
read_regression_active_pid=''

scenario="${1:-baseline-queries}"
[[ "$scenario" =~ ^[a-z0-9-]+$ ]] || { echo 'シナリオIDが不正です' >&2; exit 64; }
for command in docker adb firebase dart flutter python3 flock timeout setsid; do
  command -v "$command" >/dev/null || { echo "$command が必要です" >&2; exit 69; }
done
java_home="${MEMORA_FIREBASE_JAVA_HOME:-${JAVA_HOME:-}}"
[[ -n "$java_home" && -x "$java_home/bin/java" ]] || { echo 'MEMORA_FIREBASE_JAVA_HOMEにJava 21以上の場所を指定してください' >&2; exit 69; }
java_major="$("$java_home/bin/java" -version 2>&1 | sed -n 's/.*version "\([0-9]*\).*/\1/p' | head -1)"
[[ "$java_major" =~ ^[0-9]+$ && "$java_major" -ge 21 ]] || { echo 'Firebase EmulatorにはJava 21以上が必要です' >&2; exit 69; }
exec 9>/tmp/memora-firestore-read-regression.lock
flock -n 9 || { echo '別の読み取り回帰テストが実行中です' >&2; exit 73; }
python3 - <<'PY'
import socket
for port in (4400, 4500, 8080, 9099, 9151, 8765):
    with socket.socket() as sock:
        sock.setsockopt(socket.SOL_SOCKET, socket.SO_REUSEADDR, 1)
        try:
            sock.bind(('127.0.0.1', port))
        except OSError:
            raise SystemExit(f'テスト用ポート{port}が使用中です')
PY
run_id="reads-$(date -u +%Y%m%d%H%M%S)-$$"
output="$(pwd)/build/firestore_read_regression/$run_id"
mkdir -p "$output"
work="$(mktemp -d)"
volume="memora-$run_id-data"
socket_directory="/root/.android/memora-$run_id"
serial="localfilesystem:$socket_directory/adbd.sock"
compose=(docker compose --profile test --project-name "memora-$run_id" -f compose.yaml -f "$work/compose.yaml")
firebase_pid=''
host_pid=''
logcat_pid=''
container_started=false
connected=false
reverse_ports=()
cleanup() {
  status=$?
  trap - EXIT INT TERM
  set +e
  cleanup_failed=0
  read_regression_stop "$read_regression_active_pid" || cleanup_failed=1
  if [[ -n "$logcat_pid" ]]; then kill "$logcat_pid" 2>/dev/null; wait "$logcat_pid" 2>/dev/null; fi
  for port in "${reverse_ports[@]}"; do
    adb -s "$serial" reverse --remove "tcp:$port" >>"$output/cleanup.log" 2>&1 || cleanup_failed=1
  done
  if "$connected"; then adb disconnect "$serial" >>"$output/cleanup.log" 2>&1 || cleanup_failed=1; fi
  if "$container_started"; then
    "${compose[@]}" logs emulator >"$output/android-emulator.log" 2>&1
    "${compose[@]}" down --timeout 30 >>"$output/cleanup.log" 2>&1 || cleanup_failed=1
    docker volume rm "$volume" >>"$output/cleanup.log" 2>&1 || cleanup_failed=1
  fi
  for pid in "$host_pid" "$firebase_pid"; do
    read_regression_stop "$pid" >>"$output/cleanup.log" 2>&1 || cleanup_failed=1
  done
  rm -rf -- "$socket_directory" "$work" || cleanup_failed=1
  if [[ "$status" -eq 0 && "$cleanup_failed" -ne 0 ]]; then status=1; fi
  printf '{"exitCode":%s,"cleanupFailed":%s}\n' "$status" "$cleanup_failed" >"$output/exit.json"
  printf '結果: %s\n' "$output"
  exit "$status"
}
trap cleanup EXIT
trap 'exit 130' INT
trap 'exit 143' TERM
cat >"$work/compose.yaml" <<YAML
services:
  emulator:
    image: memora-firestore-read-regression-emulator
    environment:
      MEMORA_ADB_DIRECTORY: $socket_directory
volumes:
  emulator-data:
    name: $volume
YAML

wait_http() {
  read_regression_run python3 - "$1" "$2" <<'PY'
import json, sys, time, urllib.request
url, expected = sys.argv[1:]
deadline = time.monotonic() + 120
while time.monotonic() < deadline:
    try:
        with urllib.request.urlopen(url, timeout=2) as response:
            body = json.load(response)
        if expected == 'firebase':
            if not all(key in body for key in ('auth', 'firestore')):
                raise ValueError('準備中')
        elif body.get('runId') != expected:
            raise ValueError('実行IDの異なる集約サーバーです')
        break
    except (OSError, ValueError):
        time.sleep(0.25)
else:
    raise SystemExit(f'準備完了待機がタイムアウトしました: {url}')
PY
}

read_regression_run dart scripts/test/firestore_reads/host.dart \
  test/fixtures/firestore_read_regression "$scenario" "$output" "$run_id" --validate >"$output/validation.log" 2>&1
setsid env JAVA_HOME="$java_home" PATH="$java_home/bin:$PATH" CI=true FIREBASE_CLI_DISABLE_TELEMETRY=1 \
  firebase emulators:start --config firestore_read_regression.emulators.json \
  --project demo-memora-read-regression --only auth,firestore >"$output/firebase.log" 2>&1 &
firebase_pid=$!
wait_http http://127.0.0.1:4400/emulators firebase
setsid dart scripts/test/firestore_reads/host.dart \
  test/fixtures/firestore_read_regression "$scenario" "$output" "$run_id" >"$output/collector.log" 2>&1 &
host_pid=$!
wait_http http://127.0.0.1:8765/health "$run_id"
# 入力検査済みのbundleから投入対象を選ぶ。
python3 - "$output/bundle.json" "$work/dataset.json" <<'PY'
import json, sys
with open(sys.argv[1]) as stream:
    dataset = json.load(stream)['dataset']
with open(sys.argv[2], 'w') as stream:
    json.dump(dataset, stream)
PY
read_regression_run dart scripts/test/firestore_reads/seed.dart seed "$work/dataset.json" >"$output/seed.json" 2>&1
container_started=true
read_regression_run timeout --signal=TERM --kill-after=30 900 "${compose[@]}" up --build --detach --wait --wait-timeout 300 emulator >"$output/compose.log" 2>&1
unset ADB_SERVER_SOCKET
adb connect "$serial" >"$output/adb.log" 2>&1
connected=true
for port in 8080 9099 8765; do
  adb -s "$serial" reverse "tcp:$port" "tcp:$port" >>"$output/adb.log" 2>&1
  reverse_ports+=("$port")
done
time_zone="$(python3 -c 'import json,sys; print(json.load(open(sys.argv[1]))["scenario"]["timeZone"])' "$output/bundle.json")"
adb -s "$serial" shell cmd alarm set-timezone "$time_zone" >>"$output/adb.log" 2>&1
adb -s "$serial" logcat -v threadtime >"$output/logcat.log" 2>&1 &
logcat_pid=$!
set +e
read_regression_run env GRADLE_OPTS="${GRADLE_OPTS:-} -Dorg.gradle.daemon=false" timeout --signal=TERM --kill-after=30 1200 flutter test \
  integration_test/firestore_read_regression/queries_test.dart \
  --flavor online -d "$serial" --dart-define-from-file="$output/defines.json" \
  >"$output/flutter.log" 2>&1
test_status=$?
set -e
dart scripts/test/firestore_reads/report.dart "$output" test/fixtures/firestore_read_regression >"$output/report.log" 2>&1 || {
  [[ "$test_status" -ne 0 ]] && exit "$test_status"
  exit 1
}
exit "$test_status"
