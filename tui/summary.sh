#!/bin/env bash

# shellcheck source=locales/en-us/summary.sh
source "tui/locales/$LOCALE/summary.sh"

whiptail --yesno --defaultno --no-button "$NO_BUTTON" --yes-button "$YES_BUTTON" --title "$TITLE" "$CONTENT" "$TUI_WINDOW_HEIGHT" "$TUI_WINDOW_WIDTH"

exit_status=$?
if [ "$exit_status" -eq 1 ]; then
  exit 0
fi
