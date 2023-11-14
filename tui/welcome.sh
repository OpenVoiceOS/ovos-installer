#!/bin/env bash

# shellcheck source=locales/en-us/welcome.sh
source "tui/locales/$LOCALE/welcome.sh"

whiptail --msgbox --ok-button "$OK_BUTTON" --title "${TITLE}" "$CONTENT" 25 80
