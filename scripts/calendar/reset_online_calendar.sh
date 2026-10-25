#!/usr/bin/env bash
set -euo pipefail
if [[ "$#" != 2 || "$2" != --confirm-calendar-delete ]]; then
  echo '使い方: just reset-calendar-online <project-id> --confirm-calendar-delete' >&2
  exit 1
fi
for collection in calendar_event_overrides calendar_events calendar_labels; do
  firebase firestore:delete "$collection" --project "$1" --recursive --force
done
