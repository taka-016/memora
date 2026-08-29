#!/bin/bash

set -o pipefail

CHECK_STARTED_AT=$SECONDS

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$ROOT_DIR/tools/ci/app_mode_arguments.sh"
if ! app_mode="$(resolve_memora_app_mode "$@")"; then
    exit 1
fi

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

extract_test_count() {
    local test_progress
    test_progress="$({
        tr '\r' '\n' < "$STDOUT_LOG" |
            grep -Eo '\+[0-9]+:' |
            tail -n 1
    } || true)"

    if [[ -z "$test_progress" ]]; then
        echo 0
        return
    fi

    test_progress="${test_progress#+}"
    echo "${test_progress%:}"
}

format_duration() {
    local total_seconds="$1"
    local minutes=$((total_seconds / 60))
    local seconds=$((total_seconds % 60))

    printf '%d分%d秒' "$minutes" "$seconds"
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
run_step "Build runner" dart run build_runner build
run_step "Analyze" flutter analyze
echo "MEMORA_APP_MODE=${app_mode}"

run_step "Test" dart pub global run very_good_cli:very_good test "$@"

TEST_COUNT="$(extract_test_count)"
echo "テスト実施件数: ${TEST_COUNT}件"

echo "✅ All checks passed!"
echo "Stdout log: $STDOUT_LOG"
echo "Stderr log: $STDERR_LOG"
ELAPSED_SECONDS=$((SECONDS - CHECK_STARTED_AT))
echo "所要時間: $(format_duration "$ELAPSED_SECONDS")"
