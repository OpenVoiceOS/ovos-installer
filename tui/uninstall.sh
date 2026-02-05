#!/bin/env bash

export CONFIRM_UNINSTALL="true"

# shellcheck source=tui/locales/en-us/misc.sh
source "tui/locales/$LOCALE/misc.sh"

# shellcheck source=tui/locales/en-us/uninstall.sh
source "tui/locales/$LOCALE/uninstall.sh"

whiptail --yesno --defaultno --no-button "$NO_BUTTON" --yes-button "$YES_BUTTON" --title "$TITLE" "$CONTENT" "$TUI_WINDOW_HEIGHT" "$TUI_WINDOW_WIDTH"

exit_status=$?
if [ "$exit_status" -eq 1 ]; then
  export CONFIRM_UNINSTALL="false"

  # shellcheck source=tui/update.sh
  source tui/update.sh
fi
