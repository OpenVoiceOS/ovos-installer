#!/usr/bin/env bash
while :; do
  # shellcheck source=tui/locales/en-us/summary.sh
  source "tui/locales/$LOCALE/summary.sh"

  whiptail --yesno --no-button "$BACK_BUTTON" --yes-button "$OK_BUTTON" \
    --title "$TITLE" "$CONTENT" "$TUI_WINDOW_HEIGHT" "$TUI_WINDOW_WIDTH"

  exit_status=$?
  if [ "$exit_status" -eq 0 ]; then
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
