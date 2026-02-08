#!/usr/bin/env bash
export SHARE_TELEMETRY="true"

# shellcheck source=tui/locales/en-us/telemetry.sh
source "tui/locales/$LOCALE/telemetry.sh"

whiptail --yesno --no-button "$NO_BUTTON" --yes-button "$YES_BUTTON" --title "$TITLE" "$CONTENT" "$TUI_WINDOW_HEIGHT" "$TUI_WINDOW_WIDTH"

exit_status=$?
if [ "$exit_status" -ne 0 ]; then
  export SHARE_TELEMETRY="false"
fi
