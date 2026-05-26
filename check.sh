#!/bin/bash

set -o pipefail

LOG_DIR="${TMPDIR:-/tmp}"
STDOUT_LOG="$LOG_DIR/memora-check.stdout.log"
STDERR_LOG="$LOG_DIR/memora-check.stderr.log"
: > "$STDOUT_LOG"
: > "$STDERR_LOG"

RED="$(printf '\033[31m')"
RESET="$(printf '\033[0m')"

error_log() {
    printf '%b\n' "${RED}$*${RESET}" >&2
}

run_step() {
    local label="$1"
    shift

    echo "▶ $label..."
    if "$@" >> "$STDOUT_LOG" 2>> "$STDERR_LOG"; then
        echo "✅ $label passed"
        return 0
    fi

    error_log "❌ $label failed"
    error_log "---- error lines ----"
    {
        grep -Ei "exception|error|failed|failure|fatal|could not|some tests failed" "$STDERR_LOG" || true
        grep -Ei "exception|error|failed|failure|fatal|could not|some tests failed" "$STDOUT_LOG" || true
    } | tail -n 80 >&2
    error_log "---- stderr tail ----"
    tail -n 120 "$STDERR_LOG" >&2
    echo "---- log tail ----"
    tail -n 120 "$STDOUT_LOG"
    echo "Stdout log: $STDOUT_LOG"
    error_log "Stderr log: $STDERR_LOG"
    exit 1
}

run_step "Format" dart format .
run_step "Build runner" dart run build_runner build --delete-conflicting-outputs
run_step "Analyze" flutter analyze
run_step "Test" dart pub global run very_good_cli:very_good test

echo "✅ All checks passed!"
echo "Stdout log: $STDOUT_LOG"
echo "Stderr log: $STDERR_LOG"
