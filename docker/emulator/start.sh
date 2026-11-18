#!/usr/bin/env bash
set -euo pipefail

avd_name=memora_aosp_api36
avd_path="$ANDROID_AVD_HOME/$avd_name.avd"
mkdir -p "$avd_path" /root/.android/memora-adb
if [[ ! -f "$avd_path/config.ini" ]]; then
  cp /opt/memora-emulator/config.ini "$avd_path/config.ini"
fi
printf 'avd.ini.encoding=UTF-8\npath=%s\ntarget=android-36\n' "$avd_path" > "$ANDROID_AVD_HOME/$avd_name.ini"

socat UNIX-LISTEN:/root/.android/memora-adb/adbd.sock,fork,unlink-early TCP:127.0.0.1:5555 &
adb start-server
(
  for ((attempt = 0; attempt < 90; attempt++)); do
    adb connect 127.0.0.1:5555 >/dev/null 2>&1 || true
    if [[ "$(adb -s 127.0.0.1:5555 get-state 2>/dev/null)" == device ]]; then
      exit 0
    fi
    sleep 2
  done
  printf '%s\n' 'エミュレータへのADB接続がタイムアウトしました' >&2
  exit 1
) &

exec emulator -avd "$avd_name" \
  -no-window -no-audio -no-boot-anim -no-snapshot \
  -gpu swiftshader -accel on -memory 2048 -cores 2 \
  -camera-back none -camera-front none -port 5554 -no-metrics
