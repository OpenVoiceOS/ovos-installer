#!/bin/env bash

# shellcheck source=tui/locales/en-us/channels.sh
source "tui/locales/$LOCALE/channels.sh"

active_channel="testing"
available_channels=(stable testing alpha)

# Handle existing installation
if [ -f "$INSTALLER_STATE_FILE" ]; then
  if jq -e 'has("channel")' "$INSTALLER_STATE_FILE" &>>"$LOG_FILE"; then
    current_channel=$(jq -re '.channel' "$INSTALLER_STATE_FILE")
    active_channel="$current_channel"
    available_channels=("$current_channel")
  fi
fi

whiptail_args=(
  --title "$TITLE"
  --radiolist "$CONTENT"
  --cancel-button "$BACK_BUTTON"
  --ok-button "$OK_BUTTON"
  --yes-button "$OK_BUTTON"
  "$TUI_WINDOW_HEIGHT" "$TUI_WINDOW_WIDTH" "${#available_channels[@]}"
)

for channel in "${available_channels[@]}"; do
  whiptail_args+=("$channel" "")
  if [[ $channel = "$active_channel" ]]; then
    whiptail_args+=("on")
  else
    whiptail_args+=("off")
  fi
done

CHANNEL=$(whiptail "${whiptail_args[@]}" 3>&1 1>&2 2>&3)
export CHANNEL

if [ -z "$CHANNEL" ]; then
  source tui/methods.sh
  source tui/channels.sh
fi

jq -en --arg channel "$CHANNEL" '.channel += $channel' >"$TEMP_CHANNEL_FILE"
