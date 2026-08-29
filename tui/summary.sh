#!/usr/bin/env bash
# shellcheck source=tui/dialogs.sh
source tui/dialogs.sh

function summary_toggle_state() {
  local value="${1:-}"

  case "${value,,}" in
    true|yes|enabled|on)
      printf '%s\n' "enabled"
      ;;
    false|no|disabled|off|"")
      printf '%s\n' "disabled"
      ;;
    *)
      printf '%s\n' "$value"
      ;;
  esac
}

# A feature can be selected and still not be applied, either because the profile
# does not support it or because its configuration is incomplete. Say which.
function summary_feature_state() {
  local selected="${1:-false}"
  local configured="${2:-false}"
  local incomplete_state="$3"

  if [ "$selected" != "true" ]; then
    printf '%s\n' "disabled"
    return
  fi

  if [ "${PROFILE:-}" == "server" ] || [ "${PROFILE:-}" == "satellite" ]; then
    printf '%s\n' "selected (not supported for this profile)"
    return
  fi

  if [ "$configured" == "true" ]; then
    printf '%s\n' "enabled"
    return
  fi

  printf '%s\n' "$incomplete_state"
}

# Recomputed on every pass: the user can go back, change a choice, and come
# straight back to this screen.
function summary_refresh_states() {
  export FEATURE_SKILLS_SUMMARY_STATE
  FEATURE_SKILLS_SUMMARY_STATE="$(summary_toggle_state "${FEATURE_SKILLS:-false}")"

  export FEATURE_EXTRA_SKILLS_SUMMARY_STATE
  FEATURE_EXTRA_SKILLS_SUMMARY_STATE="$(summary_toggle_state "${FEATURE_EXTRA_SKILLS:-false}")"

  export TUNING_SUMMARY_STATE
  TUNING_SUMMARY_STATE="$(summary_toggle_state "${TUNING:-no}")"

  local homeassistant_configured="false"
  if [ -n "${HOMEASSISTANT_URL:-}" ]; then
    homeassistant_configured="true"
  fi

  export HOMEASSISTANT_SUMMARY_STATE
  HOMEASSISTANT_SUMMARY_STATE="$(summary_feature_state \
    "${FEATURE_HOMEASSISTANT:-false}" \
    "$homeassistant_configured" \
    "selected (missing URL; will be skipped)")"

  local llm_configured="false"
  if [ -n "${LLM_API_URL:-}" ] && [ -n "${LLM_API_KEY:-}" ] &&
    [ -n "${LLM_MODEL:-}" ] && [ -n "${LLM_PERSONA:-}" ]; then
    llm_configured="true"
  fi

  export LLM_SUMMARY_STATE
  LLM_SUMMARY_STATE="$(summary_feature_state \
    "${FEATURE_LLM:-false}" \
    "$llm_configured" \
    "selected (missing configuration; will be skipped)")"
}

while :; do
  summary_refresh_states

  # shellcheck source=tui/locales/en-us/summary.sh
  source "tui/locales/$LOCALE/summary.sh"

  if tui_whiptail_dialog --yesno --no-button "$BACK_BUTTON" --yes-button "$OK_BUTTON" \
    --title "$TITLE" "$CONTENT" "$TUI_WINDOW_HEIGHT" "$TUI_WINDOW_WIDTH"; then
    break
  fi

  # Go back and allow the user to adjust choices. ESC returns 255 in whiptail,
  # which we treat as "Back" here.
  if [[ "${RASPBERRYPI_MODEL:-N/A}" != "N/A" ]]; then
    source tui/tuning.sh
  elif [[ "${PROFILE:-}" == "satellite" ]]; then
    source tui/satellite/main.sh
  else
    source tui/features.sh
  fi
done
