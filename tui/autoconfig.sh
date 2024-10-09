#!/bin/env bash

# shellcheck source=locales/en-us/autoconfig.sh
source "tui/locales/$LOCALE/autoconfig.sh"

export AUTOCONFIG = "true"
whiptail --yesno --defaultno --no-button "$NO_BUTTON" --yes-button "$YES_BUTTON" --title "$TITLE" "$CONTENT" "$TUI_WINDOW_HEIGHT" "$TUI_WINDOW_WIDTH"

exit_status=$?
if [ "$exit_status" -ne 1 ]; then
  source autoconfig/main.sh
fi

export AUTOCONFIG = "false"
