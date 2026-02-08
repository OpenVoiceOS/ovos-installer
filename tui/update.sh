#!/bin/env bash

# shellcheck source=tui/locales/en-us/misc.sh
source "tui/locales/$LOCALE/misc.sh"

# shellcheck source=tui/locales/en-us/update.sh
source "tui/locales/$LOCALE/update.sh"

whiptail --yesno --no-button "$NO_BUTTON" --yes-button "$YES_BUTTON" --title "$TITLE" "$CONTENT" "$TUI_WINDOW_HEIGHT" "$TUI_WINDOW_WIDTH"

exit_status=$?
if [ "$exit_status" -ne 0 ]; then
  exit 0
fi
