#!/usr/bin/env bash

# Run whiptail without letting expected dialog statuses trip errexit.
function tui_whiptail_dialog() {
  local had_errexit="false"
  local status

  case "$-" in
    *e*)
      had_errexit="true"
      set +e
      ;;
  esac

  whiptail "$@"
  status=$?

  if [ "$had_errexit" == "true" ]; then
    set -e
  fi

  return "$status"
}

# Run whiptail and treat ESC/cancel as non-fatal for informational dialogs.
function tui_whiptail_dialog_allow_escape() {
  local had_errexit="false"
  local status

  case "$-" in
    *e*)
      had_errexit="true"
      set +e
      ;;
  esac

  whiptail "$@"
  status=$?

  if [ "$had_errexit" == "true" ]; then
    set -e
  fi

  if [ "$status" -eq 255 ]; then
    return 0
  fi

  return "$status"
}

# Capture whiptail output while preserving its exit status under errexit.
function tui_whiptail_capture() {
  if [ "$#" -lt 1 ]; then
    printf '%s\n' "tui_whiptail_capture: missing output variable" >&2
    return 2
  fi

  local output_var="$1"
  shift

  local had_errexit="false"
  local output=""
  local status

  case "$-" in
    *e*)
      had_errexit="true"
      set +e
      ;;
  esac

  output="$(whiptail "$@" 3>&1 1>&2 2>&3)"
  status=$?

  if [ "$had_errexit" == "true" ]; then
    set -e
  fi

  printf -v "$output_var" '%s' "$output"
  return "$status"
}
