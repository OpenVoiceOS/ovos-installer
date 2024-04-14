#!/bin/env bash

# shellcheck source=locales/en-us/tuning.sh
source "tui/locales/$LOCALE/tuning.sh"

active_option="yes"
available_options=(yes no)

whiptail_args=(
  --title "$TITLE"
  --radiolist "$CONTENT"
  --cancel-button "$BACK_BUTTON"
  --ok-button "$OK_BUTTON"
  --yes-button "$OK_BUTTON"
  "$TUI_WINDOW_HEIGHT" "$TUI_WINDOW_WIDTH" "${#available_options[@]}"
)

for option in "${available_options[@]}"; do
  whiptail_args+=("$option" "")
  if [[ $option = "$active_option" ]]; then
    whiptail_args+=("on")
  else
    whiptail_args+=("off")
  fi
done

TUNING=$(whiptail "${whiptail_args[@]}" 3>&1 1>&2 2>&3)

exit_status=$?

if [ "$exit_status" -eq 0 ]; then
  export TUNING
else
  source tui/features.sh
  source tui/tuning.sh
fi
