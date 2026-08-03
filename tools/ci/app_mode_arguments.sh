#!/usr/bin/env bash

resolve_memora_app_mode() {
  local app_mode='auto'
  local prev=''
  local arg

  for arg in "$@"; do
    if [ "$prev" = '--dart-define' ]; then
      case "$arg" in
        MEMORA_APP_MODE=*)
          app_mode="${arg#MEMORA_APP_MODE=}"
          ;;
      esac
      prev=''
      continue
    fi

    case "$arg" in
      --dart-define=MEMORA_APP_MODE=*)
        app_mode="${arg#--dart-define=MEMORA_APP_MODE=}"
        ;;
      --dart-define)
        prev='--dart-define'
        ;;
    esac
  done

  case "$app_mode" in
    auto|online|offline)
      printf '%s\n' "$app_mode"
      ;;
    *)
      echo 'MEMORA_APP_MODEにはauto、online、offlineのいずれかを指定してください。' >&2
      return 1
      ;;
  esac
}
