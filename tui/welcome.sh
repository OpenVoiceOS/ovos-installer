#!/usr/bin/env bash
# shellcheck source=tui/navigation.sh
source tui/navigation.sh
# shellcheck source=tui/locales/en-us/welcome.sh
source "tui/locales/$LOCALE/welcome.sh"

# A yes/no box rather than a message box: the extra button is what gives the
# first screen a "Back", which returns to the language picker.
tui_nav_dialog --yesno --yes-button "$OK_BUTTON" --no-button "$BACK_BUTTON" \
  --title "${TITLE}" "$CONTENT" "$TUI_WINDOW_HEIGHT" "$TUI_WINDOW_WIDTH" || true
