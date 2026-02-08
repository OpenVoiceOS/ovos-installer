#!/usr/bin/env bash
CONFIG_FILE="${RUN_AS_HOME}/.config/mycroft/mycroft.conf"
if [[ "$METHOD" == "containers" ]]; then
    CONFIG_FILE="${RUN_AS_HOME}/ovos/config/mycroft.conf"
fi
export CONFIG_FILE

# shellcheck source=tui/locales/en-us/finish.sh
source "tui/locales/$LOCALE/finish.sh"

whiptail --msgbox --ok-button "$OK_BUTTON" --title "$TITLE" "$CONTENT" "$TUI_WINDOW_HEIGHT" "$TUI_WINDOW_WIDTH"
