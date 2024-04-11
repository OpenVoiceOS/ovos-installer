#!/bin/env bash

# shellcheck source=locales/en-us/channels.sh
source "tui/locales/$LOCALE/channels.sh"

active_channel="development"
available_channels=(development)

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
