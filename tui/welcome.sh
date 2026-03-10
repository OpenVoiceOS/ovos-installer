#!/usr/bin/env bash
# shellcheck source=tui/dialogs.sh
source tui/dialogs.sh
# shellcheck source=tui/locales/en-us/welcome.sh
source "tui/locales/$LOCALE/welcome.sh"

tui_whiptail_dialog_allow_escape --msgbox --ok-button "$OK_BUTTON" --title "${TITLE}" "$CONTENT" "$TUI_WINDOW_HEIGHT" "$TUI_WINDOW_WIDTH"
