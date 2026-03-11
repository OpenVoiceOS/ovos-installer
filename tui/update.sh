#!/usr/bin/env bash
# shellcheck source=tui/locales/en-us/misc.sh
source "tui/locales/$LOCALE/misc.sh"

# shellcheck source=tui/dialogs.sh
source tui/dialogs.sh

# shellcheck source=tui/locales/en-us/update.sh
source "tui/locales/$LOCALE/update.sh"

if ! tui_whiptail_dialog --yesno --no-button "$NO_BUTTON" --yes-button "$YES_BUTTON" --title "$TITLE" "$CONTENT" "$TUI_WINDOW_HEIGHT" "$TUI_WINDOW_WIDTH"; then
  exit 0
fi
