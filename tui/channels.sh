#!/bin/env bash

# shellcheck source=tui/locales/en-us/channels.sh
source "tui/locales/$LOCALE/channels.sh"

active_channel="testing"
available_channels=(stable testing alpha)

# If a previous selection exists, use it as the default. Only lock the choice
# to that value when upgrading an existing installation.
if [ -f "$INSTALLER_STATE_FILE" ]; then
  current_channel="$(jq -r '.channel // ""' "$INSTALLER_STATE_FILE" 2>>"$LOG_FILE")"
  case "$current_channel" in
    stable|testing|alpha)
      active_channel="$current_channel"
      if [ "${EXISTING_INSTANCE:-false}" == "true" ]; then
        available_channels=("$current_channel")
      fi
      ;;
  esac
fi

list_height="${#available_channels[@]}"
if [ "$list_height" -lt 1 ]; then
  available_channels=(stable testing alpha)
  list_height="${#available_channels[@]}"
fi
if [ "$list_height" -lt 4 ]; then
  list_height=4
fi

whiptail_args=(
  --title "$TITLE"
  --radiolist "$CONTENT"
  --cancel-button "$BACK_BUTTON"
  --ok-button "$OK_BUTTON"
  "$TUI_WINDOW_HEIGHT" "$TUI_WINDOW_WIDTH" "$list_height"
)

for channel in "${available_channels[@]}"; do
  whiptail_args+=("$channel" "")
  if [[ $channel = "$active_channel" ]]; then
    whiptail_args+=("ON")
  else
    whiptail_args+=("OFF")
  fi
done

CHANNEL=$(whiptail "${whiptail_args[@]}" 3>&1 1>&2 2>&3)
export CHANNEL

if [ -z "$CHANNEL" ]; then
  source tui/methods.sh
  source tui/channels.sh
  return
fi

# Persist selection (used for defaults when navigating back or re-running).
state_tmp="$(mktemp)"
if [ -f "$INSTALLER_STATE_FILE" ] && \
  jq --arg channel "$CHANNEL" \
    'if type=="object" then . else {} end | .channel = $channel' \
    "$INSTALLER_STATE_FILE" >"$state_tmp" 2>>"$LOG_FILE"; then
  mv -f "$state_tmp" "$INSTALLER_STATE_FILE"
else
  jq -n --arg channel "$CHANNEL" '{channel: $channel}' >"$state_tmp" 2>>"$LOG_FILE" && \
    mv -f "$state_tmp" "$INSTALLER_STATE_FILE"
fi

# Keep state writable by the target user when running under sudo/root.
if [ -n "${RUN_AS:-}" ] && [ -f "$INSTALLER_STATE_FILE" ]; then
  chown "$RUN_AS":"$(id -ng "$RUN_AS" 2>>"$LOG_FILE")" "$INSTALLER_STATE_FILE" &>>"$LOG_FILE" || true
fi
