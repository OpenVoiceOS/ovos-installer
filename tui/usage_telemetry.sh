#!/usr/bin/env bash
export SHARE_USAGE_TELEMETRY="true"

# shellcheck source=tui/dialogs.sh
source tui/dialogs.sh

# shellcheck source=tui/locales/en-us/usage_telemetry.sh
source "tui/locales/$LOCALE/usage_telemetry.sh"

if ! tui_whiptail_dialog --yesno --no-button "$NO_BUTTON" --yes-button "$YES_BUTTON" --title "$TITLE" "$CONTENT" "$TUI_WINDOW_HEIGHT" "$TUI_WINDOW_WIDTH"; then
  export SHARE_USAGE_TELEMETRY="false"
fi
