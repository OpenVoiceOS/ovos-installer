#!/usr/bin/env bash
export SHARE_USAGE_TELEMETRY="true"

# shellcheck source=tui/locales/en-us/usage_telemetry.sh
source "tui/locales/$LOCALE/usage_telemetry.sh"

whiptail --yesno --no-button "$NO_BUTTON" --yes-button "$YES_BUTTON" --title "$TITLE" "$CONTENT" "$TUI_WINDOW_HEIGHT" "$TUI_WINDOW_WIDTH"

exit_status=$?
if [ "$exit_status" -ne 0 ]; then
  export SHARE_USAGE_TELEMETRY="false"
fi
