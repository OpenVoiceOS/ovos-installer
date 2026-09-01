#!/usr/bin/env bash
# shellcheck source=tui/navigation.sh
source tui/navigation.sh

# shellcheck source=tui/locales/en-us/update.sh
source "tui/locales/$LOCALE/update.sh"

# Declining here is the way out for an existing installation: there is nothing
# to uninstall and nothing to update, so the installer has no work left.
if ! tui_whiptail_dialog --yesno --no-button "$NO_BUTTON" --yes-button "$YES_BUTTON" --title "$TITLE" "$CONTENT" "$TUI_WINDOW_HEIGHT" "$TUI_WINDOW_WIDTH"; then
  tui_nav_quit
fi
