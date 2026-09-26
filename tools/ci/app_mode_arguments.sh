#!/usr/bin/env bash

resolve_memora_app_mode() {
  local app_mode="${1:-online}"

  case "$app_mode" in
    online|offline)
      printf '%s\n' "$app_mode"
      ;;
    *)
      echo 'アプリモードにはonline、offlineのいずれかを指定してください。' >&2
      return 1
      ;;
  esac
}

validate_memora_app_arguments() {
  local previous=''
  local argument

  for argument in "$@"; do
    if [ "$previous" = 'dart-define' ]; then
      if [[ "$argument" == MEMORA_APP_MODE=* ]]; then
        echo 'MEMORA_APP_MODEは第1引数のアプリモードから決定するため指定できません。' >&2
        return 1
      fi
      previous=''
      continue
    fi

    case "$argument" in
      --dart-define|--DartDefines|-D)
        previous='dart-define'
        ;;
      --dart-define=MEMORA_APP_MODE=*|--DartDefines=MEMORA_APP_MODE=*|-DMEMORA_APP_MODE=*)
        echo 'MEMORA_APP_MODEは第1引数のアプリモードから決定するため指定できません。' >&2
        return 1
        ;;
      --flavor|--flavor=*)
        echo 'flavorは第1引数のアプリモードから決定するため指定できません。' >&2
        return 1
        ;;
    esac
  done
}
