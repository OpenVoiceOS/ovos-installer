#!/usr/bin/env bash
export SHARE_TELEMETRY="true"

# shellcheck source=tui/dialogs.sh
source tui/dialogs.sh

# shellcheck source=tui/locales/en-us/telemetry.sh
source "tui/locales/$LOCALE/telemetry.sh"

if ! tui_whiptail_dialog --yesno --no-button "$NO_BUTTON" --yes-button "$YES_BUTTON" --title "$TITLE" "$CONTENT" "$TUI_WINDOW_HEIGHT" "$TUI_WINDOW_WIDTH"; then
  export SHARE_TELEMETRY="false"
fi
