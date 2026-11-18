#!/usr/bin/env bash

read_regression_run() {
  local managed_status
  setsid "$@" <&0 &
  read_regression_active_pid=$!
  if wait "$read_regression_active_pid"; then managed_status=0; else managed_status=$?; fi
  read_regression_active_pid=''
  return "$managed_status"
}

read_regression_stop() {
  local managed_pid="${1:-}"
  [[ -n "$managed_pid" ]] || return 0
  kill -TERM -- "-$managed_pid" 2>/dev/null || true
  for ((attempt=0; attempt<40; attempt++)); do
    if ! kill -0 -- "-$managed_pid" 2>/dev/null; then
      wait "$managed_pid" 2>/dev/null || true
      return 0
    fi
    sleep 0.1
  done
  kill -KILL -- "-$managed_pid" 2>/dev/null || true
  wait "$managed_pid" 2>/dev/null || true
  for ((attempt=0; attempt<40; attempt++)); do
    kill -0 -- "-$managed_pid" 2>/dev/null || return 1
    sleep 0.1
  done
  return 1
}
